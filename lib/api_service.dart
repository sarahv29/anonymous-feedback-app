import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Eroare cu mesaj citibil, venita fie de la server, fie de la retea.
class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

/// Un feedback afisat in lista publica.
class FeedbackItem {
  final String username;
  final String version;
  final int rating;
  final String comment;
  final String timestamp;
  final String manufacturer;
  final String model;
  final String androidVersion;
  final String sentiment;

  FeedbackItem({
    required this.username,
    required this.version,
    required this.rating,
    required this.comment,
    required this.timestamp,
    required this.manufacturer,
    required this.model,
    required this.androidVersion,
    required this.sentiment,
  });

  bool get isPositive => sentiment == 'positive';
  bool get isNegative => sentiment == 'negative';

  String get deviceLabel {
    final parts = [manufacturer, model].where((p) => p.isNotEmpty);
    return parts.isEmpty ? '' : parts.join(' ');
  }

  factory FeedbackItem.fromJson(Map<String, dynamic> json) {
    return FeedbackItem(
      username: json['username']?.toString() ?? 'anonymous',
      version: json['software_version']?.toString() ?? '',
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      comment: json['comment']?.toString() ?? '',
      timestamp: json['timestamp']?.toString() ?? '',
      manufacturer: json['manufacturer']?.toString() ?? '',
      model: json['model']?.toString() ?? '',
      androidVersion: json['android_version']?.toString() ?? '',
      sentiment: json['sentiment']?.toString() ?? 'neutral',
    );
  }
}

/// Statistica agregata pentru o versiune.
class VersionStat {
  final String version;
  final int totalReviews;
  final double avgRating;

  VersionStat({
    required this.version,
    required this.totalReviews,
    required this.avgRating,
  });

  factory VersionStat.fromJson(Map<String, dynamic> json) {
    return VersionStat(
      version: json['software_version']?.toString() ?? '',
      totalReviews: (json['total_reviews'] as num?)?.toInt() ?? 0,
      avgRating: (json['avg_rating'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ApiService {
  /// Adresa backendului de pe Render.
  static const String baseUrl = 'https://feedback-mobile-app-1.onrender.com';

  /// Instanta gratuita Render adoarme dupa 15 minute de inactivitate
  /// si are nevoie de pana la 50 de secunde ca sa se trezeasca.
  /// Fara un timeout generos, prima cerere ar esua mereu.
  static const Duration _timeout = Duration(seconds: 60);

  static const String _tokenKey = 'auth_token';
  static const String _emailKey = 'user_email';

  static String? _token;
  static String? _email;

  static bool get isLoggedIn => _token != null;
  static String? get currentEmail => _email;

  // ==================== SESIUNE ====================

  /// Se apeleaza o singura data, la pornirea aplicatiei.
  /// Recupereaza token-ul salvat, ca utilizatorul sa nu se reautentifice de fiecare data.
  static Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    _email = prefs.getString(_emailKey);
  }

  static Future<void> _saveSession(String token, String email) async {
    _token = token;
    _email = email;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_emailKey, email);
  }

  static Future<void> _clearSession() async {
    _token = null;
    _email = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_emailKey);
  }

  // ==================== INFRASTRUCTURA ====================

  static Map<String, String> get _headers {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  /// Decodifica raspunsul si transforma erorile serverului in ApiException.
  static dynamic _decode(http.Response response) {
    dynamic body;
    try {
      body = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      throw ApiException('Invalid response from the server (${response.statusCode}).');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    if (body is Map && body['error'] != null) {
      throw ApiException(body['error'].toString());
    }
    throw ApiException('Server error (${response.statusCode}).');
  }

  /// Un singur loc unde tratam problemele de retea,
  /// ca fiecare ecran sa primeasca un mesaj clar in loc de o exceptie bruta.
  static Future<T> _guard<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on ApiException {
      rethrow;
    } on SocketException {
      throw ApiException('No internet connection.');
    } on HttpException {
      throw ApiException('The server did not respond.');
    } on FormatException {
      throw ApiException('Invalid response from the server.');
    } catch (e) {
      throw ApiException('The server is not responding. Please try again.');
    }
  }

  // ==================== CONT ====================

  static Future<void> register(String email, String password) {
    return _guard(() async {
      final response = await http
          .post(
            Uri.parse('$baseUrl/register'),
            headers: _headers,
            body: jsonEncode({'username': email, 'password': password}),
          )
          .timeout(_timeout);

      final data = _decode(response) as Map<String, dynamic>;
      final token = data['token']?.toString();
      if (token == null) {
        throw ApiException('The server did not return a token.');
      }
      await _saveSession(token, email);
    });
  }

  static Future<void> login(String email, String password) {
    return _guard(() async {
      final response = await http
          .post(
            Uri.parse('$baseUrl/login'),
            headers: _headers,
            body: jsonEncode({'username': email, 'password': password}),
          )
          .timeout(_timeout);

      final data = _decode(response) as Map<String, dynamic>;
      final token = data['token']?.toString();
      if (token == null) {
        throw ApiException('The server did not return a token.');
      }
      await _saveSession(token, email);
    });
  }

  /// Deconectarea sterge sesiunea local chiar daca serverul nu raspunde --
  /// altfel utilizatorul ar ramane blocat autentificat.
  static Future<void> logout() async {
    try {
      await http
          .get(Uri.parse('$baseUrl/logout'), headers: _headers)
          .timeout(_timeout);
    } catch (_) {
      // ignorat intentionat
    }
    await _clearSession();
  }

  static Future<void> deleteAccount(String email, String password) {
    return _guard(() async {
      final response = await http
          .post(
            Uri.parse('$baseUrl/account/delete'),
            headers: _headers,
            body: jsonEncode({'username': email, 'password': password}),
          )
          .timeout(_timeout);

      _decode(response);
      await _clearSession();
    });
  }

  // ==================== FEEDBACK ====================

  static Future<void> submitFeedback({
    required String version,
    required int rating,
    required String comment,
    String manufacturer = '',
    String model = '',
    String androidVersion = '',
    String securityPatch = '',
  }) {
    return _guard(() async {
      final body = <String, dynamic>{
        'software_version': version,
        'rating': rating,
        'comment': comment,
      };
      // Datele dispozitivului se trimit doar daca au putut fi citite.
      if (manufacturer.isNotEmpty) body['manufacturer'] = manufacturer;
      if (model.isNotEmpty) body['model'] = model;
      if (androidVersion.isNotEmpty) body['android_version'] = androidVersion;
      if (securityPatch.isNotEmpty) body['security_patch'] = securityPatch;

      final response = await http
          .post(
            Uri.parse('$baseUrl/feedback'),
            headers: _headers,
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      _decode(response);
    });
  }

  /// Construieste adresa, adaugand filtrul de model daca a fost cerut.
  static Uri _uri(String path, {String model = ''}) {
    if (model.isEmpty) return Uri.parse('$baseUrl$path');
    return Uri.parse('$baseUrl$path').replace(queryParameters: {'model': model});
  }

  static Future<List<FeedbackItem>> getFeedback({String model = ''}) {
    return _guard(() async {
      final response = await http
          .get(_uri('/feedback', model: model), headers: _headers)
          .timeout(_timeout);

      final data = _decode(response) as List<dynamic>;
      return data
          .map((e) => FeedbackItem.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  static Future<List<VersionStat>> getStats({String model = ''}) {
    return _guard(() async {
      final response = await http
          .get(_uri('/stats', model: model), headers: _headers)
          .timeout(_timeout);

      final data = _decode(response) as List<dynamic>;
      return data
          .map((e) => VersionStat.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }
}

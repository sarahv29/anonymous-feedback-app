import 'package:device_info_plus/device_info_plus.dart';

/// Datele dispozitivului, citite automat de pe telefon.
/// Se trimit odata cu fiecare recenzie, ca sa se stie despre ce telefon e vorba.
class DeviceDetails {
  final String manufacturer;
  final String model;
  final String androidVersion;
  final String securityPatch;

  const DeviceDetails({
    required this.manufacturer,
    required this.model,
    required this.androidVersion,
    required this.securityPatch,
  });

  static const DeviceDetails unknown = DeviceDetails(
    manufacturer: '',
    model: '',
    androidVersion: '',
    securityPatch: '',
  );

  bool get isEmpty => manufacturer.isEmpty && model.isEmpty;

  /// Numele afisat utilizatorului, de exemplu "samsung SM-G988B".
  String get displayName {
    final parts = [manufacturer, model].where((p) => p.isNotEmpty);
    return parts.isEmpty ? 'Unknown device' : parts.join(' ');
  }
}

class DeviceInfo {
  static DeviceDetails? _cached;

  /// Curata o valoare venita din API-ul Android.
  /// Parametrul e Object? intentionat: unele campuri sunt String, altele String?,
  /// iar asa functioneaza in ambele cazuri fara avertismente de la analizator.
  static String _clean(Object? value) {
    final text = value?.toString().trim() ?? '';
    return (text.isEmpty || text == 'null') ? '' : text;
  }

  /// Citeste datele o singura data si le pastreaza in memorie.
  /// Daca citirea esueaza, intoarce valori goale -- serverul le accepta
  /// ca optionale, deci recenzia se trimite oricum.
  static Future<DeviceDetails> load() async {
    if (_cached != null) return _cached!;

    try {
      final android = await DeviceInfoPlugin().androidInfo;
      _cached = DeviceDetails(
        manufacturer: _clean(android.manufacturer),
        model: _clean(android.model),
        androidVersion: _clean(android.version.release),
        securityPatch: _clean(android.version.securityPatch),
      );
    } catch (_) {
      _cached = DeviceDetails.unknown;
    }

    return _cached!;
  }
}

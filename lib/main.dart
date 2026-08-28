import 'package:flutter/material.dart';

import 'api_service.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';

/// Verdele marcii, acelasi din logo (#43A047).
const Color kBrandGreen = Color(0xFF43A047);

/// Verde-menta aprins, pentru bara de navigare.
/// Sare in ochi ca un neon, dar ramane lizibil si pe tema luminoasa,
/// spre deosebire de verdele neon pur, care pe alb devine ilizibil.
const Color kAccentNeon = Color(0xFF00E676);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.loadSession();
  runApp(const AnonymousFeedbackApp());
}

class AnonymousFeedbackApp extends StatelessWidget {
  const AnonymousFeedbackApp({super.key});

  ThemeData _theme(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: kBrandGreen,
      brightness: brightness,
    );
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      navigationBarTheme: NavigationBarThemeData(
        // Pastila din spatele filei active, in chihlimbar.
        indicatorColor: kAccentNeon,
        backgroundColor: isDark ? scheme.surfaceContainer : scheme.surface,
        elevation: 3,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? kAccentNeon : scheme.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            // Pe pastila verde aprinsa punem iconita inchisa, altfel nu se vede.
            color: selected ? const Color(0xFF003820) : scheme.onSurfaceVariant,
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Anonymous Feedback',
      debugShowCheckedModeBanner: false,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      themeMode: ThemeMode.system,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _loggedIn = ApiService.isLoggedIn;

  void _onLoggedIn() => setState(() => _loggedIn = true);
  void _onLoggedOut() => setState(() => _loggedIn = false);

  @override
  Widget build(BuildContext context) {
    if (_loggedIn) {
      return HomeScreen(onLoggedOut: _onLoggedOut);
    }
    return AuthScreen(onLoggedIn: _onLoggedIn);
  }
}

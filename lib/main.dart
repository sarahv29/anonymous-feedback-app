import 'package:flutter/material.dart';

import 'api_service.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  // Necesar inainte de orice apel asincron facut inaintea runApp().
  WidgetsFlutterBinding.ensureInitialized();

  // Recupereaza token-ul salvat pe telefon, ca utilizatorul
  // sa nu se reautentifice la fiecare pornire.
  await ApiService.loadSession();

  runApp(const FeedbackApp());
}

class FeedbackApp extends StatelessWidget {
  const FeedbackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Feedback',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          brightness: Brightness.dark,
        ),
      ),
      // Urmeaza setarea telefonului: luminos sau intunecat.
      themeMode: ThemeMode.system,
      home: const AuthGate(),
    );
  }
}

/// Decide ce ecran se vede la pornire, in functie de existenta unui token.
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

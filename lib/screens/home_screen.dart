import 'package:flutter/material.dart';

import '../api_service.dart';
import 'feedback_screen.dart';

/// Ecranul principal dupa autentificare.
/// Deocamdata gazduieste formularul de feedback; lista de recenzii
/// si statisticile se adauga la pasul urmator.
class HomeScreen extends StatelessWidget {
  final VoidCallback onLoggedOut;

  const HomeScreen({super.key, required this.onLoggedOut});

  Future<void> _logout() async {
    await ApiService.logout();
    onLoggedOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send feedback'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: _logout,
          ),
        ],
      ),
      body: const FeedbackScreen(),
    );
  }
}

import 'package:flutter/material.dart';

import 'account_screen.dart';
import 'feedback_screen.dart';
import 'reviews_screen.dart';

/// Invelisul aplicatiei dupa autentificare: bara de navigare de jos
/// si cele trei ecrane principale.
class HomeScreen extends StatefulWidget {
  final VoidCallback onLoggedOut;

  const HomeScreen({super.key, required this.onLoggedOut});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  static const _titles = ['Send feedback', 'Reviews', 'Account'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_index])),
      // IndexedStack pastreaza starea fiecarui ecran la comutare,
      // deci lista de recenzii nu se reincarca de fiecare data.
      body: IndexedStack(
        index: _index,
        children: [
          const FeedbackScreen(),
          const ReviewsScreen(),
          AccountScreen(onLoggedOut: widget.onLoggedOut),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.rate_review_outlined),
            selectedIcon: Icon(Icons.rate_review),
            label: 'Feedback',
          ),
          NavigationDestination(
            icon: Icon(Icons.forum_outlined),
            selectedIcon: Icon(Icons.forum),
            label: 'Reviews',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../api_service.dart';
import '../device_info.dart';

class AccountScreen extends StatefulWidget {
  final VoidCallback onLoggedOut;

  const AccountScreen({super.key, required this.onLoggedOut});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  DeviceDetails _device = DeviceDetails.unknown;

  @override
  void initState() {
    super.initState();
    DeviceInfo.load().then((d) {
      if (mounted) setState(() => _device = d);
    });
  }

  Future<void> _logout() async {
    await ApiService.logout();
    widget.onLoggedOut();
  }

  /// Dialogul de stergere. Cere parola din nou, pentru ca actiunea
  /// e ireversibila si nu trebuie sa se poata face din greseala.
  Future<void> _confirmDelete() async {
    final passwordController = TextEditingController();
    final deleted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _DeleteDialog(
        email: ApiService.currentEmail ?? '',
        controller: passwordController,
      ),
    );
    passwordController.dispose();

    if (deleted == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your account has been deleted.')),
      );
      widget.onLoggedOut();
    }
  }

  Widget _infoRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.person_outline,
                        size: 20, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text('Account', style: theme.textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: 12),
                _infoRow(theme, 'Email', ApiService.currentEmail ?? ''),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.smartphone_outlined,
                        size: 20, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text('Device', style: theme.textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: 12),
                _infoRow(theme, 'Model', _device.displayName),
                _infoRow(theme, 'Android', _device.androidVersion),
                _infoRow(theme, 'Security patch', _device.securityPatch),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        OutlinedButton.icon(
          onPressed: _logout,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          icon: const Icon(Icons.logout),
          label: const Text('Log out'),
        ),
        const SizedBox(height: 32),

        Text(
          'Danger zone',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Deleting your account permanently removes your email address, your '
          'password and every review you have submitted, together with the '
          'device details attached to them. This cannot be undone.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _confirmDelete,
          style: OutlinedButton.styleFrom(
            foregroundColor: theme.colorScheme.error,
            side: BorderSide(color: theme.colorScheme.error),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          icon: const Icon(Icons.delete_forever_outlined),
          label: const Text('Delete my account'),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _DeleteDialog extends StatefulWidget {
  final String email;
  final TextEditingController controller;

  const _DeleteDialog({required this.email, required this.controller});

  @override
  State<_DeleteDialog> createState() => _DeleteDialogState();
}

class _DeleteDialogState extends State<_DeleteDialog> {
  bool _busy = false;
  String? _error;

  Future<void> _delete() async {
    final password = widget.controller.text;
    if (password.isEmpty) {
      setState(() => _error = 'Enter your password to confirm');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await ApiService.deleteAccount(widget.email, password);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      icon: Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error),
      title: const Text('Delete account?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This permanently deletes ${widget.email} and all reviews you '
            'have submitted. It cannot be undone.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: widget.controller,
            enabled: !_busy,
            obscureText: true,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _busy ? null : _delete,
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
          ),
          child: _busy
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Delete forever'),
        ),
      ],
    );
  }
}

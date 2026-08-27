import 'package:flutter/material.dart';

import '../api_service.dart';
import '../device_info.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _versionController = TextEditingController();
  final _commentController = TextEditingController();

  DeviceDetails _device = DeviceDetails.unknown;
  int _rating = 0;
  bool _busy = false;
  bool _loadingDevice = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDevice();
  }

  @override
  void dispose() {
    _versionController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadDevice() async {
    final device = await DeviceInfo.load();
    if (!mounted) return;
    setState(() {
      _device = device;
      _loadingDevice = false;
      // Precompletam versiunea cu cea detectata; utilizatorul o poate schimba
      // daca vrea sa fie mai exact, de exemplu "One UI 6.1".
      if (_versionController.text.isEmpty && device.androidVersion.isNotEmpty) {
        _versionController.text = 'Android ${device.androidVersion}';
      }
    });
  }

  Future<void> _submit() async {
    final version = _versionController.text.trim();
    final comment = _commentController.text.trim();

    if (version.isEmpty) {
      setState(() => _error = 'Enter the software version');
      return;
    }
    if (_rating == 0) {
      setState(() => _error = 'Tap a star to rate');
      return;
    }
    if (comment.isEmpty) {
      setState(() => _error = 'Write a short comment');
      return;
    }

    setState(() {
      _error = null;
      _busy = true;
    });

    try {
      await ApiService.submitFeedback(
        version: version,
        rating: _rating,
        comment: comment,
        manufacturer: _device.manufacturer,
        model: _device.model,
        androidVersion: _device.androidVersion,
        securityPatch: _device.securityPatch,
      );

      if (!mounted) return;
      setState(() {
        _rating = 0;
        _commentController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thanks! Your feedback was sent.')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _deviceCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.smartphone_outlined,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text('Your device', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            if (_loadingDevice)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(),
              )
            else if (_device.isEmpty)
              Text(
                'Device details could not be read.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else ...[
              _deviceRow(theme, 'Device', _device.displayName),
              _deviceRow(theme, 'Android', _device.androidVersion),
              if (_device.securityPatch.isNotEmpty)
                _deviceRow(theme, 'Security patch', _device.securityPatch),
            ],
            const SizedBox(height: 12),
            Text(
              'This information is attached to your feedback so it can be '
              'grouped by device. It is deleted if you delete your account.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _deviceRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
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
            child: Text(value, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _deviceCard(theme),
          const SizedBox(height: 24),

          Text('Software version', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _versionController,
            enabled: !_busy,
            decoration: const InputDecoration(
              hintText: 'e.g. Android 13, One UI 6.1',
              prefixIcon: Icon(Icons.system_update_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),

          Text('Your rating', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final value = index + 1;
              return IconButton(
                onPressed: _busy ? null : () => setState(() => _rating = value),
                tooltip: '$value out of 5',
                iconSize: 40,
                icon: Icon(
                  _rating >= value ? Icons.star : Icons.star_border,
                  color: theme.colorScheme.primary,
                ),
              );
            }),
          ),
          Center(
            child: Text(
              _rating == 0 ? 'Not rated yet' : '$_rating out of 5',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 24),

          Text('Your comment', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _commentController,
            enabled: !_busy,
            maxLines: 5,
            maxLength: 2000,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'What changed for better or worse in this version?',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),

          if (_error != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 20,
                    color: theme.colorScheme.onErrorContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _busy ? null : _submit,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            icon: _busy
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_outlined),
            label: Text(_busy ? 'Sending...' : 'Send feedback'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

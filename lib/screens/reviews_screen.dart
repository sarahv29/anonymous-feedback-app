import 'package:flutter/material.dart';

import '../api_service.dart';
import '../device_info.dart';

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  bool _myDeviceOnly = true;
  String _myModel = '';
  String _myDeviceLabel = '';

  List<FeedbackItem> _items = [];
  List<VersionStat> _stats = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final device = await DeviceInfo.load();
    if (!mounted) return;
    _myModel = device.model;
    _myDeviceLabel = device.displayName;
    // Daca modelul nu a putut fi citit, filtrul nu are sens.
    if (_myModel.isEmpty) _myDeviceOnly = false;
    await _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);

    final filter = _myDeviceOnly ? _myModel : '';
    try {
      final items = await ApiService.getFeedback(model: filter);
      final stats = await ApiService.getStats(model: filter);
      if (!mounted) return;
      setState(() {
        _items = items;
        _stats = stats;
        _error = null;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  void _setFilter(bool myDeviceOnly) {
    if (_myDeviceOnly == myDeviceOnly) return;
    setState(() => _myDeviceOnly = myDeviceOnly);
    _load();
  }

  /// Deschide dialogul de raportare si trimite motivul ales.
  Future<void> _report(FeedbackItem item) async {
    const motive = [
      'Spam or advertising',
      'Offensive or hateful',
      'Contains personal information',
      'Not relevant to the version',
      'Something else',
    ];

    final ales = await showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Report this review'),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: Text(
              'Tell us what is wrong with it. Reviews reported by several '
              'people are hidden automatically and checked.',
              style: Theme.of(dialogContext).textTheme.bodySmall,
            ),
          ),
          for (final motiv in motive)
            SimpleDialogOption(
              onPressed: () => Navigator.of(dialogContext).pop(motiv),
              child: Text(motiv),
            ),
          SimpleDialogOption(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: Theme.of(dialogContext).colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );

    if (ales == null) return;

    try {
      await ApiService.reportFeedback(item.id, ales);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thank you. This review has been reported.')),
      );
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  // ==================== BUCATI DE INTERFATA ====================

  Widget _filterRow(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          ChoiceChip(
            label: Text(_myDeviceLabel.isEmpty ? 'My device' : _myDeviceLabel),
            selected: _myDeviceOnly,
            onSelected: _myModel.isEmpty ? null : (_) => _setFilter(true),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('All devices'),
            selected: !_myDeviceOnly,
            onSelected: (_) => _setFilter(false),
          ),
        ],
      ),
    );
  }

  Widget _statsCard(ThemeData theme) {
    if (_stats.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('By version', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            for (final stat in _stats) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      stat.version.isEmpty ? 'Unspecified' : stat.version,
                      style: theme.textTheme.bodyLarge,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.star, size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    stat.avgRating.toStringAsFixed(1),
                    style: theme.textTheme.bodyLarge,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  _pill(theme, '${stat.positive} positive',
                      theme.colorScheme.primaryContainer,
                      theme.colorScheme.onPrimaryContainer),
                  const SizedBox(width: 6),
                  _pill(theme, '${stat.negative} negative',
                      theme.colorScheme.errorContainer,
                      theme.colorScheme.onErrorContainer),
                  const SizedBox(width: 6),
                  Text(
                    '${stat.totalReviews} total',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }

  Widget _pill(ThemeData theme, String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(color: fg),
      ),
    );
  }

  Widget _sectionHeader(ThemeData theme, String title, int count, IconData icon,
      Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Text('$title ($count)', style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }

  Widget _reviewCard(ThemeData theme, FeedbackItem item) {
    final Color accent = item.isPositive
        ? theme.colorScheme.primary
        : item.isNegative
            ? theme.colorScheme.error
            : theme.colorScheme.outline;

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Row(
                  children: List.generate(5, (i) {
                    return Icon(
                      i < item.rating ? Icons.star : Icons.star_border,
                      size: 16,
                      color: accent,
                    );
                  }),
                ),
                const Spacer(),
                Text(
                  item.version,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                // Raportarea continutului nepotrivit. Google o cere obligatoriu
                // pentru orice aplicatie in care utilizatorii publica text.
                IconButton(
                  icon: const Icon(Icons.flag_outlined, size: 18),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Report this review',
                  color: theme.colorScheme.onSurfaceVariant,
                  onPressed: () => _report(item),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(item.comment, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            Text(
              [
                item.username,
                if (item.deviceLabel.isNotEmpty) item.deviceLabel,
                item.timestamp,
              ].join('  ·  '),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyOrError(ThemeData theme) {
    final isError = _error != null;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            isError ? Icons.cloud_off : Icons.reviews_outlined,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            isError ? _error! : 'No reviews yet for this filter.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (isError) ...[
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final positive = _items.where((i) => i.isPositive).toList();
    final negative = _items.where((i) => i.isNegative).toList();
    final neutral =
        _items.where((i) => !i.isPositive && !i.isNegative).toList();

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _filterRow(theme),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null || _items.isEmpty)
            _emptyOrError(theme)
          else ...[
            _statsCard(theme),
            if (positive.isNotEmpty) ...[
              _sectionHeader(theme, 'Positive', positive.length,
                  Icons.thumb_up_outlined, theme.colorScheme.primary),
              for (final item in positive) _reviewCard(theme, item),
            ],
            if (negative.isNotEmpty) ...[
              _sectionHeader(theme, 'Negative', negative.length,
                  Icons.thumb_down_outlined, theme.colorScheme.error),
              for (final item in negative) _reviewCard(theme, item),
            ],
            if (neutral.isNotEmpty) ...[
              _sectionHeader(theme, 'Neutral', neutral.length,
                  Icons.remove_circle_outline, theme.colorScheme.outline),
              for (final item in neutral) _reviewCard(theme, item),
            ],
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

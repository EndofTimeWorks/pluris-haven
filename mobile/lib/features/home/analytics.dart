part of 'home_page.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key, required this.repository});

  final HavenRepository repository;

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  _AnalyticsWindow _window = _AnalyticsWindow.thirtyDays;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FrontHistoryEntry>>(
      stream: widget.repository.watchFrontHistory(),
      initialData: const [],
      builder: (context, snapshot) {
        final l10n = AppLocalizations.of(context);
        final entries = snapshot.data ?? const <FrontHistoryEntry>[];
        final stats = _buildAnalytics(entries, _window, l10n.unknownLabel);

        return SpPage(
          children: [
            SpCard(
              outlined: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SpSectionHeader(
                    title: l10n.analyticsTitle,
                    trailing: StatusPill(text: _window.label(l10n)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.analyticsDescription,
                    style: const TextStyle(color: _spMuted, height: 1.35),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final window in _AnalyticsWindow.values) ...[
                    FilterChip(
                      label: Text(window.label(l10n)),
                      selected: _window == window,
                      onSelected: (_) => setState(() => _window = window),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (stats.sessions == 0)
              SpEmptyState(
                title: l10n.noAnalyticsTitle,
                body: l10n.noAnalyticsBody,
              )
            else ...[
              _AnalyticsSummary(stats: stats),
              const SizedBox(height: 12),
              _TopFrontsCard(stats: stats),
              const SizedBox(height: 12),
              _HourChartCard(stats: stats),
            ],
          ],
        );
      },
    );
  }
}

class _AnalyticsSummary extends StatelessWidget {
  const _AnalyticsSummary({required this.stats});

  final _FrontAnalytics stats;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SpCard(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _MetricBlock(
                  label: l10n.totalFrontTimeLabel,
                  value: _formatAnalyticsDuration(l10n, stats.totalSeconds),
                ),
              ),
              Expanded(
                child: _MetricBlock(
                  label: l10n.sessionsLabel,
                  value: '${stats.sessions}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MetricBlock(
                  label: l10n.averageLabel,
                  value: _formatAnalyticsDuration(l10n, stats.averageSeconds),
                ),
              ),
              Expanded(
                child: _MetricBlock(
                  label: l10n.longestLabel,
                  value: _formatAnalyticsDuration(l10n, stats.longestSeconds),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricBlock extends StatelessWidget {
  const _MetricBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label $value',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 3),
          ExcludeSemantics(
            child: Text(
              label,
              style: const TextStyle(color: _spMuted, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopFrontsCard extends StatelessWidget {
  const _TopFrontsCard({required this.stats});

  final _FrontAnalytics stats;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final top = stats.topLabels.take(8).toList(growable: false);
    final maxSeconds = top.isEmpty ? 1 : top.first.totalSeconds;

    return SpCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SpSectionHeader(title: l10n.topFrontsTitle),
          const SizedBox(height: 12),
          for (final item in top) ...[
            Semantics(
              label: l10n.frontAnalyticsSemantic(
                item.label,
                _formatAnalyticsDuration(l10n, item.totalSeconds),
                item.sessions,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _formatAnalyticsDuration(l10n, item.totalSeconds),
                        style: const TextStyle(color: _spMuted, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  LinearProgressIndicator(
                    minHeight: 7,
                    value: item.totalSeconds / maxSeconds,
                    color: _spGold,
                    backgroundColor: _spLine,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.sessionCount(item.sessions),
                    style: const TextStyle(color: _spMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (item != top.last) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _HourChartCard extends StatelessWidget {
  const _HourChartCard({required this.stats});

  final _FrontAnalytics stats;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final maxSeconds = stats.hourSeconds.fold<int>(
      1,
      (current, value) => value > current ? value : current,
    );

    return SpCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SpSectionHeader(title: l10n.hourOfDayTitle),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var hour = 0; hour < 24; hour++)
                  Expanded(
                    child: Semantics(
                      label: l10n.hourAnalyticsSemantic(
                        hour,
                        _formatAnalyticsDuration(l10n, stats.hourSeconds[hour]),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1.5),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: FractionallySizedBox(
                            heightFactor: stats.hourSeconds[hour] / maxSeconds,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: _spPurple,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const SizedBox(width: double.infinity),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              Text('00', style: TextStyle(color: _spMuted, fontSize: 12)),
              Spacer(),
              Text('12', style: TextStyle(color: _spMuted, fontSize: 12)),
              Spacer(),
              Text('23', style: TextStyle(color: _spMuted, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

enum _AnalyticsWindow {
  sevenDays(Duration(days: 7)),
  thirtyDays(Duration(days: 30)),
  ninetyDays(Duration(days: 90)),
  oneYear(Duration(days: 365)),
  all(null);

  const _AnalyticsWindow(this.duration);

  final Duration? duration;

  String label(AppLocalizations l10n) => switch (this) {
    sevenDays => l10n.analyticsSevenDays,
    thirtyDays => l10n.analyticsThirtyDays,
    ninetyDays => l10n.analyticsNinetyDays,
    oneYear => l10n.analyticsOneYear,
    all => l10n.allFilter,
  };
}

class _FrontAnalytics {
  const _FrontAnalytics({
    required this.sessions,
    required this.totalSeconds,
    required this.averageSeconds,
    required this.longestSeconds,
    required this.topLabels,
    required this.hourSeconds,
  });

  final int sessions;
  final int totalSeconds;
  final int averageSeconds;
  final int longestSeconds;
  final List<_FrontLabelAnalytics> topLabels;
  final List<int> hourSeconds;
}

class _FrontLabelAnalytics {
  const _FrontLabelAnalytics({
    required this.label,
    required this.totalSeconds,
    required this.sessions,
  });

  final String label;
  final int totalSeconds;
  final int sessions;
}

class _LabelAccumulator {
  int totalSeconds = 0;
  int sessions = 0;
}

_FrontAnalytics _buildAnalytics(
  List<FrontHistoryEntry> entries,
  _AnalyticsWindow window,
  String unknownLabel,
) {
  final now = DateTime.now();
  final since = window.duration == null ? null : now.subtract(window.duration!);
  final labels = <String, _LabelAccumulator>{};
  final hourSeconds = List<int>.filled(24, 0);
  var totalSeconds = 0;
  var longestSeconds = 0;
  var sessions = 0;

  for (final entry in entries) {
    final interval = _clipAnalyticsInterval(entry, since, now);
    if (interval == null) {
      continue;
    }
    final seconds = interval.end.difference(interval.start).inSeconds;
    if (seconds <= 0) {
      continue;
    }

    sessions += 1;
    totalSeconds += seconds;
    if (seconds > longestSeconds) {
      longestSeconds = seconds;
    }

    final label = entry.label.trim().isEmpty
        ? unknownLabel
        : entry.label.trim();
    final labelStats = labels.putIfAbsent(label, _LabelAccumulator.new);
    labelStats.sessions += 1;
    labelStats.totalSeconds += seconds;

    _addHourBuckets(hourSeconds, interval.start, interval.end);
  }

  final topLabels =
      [
        for (final entry in labels.entries)
          _FrontLabelAnalytics(
            label: entry.key,
            totalSeconds: entry.value.totalSeconds,
            sessions: entry.value.sessions,
          ),
      ]..sort((a, b) {
        final byTime = b.totalSeconds.compareTo(a.totalSeconds);
        if (byTime != 0) {
          return byTime;
        }
        return a.label.toLowerCase().compareTo(b.label.toLowerCase());
      });

  return _FrontAnalytics(
    sessions: sessions,
    totalSeconds: totalSeconds,
    averageSeconds: sessions == 0 ? 0 : totalSeconds ~/ sessions,
    longestSeconds: longestSeconds,
    topLabels: topLabels,
    hourSeconds: List.unmodifiable(hourSeconds),
  );
}

({DateTime start, DateTime end})? _clipAnalyticsInterval(
  FrontHistoryEntry entry,
  DateTime? since,
  DateTime now,
) {
  var start = entry.startedAt.toLocal();
  var end = (entry.endedAt ?? now).toLocal();
  if (end.isAfter(now)) {
    end = now;
  }
  if (since != null && start.isBefore(since)) {
    start = since;
  }
  if (!end.isAfter(start)) {
    return null;
  }
  return (start: start, end: end);
}

void _addHourBuckets(List<int> buckets, DateTime start, DateTime end) {
  var cursor = start;
  while (cursor.isBefore(end)) {
    final nextHour = DateTime(
      cursor.year,
      cursor.month,
      cursor.day,
      cursor.hour + 1,
    );
    final sliceEnd = nextHour.isBefore(end) ? nextHour : end;
    final seconds = sliceEnd.difference(cursor).inSeconds;
    if (seconds > 0) {
      buckets[cursor.hour] += seconds;
    }
    cursor = sliceEnd;
  }
}

String _formatAnalyticsDuration(AppLocalizations l10n, int seconds) {
  if (seconds <= 0) {
    return l10n.durationMinutes(0);
  }
  final days = seconds ~/ 86400;
  final hours = (seconds % 86400) ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  if (days > 0) {
    return hours > 0
        ? l10n.durationDaysHours(days, hours)
        : l10n.durationDays(days);
  }
  if (hours > 0) {
    return minutes > 0
        ? l10n.durationHoursMinutes(hours, minutes)
        : l10n.durationHours(hours);
  }
  return l10n.durationMinutes(minutes);
}

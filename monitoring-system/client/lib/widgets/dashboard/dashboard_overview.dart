import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/submission_service.dart';
import 'dash_ui.dart';

/// Admin landing tab: headline numbers as stat tiles, then three charts —
/// case status (donut), cases by category (bar) and the 7-day case trend
/// (line). Data comes from `/api/monitoring/stats`.
class DashboardOverview extends StatefulWidget {
  final Listenable? refreshSignal;
  const DashboardOverview({super.key, this.refreshSignal});

  @override
  State<DashboardOverview> createState() => _DashboardOverviewState();
}

class _DashboardOverviewState extends State<DashboardOverview> {
  final _service = SubmissionService();
  Map<String, dynamic>? _stats;
  bool _loading = true;
  String? _error;

  static const _statusOrder = [
    'pending', 'under_review', 'assigned', 'resolved', 'closed'
  ];
  static const _statusLabel = {
    'pending': 'Pending',
    'under_review': 'Under review',
    'assigned': 'Assigned',
    'resolved': 'Resolved',
    'closed': 'Closed',
  };
  @override
  void initState() {
    super.initState();
    _load();
    widget.refreshSignal?.addListener(_load);
  }

  @override
  void dispose() {
    widget.refreshSignal?.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    try {
      final stats = await _service.getStats();
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _error = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int _num(Map? m, String k) => (m?[k] as num?)?.toInt() ?? 0;

  @override
  Widget build(BuildContext context) {
    return SectionState(
      loading: _loading,
      error: _error,
      empty: _stats == null,
      emptyText: 'No statistics available.',
      onRetry: _load,
      child: _stats == null
          ? const SizedBox.shrink()
          : RefreshIndicator(
              color: Dash.primary,
              backgroundColor: Dash.card,
              onRefresh: _load,
              child: _buildBody(),
            ),
    );
  }

  Widget _buildBody() {
    final overview = _stats!['overview'] as Map<String, dynamic>? ?? {};
    final visitors = _stats!['visitors'] as Map<String, dynamic>? ?? {};
    final programs = _stats!['programs'] as Map<String, dynamic>? ?? {};
    final byCategory =
        (_stats!['by_category'] as Map<String, dynamic>? ?? {}).cast<String, dynamic>();
    final trend = (_stats!['daily_trend'] as List<dynamic>? ?? []);

    final tiles = [
      _Tile('Open cases', _num(overview, 'total'), Icons.folder_open),
      _Tile('Pending', _num(overview, 'pending'), Icons.hourglass_empty,
          color: Dash.caseStatus('pending')),
      _Tile('Resolved', _num(overview, 'resolved'), Icons.check_circle_outline,
          color: Dash.ok),
      _Tile('Visitors today', _num(visitors, 'today'), Icons.how_to_reg),
      _Tile('Active programmes', _num(programs, 'active'), Icons.event_available),
      _Tile('Staff', _num(overview, 'total_staff'), Icons.badge_outlined),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SectionHeader('Overview'),
        LayoutBuilder(builder: (context, c) {
          final cols = c.maxWidth > 640 ? 3 : 2;
          final w = (c.maxWidth - (cols - 1) * 12) / cols;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children:
                tiles.map((t) => SizedBox(width: w, child: t)).toList(),
          );
        }),
        const SizedBox(height: 20),
        _chartCard(
          'Cases by status',
          SizedBox(height: 200, child: _statusDonut(overview)),
        ),
        const SizedBox(height: 12),
        _chartCard(
          'Cases by category',
          SizedBox(height: 220, child: _categoryBars(byCategory)),
        ),
        const SizedBox(height: 12),
        _chartCard(
          'New cases · last 7 days',
          SizedBox(height: 200, child: _trendLine(trend)),
        ),
      ],
    );
  }

  Widget _chartCard(String title, Widget chart) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: Dash.cardBox,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: Dash.ink, fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          chart,
        ],
      ),
    );
  }

  // ---- status donut ----
  Widget _statusDonut(Map<String, dynamic> overview) {
    final entries = [
      for (final s in _statusOrder)
        if (_num(overview, s) > 0) MapEntry(s, _num(overview, s)),
    ];
    if (entries.isEmpty) {
      return const Center(
          child: Text('No cases yet.', style: TextStyle(color: Dash.faint)));
    }
    final total = entries.fold<int>(0, (a, e) => a + e.value);
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 44,
                  sections: [
                    for (final e in entries)
                      PieChartSectionData(
                        value: e.value.toDouble(),
                        color: Dash.caseStatus(e.key),
                        radius: 26,
                        showTitle: false,
                      ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$total',
                      style: const TextStyle(
                          color: Dash.ink,
                          fontSize: 22,
                          fontWeight: FontWeight.w800)),
                  const Text('cases',
                      style: TextStyle(color: Dash.faint, fontSize: 11)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final e in entries)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                            color: Dash.caseStatus(e.key),
                            borderRadius: BorderRadius.circular(3)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_statusLabel[e.key] ?? e.key,
                            style: const TextStyle(
                                color: Dash.dim, fontSize: 12)),
                      ),
                      Text('${e.value}',
                          style: const TextStyle(
                              color: Dash.ink,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ---- category bars ----
  Widget _categoryBars(Map<String, dynamic> byCategory) {
    if (byCategory.isEmpty) {
      return const Center(
          child: Text('No cases yet.', style: TextStyle(color: Dash.faint)));
    }
    final cats = byCategory.keys.toList();
    final maxV = byCategory.values
        .fold<int>(1, (a, b) => (b as num).toInt() > a ? (b).toInt() : a);
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (maxV + 1).toDouble(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: Color(0x14000000), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => Dash.field,
            getTooltipItem: (group, _, rod, __) => BarTooltipItem(
              '${cats[group.x]}\n${rod.toY.toInt()}',
              const TextStyle(color: Dash.ink, fontSize: 12),
            ),
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: (v, meta) => v % 1 == 0
                  ? SideTitleWidget(
                      meta: meta,
                      child: Text('${v.toInt()}',
                          style: const TextStyle(
                              color: Dash.faint, fontSize: 10)),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 34,
              getTitlesWidget: (v, meta) {
                final i = v.toInt();
                if (i < 0 || i >= cats.length) return const SizedBox.shrink();
                return SideTitleWidget(
                  meta: meta,
                  child: Text(_cap(cats[i]),
                      style:
                          const TextStyle(color: Dash.dim, fontSize: 10)),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < cats.length; i++)
            BarChartGroupData(x: i, barRods: [
              BarChartRodData(
                toY: (byCategory[cats[i]] as num).toDouble(),
                color: Dash.primary,
                width: 22,
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4)),
              ),
            ]),
        ],
      ),
    );
  }

  // ---- 7-day trend ----
  Widget _trendLine(List<dynamic> trend) {
    if (trend.isEmpty) {
      return const Center(
          child: Text('No data.', style: TextStyle(color: Dash.faint)));
    }
    final spots = <FlSpot>[];
    for (var i = 0; i < trend.length; i++) {
      final row = trend[i] as Map<String, dynamic>;
      spots.add(FlSpot(i.toDouble(), ((row['count'] as num?) ?? 0).toDouble()));
    }
    final maxY = spots.fold<double>(1, (a, s) => s.y > a ? s.y : a);
    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY + 1,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: Color(0x14000000), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => Dash.field,
            getTooltipItems: (spots) => spots
                .map((s) => LineTooltipItem('${s.y.toInt()}',
                    const TextStyle(color: Dash.ink, fontSize: 12)))
                .toList(),
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              interval: 1,
              getTitlesWidget: (v, meta) => v % 1 == 0
                  ? SideTitleWidget(
                      meta: meta,
                      child: Text('${v.toInt()}',
                          style: const TextStyle(
                              color: Dash.faint, fontSize: 10)),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: 1,
              getTitlesWidget: (v, meta) {
                final i = v.toInt();
                if (i < 0 || i >= trend.length) return const SizedBox.shrink();
                final iso = (trend[i] as Map)['date'] as String?;
                final dt = iso == null ? null : DateTime.tryParse(iso);
                return SideTitleWidget(
                  meta: meta,
                  child: Text(dt == null ? '' : DateFormat('E').format(dt),
                      style:
                          const TextStyle(color: Dash.dim, fontSize: 10)),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            color: Dash.primary,
            barWidth: 2,
            isCurved: false,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Dash.primary.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }

  String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _Tile extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color? color;
  const _Tile(this.label, this.value, this.icon, {this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Dash.primaryText;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: Dash.cardBox,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: c, size: 18),
          const SizedBox(height: 8),
          Text('$value',
              style: const TextStyle(
                  color: Dash.ink, fontSize: 24, fontWeight: FontWeight.w800)),
          Text(label,
              style: const TextStyle(color: Dash.faint, fontSize: 12)),
        ],
      ),
    );
  }
}

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';

class ActivityChart extends StatelessWidget {
  final Map<int, int> hourlyActivity;

  const ActivityChart({super.key, required this.hourlyActivity});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    // Group into 6 time intervals (each 4 hours)
    final intervals = [
      {'label': '00-04', 'count': 0},
      {'label': '04-08', 'count': 0},
      {'label': '08-12', 'count': 0},
      {'label': '12-16', 'count': 0},
      {'label': '16-20', 'count': 0},
      {'label': '20-24', 'count': 0},
    ];

    hourlyActivity.forEach((hour, count) {
      if (hour < 4) {
        intervals[0]['count'] = (intervals[0]['count'] as int) + count;
      } else if (hour < 8) {
        intervals[1]['count'] = (intervals[1]['count'] as int) + count;
      } else if (hour < 12) {
        intervals[2]['count'] = (intervals[2]['count'] as int) + count;
      } else if (hour < 16) {
        intervals[3]['count'] = (intervals[3]['count'] as int) + count;
      } else if (hour < 20) {
        intervals[4]['count'] = (intervals[4]['count'] as int) + count;
      } else {
        intervals[5]['count'] = (intervals[5]['count'] as int) + count;
      }
    });

    int maxCount = 0;
    int peakIndex = 0;
    for (var i = 0; i < intervals.length; i++) {
      final c = intervals[i]['count'] as int;
      if (c > maxCount) {
        maxCount = c;
        peakIndex = i;
      }
    }

    final barGroups = List.generate(intervals.length, (i) {
      final count = (intervals[i]['count'] as int).toDouble();
      final isPeak = i == peakIndex && maxCount > 0;

      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: count == 0 ? 0.3 : count,
            color: isPeak ? AppTheme.accentGreen : AppTheme.surfaceElevated,
            width: 22,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            borderSide: BorderSide(
              color: isPeak
                  ? AppTheme.accentGreen.withValues(alpha: 0.5)
                  : AppTheme.border,
              width: 1,
            ),
          ),
        ],
      );
    });

    return RepaintBoundary(
      child: GlassCard(
        enableBlur: false,
        padding: const EdgeInsets.all(16),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 16,
                      color: AppTheme.primaryCyan,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        loc.activityRhythmTitle,
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (maxCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppTheme.accentGreen.withValues(alpha: 0.25),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    '${loc.peakLabel}: ${intervals[peakIndex]['label']}',
                    style: TextStyle(
                      color: AppTheme.accentGreen,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            loc.activityRhythmSubtitle,
            style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxCount == 0 ? 5 : maxCount.toDouble() * 1.25,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppTheme.surfaceElevated,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final item = intervals[group.x.toInt()];
                      return BarTooltipItem(
                        '${item['label']}\n${rod.toY.toInt()} ${loc.eventsUnit}',
                        TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 11.5,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= intervals.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            intervals[index]['label'] as String,
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: barGroups,
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }
}

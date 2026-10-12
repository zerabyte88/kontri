import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../localization/app_localizations.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';

class LanguageChart extends StatelessWidget {
  final Map<String, int> languageCounts;

  const LanguageChart({super.key, required this.languageCounts});

  static const List<Color> _palette = [
    Color(0xFF3178C6), // TypeScript / Dart Blue
    Color(0xFFF1E05A), // JavaScript Amber / Gold
    Color(0xFF3572A5), // Python Blue
    Color(0xFF3FB950), // Emerald Green
    Color(0xFFE34C26), // HTML Orange / Coral
    Color(0xFFBC8CFF), // Purple
    Color(0xFF00ADD8), // Go Cyan
    Color(0xFF8B949E), // Muted Slate
  ];

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    if (languageCounts.isEmpty) {
      return GlassCard(
        enableBlur: false,
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text(
            loc.noLanguageData,
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
        ),
      );
    }

    // Sort by count/bytes descending
    final sortedEntries = languageCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Limit to top 5 + "Lainnya"
    final topEntries = sortedEntries.take(5).toList();
    final otherBytes = sortedEntries
        .skip(5)
        .fold<int>(0, (sum, item) => sum + item.value);

    final totalCount = languageCounts.values.fold<int>(0, (a, b) => a + b);

    final List<PieChartSectionData> sections = [];
    final List<Map<String, dynamic>> legendItems = [];

    for (var i = 0; i < topEntries.length; i++) {
      final entry = topEntries[i];
      final color = _palette[i % _palette.length];
      final percent = totalCount > 0 ? (entry.value / totalCount) * 100 : 0.0;

      sections.add(
        PieChartSectionData(
          color: color,
          value: entry.value.toDouble(),
          title: percent >= 8 ? '${percent.toStringAsFixed(0)}%' : '',
          radius: 34,
          titleStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0D1117),
          ),
        ),
      );

      legendItems.add({
        'name': entry.key,
        'percent': percent,
        'bytes': entry.value,
        'color': color,
      });
    }

    if (otherBytes > 0) {
      final percent = totalCount > 0 ? (otherBytes / totalCount) * 100 : 0.0;
      final color = _palette.last;
      sections.add(
        PieChartSectionData(
          color: color,
          value: otherBytes.toDouble(),
          title: percent >= 8 ? '${percent.toStringAsFixed(0)}%' : '',
          radius: 34,
          titleStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0D1117),
          ),
        ),
      );
      legendItems.add({
        'name': loc.otherLanguages,
        'percent': percent,
        'bytes': otherBytes,
        'color': color,
      });
    }

    return RepaintBoundary(
      child: GlassCard(
        enableBlur: false,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.code_rounded, size: 16, color: AppTheme.primaryCyan),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    loc.languageDistribution,
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
            const SizedBox(height: 18),
            SizedBox(
              height: 160,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 42,
                  sections: sections,
                ),
              ),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = (constraints.maxWidth - 12) / 2;
                return Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: legendItems.map((item) {
                    final color = item['color'] as Color;
                    final name = item['name'] as String;
                    final percent = item['percent'] as double;

                    return SizedBox(
                      width: itemWidth,
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: '$name ',
                                    style: TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '(${percent.toStringAsFixed(1)}%)',
                                    style: TextStyle(
                                      color: AppTheme.textMuted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

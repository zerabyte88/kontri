import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'glass_card.dart';

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accentColor;
  final String? subtitle;
  final int maxLines;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.accentColor,
    this.subtitle,
    this.maxLines = 4,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GlassCard(
        enableBlur: false,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      height: 1.25,
                    ),
                    maxLines: maxLines,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.20),
                      width: 0.8,
                    ),
                  ),
                  child: Icon(icon, size: 15, color: accentColor),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/app_theme_service.dart';
import '../theme/app_theme.dart';

/// Reusable adaptive Glassmorphism card container.
///
/// Automatically reads [AppThemeService.surfaceOpacityNotifier].
/// When opacity < 1.0, applies [BackdropFilter] with frosted glass blur and semi-transparent surface.
/// When opacity == 1.0, automatically bypasses blur filtering for optimal rendering performance.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final Border? border;
  final Color? color;
  final double blurAmount;
  final bool enableBlur;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.border,
    this.color,
    this.blurAmount = 10.0,
    this.enableBlur = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? BorderRadius.circular(12);

    return ValueListenableBuilder<double>(
      valueListenable: AppThemeService.surfaceOpacityNotifier,
      builder: (context, opacity, _) {
        final isGlass = opacity < 0.999;
        final baseColor = color ?? AppTheme.surface;
        final effectiveColor =
            isGlass ? baseColor.withValues(alpha: opacity) : baseColor;
        final effectiveBorder = border ??
            Border.all(
              color: AppTheme.border.withValues(alpha: isGlass ? 0.65 : 1.0),
              width: 1.0,
            );

        Widget box = Container(
          padding: padding,
          decoration: BoxDecoration(
            color: effectiveColor,
            borderRadius: effectiveRadius,
            border: effectiveBorder,
          ),
          child: Material(
            color: Colors.transparent,
            child: child,
          ),
        );

        if (isGlass && enableBlur) {
          box = RepaintBoundary(
            child: ClipRRect(
              borderRadius: effectiveRadius,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
                child: box,
              ),
            ),
          );
        }

        if (margin != null) {
          box = Padding(padding: margin!, child: box);
        }

        return box;
      },
    );
  }
}

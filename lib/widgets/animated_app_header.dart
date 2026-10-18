import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/app_theme_service.dart';
import '../theme/app_theme.dart';

/// Global controller to synchronize header animation lifecycle state across the header.
class HeaderAnimationState {
  static final ValueNotifier<bool> isPausedNotifier = ValueNotifier<bool>(
    false,
  );

  static void pauseAnimation() {
    isPausedNotifier.value = true;
  }

  static void resumeAnimation() {
    isPausedNotifier.value = false;
  }
}

/// App logo widget.
class KontriLogo extends StatelessWidget {
  final double size;
  final Color color;
  final double progress;

  const KontriLogo({
    super.key,
    this.size = 20,
    required this.color,
    this.progress = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.22),
        child: Image.asset(
          'assets/icons/app_icon.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => CustomPaint(
            painter: _KontriLogoPainter(color: color, progress: progress),
          ),
        ),
      ),
    );
  }
}

class _KontriLogoPainter extends CustomPainter {
  final Color color;
  final double progress;

  static final Paint _linePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  static final Paint _fillPaint = Paint()..style = PaintingStyle.fill;
  static final Paint _strokePaint = Paint()..style = PaintingStyle.stroke;
  static final Paint _glowPaint = Paint();
  static final Paint _sparkGlow = Paint();
  static final Paint _sparkCore = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.fill;

  _KontriLogoPainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final strokeWidth = (w * 0.09).clamp(1.4, 2.4);

    _linePaint
      ..color = color.withValues(alpha: 0.95)
      ..strokeWidth = strokeWidth;

    final baseNode = Offset(w * 0.20, h * 0.74);
    final bottomNode = Offset(w * 0.80, h * 0.74);
    final headNode = Offset(w * 0.82, h * 0.38);

    // 1. Lower Git master branch line
    canvas.drawLine(baseNode, bottomNode, _linePaint);

    // 2. Upper Git branch with ECG pulse waveform
    final pulsePath = Path()..moveTo(baseNode.dx, baseNode.dy);

    // Branch curve upward
    pulsePath.cubicTo(
      w * 0.22,
      h * 0.52,
      w * 0.30,
      h * 0.46,
      w * 0.38,
      h * 0.46,
    );

    // ECG cardiac pulse spike
    pulsePath.lineTo(w * 0.44, h * 0.52); // Pre-dip
    pulsePath.lineTo(w * 0.54, h * 0.14); // High pulse spike (R-wave peak)
    pulsePath.lineTo(w * 0.64, h * 0.70); // Deep S-wave valley
    pulsePath.lineTo(w * 0.72, h * 0.38); // Recovery
    pulsePath.lineTo(
      headNode.dx,
      headNode.dy,
    ); // Connecting to HEAD release node

    canvas.drawPath(pulsePath, _linePaint);

    // 3. Draw commit nodes (Origin, Main Branch, and HEAD Pulse Node)
    final nodeRadius = w * 0.12;
    final innerDotRadius = w * 0.055;

    _fillPaint.color = AppTheme.surfaceElevated;
    _strokePaint
      ..color = color
      ..strokeWidth = strokeWidth * 0.9;
    final dotPaint = _glowPaint..color = color;

    // Origin / Root Node
    canvas.drawCircle(baseNode, nodeRadius, _fillPaint);
    canvas.drawCircle(baseNode, nodeRadius, _strokePaint);
    canvas.drawCircle(baseNode, innerDotRadius, dotPaint);

    // Bottom branch node
    canvas.drawCircle(bottomNode, nodeRadius * 0.85, _fillPaint);
    canvas.drawCircle(bottomNode, nodeRadius * 0.85, _strokePaint);
    canvas.drawCircle(bottomNode, innerDotRadius * 0.8, dotPaint);

    // Active HEAD Pulse node with glowing aura (GPU-accelerated, zero blur overhead)
    final pulseBreath = 0.5 + 0.5 * math.sin(progress * 2 * math.pi);
    _glowPaint.color = color.withValues(alpha: 0.22 * pulseBreath);
    canvas.drawCircle(headNode, nodeRadius + 3.0 * pulseBreath, _glowPaint);

    canvas.drawCircle(headNode, nodeRadius, _fillPaint);
    canvas.drawCircle(headNode, nodeRadius, _strokePaint);
    canvas.drawCircle(headNode, innerDotRadius, dotPaint);

    // 4. Live traveling pulse spark along the pulse branch
    for (final metric in pulsePath.computeMetrics()) {
      final t = (progress * 2.0) % 1.0;
      final tangent = metric.getTangentForOffset(metric.length * t);
      if (tangent != null) {
        final sparkAlpha = (math.sin(t * math.pi) * 0.9).clamp(0.0, 1.0);
        _sparkGlow.color = Colors.white.withValues(alpha: sparkAlpha * 0.4);
        canvas.drawCircle(tangent.position, 2.4, _sparkGlow);
        _sparkCore.color = Colors.white.withValues(alpha: sparkAlpha);
        canvas.drawCircle(tangent.position, 1.2, _sparkCore);
      }
      break;
    }
  }

  @override
  bool shouldRepaint(covariant _KontriLogoPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.progress != progress;
  }
}

/// Full-width header background widget for [AppBar.flexibleSpace].
///
/// Kept for compatibility; ambient background animation is now unified
/// across the entire application canvas by [AnimatedAppBackground].
class AnimatedHeaderBackground extends StatelessWidget {
  const AnimatedHeaderBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

/// Header bar with app logo, title, and version.
class AnimatedAppHeader extends StatelessWidget {
  const AnimatedAppHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeMode>(
      valueListenable: AppThemeService.currentThemeNotifier,
      builder: (context, currentTheme, _) {
        final accentColor = _getThemeAccentColor(currentTheme);

        return SizedBox(
          height: 40,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLogoContainer(
                accentColor,
                isLight: currentTheme.isLight,
              ),
              const SizedBox(width: 9),
              _buildTitle(),
              const SizedBox(width: 8),
              _buildVersionBadge(accentColor),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLogoContainer(Color accentColor, {required bool isLight}) {
    return Container(
      decoration: BoxDecoration(
        color: isLight ? AppTheme.surfaceElevated : Colors.black,
        borderRadius: BorderRadius.circular(7),
        border: isLight ? Border.all(color: AppTheme.border, width: 0.8) : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: KontriLogo(size: 28, color: accentColor),
    );
  }

  Widget _buildTitle() {
    return Text(
      'Kontri',
      style: TextStyle(
        color: AppTheme.textPrimary,
        fontWeight: FontWeight.w700,
        fontSize: 17.5,
        letterSpacing: -0.3,
      ),
    );
  }

  Widget _buildVersionBadge(Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: AppTheme.border, width: 0.8),
      ),
      child: Text(
        AppConfig.appVersion,
        style: TextStyle(
          color: AppTheme.textMuted,
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

Color _getThemeAccentColor(AppThemeMode mode) {
  switch (mode) {
    case AppThemeMode.amoledJapanese:
      return const Color(0xFFFF65A3);
    case AppThemeMode.amoled:
      return const Color(0xFF00E5FF);
    case AppThemeMode.light:
      return const Color(0xFF0969DA);
    case AppThemeMode.amoledSnowfall:
      return const Color(0xFF58A6FF);
    case AppThemeMode.amoledPure:
      return const Color(0xFF60A5FA);
    case AppThemeMode.cleanLight:
      return const Color(0xFF0EA5E9);
  }
}

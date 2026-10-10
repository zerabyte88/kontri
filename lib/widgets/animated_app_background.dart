import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/app_theme_service.dart';
import '../theme/app_theme.dart';
import 'animated_app_header.dart';

/// Root-level persistent animated background widget.
class AnimatedAppBackground extends StatefulWidget {
  final Widget child;
  const AnimatedAppBackground({super.key, required this.child});

  @override
  State<AnimatedAppBackground> createState() => _AnimatedAppBackgroundState();
}

class _AnimatedAppBackgroundState extends State<AnimatedAppBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    HeaderAnimationState.isPausedNotifier.addListener(_onPauseStateChanged);
  }

  void _onPauseStateChanged() {
    if (!mounted) return;
    if (HeaderAnimationState.isPausedNotifier.value) {
      if (_controller.isAnimating) _controller.stop();
    } else {
      if (!_controller.isAnimating) _controller.repeat();
    }
  }

  @override
  void dispose() {
    HeaderAnimationState.isPausedNotifier.removeListener(_onPauseStateChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeMode>(
      valueListenable: AppThemeService.currentThemeNotifier,
      builder: (context, currentTheme, _) {
        return Stack(
          children: [
            RepaintBoundary(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (ctx, _) => CustomPaint(
                    painter: _FullAppBgPainter(
                      progress: _controller.value,
                      themeMode: currentTheme,
                    ),
                    size: Size.infinite,
                  ),
                ),
              ),
            ),
            widget.child,
          ],
        );
      },
    );
  }
}

class _FullAppBgPainter extends CustomPainter {
  final double progress;
  final AppThemeMode themeMode;

  _FullAppBgPainter({required this.progress, required this.themeMode});

  static final Paint _fill = Paint()..style = PaintingStyle.fill;
  static final Paint _sparkle = Paint()
    ..strokeWidth = 1.0
    ..strokeCap = StrokeCap.round;
  static final Paint _glow = Paint();

  static const List<_PC> _petals = [
    _PC(bx: 0.04, sp: 1, sw: 12.0, sz: 6.0, ph: 0.05),
    _PC(bx: 0.12, sp: 2, sw: 15.0, sz: 7.5, ph: 0.15),
    _PC(bx: 0.20, sp: 1, sw: 13.0, sz: 6.5, ph: 0.28),
    _PC(bx: 0.29, sp: 2, sw: 17.0, sz: 8.0, ph: 0.42),
    _PC(bx: 0.37, sp: 1, sw: 11.0, sz: 5.8, ph: 0.57),
    _PC(bx: 0.45, sp: 2, sw: 16.0, sz: 7.8, ph: 0.70),
    _PC(bx: 0.53, sp: 1, sw: 14.0, sz: 6.8, ph: 0.82),
    _PC(bx: 0.60, sp: 2, sw: 18.0, sz: 8.2, ph: 0.10),
    _PC(bx: 0.67, sp: 1, sw: 12.0, sz: 6.2, ph: 0.22),
    _PC(bx: 0.74, sp: 2, sw: 15.0, sz: 7.4, ph: 0.35),
    _PC(bx: 0.80, sp: 1, sw: 13.0, sz: 5.5, ph: 0.48),
    _PC(bx: 0.86, sp: 2, sw: 16.0, sz: 7.0, ph: 0.62),
    _PC(bx: 0.91, sp: 1, sw: 11.0, sz: 6.0, ph: 0.75),
    _PC(bx: 0.95, sp: 2, sw: 14.0, sz: 7.6, ph: 0.88),
    _PC(bx: 0.02, sp: 1, sw: 10.0, sz: 5.2, ph: 0.32),
    _PC(bx: 0.16, sp: 2, sw: 19.0, sz: 8.4, ph: 0.55),
    _PC(bx: 0.33, sp: 1, sw: 12.5, sz: 6.6, ph: 0.68),
    _PC(bx: 0.57, sp: 2, sw: 17.5, sz: 7.9, ph: 0.90),
    _PC(bx: 0.77, sp: 1, sw: 13.5, sz: 6.3, ph: 0.18),
    _PC(bx: 0.98, sp: 2, sw: 14.5, sz: 7.2, ph: 0.44),
  ];

  static const List<_SC> _stars = [
    _SC(x: 0.04, y: 0.04, sz: 2.2, ph: 0.12, sp: true),
    _SC(x: 0.11, y: 0.18, sz: 1.4, ph: 0.65),
    _SC(x: 0.19, y: 0.08, sz: 2.4, ph: 0.38, sp: true),
    _SC(x: 0.25, y: 0.30, sz: 1.2, ph: 0.85),
    _SC(x: 0.33, y: 0.14, sz: 1.5, ph: 0.28),
    _SC(x: 0.38, y: 0.42, sz: 2.0, ph: 0.90),
    _SC(x: 0.46, y: 0.22, sz: 1.3, ph: 0.55),
    _SC(x: 0.52, y: 0.06, sz: 2.4, ph: 0.42, sp: true),
    _SC(x: 0.60, y: 0.32, sz: 1.6, ph: 0.18),
    _SC(x: 0.68, y: 0.10, sz: 1.4, ph: 0.88),
    _SC(x: 0.75, y: 0.50, sz: 2.3, ph: 0.08, sp: true),
    _SC(x: 0.82, y: 0.24, sz: 1.5, ph: 0.52),
    _SC(x: 0.89, y: 0.15, sz: 1.3, ph: 0.35),
    _SC(x: 0.95, y: 0.38, sz: 1.8, ph: 0.75),
    _SC(x: 0.08, y: 0.60, sz: 1.0, ph: 0.25, cl: Color(0xFF80DEEA)),
    _SC(x: 0.20, y: 0.72, sz: 0.9, ph: 0.70, cl: Color(0xFFE0F7FA)),
    _SC(x: 0.31, y: 0.55, sz: 2.1, ph: 0.40, sp: true),
    _SC(x: 0.44, y: 0.68, sz: 1.0, ph: 0.85, cl: Color(0xFF80DEEA)),
    _SC(x: 0.56, y: 0.80, sz: 1.2, ph: 0.60),
    _SC(x: 0.63, y: 0.65, sz: 0.9, ph: 0.22, cl: Color(0xFFE0F7FA)),
    _SC(x: 0.70, y: 0.78, sz: 2.0, ph: 0.48, sp: true),
    _SC(x: 0.78, y: 0.58, sz: 1.1, ph: 0.30),
    _SC(x: 0.85, y: 0.72, sz: 1.4, ph: 0.78),
    _SC(x: 0.93, y: 0.88, sz: 1.6, ph: 0.15),
    _SC(x: 0.14, y: 0.88, sz: 1.2, ph: 0.50),
    _SC(x: 0.28, y: 0.94, sz: 0.9, ph: 0.62, cl: Color(0xFF80DEEA)),
    _SC(x: 0.41, y: 0.90, sz: 1.5, ph: 0.33),
    _SC(x: 0.55, y: 0.96, sz: 1.0, ph: 0.88),
    _SC(x: 0.66, y: 0.92, sz: 2.2, ph: 0.05, sp: true),
    _SC(x: 0.79, y: 0.85, sz: 1.3, ph: 0.44),
    _SC(x: 0.88, y: 0.95, sz: 1.1, ph: 0.70),
    _SC(x: 0.97, y: 0.78, sz: 1.9, ph: 0.18, sp: true),
  ];

  static const List<_PC> _rain = [
    _PC(bx: 0.01, sp: 3, sw: 0, sz: 22, ph: 0.00),
    _PC(bx: 0.04, sp: 3, sw: 0, sz: 22, ph: 0.08),
    _PC(bx: 0.07, sp: 3, sw: 0, sz: 22, ph: 0.18),
    _PC(bx: 0.10, sp: 3, sw: 0, sz: 22, ph: 0.27),
    _PC(bx: 0.14, sp: 3, sw: 0, sz: 22, ph: 0.36),
    _PC(bx: 0.17, sp: 3, sw: 0, sz: 22, ph: 0.45),
    _PC(bx: 0.20, sp: 3, sw: 0, sz: 22, ph: 0.54),
    _PC(bx: 0.24, sp: 3, sw: 0, sz: 22, ph: 0.63),
    _PC(bx: 0.27, sp: 3, sw: 0, sz: 22, ph: 0.72),
    _PC(bx: 0.30, sp: 3, sw: 0, sz: 22, ph: 0.81),
    _PC(bx: 0.34, sp: 3, sw: 0, sz: 22, ph: 0.90),
    _PC(bx: 0.37, sp: 3, sw: 0, sz: 22, ph: 0.02),
    _PC(bx: 0.40, sp: 3, sw: 0, sz: 22, ph: 0.11),
    _PC(bx: 0.43, sp: 3, sw: 0, sz: 22, ph: 0.20),
    _PC(bx: 0.47, sp: 3, sw: 0, sz: 22, ph: 0.29),
    _PC(bx: 0.50, sp: 3, sw: 0, sz: 22, ph: 0.38),
    _PC(bx: 0.53, sp: 3, sw: 0, sz: 22, ph: 0.47),
    _PC(bx: 0.56, sp: 3, sw: 0, sz: 22, ph: 0.56),
    _PC(bx: 0.60, sp: 3, sw: 0, sz: 22, ph: 0.65),
    _PC(bx: 0.63, sp: 3, sw: 0, sz: 22, ph: 0.74),
    _PC(bx: 0.66, sp: 3, sw: 0, sz: 22, ph: 0.83),
    _PC(bx: 0.69, sp: 3, sw: 0, sz: 22, ph: 0.92),
    _PC(bx: 0.72, sp: 3, sw: 0, sz: 22, ph: 0.04),
    _PC(bx: 0.75, sp: 3, sw: 0, sz: 22, ph: 0.13),
    _PC(bx: 0.78, sp: 3, sw: 0, sz: 22, ph: 0.22),
    _PC(bx: 0.81, sp: 3, sw: 0, sz: 22, ph: 0.31),
    _PC(bx: 0.84, sp: 3, sw: 0, sz: 22, ph: 0.40),
    _PC(bx: 0.87, sp: 3, sw: 0, sz: 22, ph: 0.49),
    _PC(bx: 0.90, sp: 3, sw: 0, sz: 22, ph: 0.58),
    _PC(bx: 0.93, sp: 3, sw: 0, sz: 22, ph: 0.67),
    _PC(bx: 0.96, sp: 3, sw: 0, sz: 22, ph: 0.76),
    _PC(bx: 0.98, sp: 3, sw: 0, sz: 22, ph: 0.85),
    _PC(bx: 0.02, sp: 3, sw: 0, sz: 22, ph: 0.94),
    _PC(bx: 0.06, sp: 3, sw: 0, sz: 22, ph: 0.06),
    _PC(bx: 0.15, sp: 3, sw: 0, sz: 22, ph: 0.15),
    _PC(bx: 0.25, sp: 3, sw: 0, sz: 22, ph: 0.25),
    _PC(bx: 0.48, sp: 3, sw: 0, sz: 22, ph: 0.48),
    _PC(bx: 0.58, sp: 3, sw: 0, sz: 22, ph: 0.52),
    _PC(bx: 0.71, sp: 3, sw: 0, sz: 22, ph: 0.71),
    _PC(bx: 0.88, sp: 3, sw: 0, sz: 22, ph: 0.35),
  ];

  static const List<_LC> _leaves = [
    _LC(bx: 0.04, sp: 1, sw: 14.0, sz: 7.0, ph: 0.05, cl: Color(0xFF2EA043)),
    _LC(bx: 0.13, sp: 2, sw: 16.0, sz: 8.2, ph: 0.25, cl: Color(0xFFE28743)),
    _LC(bx: 0.21, sp: 1, sw: 12.0, sz: 6.5, ph: 0.45, cl: Color(0xFF1A7F37)),
    _LC(bx: 0.30, sp: 2, sw: 18.0, sz: 8.5, ph: 0.65, cl: Color(0xFFD97706)),
    _LC(bx: 0.39, sp: 1, sw: 13.0, sz: 7.2, ph: 0.85, cl: Color(0xFF2EA043)),
    _LC(bx: 0.47, sp: 2, sw: 15.0, sz: 8.0, ph: 0.10, cl: Color(0xFFE28743)),
    _LC(bx: 0.55, sp: 1, sw: 11.0, sz: 6.2, ph: 0.30, cl: Color(0xFF1A7F37)),
    _LC(bx: 0.63, sp: 2, sw: 17.0, sz: 7.8, ph: 0.50, cl: Color(0xFFD97706)),
    _LC(bx: 0.71, sp: 1, sw: 14.0, sz: 6.8, ph: 0.70, cl: Color(0xFF2EA043)),
    _LC(bx: 0.79, sp: 2, sw: 16.0, sz: 8.0, ph: 0.90, cl: Color(0xFFE28743)),
    _LC(bx: 0.86, sp: 1, sw: 13.0, sz: 6.5, ph: 0.15, cl: Color(0xFF1A7F37)),
    _LC(bx: 0.93, sp: 2, sw: 15.0, sz: 7.4, ph: 0.35, cl: Color(0xFFD97706)),
    _LC(bx: 0.08, sp: 1, sw: 12.5, sz: 7.0, ph: 0.55, cl: Color(0xFF2EA043)),
    _LC(bx: 0.17, sp: 2, sw: 14.5, sz: 8.3, ph: 0.75, cl: Color(0xFFE28743)),
    _LC(bx: 0.26, sp: 1, sw: 11.5, sz: 6.0, ph: 0.95, cl: Color(0xFF1A7F37)),
    _LC(bx: 0.35, sp: 2, sw: 16.5, sz: 7.6, ph: 0.20, cl: Color(0xFFD97706)),
    _LC(bx: 0.44, sp: 1, sw: 13.5, sz: 6.9, ph: 0.40, cl: Color(0xFF2EA043)),
    _LC(bx: 0.58, sp: 2, sw: 18.5, sz: 8.1, ph: 0.60, cl: Color(0xFFE28743)),
    _LC(bx: 0.75, sp: 1, sw: 12.0, sz: 6.4, ph: 0.80, cl: Color(0xFF1A7F37)),
    _LC(bx: 0.96, sp: 2, sw: 15.5, sz: 7.3, ph: 0.00, cl: Color(0xFFD97706)),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    switch (themeMode) {
      case AppThemeMode.amoledJapanese:
        _drawSakura(canvas, size);
      case AppThemeMode.amoled:
        _drawAmoledNight(canvas, size);
      case AppThemeMode.dark:
        _drawThunderstorm(canvas, size);
      case AppThemeMode.light:
        _drawLeaves(canvas, size);
    }
  }

  void _drawSakura(Canvas canvas, Size size) {
    _fill.color = const Color(0xFF000000);
    canvas.drawRect(Offset.zero & size, _fill);
    _drawSakuraTree(canvas, size);
    for (final p in _petals) {
      final t = (progress * p.sp + p.ph) % 1.0;
      final x = (p.bx * size.width) + math.sin(t * 2 * math.pi + p.ph) * p.sw;
      final y = -p.sz + t * (size.height + p.sz * 2);
      final opacity = (math.sin(t * math.pi) * 0.85).clamp(0.0, 1.0);
      _fill.color = const Color(0xFFFF7AA5).withValues(alpha: opacity);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate((t * 2 * math.pi) + p.ph);
      canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: p.sz * 1.5, height: p.sz * 0.8), _fill);
      canvas.restore();
    }
    _drawSparkle(canvas, Offset(size.width * 0.30, size.height * 0.15), progress, const Color(0xFFFFD1E3));
    _drawSparkle(canvas, Offset(size.width * 0.70, size.height * 0.08), progress + 0.3, const Color(0xFFFFD1E3));
    _drawSparkle(canvas, Offset(size.width * 0.55, size.height * 0.55), progress + 0.6, const Color(0xFFFF85BF));
  }

  void _drawSakuraTree(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final trunkP = Paint()
      ..color = const Color(0xFF381528).withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.92, h * 1.02)
        ..cubicTo(w * 0.90, h * 0.85, w * 0.88, h * 0.72, w * 0.85, h * 0.58),
      trunkP,
    );
    final branchP = Paint()
      ..color = const Color(0xFF381528).withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      Path()..moveTo(w * 0.85, h * 0.58)..cubicTo(w * 0.82, h * 0.48, w * 0.76, h * 0.40, w * 0.70, h * 0.33),
      branchP,
    );
    canvas.drawPath(
      Path()..moveTo(w * 0.85, h * 0.58)..cubicTo(w * 0.90, h * 0.50, w * 0.95, h * 0.44, w * 0.97, h * 0.36),
      branchP,
    );
    final subP = Paint()
      ..color = const Color(0xFF381528).withValues(alpha: 0.50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(Path()..moveTo(w * 0.70, h * 0.33)..cubicTo(w * 0.66, h * 0.26, w * 0.60, h * 0.22, w * 0.56, h * 0.18), subP);
    canvas.drawPath(Path()..moveTo(w * 0.70, h * 0.33)..cubicTo(w * 0.73, h * 0.26, w * 0.76, h * 0.20, w * 0.79, h * 0.16), subP);
    canvas.drawPath(Path()..moveTo(w * 0.97, h * 0.36)..cubicTo(w * 0.96, h * 0.28, w * 0.94, h * 0.22, w * 0.92, h * 0.16), subP);
    canvas.drawPath(Path()..moveTo(w * 0.97, h * 0.36)..cubicTo(w * 1.00, h * 0.28, w * 1.02, h * 0.21, w * 1.01, h * 0.14), subP);
    final blP = Paint()..color = const Color(0xFFFF80BF).withValues(alpha: 0.42)..style = PaintingStyle.fill;
    final blP2 = Paint()..color = const Color(0xFFFFB3D9).withValues(alpha: 0.32)..style = PaintingStyle.fill;
    void cluster(Offset c, double r) {
      canvas.drawCircle(c, r, blP2);
      canvas.drawCircle(c.translate(-r * 0.5, r * 0.3), r * 0.7, blP);
      canvas.drawCircle(c.translate(r * 0.5, -r * 0.2), r * 0.65, blP);
      canvas.drawCircle(c.translate(0, -r * 0.6), r * 0.55, blP2);
    }
    cluster(Offset(w * 0.56, h * 0.18), 14);
    cluster(Offset(w * 0.79, h * 0.16), 12);
    cluster(Offset(w * 0.92, h * 0.16), 11);
    cluster(Offset(w * 1.01, h * 0.14), 10);
    cluster(Offset(w * 0.70, h * 0.33), 10);
  }

  void _drawAmoledNight(Canvas canvas, Size size) {
    _fill.color = const Color(0xFF000000);
    canvas.drawRect(Offset.zero & size, _fill);
    for (final s in _stars) {
      final pos = Offset(s.x * size.width, s.y * size.height);
      final twinkle = 0.25 + 0.75 * (0.5 + 0.5 * math.sin((progress + s.ph) * 2 * math.pi));
      final alpha = (twinkle * 0.9).clamp(0.0, 1.0);
      final starColor = s.cl.withValues(alpha: alpha);
      if (s.sp) _drawSparkle(canvas, pos, (progress + s.ph) % 1.0, starColor);
      _fill.color = starColor;
      canvas.drawCircle(pos, s.sz * (0.7 + 0.3 * twinkle), _fill);
    }
    _drawCrescent(canvas, Offset(size.width * 0.78, size.height * 0.12));
    _drawMeteor(canvas, size, 0.00);
    _drawMeteor(canvas, size, 0.33);
    _drawMeteor(canvas, size, 0.67);
  }

  void _drawCrescent(Canvas canvas, Offset center) {
    const moonRadius = 11.0;
    final pulse = 0.7 + 0.3 * math.sin(progress * 2 * math.pi);
    _glow.color = const Color(0xFF00E5FF).withValues(alpha: 0.08 * pulse);
    canvas.drawCircle(center, moonRadius + 7.0, _glow);
    _glow.color = const Color(0xFF00E5FF).withValues(alpha: 0.18 * pulse);
    canvas.drawCircle(center, moonRadius + 3.5, _glow);
    final crescent = Path()
      ..moveTo(center.dx, center.dy - moonRadius)
      ..arcToPoint(Offset(center.dx, center.dy + moonRadius), radius: const Radius.circular(moonRadius), clockwise: false)
      ..arcToPoint(Offset(center.dx, center.dy - moonRadius), radius: const Radius.circular(moonRadius * 1.35), clockwise: true)
      ..close();
    _fill.color = const Color(0xFFE0F7FA).withValues(alpha: 0.92);
    canvas.drawPath(crescent, _fill);
  }

  void _drawMeteor(Canvas canvas, Size size, double phaseOffset) {
    final t = (progress * 0.7 + phaseOffset) % 1.0;
    if (t > 0.15) return;
    final startX = size.width * (0.05 + phaseOffset * 0.3);
    final startY = size.height * (0.02 + phaseOffset * 0.08);
    const angle = 30.0 * math.pi / 180.0;
    const length = 120.0;
    final p01 = t / 0.15;
    final headX = startX + math.cos(angle) * length * p01;
    final headY = startY + math.sin(angle) * length * p01;
    final tailP = Paint()..strokeWidth = 1.8..strokeCap = StrokeCap.round;
    for (int i = 0; i < 5; i++) {
      final frac = i / 5.0;
      final sx = headX - math.cos(angle) * length * 0.3 * frac;
      final sy = headY - math.sin(angle) * length * 0.3 * frac;
      final nf = (i + 1) / 5.0;
      final nx = headX - math.cos(angle) * length * 0.3 * nf;
      final ny = headY - math.sin(angle) * length * 0.3 * nf;
      final alpha = ((1.0 - frac) * (1.0 - p01) * 0.85).clamp(0.0, 1.0);
      tailP.color = const Color(0xFFE0F7FA).withValues(alpha: alpha);
      canvas.drawLine(Offset(sx, sy), Offset(nx, ny), tailP);
    }
    _fill.color = Colors.white.withValues(alpha: (1.0 - p01) * 0.9);
    canvas.drawCircle(Offset(headX, headY), 2.0, _fill);
  }

  void _drawThunderstorm(Canvas canvas, Size size) {
    _fill.color = const Color(0xFF0D1117);
    canvas.drawRect(Offset.zero & size, _fill);
    final rainP = Paint()..strokeWidth = 1.2..strokeCap = StrokeCap.round;
    for (final r in _rain) {
      final t = (progress * 2.5 + r.ph) % 1.0;
      final x = r.bx * size.width - 6 * t;
      final y = -22.0 + (size.height + 22.0) * t;
      final alpha = (0.25 + 0.10 * math.sin(t * math.pi)).clamp(0.0, 1.0);
      rainP.color = const Color(0xFF8B9BAB).withValues(alpha: alpha);
      canvas.drawLine(Offset(x, y), Offset(x + 6, y + 22), rainP);
    }
    _drawStormClouds(canvas, size);
    final lp = (progress * (8.0 / 12.0)) % 1.0;
    if (lp < 0.08) {
      final flashAlpha = (math.sin(lp / 0.08 * math.pi) * 0.05).clamp(0.0, 0.06);
      _fill.color = const Color(0xFF4DB8FF).withValues(alpha: flashAlpha);
      canvas.drawRect(Offset.zero & size, _fill);
      _drawLightningBolt(canvas, size, lp);
    }
  }

  void _drawStormClouds(Canvas canvas, Size size) {
    final cP = Paint()..color = const Color(0xFF1C2128).withValues(alpha: 0.85)..style = PaintingStyle.fill;
    void cloud(Offset c, double sc) {
      canvas.drawCircle(c, 28 * sc, cP);
      canvas.drawCircle(c.translate(-22 * sc, 8 * sc), 20 * sc, cP);
      canvas.drawCircle(c.translate(22 * sc, 8 * sc), 22 * sc, cP);
      canvas.drawCircle(c.translate(-10 * sc, -10 * sc), 18 * sc, cP);
      canvas.drawCircle(c.translate(10 * sc, -8 * sc), 16 * sc, cP);
    }
    cloud(Offset(size.width * 0.10, size.height * 0.06), 1.0);
    cloud(Offset(size.width * 0.45, size.height * 0.08), 1.15);
    cloud(Offset(size.width * 0.80, size.height * 0.05), 0.95);
    cloud(Offset(size.width * 0.62, size.height * 0.14), 0.85);
  }

  void _drawLightningBolt(Canvas canvas, Size size, double lp) {
    final v = math.sin(progress * 137.508);
    final sx = size.width * 0.55;
    final sy = size.height * 0.05;
    final pts = [
      Offset(sx, sy),
      Offset(sx - 8 + v * 6, sy + size.height * 0.07),
      Offset(sx + 12 + v * 8, sy + size.height * 0.14),
      Offset(sx - 5 + v * 4, sy + size.height * 0.22),
      Offset(sx + 6 + v * 5, sy + size.height * 0.30),
      Offset(sx - 2 + v * 3, sy + size.height * 0.38),
    ];
    final bolt = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (int i = 1; i < pts.length; i++) {
      bolt.lineTo(pts[i].dx, pts[i].dy);
    }

    final alpha = (math.sin(lp / 0.08 * math.pi) * 0.92).clamp(0.0, 1.0);
    canvas.drawPath(bolt, Paint()..color = const Color(0xFF4DB8FF).withValues(alpha: alpha * 0.35)..style = PaintingStyle.stroke..strokeWidth = 8..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round);
    canvas.drawPath(bolt, Paint()..color = const Color(0xFF99D6FF).withValues(alpha: alpha * 0.92)..style = PaintingStyle.stroke..strokeWidth = 2.0..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round);
    canvas.drawPath(bolt, Paint()..color = Colors.white.withValues(alpha: alpha * 0.6)..style = PaintingStyle.stroke..strokeWidth = 0.8..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round);
  }

  void _drawLeaves(Canvas canvas, Size size) {
    _fill.color = const Color(0xFFF6F8FA);
    canvas.drawRect(Offset.zero & size, _fill);
    for (final l in _leaves) {
      final t = (progress * l.sp + l.ph) % 1.0;
      final x = (l.bx * size.width) + math.sin(t * 2 * math.pi + l.ph) * l.sw;
      final y = -l.sz + t * (size.height + l.sz * 2);
      final alpha = (math.sin(t * math.pi) * 0.80).clamp(0.0, 1.0);
      _fill.color = l.cl.withValues(alpha: alpha);
      final vP = Paint()..style = PaintingStyle.stroke..strokeWidth = 0.8..color = Colors.white.withValues(alpha: alpha * 0.55);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate((t * 2 * math.pi) + l.ph);
      canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: l.sz * 1.8, height: l.sz * 0.7), _fill);
      canvas.drawLine(Offset(-l.sz * 0.7, 0), Offset(l.sz * 0.7, 0), vP);
      canvas.restore();
    }
  }

  void _drawSparkle(Canvas canvas, Offset center, double phase, Color color) {
    final arm = 2.0 + 1.5 * (0.5 + 0.5 * math.sin(phase * 2 * math.pi));
    _sparkle.color = color;
    canvas.drawLine(Offset(center.dx - arm, center.dy), Offset(center.dx + arm, center.dy), _sparkle);
    canvas.drawLine(Offset(center.dx, center.dy - arm), Offset(center.dx, center.dy + arm), _sparkle);
  }

  @override
  bool shouldRepaint(covariant _FullAppBgPainter old) =>
      old.progress != progress || old.themeMode != themeMode;
}

class _PC {
  final double bx;
  final int sp;
  final double sw;
  final double sz;
  final double ph;
  const _PC({required this.bx, required this.sp, required this.sw, required this.sz, required this.ph});
}

class _SC {
  final double x;
  final double y;
  final double sz;
  final double ph;
  final bool sp;
  final Color cl;
  const _SC({required this.x, required this.y, required this.sz, required this.ph, this.sp = false, this.cl = const Color(0xFF00E5FF)});
}

class _LC {
  final double bx;
  final int sp;
  final double sw;
  final double sz;
  final double ph;
  final Color cl;
  const _LC({required this.bx, required this.sp, required this.sw, required this.sz, required this.ph, required this.cl});
}

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
  static final Paint _stroke = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  static final Paint _sparkle = Paint()
    ..strokeWidth = 1.0
    ..strokeCap = StrokeCap.round;
  static final Paint _glow = Paint();

  // Sakura petals (AMOLED Sakura)
  static const List<_PC> _petals = [
    _PC(bx: 0.04, sp: 1, sw: 14.0, sz: 6.2, ph: 0.05),
    _PC(bx: 0.12, sp: 2, sw: 16.0, sz: 7.5, ph: 0.15),
    _PC(bx: 0.20, sp: 1, sw: 13.0, sz: 6.5, ph: 0.28),
    _PC(bx: 0.29, sp: 2, sw: 18.0, sz: 8.0, ph: 0.42),
    _PC(bx: 0.37, sp: 1, sw: 12.0, sz: 5.8, ph: 0.57),
    _PC(bx: 0.45, sp: 2, sw: 17.0, sz: 7.8, ph: 0.70),
    _PC(bx: 0.53, sp: 1, sw: 15.0, sz: 6.8, ph: 0.82),
    _PC(bx: 0.60, sp: 2, sw: 19.0, sz: 8.2, ph: 0.10),
    _PC(bx: 0.67, sp: 1, sw: 13.0, sz: 6.2, ph: 0.22),
    _PC(bx: 0.74, sp: 2, sw: 16.0, sz: 7.4, ph: 0.35),
    _PC(bx: 0.80, sp: 1, sw: 14.0, sz: 5.5, ph: 0.48),
    _PC(bx: 0.86, sp: 2, sw: 17.0, sz: 7.0, ph: 0.62),
    _PC(bx: 0.91, sp: 1, sw: 12.0, sz: 6.0, ph: 0.75),
    _PC(bx: 0.95, sp: 2, sw: 15.0, sz: 7.6, ph: 0.88),
    _PC(bx: 0.02, sp: 1, sw: 11.0, sz: 5.2, ph: 0.32),
    _PC(bx: 0.16, sp: 2, sw: 20.0, sz: 8.4, ph: 0.55),
    _PC(bx: 0.33, sp: 1, sw: 13.5, sz: 6.6, ph: 0.68),
    _PC(bx: 0.57, sp: 2, sw: 18.5, sz: 7.9, ph: 0.90),
    _PC(bx: 0.77, sp: 1, sw: 14.5, sz: 6.3, ph: 0.18),
    _PC(bx: 0.98, sp: 2, sw: 15.5, sz: 7.2, ph: 0.44),
  ];

  // Stars (AMOLED Night)
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

  // 6 Meteors traversing full screen (AMOLED Night)
  static const List<_Meteor> _meteors = [
    _Meteor(startXRatio: 0.88, startYRatio: -0.06, speed: 0.85, phase: 0.02, length: 190, headSize: 2.6),
    _Meteor(startXRatio: 1.18, startYRatio: 0.08, speed: 1.05, phase: 0.18, length: 160, headSize: 2.1, color: Color(0xFF80DEEA)),
    _Meteor(startXRatio: 0.62, startYRatio: -0.08, speed: 0.78, phase: 0.36, length: 210, headSize: 2.8),
    _Meteor(startXRatio: 1.02, startYRatio: 0.14, speed: 0.95, phase: 0.54, length: 175, headSize: 2.3),
    _Meteor(startXRatio: 0.48, startYRatio: -0.05, speed: 0.82, phase: 0.72, length: 180, headSize: 2.5, color: Color(0xFFE0F7FA)),
    _Meteor(startXRatio: 1.26, startYRatio: 0.20, speed: 1.12, phase: 0.88, length: 195, headSize: 2.7),
  ];

  // Wind-swept rain (Dark Thunderstorm)
  static const List<_RainDrop> _rainDrops = [
    _RainDrop(x: 0.02, speed: 3.2, len: 26, ph: 0.02, width: 1.3, alpha: 0.45),
    _RainDrop(x: 0.06, speed: 2.4, len: 18, ph: 0.12, width: 1.0, alpha: 0.28),
    _RainDrop(x: 0.09, speed: 3.6, len: 30, ph: 0.24, width: 1.4, alpha: 0.50),
    _RainDrop(x: 0.13, speed: 2.8, len: 22, ph: 0.35, width: 1.1, alpha: 0.35),
    _RainDrop(x: 0.17, speed: 3.3, len: 28, ph: 0.46, width: 1.3, alpha: 0.46),
    _RainDrop(x: 0.21, speed: 2.5, len: 19, ph: 0.58, width: 1.0, alpha: 0.30),
    _RainDrop(x: 0.25, speed: 3.5, len: 29, ph: 0.69, width: 1.4, alpha: 0.52),
    _RainDrop(x: 0.29, speed: 2.9, len: 23, ph: 0.80, width: 1.2, alpha: 0.38),
    _RainDrop(x: 0.33, speed: 3.1, len: 25, ph: 0.91, width: 1.2, alpha: 0.44),
    _RainDrop(x: 0.37, speed: 2.6, len: 20, ph: 0.05, width: 1.1, alpha: 0.32),
    _RainDrop(x: 0.41, speed: 3.7, len: 31, ph: 0.16, width: 1.5, alpha: 0.54),
    _RainDrop(x: 0.45, speed: 2.8, len: 21, ph: 0.28, width: 1.1, alpha: 0.36),
    _RainDrop(x: 0.49, speed: 3.4, len: 27, ph: 0.39, width: 1.3, alpha: 0.48),
    _RainDrop(x: 0.53, speed: 2.5, len: 18, ph: 0.50, width: 1.0, alpha: 0.29),
    _RainDrop(x: 0.57, speed: 3.6, len: 30, ph: 0.62, width: 1.4, alpha: 0.50),
    _RainDrop(x: 0.61, speed: 2.7, len: 22, ph: 0.73, width: 1.1, alpha: 0.34),
    _RainDrop(x: 0.65, speed: 3.2, len: 26, ph: 0.84, width: 1.3, alpha: 0.45),
    _RainDrop(x: 0.69, speed: 2.4, len: 17, ph: 0.95, width: 1.0, alpha: 0.27),
    _RainDrop(x: 0.73, speed: 3.8, len: 32, ph: 0.08, width: 1.5, alpha: 0.55),
    _RainDrop(x: 0.77, speed: 2.9, len: 23, ph: 0.20, width: 1.2, alpha: 0.37),
    _RainDrop(x: 0.81, speed: 3.3, len: 27, ph: 0.31, width: 1.3, alpha: 0.47),
    _RainDrop(x: 0.85, speed: 2.6, len: 19, ph: 0.43, width: 1.0, alpha: 0.31),
    _RainDrop(x: 0.89, speed: 3.5, len: 29, ph: 0.54, width: 1.4, alpha: 0.51),
    _RainDrop(x: 0.93, speed: 2.8, len: 21, ph: 0.66, width: 1.1, alpha: 0.35),
    _RainDrop(x: 0.97, speed: 3.4, len: 28, ph: 0.77, width: 1.3, alpha: 0.48),
    _RainDrop(x: 0.04, speed: 3.0, len: 24, ph: 0.88, width: 1.2, alpha: 0.40),
    _RainDrop(x: 0.15, speed: 3.5, len: 29, ph: 0.98, width: 1.4, alpha: 0.50),
    _RainDrop(x: 0.28, speed: 2.7, len: 20, ph: 0.14, width: 1.1, alpha: 0.33),
    _RainDrop(x: 0.46, speed: 3.3, len: 27, ph: 0.26, width: 1.3, alpha: 0.46),
    _RainDrop(x: 0.63, speed: 2.5, len: 19, ph: 0.38, width: 1.0, alpha: 0.30),
    _RainDrop(x: 0.79, speed: 3.6, len: 30, ph: 0.51, width: 1.4, alpha: 0.52),
    _RainDrop(x: 0.91, speed: 2.9, len: 22, ph: 0.63, width: 1.1, alpha: 0.36),
  ];

  // Drifting leaves (Light theme)
  static const List<_LC> _leaves = [
    _LC(bx: 0.06, sp: 1, sw: 14.0, sz: 6.8, ph: 0.05, cl: Color(0xFF2E7D32)),
    _LC(bx: 0.16, sp: 2, sw: 16.0, sz: 8.0, ph: 0.25, cl: Color(0xFFD97706)),
    _LC(bx: 0.27, sp: 1, sw: 12.0, sz: 6.5, ph: 0.45, cl: Color(0xFF388E3C)),
    _LC(bx: 0.38, sp: 2, sw: 18.0, sz: 8.2, ph: 0.65, cl: Color(0xFFE28743)),
    _LC(bx: 0.48, sp: 1, sw: 13.0, sz: 7.0, ph: 0.85, cl: Color(0xFF4CAF50)),
    _LC(bx: 0.58, sp: 2, sw: 15.0, sz: 7.8, ph: 0.10, cl: Color(0xFFD97706)),
    _LC(bx: 0.68, sp: 1, sw: 11.0, sz: 6.2, ph: 0.30, cl: Color(0xFF2E7D32)),
    _LC(bx: 0.78, sp: 2, sw: 17.0, sz: 7.8, ph: 0.50, cl: Color(0xFFE28743)),
    _LC(bx: 0.88, sp: 1, sw: 14.0, sz: 6.8, ph: 0.70, cl: Color(0xFF388E3C)),
    _LC(bx: 0.95, sp: 2, sw: 16.0, sz: 7.6, ph: 0.90, cl: Color(0xFFD97706)),
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
        _drawLightTheme(canvas, size);
    }
  }

  // ---------------------------------------------------------------------------
  // 1. AMOLED SAKURA THEME
  // ---------------------------------------------------------------------------
  void _drawSakura(Canvas canvas, Size size) {
    _fill.color = const Color(0xFF000000);
    canvas.drawRect(Offset.zero & size, _fill);

    // Lush Sakura Tree with Volumetric Canopy & Foliage
    _drawLushSakuraTree(canvas, size);

    // Drifting Sakura Petals
    for (final p in _petals) {
      final t = (progress * p.sp + p.ph) % 1.0;
      final x = (p.bx * size.width) + math.sin(t * 2 * math.pi + p.ph) * p.sw;
      final y = -p.sz + t * (size.height + p.sz * 2);
      final opacity = (math.sin(t * math.pi) * 0.85).clamp(0.0, 1.0);
      _fill.color = const Color(0xFFFF7AA5).withValues(alpha: opacity);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate((t * 2 * math.pi) + p.ph);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: p.sz * 1.5, height: p.sz * 0.8),
        _fill,
      );
      canvas.restore();
    }

    _drawSparkle(canvas, Offset(size.width * 0.30, size.height * 0.15), progress, const Color(0xFFFFD1E3));
    _drawSparkle(canvas, Offset(size.width * 0.65, size.height * 0.08), progress + 0.3, const Color(0xFFFFD1E3));
    _drawSparkle(canvas, Offset(size.width * 0.48, size.height * 0.45), progress + 0.6, const Color(0xFFFF85BF));
  }

  void _drawLushSakuraTree(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Organic Tapered Trunk
    final trunkPath = Path()
      ..moveTo(w * 0.88, h * 1.02)
      ..cubicTo(w * 0.89, h * 0.88, w * 0.87, h * 0.74, w * 0.84, h * 0.62)
      ..cubicTo(w * 0.81, h * 0.52, w * 0.77, h * 0.44, w * 0.72, h * 0.36)
      ..lineTo(w * 0.76, h * 0.35)
      ..cubicTo(w * 0.82, h * 0.45, w * 0.87, h * 0.54, w * 0.91, h * 0.65)
      ..cubicTo(w * 0.94, h * 0.76, w * 0.97, h * 0.88, w * 1.02, h * 1.02)
      ..close();

    _fill.color = const Color(0xFF2E1020).withValues(alpha: 0.80);
    canvas.drawPath(trunkPath, _fill);

    // Inner Bark Grain Lines
    _stroke
      ..color = const Color(0xFF451832).withValues(alpha: 0.65)
      ..strokeWidth = 3.5;
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.94, h * 1.01)
        ..cubicTo(w * 0.92, h * 0.85, w * 0.89, h * 0.70, w * 0.84, h * 0.58),
      _stroke,
    );

    // 2. Main Boughs & Reaching Branches
    _stroke
      ..color = const Color(0xFF351225).withValues(alpha: 0.75)
      ..strokeWidth = 10;
    // Bough reaching toward center-left
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.84, h * 0.62)
        ..cubicTo(w * 0.78, h * 0.52, w * 0.70, h * 0.44, w * 0.60, h * 0.34),
      _stroke,
    );
    // Bough reaching upward
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.86, h * 0.60)
        ..cubicTo(w * 0.86, h * 0.48, w * 0.84, h * 0.38, w * 0.80, h * 0.24),
      _stroke,
    );
    // Bough reaching rightward
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.89, h * 0.63)
        ..cubicTo(w * 0.92, h * 0.52, w * 0.96, h * 0.42, w * 0.99, h * 0.28),
      _stroke,
    );

    // Sub-branches
    _stroke
      ..strokeWidth = 5.0
      ..color = const Color(0xFF3D152B).withValues(alpha: 0.65);
    canvas.drawPath(
      Path()..moveTo(w * 0.70, h * 0.44)..cubicTo(w * 0.65, h * 0.38, w * 0.54, h * 0.32, w * 0.48, h * 0.28),
      _stroke,
    );
    canvas.drawPath(
      Path()..moveTo(w * 0.73, h * 0.46)..cubicTo(w * 0.74, h * 0.36, w * 0.70, h * 0.28, w * 0.68, h * 0.20),
      _stroke,
    );
    canvas.drawPath(
      Path()..moveTo(w * 0.83, h * 0.42)..cubicTo(w * 0.88, h * 0.32, w * 0.90, h * 0.24, w * 0.89, h * 0.16),
      _stroke,
    );
    canvas.drawPath(
      Path()..moveTo(w * 0.94, h * 0.46)..cubicTo(w * 0.97, h * 0.38, w * 1.01, h * 0.30, w * 1.02, h * 0.22),
      _stroke,
    );

    // 3. Volumetric Cherry Blossom Canopy Clouds with Foliage Underlay
    void drawCanopyCluster(Offset c, double radius) {
      // Layer A: Under-canopy Depth Shadow
      _fill.color = const Color(0xFF561533).withValues(alpha: 0.50);
      canvas.drawCircle(c.translate(0, radius * 0.25), radius * 0.95, _fill);

      // Layer B: Spring Green Leaves nestled in the blooms
      _fill.color = const Color(0xFF2E6832).withValues(alpha: 0.42);
      canvas.drawCircle(c.translate(-radius * 0.35, radius * 0.20), radius * 0.55, _fill);
      _fill.color = const Color(0xFF4C8C50).withValues(alpha: 0.38);
      canvas.drawCircle(c.translate(radius * 0.30, radius * 0.15), radius * 0.50, _fill);

      // Layer C: Rich Magenta / Deep Rose Blossom Base
      _fill.color = const Color(0xFFFF528F).withValues(alpha: 0.55);
      canvas.drawCircle(c.translate(-radius * 0.25, 0), radius * 0.75, _fill);
      canvas.drawCircle(c.translate(radius * 0.25, -radius * 0.10), radius * 0.70, _fill);
      canvas.drawCircle(c.translate(0, -radius * 0.30), radius * 0.65, _fill);

      // Layer D: Soft Sakura Blossom Clouds
      _fill.color = const Color(0xFFFF85BF).withValues(alpha: 0.60);
      canvas.drawCircle(c, radius * 0.60, _fill);
      canvas.drawCircle(c.translate(-radius * 0.20, -radius * 0.20), radius * 0.48, _fill);
      canvas.drawCircle(c.translate(radius * 0.20, -radius * 0.15), radius * 0.45, _fill);

      // Layer E: Sunlit Petal Highlight Puffs
      _fill.color = const Color(0xFFFFD4E8).withValues(alpha: 0.68);
      canvas.drawCircle(c.translate(-radius * 0.10, -radius * 0.35), radius * 0.38, _fill);
      canvas.drawCircle(c.translate(radius * 0.15, -radius * 0.30), radius * 0.32, _fill);
    }

    // Lush Canopy Lobes spanning across the upper and mid boughs
    drawCanopyCluster(Offset(w * 0.48, h * 0.27), 38);
    drawCanopyCluster(Offset(w * 0.59, h * 0.22), 44);
    drawCanopyCluster(Offset(w * 0.69, h * 0.17), 46);
    drawCanopyCluster(Offset(w * 0.80, h * 0.14), 45);
    drawCanopyCluster(Offset(w * 0.89, h * 0.16), 40);
    drawCanopyCluster(Offset(w * 0.99, h * 0.22), 38);
    drawCanopyCluster(Offset(w * 0.72, h * 0.33), 36);
    drawCanopyCluster(Offset(w * 0.86, h * 0.30), 34);
    drawCanopyCluster(Offset(w * 0.95, h * 0.36), 30);
  }

  // ---------------------------------------------------------------------------
  // 2. AMOLED NIGHT THEME (Continuous Multi-Meteor Shower)
  // ---------------------------------------------------------------------------
  void _drawAmoledNight(Canvas canvas, Size size) {
    _fill.color = const Color(0xFF000000);
    canvas.drawRect(Offset.zero & size, _fill);

    // Stars
    for (final s in _stars) {
      final pos = Offset(s.x * size.width, s.y * size.height);
      final twinkle = 0.25 + 0.75 * (0.5 + 0.5 * math.sin((progress + s.ph) * 2 * math.pi));
      final alpha = (twinkle * 0.9).clamp(0.0, 1.0);
      final starColor = s.cl.withValues(alpha: alpha);
      if (s.sp) _drawSparkle(canvas, pos, (progress + s.ph) % 1.0, starColor);
      _fill.color = starColor;
      canvas.drawCircle(pos, s.sz * (0.7 + 0.3 * twinkle), _fill);
    }

    // Glowing Crescent Moon
    _drawCrescent(canvas, Offset(size.width * 0.78, size.height * 0.12));

    // 6 Full-Screen Meteors
    for (final m in _meteors) {
      _drawContinuousMeteor(canvas, size, m);
    }
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
      ..arcToPoint(
        Offset(center.dx, center.dy + moonRadius),
        radius: const Radius.circular(moonRadius),
        clockwise: false,
      )
      ..arcToPoint(
        Offset(center.dx, center.dy - moonRadius),
        radius: const Radius.circular(moonRadius * 1.35),
        clockwise: true,
      )
      ..close();
    _fill.color = const Color(0xFFE0F7FA).withValues(alpha: 0.92);
    canvas.drawPath(crescent, _fill);
  }

  void _drawContinuousMeteor(Canvas canvas, Size size, _Meteor m) {
    final tCycle = (progress * m.speed + m.phase) % 1.0;
    // Each meteor transits the canvas for 42% of its cycle, then waits in cooldown
    const transitFraction = 0.42;
    if (tCycle > transitFraction) return;

    final p = tCycle / transitFraction; // 0.0 (entering) to 1.0 (exited)
    const angle = 36.0 * math.pi / 180.0;
    final cosA = math.cos(angle);
    final sinA = math.sin(angle);

    // Full traversal length across the diagonal
    final totalDistance = (size.width + size.height) * 1.35;
    final startX = size.width * m.startXRatio;
    final startY = size.height * m.startYRatio;

    // Head moves from start towards bottom-left
    final headX = startX - cosA * totalDistance * p;
    final headY = startY + sinA * totalDistance * p;

    // Smooth entry and exit envelope (no abrupt disappearance)
    final envelope = (math.sin(p * math.pi)).clamp(0.0, 1.0);

    // Draw glowing gradient trail
    const steps = 7;
    for (int i = 0; i < steps; i++) {
      final f1 = i / steps;
      final f2 = (i + 1) / steps;
      final x1 = headX + cosA * m.length * f1;
      final y1 = headY - sinA * m.length * f1;
      final x2 = headX + cosA * m.length * f2;
      final y2 = headY - sinA * m.length * f2;

      final alpha = (envelope * (1.0 - f1) * 0.85).clamp(0.0, 1.0);
      _stroke
        ..strokeWidth = (m.headSize * (1.0 - f1 * 0.75)).clamp(0.8, 3.5)
        ..color = m.color.withValues(alpha: alpha);
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), _stroke);
    }

    // Radiant Glowing Head
    _fill.color = m.color.withValues(alpha: envelope * 0.45);
    canvas.drawCircle(Offset(headX, headY), m.headSize * 2.2, _fill);
    _fill.color = Colors.white.withValues(alpha: envelope * 0.95);
    canvas.drawCircle(Offset(headX, headY), m.headSize, _fill);
  }

  // ---------------------------------------------------------------------------
  // 3. DARK THUNDERSTORM THEME (Drifting Clouds, Forked Lightning, Angled Rain)
  // ---------------------------------------------------------------------------
  void _drawThunderstorm(Canvas canvas, Size size) {
    _fill.color = const Color(0xFF0D1117);
    canvas.drawRect(Offset.zero & size, _fill);

    // Lightning Flash Check (two strike cycles in the animation)
    final lProgress1 = (progress * 1.5) % 1.0;
    final lProgress2 = (progress * 1.5 + 0.55) % 1.0;
    final bool isStrike1 = lProgress1 < 0.08;
    final bool isStrike2 = lProgress2 < 0.06;

    double flashAlpha = 0.0;
    if (isStrike1) {
      flashAlpha = (math.sin(lProgress1 / 0.08 * math.pi) * 0.07).clamp(0.0, 0.08);
    } else if (isStrike2) {
      flashAlpha = (math.sin(lProgress2 / 0.06 * math.pi) * 0.06).clamp(0.0, 0.07);
    }

    if (flashAlpha > 0.0) {
      _fill.color = const Color(0xFF388BFD).withValues(alpha: flashAlpha);
      canvas.drawRect(Offset.zero & size, _fill);
    }

    // Wind-swept rain (~15 degree tilt to right)
    final rainTiltX = 7.0;
    final rainTiltY = 26.0;

    for (final r in _rainDrops) {
      final t = (progress * r.speed + r.ph) % 1.0;
      final x = r.x * size.width + (t * 40.0) % size.width;
      final y = -40.0 + (size.height + 60.0) * t;
      final alpha = (r.alpha * (0.6 + 0.4 * math.sin(t * math.pi))).clamp(0.0, 1.0);

      _stroke
        ..strokeWidth = r.width
        ..color = const Color(0xFF8B949E).withValues(alpha: alpha);
      canvas.drawLine(
        Offset(x, y),
        Offset(x + rainTiltX * (r.len / 26.0), y + rainTiltY * (r.len / 26.0)),
        _stroke,
      );

      // Splash ripple when drop hits the bottom
      if (y > size.height - 18) {
        final spT = (y - (size.height - 18)) / 18;
        _stroke
          ..strokeWidth = 0.8
          ..color = const Color(0xFF8B949E).withValues(alpha: (1.0 - spT) * 0.25);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(x + rainTiltX, size.height - 2),
            width: 8 * spT,
            height: 2.5 * spT,
          ),
          _stroke,
        );
      }
    }

    // Dynamic Multi-Tier Storm Clouds
    _drawStormClouds(canvas, size, flashAlpha);

    // Forked Branching Lightning Bolt
    if (isStrike1) {
      _drawForkedLightning(canvas, size, lProgress1 / 0.08, Offset(size.width * 0.58, size.height * 0.06));
    } else if (isStrike2) {
      _drawForkedLightning(canvas, size, lProgress2 / 0.06, Offset(size.width * 0.32, size.height * 0.05));
    }
  }

  void _drawStormClouds(Canvas canvas, Size size, double flashAlpha) {
    final w = size.width;
    final h = size.height;
    final drift = math.sin(progress * 2 * math.pi) * 8.0;

    void drawCloudPuff(Offset c, double radius, Color color) {
      _fill.color = color;
      canvas.drawCircle(c, radius, _fill);
    }

    // Back Dark Storm Tier
    final backColor = const Color(0xFF131924).withValues(alpha: 0.90);
    drawCloudPuff(Offset(w * 0.08 + drift * 0.5, h * 0.04), 48, backColor);
    drawCloudPuff(Offset(w * 0.35 + drift * 0.5, h * 0.06), 56, backColor);
    drawCloudPuff(Offset(w * 0.68 + drift * 0.5, h * 0.05), 52, backColor);
    drawCloudPuff(Offset(w * 0.95 + drift * 0.5, h * 0.03), 46, backColor);

    // Front Textured Thundercloud Tier
    final frontColor = Color.lerp(
      const Color(0xFF1C2331).withValues(alpha: 0.88),
      const Color(0xFF324560).withValues(alpha: 0.95),
      (flashAlpha * 12.0).clamp(0.0, 1.0),
    )!;

    drawCloudPuff(Offset(w * 0.18 + drift, h * 0.07), 42, frontColor);
    drawCloudPuff(Offset(w * 0.50 + drift, h * 0.08), 50, frontColor);
    drawCloudPuff(Offset(w * 0.82 + drift, h * 0.06), 46, frontColor);
    drawCloudPuff(Offset(w * 0.34 + drift, h * 0.11), 36, frontColor);
    drawCloudPuff(Offset(w * 0.64 + drift, h * 0.10), 38, frontColor);
  }

  void _drawForkedLightning(Canvas canvas, Size size, double p01, Offset origin) {
    final alpha = (math.sin(p01 * math.pi) * 0.95).clamp(0.0, 1.0);
    final h = size.height;

    // Main jagged trunk
    final pts = [
      origin,
      Offset(origin.dx - 8, origin.dy + h * 0.07),
      Offset(origin.dx + 14, origin.dy + h * 0.15),
      Offset(origin.dx - 6, origin.dy + h * 0.23),
      Offset(origin.dx + 10, origin.dy + h * 0.32),
      Offset(origin.dx - 2, origin.dy + h * 0.40),
    ];

    final mainBolt = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (int i = 1; i < pts.length; i++) {
      mainBolt.lineTo(pts[i].dx, pts[i].dy);
    }

    // Branch 1 (splitting to the left at step 2)
    final branch1 = Path()
      ..moveTo(pts[2].dx, pts[2].dy)
      ..lineTo(pts[2].dx - 18, pts[2].dy + h * 0.06)
      ..lineTo(pts[2].dx - 26, pts[2].dy + h * 0.12);

    // Branch 2 (splitting to the right at step 4)
    final branch2 = Path()
      ..moveTo(pts[4].dx, pts[4].dy)
      ..lineTo(pts[4].dx + 16, pts[4].dy + h * 0.05)
      ..lineTo(pts[4].dx + 22, pts[4].dy + h * 0.09);

    void renderBolt(Path path, double glowW, double coreW) {
      _stroke
        ..strokeWidth = glowW
        ..color = const Color(0xFF388BFD).withValues(alpha: alpha * 0.30);
      canvas.drawPath(path, _stroke);

      _stroke
        ..strokeWidth = coreW * 1.8
        ..color = const Color(0xFF79C0FF).withValues(alpha: alpha * 0.85);
      canvas.drawPath(path, _stroke);

      _stroke
        ..strokeWidth = coreW * 0.8
        ..color = Colors.white.withValues(alpha: alpha * 0.95);
      canvas.drawPath(path, _stroke);
    }

    renderBolt(mainBolt, 9.0, 2.0);
    renderBolt(branch1, 5.0, 1.2);
    renderBolt(branch2, 5.0, 1.2);
  }

  // ---------------------------------------------------------------------------
  // 4. LIGHT THEME (Left Fruit Tree, Rolling Grass Hills, Drifting Clouds)
  // ---------------------------------------------------------------------------
  void _drawLightTheme(Canvas canvas, Size size) {
    _fill.color = const Color(0xFFF6F8FA);
    canvas.drawRect(Offset.zero & size, _fill);

    // Awan Putih di Langit Atas
    _drawSkyClouds(canvas, size);

    // Pohon Buah di Sisi Kiri Layar
    _drawLeftFruitTree(canvas, size);

    // Rerumputan di Bagian Footer
    _drawFooterGrassHills(canvas, size);

    // Daun-daun lembut melayang tertiup angin
    for (final l in _leaves) {
      final t = (progress * l.sp + l.ph) % 1.0;
      final x = (l.bx * size.width) + math.sin(t * 2 * math.pi + l.ph) * l.sw;
      final y = -l.sz + t * (size.height + l.sz * 2);
      final alpha = (math.sin(t * math.pi) * 0.70).clamp(0.0, 1.0);
      _fill.color = l.cl.withValues(alpha: alpha);

      _stroke
        ..strokeWidth = 0.8
        ..color = Colors.white.withValues(alpha: alpha * 0.55);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate((t * 2 * math.pi) + l.ph);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: l.sz * 1.8, height: l.sz * 0.7),
        _fill,
      );
      canvas.drawLine(Offset(-l.sz * 0.7, 0), Offset(l.sz * 0.7, 0), _stroke);
      canvas.restore();
    }
  }

  void _drawSkyClouds(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    void drawPuffyCloud(double baseXRatio, double y, double scale) {
      final x = ((baseXRatio + progress * 0.08) % 1.3 - 0.15) * w;

      // Soft underside shadow
      _fill.color = const Color(0xFFE2EBF5).withValues(alpha: 0.45);
      canvas.drawCircle(Offset(x, y + 4 * scale), 20 * scale, _fill);
      canvas.drawCircle(Offset(x - 18 * scale, y + 6 * scale), 15 * scale, _fill);
      canvas.drawCircle(Offset(x + 18 * scale, y + 5 * scale), 16 * scale, _fill);

      // Pure white cloud puffs
      _fill.color = const Color(0xFFFFFFFF).withValues(alpha: 0.68);
      canvas.drawCircle(Offset(x, y), 20 * scale, _fill);
      canvas.drawCircle(Offset(x - 18 * scale, y + 2 * scale), 15 * scale, _fill);
      canvas.drawCircle(Offset(x + 18 * scale, y + 1 * scale), 16 * scale, _fill);
      canvas.drawCircle(Offset(x - 8 * scale, y - 8 * scale), 14 * scale, _fill);
      canvas.drawCircle(Offset(x + 8 * scale, y - 6 * scale), 13 * scale, _fill);
    }

    drawPuffyCloud(0.15, h * 0.05, 1.15);
    drawPuffyCloud(0.58, h * 0.08, 0.95);
    drawPuffyCloud(0.92, h * 0.04, 1.05);
  }

  void _drawLeftFruitTree(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Organic Tapered Tree Trunk on the Left
    final trunkPath = Path()
      ..moveTo(-w * 0.02, h * 1.02)
      ..cubicTo(w * 0.02, h * 0.88, w * 0.06, h * 0.75, w * 0.10, h * 0.62)
      ..cubicTo(w * 0.12, h * 0.52, w * 0.15, h * 0.44, w * 0.20, h * 0.35)
      ..lineTo(w * 0.16, h * 0.34)
      ..cubicTo(w * 0.11, h * 0.45, w * 0.07, h * 0.55, w * 0.04, h * 0.68)
      ..cubicTo(w * 0.02, h * 0.80, -w * 0.01, h * 0.90, w * 0.12, h * 1.02)
      ..close();

    _fill.color = const Color(0xFF5D4037).withValues(alpha: 0.75);
    canvas.drawPath(trunkPath, _fill);

    // Trunk Grain
    _stroke
      ..color = const Color(0xFF795548).withValues(alpha: 0.60)
      ..strokeWidth = 3.0;
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.03, h * 1.01)
        ..cubicTo(w * 0.05, h * 0.84, w * 0.08, h * 0.70, w * 0.13, h * 0.56),
      _stroke,
    );

    // 2. Reaching Branches
    _stroke
      ..color = const Color(0xFF5D4037).withValues(alpha: 0.75)
      ..strokeWidth = 9.0;
    // Main right bough
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.10, h * 0.62)
        ..cubicTo(w * 0.16, h * 0.52, w * 0.24, h * 0.44, w * 0.32, h * 0.34),
      _stroke,
    );
    // Center-top bough
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.11, h * 0.58)
        ..cubicTo(w * 0.13, h * 0.46, w * 0.15, h * 0.36, w * 0.18, h * 0.22),
      _stroke,
    );
    // Outer-left bough
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.07, h * 0.60)
        ..cubicTo(w * 0.05, h * 0.50, w * 0.03, h * 0.40, w * 0.02, h * 0.28),
      _stroke,
    );

    // Sub-branches
    _stroke
      ..strokeWidth = 4.5
      ..color = const Color(0xFF6D4C41).withValues(alpha: 0.68);
    canvas.drawPath(
      Path()..moveTo(w * 0.22, h * 0.45)..cubicTo(w * 0.28, h * 0.38, w * 0.34, h * 0.32, w * 0.38, h * 0.28),
      _stroke,
    );
    canvas.drawPath(
      Path()..moveTo(w * 0.20, h * 0.48)..cubicTo(w * 0.22, h * 0.36, w * 0.25, h * 0.28, w * 0.28, h * 0.20),
      _stroke,
    );
    canvas.drawPath(
      Path()..moveTo(w * 0.14, h * 0.38)..cubicTo(w * 0.10, h * 0.30, w * 0.08, h * 0.22, w * 0.06, h * 0.16),
      _stroke,
    );

    // 3. Volumetric Lush Green Canopy Clouds
    void drawFoliageCluster(Offset c, double radius) {
      // Under-canopy shadow
      _fill.color = const Color(0xFF1B5E20).withValues(alpha: 0.45);
      canvas.drawCircle(c.translate(0, radius * 0.25), radius * 0.95, _fill);

      // Deep forest mid-tier
      _fill.color = const Color(0xFF2E7D32).withValues(alpha: 0.60);
      canvas.drawCircle(c.translate(-radius * 0.25, 0), radius * 0.75, _fill);
      canvas.drawCircle(c.translate(radius * 0.25, -radius * 0.10), radius * 0.70, _fill);

      // Fresh leafy green
      _fill.color = const Color(0xFF43A047).withValues(alpha: 0.65);
      canvas.drawCircle(c, radius * 0.60, _fill);
      canvas.drawCircle(c.translate(0, -radius * 0.25), radius * 0.55, _fill);

      // Sunlit bright highlights
      _fill.color = const Color(0xFF81C784).withValues(alpha: 0.70);
      canvas.drawCircle(c.translate(-radius * 0.10, -radius * 0.35), radius * 0.38, _fill);
      canvas.drawCircle(c.translate(radius * 0.15, -radius * 0.30), radius * 0.34, _fill);
    }

    drawFoliageCluster(Offset(w * 0.03, h * 0.26), 36);
    drawFoliageCluster(Offset(w * 0.12, h * 0.18), 42);
    drawFoliageCluster(Offset(w * 0.22, h * 0.22), 44);
    drawFoliageCluster(Offset(w * 0.32, h * 0.28), 40);
    drawFoliageCluster(Offset(w * 0.38, h * 0.34), 32);
    drawFoliageCluster(Offset(w * 0.20, h * 0.36), 38);
    drawFoliageCluster(Offset(w * 0.11, h * 0.44), 34);

    // 4. Shiny Ripe Red Fruits (Apples/Cherries) with Stems and Highlights
    void drawFruit(Offset center, double radius) {
      // Little brown stem
      _stroke
        ..strokeWidth = 1.2
        ..color = const Color(0xFF4E342E).withValues(alpha: 0.85);
      canvas.drawLine(
        Offset(center.dx, center.dy - radius * 0.8),
        Offset(center.dx + 2.0, center.dy - radius * 1.6),
        _stroke,
      );

      // Fruit body
      _fill.color = const Color(0xFFE53935).withValues(alpha: 0.88);
      canvas.drawCircle(center, radius, _fill);

      // Subtle depth shade
      _fill.color = const Color(0xFFB71C1C).withValues(alpha: 0.50);
      canvas.drawCircle(center.translate(radius * 0.25, radius * 0.25), radius * 0.55, _fill);

      // Specular white shine dot
      _fill.color = Colors.white.withValues(alpha: 0.90);
      canvas.drawCircle(center.translate(-radius * 0.35, -radius * 0.35), radius * 0.28, _fill);
    }

    drawFruit(Offset(w * 0.33, h * 0.32), 4.5);
    drawFruit(Offset(w * 0.26, h * 0.26), 4.2);
    drawFruit(Offset(w * 0.36, h * 0.38), 4.0);
    drawFruit(Offset(w * 0.18, h * 0.22), 4.5);
    drawFruit(Offset(w * 0.12, h * 0.26), 4.0);
    drawFruit(Offset(w * 0.06, h * 0.32), 4.2);
    drawFruit(Offset(w * 0.24, h * 0.40), 4.5);
    drawFruit(Offset(w * 0.14, h * 0.36), 4.2);
  }

  void _drawFooterGrassHills(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Back Rolling Grass Hill
    final backHillPath = Path()
      ..moveTo(0, h * 0.94)
      ..cubicTo(w * 0.30, h * 0.92, w * 0.65, h * 0.96, w, h * 0.93)
      ..lineTo(w, h * 1.02)
      ..lineTo(0, h * 1.02)
      ..close();
    _fill.color = const Color(0xFF81C784).withValues(alpha: 0.40);
    canvas.drawPath(backHillPath, _fill);

    // Front Lush Grass Hill
    final frontHillPath = Path()
      ..moveTo(0, h * 0.96)
      ..cubicTo(w * 0.38, h * 0.93, w * 0.72, h * 0.97, w, h * 0.95)
      ..lineTo(w, h * 1.02)
      ..lineTo(0, h * 1.02)
      ..close();
    _fill.color = const Color(0xFF4CAF50).withValues(alpha: 0.50);
    canvas.drawPath(frontHillPath, _fill);

    // Tufts of Grass Blades Swaying with Wind
    final sway = math.sin(progress * 2 * math.pi) * 2.5;
    _stroke
      ..color = const Color(0xFF2E7D32).withValues(alpha: 0.60)
      ..strokeWidth = 1.4;

    for (int i = 0; i <= 14; i++) {
      final x = (i / 14.0) * w;
      final y = h * 0.95 + math.sin(i * 1.2) * 5.0;
      canvas.drawLine(Offset(x, y), Offset(x - 3 + sway, y - 9), _stroke);
      canvas.drawLine(Offset(x, y), Offset(x + 3 + sway, y - 8), _stroke);
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

// -----------------------------------------------------------------------------
// HELPER DATA CLASSES
// -----------------------------------------------------------------------------
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

class _Meteor {
  final double startXRatio;
  final double startYRatio;
  final double speed;
  final double phase;
  final double length;
  final double headSize;
  final Color color;
  const _Meteor({
    required this.startXRatio,
    required this.startYRatio,
    required this.speed,
    required this.phase,
    required this.length,
    required this.headSize,
    this.color = const Color(0xFF00E5FF),
  });
}

class _RainDrop {
  final double x;
  final double speed;
  final double len;
  final double ph;
  final double width;
  final double alpha;
  const _RainDrop({
    required this.x,
    required this.speed,
    required this.len,
    required this.ph,
    required this.width,
    required this.alpha,
  });
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

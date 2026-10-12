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
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );
    if (!HeaderAnimationState.isPausedNotifier.value) {
      _controller.repeat();
    }

    HeaderAnimationState.isPausedNotifier.addListener(_onPauseStateChanged);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      if (_controller.isAnimating) _controller.stop();
    } else if (state == AppLifecycleState.resumed) {
      if (!HeaderAnimationState.isPausedNotifier.value &&
          !_controller.isAnimating) {
        _controller.repeat();
      }
    }
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
    WidgetsBinding.instance.removeObserver(this);
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
            RepaintBoundary(child: widget.child),
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

  // Cached static background shaders
  static Size? _cachedMoonSize;
  static Shader? _cachedMoonShader;

  // 34 Seamless Dynamic Particles (Snowfall & Daylight - Phantek Engine)
  static final List<_BackgroundParticle> _particles = _initParticles();

  static List<_BackgroundParticle> _initParticles() {
    final random = math.Random(42);
    return List.generate(34, (_) {
      return _BackgroundParticle(
        x: random.nextDouble(),
        y: random.nextDouble(),
        size: 2.5 + random.nextDouble() * 5.0,
        cycles: 1 + random.nextInt(3),
        swayFreq: 1 + random.nextInt(2),
        swayAmplitude: 10.0 + random.nextDouble() * 16.0,
        rotCycles: (random.nextBool() ? 1 : -1) * (1 + random.nextInt(2)),
        phase: random.nextDouble() * 2 * math.pi,
        twinkleFreq: 2 + random.nextInt(4),
        variant: random.nextInt(4),
      );
    });
  }

  // 14 Sakura petals (AMOLED Sakura)
  static const List<_PC> _petals = [
    _PC(bx: 0.05, sp: 1, sw: 14.0, sz: 6.2, ph: 0.05),
    _PC(bx: 0.14, sp: 2, sw: 16.0, sz: 7.5, ph: 0.15),
    _PC(bx: 0.22, sp: 1, sw: 13.0, sz: 6.5, ph: 0.28),
    _PC(bx: 0.31, sp: 2, sw: 18.0, sz: 7.8, ph: 0.42),
    _PC(bx: 0.39, sp: 1, sw: 12.0, sz: 5.8, ph: 0.57),
    _PC(bx: 0.47, sp: 2, sw: 17.0, sz: 7.6, ph: 0.70),
    _PC(bx: 0.55, sp: 1, sw: 15.0, sz: 6.8, ph: 0.82),
    _PC(bx: 0.63, sp: 2, sw: 19.0, sz: 8.0, ph: 0.10),
    _PC(bx: 0.70, sp: 1, sw: 13.0, sz: 6.2, ph: 0.25),
    _PC(bx: 0.78, sp: 2, sw: 16.0, sz: 7.4, ph: 0.38),
    _PC(bx: 0.85, sp: 1, sw: 14.0, sz: 5.6, ph: 0.52),
    _PC(bx: 0.91, sp: 2, sw: 17.0, sz: 7.0, ph: 0.66),
    _PC(bx: 0.96, sp: 1, sw: 12.0, sz: 6.0, ph: 0.80),
    _PC(bx: 0.18, sp: 2, sw: 20.0, sz: 8.2, ph: 0.92),
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

  // 6 Meteors traversing full screen (AMOLED Night - Seamless Continuous Loops)
  static const List<_Meteor> _meteors = [
    _Meteor(
      startXRatio: 0.88,
      startYRatio: -0.06,
      speed: 1.0,
      phase: 0.02,
      length: 190,
      headSize: 2.6,
    ),
    _Meteor(
      startXRatio: 1.18,
      startYRatio: 0.08,
      speed: 1.0,
      phase: 0.18,
      length: 160,
      headSize: 2.1,
      color: Color(0xFF80DEEA),
    ),
    _Meteor(
      startXRatio: 0.62,
      startYRatio: -0.08,
      speed: 1.0,
      phase: 0.36,
      length: 210,
      headSize: 2.8,
    ),
    _Meteor(
      startXRatio: 1.02,
      startYRatio: 0.14,
      speed: 1.0,
      phase: 0.54,
      length: 175,
      headSize: 2.3,
    ),
    _Meteor(
      startXRatio: 0.48,
      startYRatio: -0.05,
      speed: 1.0,
      phase: 0.72,
      length: 180,
      headSize: 2.5,
      color: Color(0xFFE0F7FA),
    ),
    _Meteor(
      startXRatio: 1.26,
      startYRatio: 0.20,
      speed: 1.0,
      phase: 0.88,
      length: 195,
      headSize: 2.7,
    ),
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
        _paintSnowfallVillage(canvas, size);
      case AppThemeMode.light:
        _paintLightDaylight(canvas, size);
    }
  }

  // ---------------------------------------------------------------------------
  // 1. AMOLED SAKURA THEME (Zen Ethereal Moonlit Sakura)
  // ---------------------------------------------------------------------------
  void _drawSakura(Canvas canvas, Size size) {
    _fill.color = const Color(0xFF000000);
    canvas.drawRect(Offset.zero & size, _fill);

    final w = size.width;
    final h = size.height;

    // 1. Ethereal Full Moon (Repositioned down & right to clear GitPulse header text)
    final moonCenter = Offset(w * 0.36, h * 0.21);
    const moonR = 21.0;
    final moonGlow = 0.85 + 0.15 * math.sin(progress * 2 * math.pi);

    // Outer Rose-Gold Halo
    _glow.color = const Color(0xFFFF7AA5).withValues(alpha: 0.08 * moonGlow);
    canvas.drawCircle(moonCenter, moonR + 18.0, _glow);
    _glow.color = const Color(0xFFFFD4E8).withValues(alpha: 0.14 * moonGlow);
    canvas.drawCircle(moonCenter, moonR + 9.0, _glow);

    // Moon Disc: Soft rose-pearl silver gradient so it does not clash with white text
    final moonBounds = Rect.fromCircle(center: moonCenter, radius: moonR);
    if (_cachedMoonSize != size || _cachedMoonShader == null) {
      _cachedMoonSize = size;
      _cachedMoonShader = RadialGradient(
        center: const Alignment(-0.25, -0.25),
        radius: 0.9,
        colors: [
          const Color(0xFFFFF0F5).withValues(alpha: 0.92),
          const Color(0xFFFFDEEB).withValues(alpha: 0.88),
          const Color(0xFFF3C7DA).withValues(alpha: 0.82),
        ],
        stops: const [0.0, 0.65, 1.0],
      ).createShader(moonBounds);
    }
    _fill.shader = _cachedMoonShader;
    canvas.drawCircle(moonCenter, moonR, _fill);
    _fill.shader = null;

    // Subtle Soft Lunar Craters / Shading
    _fill.color = const Color(0xFFE2B4C8).withValues(alpha: 0.32);
    canvas.drawCircle(moonCenter.translate(-5, -4), 5.0, _fill);
    canvas.drawCircle(moonCenter.translate(6, 3), 4.0, _fill);
    canvas.drawCircle(moonCenter.translate(1, 6), 2.8, _fill);

    // 2. Artistic Sumi-e Sakura Bough (Hanging from top-right with micro-sway)
    _drawSumiESakuraBough(canvas, size);

    // 3. 14 Drifting Sakura Petals
    for (final p in _petals) {
      final t = (progress * p.sp + p.ph) % 1.0;
      final x = (p.bx * w) + math.sin(t * 2 * math.pi + p.ph) * p.sw;
      final y = -p.sz + t * (h + p.sz * 2);
      final opacity = (math.sin(t * math.pi) * 0.85).clamp(0.0, 1.0);
      _fill.color = const Color(0xFFFF85BF).withValues(alpha: opacity * 0.90);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate((t * 2 * math.pi) + p.ph);
      // Oval petal with cleft hint
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: p.sz * 1.5,
          height: p.sz * 0.85,
        ),
        _fill,
      );
      // Delicate inner highlight
      _fill.color = const Color(0xFFFFD4E8).withValues(alpha: opacity * 0.50);
      canvas.drawOval(
        Rect.fromCenter(
          center: const Offset(-1, 0),
          width: p.sz * 0.9,
          height: p.sz * 0.45,
        ),
        _fill,
      );
      canvas.restore();
    }

    // 4. Stardust / Sparkle Puffs
    _drawSparkle(
      canvas,
      Offset(w * 0.14, h * 0.12),
      progress,
      const Color(0xFFFFD4E8),
    );
    _drawSparkle(
      canvas,
      Offset(w * 0.52, h * 0.10),
      progress + 0.35,
      const Color(0xFFFF7AA5),
    );
    _drawSparkle(
      canvas,
      Offset(w * 0.66, h * 0.22),
      progress + 0.70,
      const Color(0xFFFFD1E3),
    );
    _drawSparkle(
      canvas,
      Offset(w * 0.82, h * 0.14),
      progress + 0.20,
      const Color(0xFFFFE485),
    );
    _drawSparkle(
      canvas,
      Offset(w * 0.20, h * 0.28),
      progress + 0.50,
      const Color(0xFFFFB3D1),
    );
  }

  void _drawSumiESakuraBough(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final sway = math.sin(progress * 2 * math.pi) * 2.5;

    // 1. Sumi-e Main Trunk & Curved Boughs
    _stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Main bough from top-right corner sweeping downward
    _stroke
      ..color = const Color(0xFF260D1B).withValues(alpha: 0.90)
      ..strokeWidth = 9.0;
    final mainBranch = Path()
      ..moveTo(w * 1.05, -h * 0.02)
      ..cubicTo(
        w * 0.90,
        h * 0.08 + sway * 0.3,
        w * 0.75,
        h * 0.16 + sway * 0.7,
        w * 0.58,
        h * 0.24 + sway,
      );
    canvas.drawPath(mainBranch, _stroke);

    // Inner bark highlight
    _stroke
      ..color = const Color(0xFF451832).withValues(alpha: 0.55)
      ..strokeWidth = 3.0;
    final barkDetail = Path()
      ..moveTo(w * 1.02, -h * 0.01)
      ..cubicTo(
        w * 0.88,
        h * 0.08 + sway * 0.3,
        w * 0.74,
        h * 0.16 + sway * 0.7,
        w * 0.60,
        h * 0.23 + sway,
      );
    canvas.drawPath(barkDetail, _stroke);

    // Sub-branch A: Reaching upward toward top
    _stroke
      ..color = const Color(0xFF2E1020).withValues(alpha: 0.85)
      ..strokeWidth = 4.5;
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.86, h * 0.09 + sway * 0.3)
        ..cubicTo(
          w * 0.82,
          h * 0.04 + sway * 0.2,
          w * 0.76,
          h * 0.02 + sway * 0.1,
          w * 0.70,
          h * 0.01 + sway * 0.1,
        ),
      _stroke,
    );

    // Sub-branch B: Arching downward
    _stroke.strokeWidth = 4.0;
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.74, h * 0.16 + sway * 0.7)
        ..cubicTo(
          w * 0.72,
          h * 0.24 + sway * 0.9,
          w * 0.66,
          h * 0.29 + sway * 1.1,
          w * 0.62,
          h * 0.32 + sway * 1.2,
        ),
      _stroke,
    );

    // Sub-branch C: Reaching center-left tip
    _stroke.strokeWidth = 3.2;
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.60, h * 0.23 + sway)
        ..cubicTo(
          w * 0.52,
          h * 0.24 + sway * 1.1,
          w * 0.46,
          h * 0.27 + sway * 1.2,
          w * 0.42,
          h * 0.30 + sway * 1.3,
        ),
      _stroke,
    );

    // Sub-branch D: Minor twig
    _stroke.strokeWidth = 2.4;
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.80, h * 0.13 + sway * 0.5)
        ..cubicTo(
          w * 0.78,
          h * 0.10 + sway * 0.4,
          w * 0.75,
          h * 0.08 + sway * 0.3,
          w * 0.73,
          h * 0.07 + sway * 0.3,
        ),
      _stroke,
    );

    // 2. Sakura Blooming Flowers (5 petals with golden stamen)
    void drawFlower(Offset center, double radius, double rot) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(rot);

      // Draw 5 petals
      for (int i = 0; i < 5; i++) {
        final angle = i * (2 * math.pi / 5);
        final petalDist = radius * 0.60;
        final petalCenter = Offset(
          math.cos(angle) * petalDist,
          math.sin(angle) * petalDist,
        );

        canvas.save();
        canvas.translate(petalCenter.dx, petalCenter.dy);
        canvas.rotate(angle);

        // Petal base
        _fill.color = const Color(0xFFFF6097).withValues(alpha: 0.85);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset.zero,
            width: radius * 0.75,
            height: radius * 0.50,
          ),
          _fill,
        );

        // Petal tip highlight
        _fill.color = const Color(0xFFFFD4E8).withValues(alpha: 0.90);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(radius * 0.15, 0),
            width: radius * 0.60,
            height: radius * 0.38,
          ),
          _fill,
        );

        canvas.restore();
      }

      // Center disc
      _fill.color = const Color(0xFFFF4081).withValues(alpha: 0.90);
      canvas.drawCircle(Offset.zero, radius * 0.28, _fill);

      // Golden Stamen & Pistil
      _fill.color = const Color(0xFFFFE485);
      canvas.drawCircle(Offset.zero, radius * 0.18, _fill);

      // 5 Tiny Golden Pollen Dots
      for (int i = 0; i < 5; i++) {
        final a = i * (2 * math.pi / 5) + 0.3;
        final px = math.cos(a) * (radius * 0.26);
        final py = math.sin(a) * (radius * 0.26);
        _fill.color = const Color(0xFFFFF9C4);
        canvas.drawCircle(Offset(px, py), 1.0, _fill);
      }

      canvas.restore();
    }

    // 3. Cherry Buds
    void drawBud(Offset center, double radius, double rot) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(rot);

      // Sepal green/wine
      _fill.color = const Color(0xFF381024).withValues(alpha: 0.85);
      canvas.drawOval(
        Rect.fromCenter(
          center: const Offset(-2, 0),
          width: radius * 0.9,
          height: radius * 0.5,
        ),
        _fill,
      );

      // Rosy bud petal
      _fill.color = const Color(0xFFFF528F).withValues(alpha: 0.95);
      canvas.drawOval(
        Rect.fromCenter(
          center: const Offset(2, 0),
          width: radius * 0.85,
          height: radius * 0.55,
        ),
        _fill,
      );

      _fill.color = const Color(0xFFFFB3D1);
      canvas.drawCircle(const Offset(3, -1), radius * 0.22, _fill);

      canvas.restore();
    }

    // Place Flowers at branch nodes and clusters
    drawFlower(Offset(w * 0.86, h * 0.09 + sway * 0.3), 13.0, 0.2);
    drawFlower(Offset(w * 0.78, h * 0.14 + sway * 0.6), 14.5, 0.8);
    drawFlower(Offset(w * 0.69, h * 0.19 + sway * 0.8), 15.0, 0.4);
    drawFlower(Offset(w * 0.58, h * 0.24 + sway), 13.5, 1.2);
    drawFlower(Offset(w * 0.42, h * 0.30 + sway * 1.3), 12.0, 0.6);
    drawFlower(Offset(w * 0.70, h * 0.02 + sway * 0.1), 11.5, 1.5);
    drawFlower(Offset(w * 0.62, h * 0.32 + sway * 1.2), 12.5, 0.9);
    drawFlower(Offset(w * 0.94, h * 0.05 + sway * 0.2), 11.0, 0.1);

    // Place Buds
    drawBud(Offset(w * 0.65, h * 0.04 + sway * 0.15), 7.0, -0.4);
    drawBud(Offset(w * 0.55, h * 0.35 + sway * 1.25), 6.5, 0.8);
    drawBud(Offset(w * 0.38, h * 0.32 + sway * 1.35), 6.0, 0.3);
    drawBud(Offset(w * 0.74, h * 0.06 + sway * 0.25), 6.5, -0.2);
    drawBud(Offset(w * 0.83, h * 0.18 + sway * 0.7), 7.0, 1.1);
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
      final twinkle =
          0.25 + 0.75 * (0.5 + 0.5 * math.sin((progress + s.ph) * 2 * math.pi));
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
    const transitFraction = 0.42;
    if (tCycle > transitFraction) return;

    final p = tCycle / transitFraction;
    const angle = 36.0 * math.pi / 180.0;
    final cosA = math.cos(angle);
    final sinA = math.sin(angle);

    final totalDistance = (size.width + size.height) * 1.35;
    final startX = size.width * m.startXRatio;
    final startY = size.height * m.startYRatio;

    final headX = startX - cosA * totalDistance * p;
    final headY = startY + sinA * totalDistance * p;

    final envelope = (math.sin(p * math.pi)).clamp(0.0, 1.0);

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

    _fill.color = m.color.withValues(alpha: envelope * 0.45);
    canvas.drawCircle(Offset(headX, headY), m.headSize * 2.2, _fill);
    _fill.color = Colors.white.withValues(alpha: envelope * 0.95);
    canvas.drawCircle(Offset(headX, headY), m.headSize, _fill);
  }

  // =========================================================================
  // 3. SNOWFALL MODE: WINTER VILLAGE NIGHT & WARM CABIN GLOW (Phantek 1:1)
  // =========================================================================
  void _paintSnowfallVillage(Canvas canvas, Size size) {
    // Base Slate 900 Canvas Fill
    _fill.color = const Color(0xFF0F172A);
    canvas.drawRect(Offset.zero & size, _fill);

    // A. Distant Snow Hill (Background rolling slope)
    final backHillPath = Path();
    final backHillBaseY = size.height * 0.83;
    backHillPath.moveTo(0, backHillBaseY + 14);
    backHillPath.cubicTo(
      size.width * 0.30,
      backHillBaseY - 24,
      size.width * 0.65,
      backHillBaseY + 20,
      size.width,
      backHillBaseY - 12,
    );
    backHillPath.lineTo(size.width, size.height);
    backHillPath.lineTo(0, size.height);
    backHillPath.close();

    final backHillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF1E293B).withAlpha(120),
          const Color(0xFF0F172A).withAlpha(190),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawPath(backHillPath, backHillPaint);

    // Distant Snow Cap on back hill
    final backHillSnowPaint = Paint()
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..color = const Color(0xFF94A3B8).withAlpha(55);
    canvas.drawPath(backHillPath, backHillSnowPaint);

    // Pine trees on distant slope
    _drawSnowyPine(
      canvas,
      Offset(size.width * 0.08, backHillBaseY + 10),
      22,
      38,
    );
    _drawSnowyPine(
      canvas,
      Offset(size.width * 0.52, backHillBaseY + 16),
      24,
      40,
    );

    // B. Foreground Village Hill (Main layer)
    final hillPath = Path();
    final hillBaseY = size.height * 0.88;
    hillPath.moveTo(0, hillBaseY - 10);
    hillPath.cubicTo(
      size.width * 0.32,
      hillBaseY + 18,
      size.width * 0.68,
      hillBaseY - 28,
      size.width,
      hillBaseY + 8,
    );
    hillPath.lineTo(size.width, size.height);
    hillPath.lineTo(0, size.height);
    hillPath.close();

    final hillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF1E293B).withAlpha(220),
          const Color(0xFF0F172A).withAlpha(255),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawPath(hillPath, hillPaint);

    // Crisp Snow Ridge Crest along main hill
    final snowRidgePaint = Paint()
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..shader = LinearGradient(
        colors: [
          const Color(0xFFCFF0FF).withAlpha(90),
          const Color(0xFFBAE6FD).withAlpha(160),
          const Color(0xFFCFF0FF).withAlpha(70),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawPath(hillPath, snowRidgePaint);

    // Pine trees on foreground slope
    _drawSnowyPine(canvas, Offset(size.width * 0.38, hillBaseY + 12), 18, 30);
    _drawSnowyPine(canvas, Offset(size.width * 0.92, hillBaseY - 4), 20, 34);

    // C. Village Cabins with warm glowing windows & chimney smoke
    // Cabin 1: Left slope (cozy cottage)
    _drawSnowyCabin(
      canvas,
      Offset(size.width * 0.22, hillBaseY + 6),
      34.0,
      30.0,
      chimneyXOffset: 8,
      hasChimney: true,
    );

    // Cabin 2: Right slope (main village cabin)
    _drawSnowyCabin(
      canvas,
      Offset(size.width * 0.74, hillBaseY - 18),
      42.0,
      36.0,
      chimneyXOffset: -10,
      hasChimney: true,
    );

    // D. Falling Snowflakes in crystalline #CFF0FF
    const snowBaseColor = Color(0xFFCFF0FF);
    for (int i = 0; i < _particles.length; i++) {
      final p = _particles[i];
      final currentProgress = (p.y + progress * p.cycles) % 1.0;
      final yPos = currentProgress * size.height;

      final sway =
          math.sin(progress * 2 * math.pi * p.swayFreq + p.phase) *
          (p.swayAmplitude * 1.3);
      final xPos = (p.x * size.width + sway) % size.width;

      final edgeFade = math.sin(currentProgress * math.pi);
      final alpha = ((50 + 190 * edgeFade) * edgeFade).toInt().clamp(0, 255);

      if (p.variant == 0) {
        // Crystal cross snowflake for prominent flakes
        final rot = progress * 2 * math.pi * p.rotCycles + p.phase;
        canvas.save();
        canvas.translate(xPos, yPos);
        canvas.rotate(rot);

        final arm = p.size * 0.85;
        final flakePaint = Paint()
          ..color = snowBaseColor.withAlpha(alpha)
          ..strokeWidth = 1.1
          ..style = PaintingStyle.stroke;

        canvas.drawLine(Offset(-arm, 0), Offset(arm, 0), flakePaint);
        canvas.drawLine(Offset(0, -arm), Offset(0, arm), flakePaint);
        final diag = arm * 0.65;
        canvas.drawLine(Offset(-diag, -diag), Offset(diag, diag), flakePaint);
        canvas.drawLine(Offset(-diag, diag), Offset(diag, -diag), flakePaint);
        canvas.restore();
      } else if (p.variant == 1) {
        // Frosty soft snowflake with halo
        _fill.color = snowBaseColor.withAlpha((alpha * 0.35).toInt());
        canvas.drawCircle(Offset(xPos, yPos), p.size * 0.9, _fill);
        _fill.color = snowBaseColor.withAlpha(alpha);
        canvas.drawCircle(Offset(xPos, yPos), p.size * 0.45, _fill);
      } else {
        // Crisp snow crystal dot
        _fill.color = snowBaseColor.withAlpha(alpha);
        canvas.drawCircle(
          Offset(xPos, yPos),
          (p.size * 0.4).clamp(1.0, 2.8),
          _fill,
        );
      }
    }
  }

  void _drawSnowyPine(Canvas canvas, Offset base, double width, double height) {
    final trunkHeight = height * 0.22;
    final trunkWidth = width * 0.18;
    final trunkRect = Rect.fromCenter(
      center: Offset(base.dx, base.dy - trunkHeight / 2),
      width: trunkWidth,
      height: trunkHeight,
    );
    canvas.drawRect(trunkRect, Paint()..color = const Color(0xFF1E293B));

    for (int tier = 0; tier < 3; tier++) {
      final tierBottom = base.dy - trunkHeight * 0.8 - (tier * height * 0.26);
      final tierTop = tierBottom - height * 0.38;
      final tierW = width * (1.0 - tier * 0.25);

      final foliagePath = Path();
      foliagePath.moveTo(base.dx, tierTop);
      foliagePath.lineTo(base.dx + tierW / 2, tierBottom);
      foliagePath.lineTo(base.dx - tierW / 2, tierBottom);
      foliagePath.close();

      canvas.drawPath(
        foliagePath,
        Paint()..color = const Color(0xFF0F172A).withAlpha(240),
      );

      final snowPath = Path();
      snowPath.moveTo(base.dx - tierW / 2, tierBottom);
      snowPath.quadraticBezierTo(
        base.dx,
        tierBottom - 4,
        base.dx + tierW / 2,
        tierBottom,
      );
      canvas.drawPath(
        snowPath,
        Paint()
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke
          ..color = const Color(0xFFCFF0FF).withAlpha(180),
      );
    }
  }

  void _drawSnowyCabin(
    Canvas canvas,
    Offset base,
    double width,
    double height, {
    required double chimneyXOffset,
    required bool hasChimney,
  }) {
    final bodyHeight = height * 0.58;
    final bodyRect = Rect.fromLTWH(
      base.dx - width / 2,
      base.dy - bodyHeight,
      width,
      bodyHeight,
    );
    canvas.drawRect(bodyRect, Paint()..color = const Color(0xFF1E293B));

    // Warm golden glowing window
    final winW = width * 0.32;
    final winH = bodyHeight * 0.44;
    final winRect = Rect.fromCenter(
      center: Offset(base.dx, base.dy - bodyHeight * 0.48),
      width: winW,
      height: winH,
    );

    // Window warm ambient halo glow
    final windowGlowPulse =
        (math.sin(progress * 2 * math.pi + base.dx) + 1) / 2;
    final haloPaint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              const Color(0xFFFDE047)
                  .withAlpha((90 + 35 * windowGlowPulse).toInt()),
              const Color(0xFFFEF08A).withAlpha(25),
              Colors.transparent,
            ],
            stops: const [0.0, 0.55, 1.0],
          ).createShader(
            Rect.fromCircle(center: winRect.center, radius: winW * 1.8),
          );
    canvas.drawCircle(winRect.center, winW * 1.8, haloPaint);

    canvas.drawRRect(
      RRect.fromRectAndRadius(winRect, const Radius.circular(2)),
      Paint()..color = const Color(0xFFFDE047).withAlpha(235),
    );

    final framePaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(winRect.left, winRect.center.dy),
      Offset(winRect.right, winRect.center.dy),
      framePaint,
    );
    canvas.drawLine(
      Offset(winRect.center.dx, winRect.top),
      Offset(winRect.center.dx, winRect.bottom),
      framePaint,
    );

    // Chimney & rising smoke
    if (hasChimney) {
      final chW = width * 0.16;
      final chH = height * 0.34;
      final chX = base.dx + chimneyXOffset;
      final chY = base.dy - bodyHeight - height * 0.22;
      canvas.drawRect(
        Rect.fromLTWH(chX - chW / 2, chY, chW, chH),
        Paint()..color = const Color(0xFF0F172A),
      );

      // Chimney snow cap
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(chX - chW * 0.65, chY - 2, chW * 1.3, 3),
          const Radius.circular(1.5),
        ),
        Paint()..color = const Color(0xFFCFF0FF),
      );

      // Drifting chimney smoke puffs
      for (int s = 0; s < 4; s++) {
        final smokeProgress = (progress + s * 0.25) % 1.0;
        final smokeY = chY - smokeProgress * 42.0;
        final smokeSway =
            math.sin(smokeProgress * math.pi * 3 + s) * 6.0 +
            (smokeProgress * 7.0);
        final smokeX = chX + smokeSway;
        final smokeRadius = 2.4 + smokeProgress * 6.5;
        final smokeAlpha = ((1.0 - smokeProgress) * 75).toInt().clamp(0, 255);

        canvas.drawCircle(
          Offset(smokeX, smokeY),
          smokeRadius,
          Paint()..color = const Color(0xFFE2E8F0).withAlpha(smokeAlpha),
        );
      }
    }

    // Snow-covered gable roof
    final roofPeak = Offset(base.dx, base.dy - height);
    final roofLeft = Offset(base.dx - width * 0.64, base.dy - bodyHeight + 2);
    final roofRight = Offset(base.dx + width * 0.64, base.dy - bodyHeight + 2);

    final roofPath = Path();
    roofPath.moveTo(roofPeak.dx, roofPeak.dy);
    roofPath.lineTo(roofRight.dx, roofRight.dy);
    roofPath.lineTo(roofLeft.dx, roofLeft.dy);
    roofPath.close();
    canvas.drawPath(roofPath, Paint()..color = const Color(0xFF0F172A));

    final snowRoofPath = Path();
    snowRoofPath.moveTo(roofPeak.dx, roofPeak.dy - 3);
    snowRoofPath.lineTo(roofRight.dx + 2, roofRight.dy - 1);
    snowRoofPath.lineTo(roofRight.dx - 2, roofRight.dy + 3);
    snowRoofPath.lineTo(roofPeak.dx, roofPeak.dy + 2);
    snowRoofPath.lineTo(roofLeft.dx + 2, roofLeft.dy + 3);
    snowRoofPath.lineTo(roofLeft.dx - 2, roofLeft.dy - 1);
    snowRoofPath.close();

    canvas.drawPath(
      snowRoofPath,
      Paint()..color = const Color(0xFFCFF0FF).withAlpha(240),
    );
  }

  // =========================================================================
  // 4. LIGHT MODE: WARM SUNBEAMS & FRESH DAYLIGHT BREEZE (Phantek 1:1)
  // =========================================================================
  void _paintLightDaylight(Canvas canvas, Size size) {
    // Base Slate 50 Sky Canvas Fill
    _fill.color = const Color(0xFFF8FAFC);
    canvas.drawRect(Offset.zero & size, _fill);

    // A. Warm Sunlight Flare in top right corner
    final sunCenter = Offset(size.width * 0.92, -10.0);
    final sunPulse = (math.sin(progress * 2 * math.pi) + 1) / 2;
    final sunRadius = size.width * 0.6;

    final sunGlowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFF59E0B).withAlpha((36 + 12 * sunPulse).toInt()),
          const Color(0xFFFBBF24).withAlpha(16),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(center: sunCenter, radius: sunRadius));
    canvas.drawCircle(sunCenter, sunRadius, sunGlowPaint);

    // B. Upward drifting sunlight motes & warm breeze particles
    for (int i = 0; i < _particles.length; i++) {
      final p = _particles[i];
      final currentProgress = (1.0 - (p.y + progress * p.cycles) % 1.0);
      final yPos = currentProgress * size.height;

      final sway =
          math.sin(progress * 2 * math.pi * p.swayFreq + p.phase) *
          (p.swayAmplitude * 0.85);
      final xPos = (p.x * size.width + sway) % size.width;

      final edgeFade = math.sin(currentProgress * math.pi);
      final alpha = ((20 + 55 * math.sin(p.phase).abs()) * edgeFade)
          .toInt()
          .clamp(0, 255);

      final color = p.variant == 0
          ? const Color(0xFFF59E0B) // Amber sunlight
          : (p.variant == 1
                ? const Color(0xFF0284C7) // Sky azure
                : (p.variant == 2
                      ? const Color(0xFFFBBF24) // Gold solar mote
                      : const Color(0xFF38BDF8))); // Light sky

      _fill.color = color.withAlpha(alpha);
      canvas.drawCircle(Offset(xPos, yPos), p.size * 1.3, _fill);
    }
  }

  void _drawSparkle(Canvas canvas, Offset center, double phase, Color color) {
    final arm = 2.0 + 1.5 * (0.5 + 0.5 * math.sin(phase * 2 * math.pi));
    _sparkle.color = color;
    canvas.drawLine(
      Offset(center.dx - arm, center.dy),
      Offset(center.dx + arm, center.dy),
      _sparkle,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - arm),
      Offset(center.dx, center.dy + arm),
      _sparkle,
    );
  }

  @override
  bool shouldRepaint(covariant _FullAppBgPainter old) {
    if (old.themeMode != themeMode) return true;
    // Quantize progress to ~60 FPS steps (720 steps over 12-second cycle).
    // On 120Hz displays, skips 50% of redundant frames while maintaining silky smooth 60 FPS motion.
    final oldStep = (old.progress * 720).floor();
    final newStep = (progress * 720).floor();
    return oldStep != newStep;
  }
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
  const _PC({
    required this.bx,
    required this.sp,
    required this.sw,
    required this.sz,
    required this.ph,
  });
}

class _SC {
  final double x;
  final double y;
  final double sz;
  final double ph;
  final bool sp;
  final Color cl;
  const _SC({
    required this.x,
    required this.y,
    required this.sz,
    required this.ph,
    this.sp = false,
    this.cl = const Color(0xFF00E5FF),
  });
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

class _BackgroundParticle {
  final double x;
  final double y;
  final double size;
  final int cycles;
  final int swayFreq;
  final double swayAmplitude;
  final int rotCycles;
  final double phase;
  final int twinkleFreq;
  final int variant;

  const _BackgroundParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.cycles,
    required this.swayFreq,
    required this.swayAmplitude,
    required this.rotCycles,
    required this.phase,
    required this.twinkleFreq,
    required this.variant,
  });
}

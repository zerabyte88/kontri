import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
      duration: const Duration(seconds: 8),
    );
    if (!HeaderAnimationState.isPausedNotifier.value) {
      _controller.repeat();
    }

    HeaderAnimationState.isPausedNotifier.addListener(_onPauseStateChanged);
  }

  int _activeScrollCount = 0;

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollStartNotification) {
      _activeScrollCount++;
      if (_controller.isAnimating) {
        _controller.stop();
      }
    } else if (notification is ScrollUpdateNotification) {
      if (notification.scrollDelta != null && notification.scrollDelta! != 0) {
        if (_controller.isAnimating) {
          _controller.stop();
        }
      }
    } else if (notification is ScrollEndNotification) {
      if (_activeScrollCount > 0) _activeScrollCount--;
      if (_activeScrollCount == 0 &&
          !HeaderAnimationState.isPausedNotifier.value &&
          !_controller.isAnimating) {
        _controller.repeat();
      }
    } else if (notification is UserScrollNotification &&
        notification.direction == ScrollDirection.idle) {
      if (!HeaderAnimationState.isPausedNotifier.value && !_controller.isAnimating) {
        _controller.repeat();
      }
    }
    return false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      if (_controller.isAnimating) _controller.stop();
    } else if (state == AppLifecycleState.resumed) {
      if (!HeaderAnimationState.isPausedNotifier.value && !_controller.isAnimating) {
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
            NotificationListener<ScrollNotification>(
              onNotification: _onScrollNotification,
              child: widget.child,
            ),
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
  static Size? _cachedMidnightSize;
  static Shader? _cachedMidnightBgShader;
  static Size? _cachedLightSize;
  static Shader? _cachedLightBgShader;

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

  // Micro-stars & Cosmic Stardust (Midnight Aurora)
  static const List<_SC> _auroraStars = [
    _SC(x: 0.05, y: 0.05, sz: 1.4, ph: 0.10, cl: Color(0xFF00E5FF)),
    _SC(x: 0.12, y: 0.15, sz: 1.0, ph: 0.45, cl: Color(0xFFE0F7FA)),
    _SC(x: 0.20, y: 0.08, sz: 1.6, ph: 0.25, sp: true, cl: Color(0xFF8B5CF6)),
    _SC(x: 0.28, y: 0.22, sz: 0.9, ph: 0.80, cl: Color(0xFF10B981)),
    _SC(x: 0.36, y: 0.12, sz: 1.2, ph: 0.35, cl: Color(0xFF00E5FF)),
    _SC(x: 0.44, y: 0.28, sz: 1.5, ph: 0.65, sp: true, cl: Color(0xFFE0F7FA)),
    _SC(x: 0.52, y: 0.06, sz: 1.1, ph: 0.15, cl: Color(0xFF10B981)),
    _SC(x: 0.60, y: 0.18, sz: 1.4, ph: 0.90, cl: Color(0xFF8B5CF6)),
    _SC(x: 0.68, y: 0.09, sz: 1.8, ph: 0.40, sp: true, cl: Color(0xFF00E5FF)),
    _SC(x: 0.76, y: 0.24, sz: 1.0, ph: 0.70, cl: Color(0xFFE0F7FA)),
    _SC(x: 0.84, y: 0.14, sz: 1.3, ph: 0.30, cl: Color(0xFF10B981)),
    _SC(x: 0.92, y: 0.07, sz: 1.6, ph: 0.85, sp: true, cl: Color(0xFF8B5CF6)),
    _SC(x: 0.16, y: 0.38, sz: 0.8, ph: 0.55, cl: Color(0xFF00E5FF)),
    _SC(x: 0.38, y: 0.42, sz: 1.0, ph: 0.20, cl: Color(0xFFE0F7FA)),
    _SC(x: 0.58, y: 0.36, sz: 0.9, ph: 0.75, cl: Color(0xFF10B981)),
    _SC(x: 0.72, y: 0.45, sz: 1.2, ph: 0.12, cl: Color(0xFF8B5CF6)),
    _SC(x: 0.86, y: 0.34, sz: 1.0, ph: 0.62, cl: Color(0xFF00E5FF)),
    _SC(x: 0.95, y: 0.25, sz: 1.3, ph: 0.48, cl: Color(0xFFE0F7FA)),
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

  // 16 Continuous Floating Stardust & Cyber Embers (Dark Theme)
  static const List<_DarkParticle> _darkParticles = [
    _DarkParticle(bx: 0.07, sp: 1, sw: 12.0, sz: 1.8, ph: 0.05, cl: Color(0xFF00E5FF)),
    _DarkParticle(bx: 0.15, sp: 2, sw: 16.0, sz: 2.2, ph: 0.18, cl: Color(0xFF8B5CF6)),
    _DarkParticle(bx: 0.23, sp: 1, sw: 10.0, sz: 1.5, ph: 0.32, cl: Color(0xFF10B981)),
    _DarkParticle(bx: 0.31, sp: 2, sw: 18.0, sz: 2.4, ph: 0.48, cl: Color(0xFF00E5FF)),
    _DarkParticle(bx: 0.40, sp: 1, sw: 14.0, sz: 1.6, ph: 0.62, cl: Color(0xFFE0F7FA)),
    _DarkParticle(bx: 0.48, sp: 2, sw: 15.0, sz: 2.0, ph: 0.75, cl: Color(0xFF8B5CF6)),
    _DarkParticle(bx: 0.57, sp: 1, sw: 11.0, sz: 1.4, ph: 0.88, cl: Color(0xFF10B981)),
    _DarkParticle(bx: 0.65, sp: 2, sw: 17.0, sz: 2.5, ph: 0.12, cl: Color(0xFF00E5FF)),
    _DarkParticle(bx: 0.73, sp: 1, sw: 13.0, sz: 1.7, ph: 0.28, cl: Color(0xFF8B5CF6)),
    _DarkParticle(bx: 0.81, sp: 2, sw: 16.0, sz: 2.1, ph: 0.42, cl: Color(0xFF10B981)),
    _DarkParticle(bx: 0.89, sp: 1, sw: 12.0, sz: 1.5, ph: 0.58, cl: Color(0xFF00E5FF)),
    _DarkParticle(bx: 0.95, sp: 2, sw: 15.0, sz: 2.3, ph: 0.72, cl: Color(0xFFE0F7FA)),
    _DarkParticle(bx: 0.12, sp: 1, sw: 14.0, sz: 1.6, ph: 0.85, cl: Color(0xFF8B5CF6)),
    _DarkParticle(bx: 0.35, sp: 2, sw: 19.0, sz: 2.6, ph: 0.02, cl: Color(0xFF00E5FF)),
    _DarkParticle(bx: 0.61, sp: 1, sw: 13.0, sz: 1.8, ph: 0.38, cl: Color(0xFF10B981)),
    _DarkParticle(bx: 0.84, sp: 2, sw: 17.0, sz: 2.2, ph: 0.68, cl: Color(0xFF8B5CF6)),
  ];

  // 12 Drifting Prismatic Daylight Motes (Light theme)
  static const List<_LC> _leaves = [
    _LC(bx: 0.08, sp: 1, sw: 14.0, sz: 5.5, ph: 0.05, cl: Color(0xFF38BDF8)),
    _LC(bx: 0.18, sp: 2, sw: 16.0, sz: 6.8, ph: 0.22, cl: Color(0xFF34D399)),
    _LC(bx: 0.28, sp: 1, sw: 12.0, sz: 5.0, ph: 0.40, cl: Color(0xFFFBBF24)),
    _LC(bx: 0.38, sp: 2, sw: 18.0, sz: 6.5, ph: 0.58, cl: Color(0xFF38BDF8)),
    _LC(bx: 0.48, sp: 1, sw: 13.0, sz: 5.8, ph: 0.76, cl: Color(0xFF34D399)),
    _LC(bx: 0.57, sp: 2, sw: 15.0, sz: 6.2, ph: 0.94, cl: Color(0xFF818CF8)),
    _LC(bx: 0.66, sp: 1, sw: 11.0, sz: 5.2, ph: 0.12, cl: Color(0xFF38BDF8)),
    _LC(bx: 0.75, sp: 2, sw: 17.0, sz: 6.6, ph: 0.30, cl: Color(0xFF34D399)),
    _LC(bx: 0.83, sp: 1, sw: 14.0, sz: 5.6, ph: 0.48, cl: Color(0xFFFBBF24)),
    _LC(bx: 0.90, sp: 2, sw: 16.0, sz: 6.4, ph: 0.66, cl: Color(0xFF38BDF8)),
    _LC(bx: 0.96, sp: 1, sw: 13.0, sz: 5.4, ph: 0.84, cl: Color(0xFF34D399)),
    _LC(bx: 0.22, sp: 2, sw: 19.0, sz: 7.0, ph: 0.02, cl: Color(0xFF818CF8)),
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
        _drawMidnightAurora(canvas, size);
      case AppThemeMode.light:
        _drawLightTheme(canvas, size);
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
    _fill.shader = RadialGradient(
      center: const Alignment(-0.25, -0.25),
      radius: 0.9,
      colors: [
        const Color(0xFFFFF0F5).withValues(alpha: 0.92),
        const Color(0xFFFFDEEB).withValues(alpha: 0.88),
        const Color(0xFFF3C7DA).withValues(alpha: 0.82),
      ],
      stops: const [0.0, 0.65, 1.0],
    ).createShader(moonBounds);
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
        Rect.fromCenter(center: Offset.zero, width: p.sz * 1.5, height: p.sz * 0.85),
        _fill,
      );
      // Delicate inner highlight
      _fill.color = const Color(0xFFFFD4E8).withValues(alpha: opacity * 0.50);
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(-1, 0), width: p.sz * 0.9, height: p.sz * 0.45),
        _fill,
      );
      canvas.restore();
    }

    // 4. Stardust / Sparkle Puffs
    _drawSparkle(canvas, Offset(w * 0.14, h * 0.12), progress, const Color(0xFFFFD4E8));
    _drawSparkle(canvas, Offset(w * 0.52, h * 0.10), progress + 0.35, const Color(0xFFFF7AA5));
    _drawSparkle(canvas, Offset(w * 0.66, h * 0.22), progress + 0.70, const Color(0xFFFFD1E3));
    _drawSparkle(canvas, Offset(w * 0.82, h * 0.14), progress + 0.20, const Color(0xFFFFE485));
    _drawSparkle(canvas, Offset(w * 0.20, h * 0.28), progress + 0.50, const Color(0xFFFFB3D1));
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
        final petalCenter = Offset(math.cos(angle) * petalDist, math.sin(angle) * petalDist);

        canvas.save();
        canvas.translate(petalCenter.dx, petalCenter.dy);
        canvas.rotate(angle);

        // Petal base
        _fill.color = const Color(0xFFFF6097).withValues(alpha: 0.85);
        canvas.drawOval(
          Rect.fromCenter(center: Offset.zero, width: radius * 0.75, height: radius * 0.50),
          _fill,
        );

        // Petal tip highlight
        _fill.color = const Color(0xFFFFD4E8).withValues(alpha: 0.90);
        canvas.drawOval(
          Rect.fromCenter(center: Offset(radius * 0.15, 0), width: radius * 0.60, height: radius * 0.38),
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
        Rect.fromCenter(center: const Offset(-2, 0), width: radius * 0.9, height: radius * 0.5),
        _fill,
      );

      // Rosy bud petal
      _fill.color = const Color(0xFFFF528F).withValues(alpha: 0.95);
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(2, 0), width: radius * 0.85, height: radius * 0.55),
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

  // ---------------------------------------------------------------------------
  // 3. DARK THEME (Midnight Cyber Aurora - Continuous & Seamless Looping)
  // ---------------------------------------------------------------------------
  void _drawMidnightAurora(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Deep Midnight Slate Canvas
    final bgRect = Offset.zero & size;
    if (_cachedMidnightSize != size || _cachedMidnightBgShader == null) {
      _cachedMidnightSize = size;
      _cachedMidnightBgShader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0B0E14), Color(0xFF111622)],
      ).createShader(bgRect);
    }
    _fill.shader = _cachedMidnightBgShader;
    canvas.drawRect(bgRect, _fill);
    _fill.shader = null;

    // Micro Cosmic Stars
    for (final s in _auroraStars) {
      final pos = Offset(s.x * w, s.y * h);
      final twinkle = 0.30 + 0.70 * (0.5 + 0.5 * math.sin((progress + s.ph) * 2 * math.pi));
      final alpha = (twinkle * 0.85).clamp(0.0, 1.0);
      final starColor = s.cl.withValues(alpha: alpha);
      if (s.sp) _drawSparkle(canvas, pos, (progress + s.ph) % 1.0, starColor);
      _fill.color = starColor;
      canvas.drawCircle(pos, s.sz * (0.75 + 0.25 * twinkle), _fill);
    }

    // Continuous Flowing Ambient Cyber Stardust Stream (Seamless loop)
    for (final p in _darkParticles) {
      final t = (progress * p.sp + p.ph) % 1.0;
      final x = (p.bx * w) + math.sin(t * 2 * math.pi + p.ph) * p.sw;
      // Drifts upward smoothly across full height
      final y = (1.0 - t) * (h + 30) - 15;
      final alpha = (math.sin(t * math.pi) * 0.85).clamp(0.0, 1.0);
      final pColor = p.cl.withValues(alpha: alpha);

      // Core particle
      _fill.color = pColor;
      canvas.drawCircle(Offset(x, y), p.sz, _fill);

      // Soft aura glow
      _glow.color = p.cl.withValues(alpha: alpha * 0.25);
      canvas.drawCircle(Offset(x, y), p.sz * 2.4, _glow);
    }

    // Ethereal Horizon Nebula Glow (Smooth continuous integer sine breathing)
    final nebulaPulse = 0.85 + 0.15 * math.sin(progress * 2 * math.pi);
    _glow.color = const Color(0xFF00E5FF).withValues(alpha: 0.05 * nebulaPulse);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.5, h * 0.22), width: w * 1.2, height: h * 0.35),
      _glow,
    );

    // 3 Undulating Aurora Curtains (Integer speeds for 100% loop continuity)
    // Curtain 1: Electric Cyan (Upper Horizon)
    _drawAuroraCurtain(canvas, size, 0.07, 0.20, const Color(0xFF00E5FF), 1, 0.0);

    // Curtain 2: Emerald Green (Mid Horizon)
    _drawAuroraCurtain(canvas, size, 0.13, 0.22, const Color(0xFF10B981), 1, 0.33);

    // Curtain 3: Nebula Violet (Lower Horizon Depth)
    _drawAuroraCurtain(canvas, size, 0.19, 0.24, const Color(0xFF8B5CF6), 1, 0.66);
  }

  void _drawAuroraCurtain(
    Canvas canvas,
    Size size,
    double baseYRatio,
    double heightRatio,
    Color peakColor,
    int speedMult,
    double phaseOffset,
  ) {
    final w = size.width;
    final h = size.height;
    final baseY = h * baseYRatio;
    final ribbonH = h * heightRatio;
    // Exactly 2*pi periodic over progress in [0, 1]
    final t = (progress * speedMult + phaseOffset) * 2 * math.pi;

    const segments = 16;
    final dx = w / segments;

    final curtainPath = Path();
    for (int i = 0; i <= segments; i++) {
      final x = i * dx;
      final normX = i / segments;
      // All harmonics use exact integer multiples of t so f(0) == f(1) exactly
      final wave1 = math.sin(normX * 3.0 * math.pi + t) * (h * 0.035);
      final wave2 = math.cos(normX * 2.0 * math.pi - t) * (h * 0.020);
      final yTop = baseY + wave1 + wave2;
      if (i == 0) {
        curtainPath.moveTo(x, yTop);
      } else {
        curtainPath.lineTo(x, yTop);
      }
    }
    for (int i = segments; i >= 0; i--) {
      final x = i * dx;
      final normX = i / segments;
      final wave1 = math.sin(normX * 3.0 * math.pi + t) * (h * 0.035);
      final wave2 = math.cos(normX * 2.0 * math.pi - t) * (h * 0.020);
      final yTop = baseY + wave1 + wave2;
      final yBot = yTop + ribbonH + (math.sin(normX * 2.0 * math.pi + t) * (h * 0.015));
      curtainPath.lineTo(x, yBot);
    }
    curtainPath.close();

    final bounds = Rect.fromLTWH(0, baseY - h * 0.06, w, ribbonH + h * 0.12);
    _fill.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        peakColor.withValues(alpha: 0.0),
        peakColor.withValues(alpha: 0.22),
        peakColor.withValues(alpha: 0.28),
        peakColor.withValues(alpha: 0.0),
      ],
      stops: const [0.0, 0.35, 0.65, 1.0],
    ).createShader(bounds);

    canvas.drawPath(curtainPath, _fill);
    _fill.shader = null;
  }

  // ---------------------------------------------------------------------------
  // 4. LIGHT THEME (Solar Horizon & Minimalist Prismatic Breeze)
  // ---------------------------------------------------------------------------
  void _drawLightTheme(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Pristine Dawn Ceramic Sky Canvas
    final bgRect = Offset.zero & size;
    if (_cachedLightSize != size || _cachedLightBgShader == null) {
      _cachedLightSize = size;
      _cachedLightBgShader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFBFDFF), Color(0xFFF3F7FA), Color(0xFFE5EDF4)],
        stops: [0.0, 0.45, 1.0],
      ).createShader(bgRect);
    }
    _fill.shader = _cachedLightBgShader;
    canvas.drawRect(bgRect, _fill);
    _fill.shader = null;

    // 2. Soft Morning Sun Radial Ambient Bloom (Top-Left)
    final sunCenter = Offset(w * 0.22, h * 0.12);
    final sunBreathe = 0.85 + 0.15 * math.sin(progress * 2 * math.pi);
    _glow.color = const Color(0xFFFEF08A).withValues(alpha: 0.09 * sunBreathe);
    canvas.drawCircle(sunCenter, w * 0.40, _glow);
    _glow.color = const Color(0xFFBAE6FD).withValues(alpha: 0.06 * sunBreathe);
    canvas.drawCircle(sunCenter, w * 0.25, _glow);

    // 3. Elegant Flowing Horizon Ribbons (Minimalist Topographic Wave Flow)
    // Ribbon 1: Sky Azure (Base wave)
    _drawHorizonRibbon(canvas, size, 0.76, 0.14, const Color(0xFF0284C7), 0.0);
    // Ribbon 2: Mint Emerald (Mid harmonic wave)
    _drawHorizonRibbon(canvas, size, 0.82, 0.12, const Color(0xFF059669), 0.33);
    // Ribbon 3: Warm Solar Iris (Deep depth wave)
    _drawHorizonRibbon(canvas, size, 0.88, 0.10, const Color(0xFFD97706), 0.66);

    // 4. Subtle Komorebi Sunlight Caustic Beams
    _drawKomorebiSunbeams(canvas, size);

    // 5. 12 Drifting Prismatic Daylight Motes (Smooth sinusoidal sway & wrap)
    for (final l in _leaves) {
      final t = (progress * l.sp + l.ph) % 1.0;
      final x = (l.bx * w) + math.sin(t * 2 * math.pi + l.ph) * l.sw;
      final y = -l.sz + t * (h + l.sz * 2);
      final alpha = (math.sin(t * math.pi) * 0.75).clamp(0.0, 1.0);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate((t * 2 * math.pi) + l.ph);

      // Translucent droplet mote
      _fill.color = l.cl.withValues(alpha: alpha * 0.65);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: l.sz * 1.6, height: l.sz * 0.75),
        _fill,
      );

      // Delicate pristine core glint
      _fill.color = Colors.white.withValues(alpha: alpha * 0.90);
      canvas.drawCircle(Offset(-l.sz * 0.2, -l.sz * 0.1), l.sz * 0.22, _fill);

      canvas.restore();
    }

    // 6. Crisp Solar Sparkles
    _drawSparkle(canvas, Offset(w * 0.18, h * 0.16), progress, const Color(0xFF0284C7));
    _drawSparkle(canvas, Offset(w * 0.68, h * 0.14), progress + 0.33, const Color(0xFF059669));
    _drawSparkle(canvas, Offset(w * 0.44, h * 0.24), progress + 0.66, const Color(0xFFD97706));
    _drawSparkle(canvas, Offset(w * 0.82, h * 0.32), progress + 0.50, const Color(0xFF38BDF8));
  }

  void _drawHorizonRibbon(
    Canvas canvas,
    Size size,
    double baseYRatio,
    double ribbonHRatio,
    Color ribbonColor,
    double phaseOffset,
  ) {
    final w = size.width;
    final h = size.height;
    final baseY = h * baseYRatio;
    final ribbonH = h * ribbonHRatio;
    // Exactly 2*pi periodic over progress in [0, 1]
    final t = (progress + phaseOffset) * 2 * math.pi;

    const segments = 14;
    final dx = w / segments;

    final ribbonPath = Path()..moveTo(0, h);
    for (int i = 0; i <= segments; i++) {
      final x = i * dx;
      final normX = i / segments;
      final wave1 = math.sin(normX * 2.0 * math.pi + t) * (h * 0.022);
      final wave2 = math.cos(normX * 1.0 * math.pi - t) * (h * 0.012);
      ribbonPath.lineTo(x, baseY + wave1 + wave2);
    }
    ribbonPath.lineTo(w, h);
    ribbonPath.close();

    final bounds = Rect.fromLTWH(0, baseY - h * 0.04, w, ribbonH + h * 0.08);
    _fill.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        ribbonColor.withValues(alpha: 0.07),
        ribbonColor.withValues(alpha: 0.03),
        ribbonColor.withValues(alpha: 0.0),
      ],
      stops: const [0.0, 0.60, 1.0],
    ).createShader(bounds);

    canvas.drawPath(ribbonPath, _fill);
    _fill.shader = null;
  }

  void _drawKomorebiSunbeams(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final breathe = 0.03 + 0.015 * math.sin(progress * 2 * math.pi);

    void drawBeam(double startX, double startW, double endX, double endW, double alphaMult) {
      final beamPath = Path()
        ..moveTo(startX, 0)
        ..lineTo(startX + startW, 0)
        ..lineTo(endX + endW, h * 0.75)
        ..lineTo(endX, h * 0.75)
        ..close();

      final bounds = Rect.fromLTWH(
        math.min(startX, endX),
        0,
        math.max(startX + startW, endX + endW) - math.min(startX, endX),
        h * 0.75,
      );

      _fill.shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFFFFFBEB).withValues(alpha: breathe * alphaMult * 1.2),
          const Color(0xFFE0F2FE).withValues(alpha: breathe * alphaMult * 0.6),
          Colors.transparent,
        ],
        stops: const [0.0, 0.40, 1.0],
      ).createShader(bounds);

      canvas.drawPath(beamPath, _fill);
      _fill.shader = null;
    }

    // 3 Distinct Komorebi Light Shafts
    drawBeam(-w * 0.05, w * 0.18, w * 0.22, w * 0.42, 1.0);
    drawBeam(w * 0.15, w * 0.16, w * 0.50, w * 0.38, 0.80);
    drawBeam(w * 0.35, w * 0.14, w * 0.76, w * 0.32, 0.65);
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

class _LC {
  final double bx;
  final int sp;
  final double sw;
  final double sz;
  final double ph;
  final Color cl;
  const _LC({required this.bx, required this.sp, required this.sw, required this.sz, required this.ph, required this.cl});
}

class _DarkParticle {
  final double bx;
  final int sp;
  final double sw;
  final double sz;
  final double ph;
  final Color cl;
  const _DarkParticle({
    required this.bx,
    required this.sp,
    required this.sw,
    required this.sz,
    required this.ph,
    required this.cl,
  });
}

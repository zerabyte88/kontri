import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/app_theme_service.dart';
import '../theme/app_theme.dart';

/// Interactive, theme-adaptive animated header widget for GitPulse.
///
/// Dynamically animates the application name and logo at the top-left based on
/// the currently active [AppThemeMode]:
/// - [AppThemeMode.amoledJapanese]: Floating sakura cherry blossom petals & pink glow.
/// - [AppThemeMode.amoled]: Crescent moon halo & twinkling cosmic stardust.
/// - [AppThemeMode.dark]: Concentric expanding water ripples & rising aquatic bubbles.
/// - [AppThemeMode.light]: Gentle breeze with fluttering, falling autumn & green leaves.
class AnimatedAppHeader extends StatefulWidget {
  final VoidCallback? onTap;

  const AnimatedAppHeader({super.key, this.onTap});

  @override
  State<AnimatedAppHeader> createState() => _AnimatedAppHeaderState();
}

class _AnimatedAppHeaderState extends State<AnimatedAppHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  double _burstProgress = 1.0;
  DateTime _lastTapTime = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    final now = DateTime.now();
    if (now.difference(_lastTapTime).inMilliseconds > 400) {
      _lastTapTime = now;
      setState(() {
        _burstProgress = 0.0;
      });
    }
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeMode>(
      valueListenable: AppThemeService.currentThemeNotifier,
      builder: (context, currentTheme, _) {
        final accentColor = _getThemeAccentColor(currentTheme);

        return GestureDetector(
          onTap: _handleTap,
          behavior: HitTestBehavior.opaque,
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final t = _controller.value;
                if (_burstProgress < 1.0) {
                  _burstProgress = math.min(1.0, _burstProgress + 0.04);
                }

                return SizedBox(
                  height: 40,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.centerLeft,
                    children: [
                      // Background theme particle layer
                      Positioned(
                        left: -12,
                        top: -12,
                        right: -16,
                        bottom: -12,
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: _HeaderThemeParticlesPainter(
                              progress: t,
                              burstProgress: _burstProgress,
                              themeMode: currentTheme,
                              accentColor: accentColor,
                            ),
                          ),
                        ),
                      ),

                      // Core Header: Logo Box + App Title + Version Badge
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildLogoContainer(currentTheme, accentColor, t),
                          const SizedBox(width: 9),
                          _buildAnimatedTitle(currentTheme, accentColor, t),
                          const SizedBox(width: 8),
                          _buildVersionBadge(accentColor),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogoContainer(
    AppThemeMode mode,
    Color accentColor,
    double progress,
  ) {
    // Subtle pulsating glow based on active theme
    final pulse = 0.5 + 0.5 * math.sin(progress * 2 * math.pi);
    final glowAlpha = (0.12 + 0.16 * pulse).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.5 + 0.4 * pulse),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: glowAlpha),
            blurRadius: 8 + 4 * pulse,
            spreadRadius: 0.5,
          ),
        ],
      ),
      child: Icon(
        Icons.terminal_rounded,
        color: accentColor,
        size: 18,
      ),
    );
  }

  Widget _buildAnimatedTitle(
    AppThemeMode mode,
    Color accentColor,
    double progress,
  ) {
    // Shimmer gradient highlights based on theme
    final cycle = (progress * 2) % 1.0;
    final gradientColors = _getTitleGradient(mode, accentColor, cycle);

    return ShaderMask(
      shaderCallback: (bounds) {
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
          stops: const [0.0, 0.5, 1.0],
        ).createShader(bounds);
      },
      child: const Text(
        'GitPulse',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 17.5,
          letterSpacing: -0.3,
        ),
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

  Color _getThemeAccentColor(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.amoledJapanese:
        return const Color(0xFFFF5C8A);
      case AppThemeMode.amoled:
        return const Color(0xFF00E5FF);
      case AppThemeMode.light:
        return const Color(0xFF0969DA);
      case AppThemeMode.dark:
        return const Color(0xFF58A6FF);
    }
  }

  List<Color> _getTitleGradient(
    AppThemeMode mode,
    Color accentColor,
    double cycle,
  ) {
    switch (mode) {
      case AppThemeMode.amoledJapanese:
        return [
          Colors.white,
          Color.lerp(const Color(0xFFFFB6C1), const Color(0xFFFF5C8A), cycle)!,
          Colors.white,
        ];
      case AppThemeMode.amoled:
        return [
          Colors.white,
          Color.lerp(const Color(0xFF80DEEA), const Color(0xFF00E5FF), cycle)!,
          Colors.white,
        ];
      case AppThemeMode.light:
        return [
          const Color(0xFF1F2328),
          Color.lerp(const Color(0xFF0969DA), const Color(0xFF1F2328), cycle)!,
          const Color(0xFF1F2328),
        ];
      case AppThemeMode.dark:
        return [
          const Color(0xFFF0F6FC),
          Color.lerp(const Color(0xFF79C0FF), const Color(0xFF58A6FF), cycle)!,
          const Color(0xFFF0F6FC),
        ];
    }
  }
}

/// GPU-accelerated lightweight Canvas painter for theme-tailored ambient particle effects.
class _HeaderThemeParticlesPainter extends CustomPainter {
  final double progress;
  final double burstProgress;
  final AppThemeMode themeMode;
  final Color accentColor;

  _HeaderThemeParticlesPainter({
    required this.progress,
    required this.burstProgress,
    required this.themeMode,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    switch (themeMode) {
      case AppThemeMode.amoledJapanese:
        _drawSakuraEffect(canvas, size);
        break;
      case AppThemeMode.amoled:
        _drawMoonAndStarsEffect(canvas, size);
        break;
      case AppThemeMode.dark:
        _drawWaterRipplesAndBubbles(canvas, size);
        break;
      case AppThemeMode.light:
        _drawFallingLeavesEffect(canvas, size);
        break;
    }
  }

  // ==========================================
  // 1. SAKURA CHERRY BLOSSOM PETALS EFFECT
  // ==========================================
  void _drawSakuraEffect(Canvas canvas, Size size) {
    final petalPaint = Paint()..style = PaintingStyle.fill;

    // Fixed particle anchors with deterministic continuous offsets
    const petals = [
      _ParticleConfig(baseX: 0.15, speed: 0.8, sway: 14.0, size: 7.0, phase: 0.1),
      _ParticleConfig(baseX: 0.38, speed: 1.1, sway: 18.0, size: 8.5, phase: 0.4),
      _ParticleConfig(baseX: 0.62, speed: 0.7, sway: 12.0, size: 6.5, phase: 0.7),
      _ParticleConfig(baseX: 0.82, speed: 0.95, sway: 16.0, size: 7.5, phase: 0.25),
      _ParticleConfig(baseX: 0.48, speed: 1.3, sway: 20.0, size: 9.0, phase: 0.85),
    ];

    for (final p in petals) {
      final t = (progress * p.speed + p.phase) % 1.0;
      final x = (p.baseX * size.width) + math.sin(t * 2 * math.pi + p.phase) * p.sway;
      final y = t * size.height;
      final opacity = (math.sin(t * math.pi) * 0.85).clamp(0.0, 1.0);
      final rotation = (t * 2 * math.pi) + p.phase;

      petalPaint.color = const Color(0xFFFF85A2).withValues(alpha: opacity);
      _drawSinglePetal(canvas, Offset(x, y), p.size, rotation, petalPaint);
    }

    // Interactive Tap Burst Petals
    if (burstProgress < 1.0) {
      final burstAlpha = (1.0 - burstProgress) * 0.9;
      petalPaint.color = const Color(0xFFFF5C8A).withValues(alpha: burstAlpha);
      for (int i = 0; i < 6; i++) {
        final angle = (i * math.pi / 3) + (burstProgress * 0.5);
        final dist = 10.0 + burstProgress * 32.0;
        final bx = 22.0 + math.cos(angle) * dist;
        final by = 20.0 + math.sin(angle) * dist;
        _drawSinglePetal(canvas, Offset(bx, by), 6.5, angle, petalPaint);
      }
    }

    // Twinkling sparkle star near the title
    _drawSparkle(canvas, Offset(size.width * 0.72, size.height * 0.22), progress, const Color(0xFFFFD1DC));
  }

  void _drawSinglePetal(
    Canvas canvas,
    Offset center,
    double radius,
    double rotation,
    Paint paint,
  ) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    final path = Path()
      ..moveTo(0, -radius)
      ..cubicTo(radius * 0.75, -radius * 0.6, radius, radius * 0.4, 0, radius)
      ..cubicTo(-radius, radius * 0.4, -radius * 0.75, -radius * 0.6, 0, -radius)
      ..close();

    canvas.drawPath(path, paint);
    canvas.restore();
  }

  // ==========================================
  // 2. AMOLED LUNAR MOON & TWINKLING STARS
  // ==========================================
  void _drawMoonAndStarsEffect(Canvas canvas, Size size) {
    // 1. Miniature Glowing Crescent Moon floating over the top-right of the logo
    final moonCenter = Offset(size.width * 0.68, size.height * 0.24);
    final moonRadius = 6.0;
    final pulse = 0.7 + 0.3 * math.sin(progress * 2 * math.pi);

    final moonGlowPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.25 * pulse)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawCircle(moonCenter, moonRadius + 2, moonGlowPaint);

    final moonPaint = Paint()
      ..color = const Color(0xFFE0F7FA).withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;

    // Draw clean crescent moon using clip path subtraction
    canvas.save();
    final moonPath = Path()
      ..addOval(Rect.fromCircle(center: moonCenter, radius: moonRadius));
    final cutoutPath = Path()
      ..addOval(Rect.fromCircle(
        center: Offset(moonCenter.dx + 2.5, moonCenter.dy - 1.5),
        radius: moonRadius * 0.9,
      ));
    final crescent = Path.combine(PathOperation.difference, moonPath, cutoutPath);
    canvas.drawPath(crescent, moonPaint);
    canvas.restore();

    // 2. Twinkling Cosmic Stars
    const stars = [
      Offset(0.12, 0.22),
      Offset(0.28, 0.82),
      Offset(0.45, 0.18),
      Offset(0.85, 0.76),
      Offset(0.92, 0.32),
    ];

    for (int i = 0; i < stars.length; i++) {
      final pos = Offset(stars[i].dx * size.width, stars[i].dy * size.height);
      final phase = (progress + (i * 0.22)) % 1.0;
      final alpha = (math.sin(phase * 2 * math.pi).abs() * 0.85).clamp(0.0, 1.0);
      final starColor = const Color(0xFF00E5FF).withValues(alpha: alpha);
      _drawSparkle(canvas, pos, phase, starColor);
    }

    // Tap burst stars
    if (burstProgress < 1.0) {
      final burstAlpha = (1.0 - burstProgress) * 0.9;
      for (int i = 0; i < 5; i++) {
        final angle = (i * math.pi * 2 / 5) + (burstProgress * 0.4);
        final dist = 8.0 + burstProgress * 28.0;
        final pos = Offset(22.0 + math.cos(angle) * dist, 20.0 + math.sin(angle) * dist);
        _drawSparkle(canvas, pos, 0.5, const Color(0xFF00E5FF).withValues(alpha: burstAlpha));
      }
    }
  }

  void _drawSparkle(Canvas canvas, Offset center, double phase, Color color) {
    final arm = 3.5 + 1.5 * math.sin(phase * 2 * math.pi);
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(center.dx - arm, center.dy), Offset(center.dx + arm, center.dy), paint);
    canvas.drawLine(Offset(center.dx, center.dy - arm), Offset(center.dx, center.dy + arm), paint);
  }

  // ==========================================
  // 3. DARK FLUID WATER RIPPLES & BUBBLES
  // ==========================================
  void _drawWaterRipplesAndBubbles(Canvas canvas, Size size) {
    // 1. Concentric water ripple rings expanding outward behind the logo box
    final rippleCenter = const Offset(22.0, 20.0);
    final ripplePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 0; i < 2; i++) {
      final ringProgress = (progress + (i * 0.5)) % 1.0;
      final radius = 12.0 + (ringProgress * 20.0);
      final ringAlpha = ((1.0 - ringProgress) * 0.35).clamp(0.0, 1.0);

      ripplePaint.color = const Color(0xFF58A6FF).withValues(alpha: ringAlpha);
      canvas.drawCircle(rippleCenter, radius, ripplePaint);
    }

    // 2. Rising aquatic bubbles
    final bubblePaint = Paint()..style = PaintingStyle.fill;
    final highlightPaint = Paint()..style = PaintingStyle.fill;

    const bubbles = [
      _ParticleConfig(baseX: 0.32, speed: 0.9, sway: 8.0, size: 3.5, phase: 0.15),
      _ParticleConfig(baseX: 0.54, speed: 1.2, sway: 10.0, size: 4.5, phase: 0.45),
      _ParticleConfig(baseX: 0.74, speed: 0.75, sway: 7.0, size: 3.0, phase: 0.8),
      _ParticleConfig(baseX: 0.88, speed: 1.05, sway: 9.0, size: 4.0, phase: 0.3),
    ];

    for (final b in bubbles) {
      final t = (1.0 - ((progress * b.speed + b.phase) % 1.0)); // Rising upwards
      final x = (b.baseX * size.width) + math.sin(t * 3 * math.pi) * b.sway;
      final y = t * size.height;
      final alpha = (math.sin(t * math.pi) * 0.55).clamp(0.0, 1.0);

      bubblePaint.color = const Color(0xFF58A6FF).withValues(alpha: alpha);
      highlightPaint.color = Colors.white.withValues(alpha: alpha * 0.7);

      canvas.drawCircle(Offset(x, y), b.size, bubblePaint);
      canvas.drawCircle(Offset(x - b.size * 0.3, y - b.size * 0.3), b.size * 0.3, highlightPaint);
    }

    // Tap burst fluid droplet splash
    if (burstProgress < 1.0) {
      final burstAlpha = (1.0 - burstProgress) * 0.8;
      bubblePaint.color = const Color(0xFF79C0FF).withValues(alpha: burstAlpha);
      for (int i = 0; i < 6; i++) {
        final angle = (i * math.pi / 3);
        final dist = 10.0 + burstProgress * 26.0;
        final bx = 22.0 + math.cos(angle) * dist;
        final by = 20.0 + math.sin(angle) * dist;
        canvas.drawCircle(Offset(bx, by), 3.0, bubblePaint);
      }
    }
  }

  // ==========================================
  // 4. LIGHT MODE FALLING LEAVES & BREEZE
  // ==========================================
  void _drawFallingLeavesEffect(Canvas canvas, Size size) {
    final leafPaint = Paint()..style = PaintingStyle.fill;
    final veinPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    const leaves = [
      _LeafConfig(baseX: 0.20, speed: 0.85, sway: 14.0, size: 7.0, phase: 0.1, color: Color(0xFF2EA043)),
      _LeafConfig(baseX: 0.44, speed: 1.1, sway: 16.0, size: 8.5, phase: 0.5, color: Color(0xFFE28743)),
      _LeafConfig(baseX: 0.68, speed: 0.75, sway: 12.0, size: 6.5, phase: 0.8, color: Color(0xFF1A7F37)),
      _LeafConfig(baseX: 0.86, speed: 0.95, sway: 15.0, size: 7.5, phase: 0.3, color: Color(0xFFD97706)),
    ];

    for (final l in leaves) {
      final t = (progress * l.speed + l.phase) % 1.0;
      final x = (l.baseX * size.width) + math.sin(t * 2 * math.pi + l.phase) * l.sway;
      final y = t * size.height;
      final alpha = (math.sin(t * math.pi) * 0.8).clamp(0.0, 1.0);
      final rotation = (t * 2 * math.pi) + l.phase;

      leafPaint.color = l.color.withValues(alpha: alpha);
      veinPaint.color = Colors.white.withValues(alpha: alpha * 0.6);

      _drawSingleLeaf(canvas, Offset(x, y), l.size, rotation, leafPaint, veinPaint);
    }

    // Tap burst leaves
    if (burstProgress < 1.0) {
      final burstAlpha = (1.0 - burstProgress) * 0.85;
      leafPaint.color = const Color(0xFF2EA043).withValues(alpha: burstAlpha);
      veinPaint.color = Colors.white.withValues(alpha: burstAlpha * 0.6);
      for (int i = 0; i < 5; i++) {
        final angle = (i * math.pi * 2 / 5);
        final dist = 10.0 + burstProgress * 30.0;
        final bx = 22.0 + math.cos(angle) * dist;
        final by = 20.0 + math.sin(angle) * dist;
        _drawSingleLeaf(canvas, Offset(bx, by), 6.5, angle, leafPaint, veinPaint);
      }
    }
  }

  void _drawSingleLeaf(
    Canvas canvas,
    Offset center,
    double radius,
    double rotation,
    Paint fillPaint,
    Paint veinPaint,
  ) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    final path = Path()
      ..moveTo(0, -radius)
      ..quadraticBezierTo(radius * 0.8, 0, 0, radius)
      ..quadraticBezierTo(-radius * 0.8, 0, 0, -radius)
      ..close();

    canvas.drawPath(path, fillPaint);
    // Draw leaf center vein
    canvas.drawLine(Offset(0, -radius * 0.7), Offset(0, radius * 0.7), veinPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _HeaderThemeParticlesPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.burstProgress != burstProgress ||
        oldDelegate.themeMode != themeMode ||
        oldDelegate.accentColor != accentColor;
  }
}

class _ParticleConfig {
  final double baseX;
  final double speed;
  final double sway;
  final double size;
  final double phase;

  const _ParticleConfig({
    required this.baseX,
    required this.speed,
    required this.sway,
    required this.size,
    required this.phase,
  });
}

class _LeafConfig {
  final double baseX;
  final double speed;
  final double sway;
  final double size;
  final double phase;
  final Color color;

  const _LeafConfig({
    required this.baseX,
    required this.speed,
    required this.sway,
    required this.size,
    required this.phase,
    required this.color,
  });
}

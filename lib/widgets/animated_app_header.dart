import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/app_theme_service.dart';
import '../theme/app_theme.dart';

/// Global controller to synchronize interactive particle bursts across the header.
class HeaderAnimationState {
  static final ValueNotifier<double> burstProgressNotifier = ValueNotifier<double>(1.0);
  static DateTime _lastTapTime = DateTime.fromMillisecondsSinceEpoch(0);

  static void triggerBurst() {
    final now = DateTime.now();
    if (now.difference(_lastTapTime).inMilliseconds > 300) {
      _lastTapTime = now;
      burstProgressNotifier.value = 0.0;
    }
  }
}

/// Bespoke vector logo for GitPulse.
///
/// Combines Git branch topology (nodes and branches) with an active
/// cardiac pulse rhythm (vital ECG waveform) and a dynamic traveling pulse spark.
class GitPulseLogo extends StatelessWidget {
  final double size;
  final Color color;
  final double progress;

  const GitPulseLogo({
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
      child: CustomPaint(
        painter: _GitPulseLogoPainter(
          color: color,
          progress: progress,
        ),
      ),
    );
  }
}

class _GitPulseLogoPainter extends CustomPainter {
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

  _GitPulseLogoPainter({
    required this.color,
    required this.progress,
  });

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
    pulsePath.lineTo(headNode.dx, headNode.dy); // Connecting to HEAD release node

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

    // Active HEAD Pulse node with glowing aura
    final pulseBreath = 0.5 + 0.5 * math.sin(progress * 2 * math.pi);
    final headGlowPaint = Paint()
      ..color = color.withValues(alpha: 0.35 * pulseBreath)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(headNode, nodeRadius + 2.5 * pulseBreath, headGlowPaint);

    canvas.drawCircle(headNode, nodeRadius, _fillPaint);
    canvas.drawCircle(headNode, nodeRadius, _strokePaint);
    canvas.drawCircle(headNode, innerDotRadius, dotPaint);

    // 4. Live traveling pulse spark along the pulse branch
    for (final metric in pulsePath.computeMetrics()) {
      final t = (progress * 1.5) % 1.0;
      final tangent = metric.getTangentForOffset(metric.length * t);
      if (tangent != null) {
        _sparkGlow
          ..color = Colors.white.withValues(alpha: 0.8)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

        canvas.drawCircle(tangent.position, 1.8, _sparkGlow);
        canvas.drawCircle(tangent.position, 1.1, _sparkCore);
      }
      break;
    }
  }

  @override
  bool shouldRepaint(covariant _GitPulseLogoPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.progress != progress;
  }
}

/// Full-width header background ambient particle animation widget for [AppBar.flexibleSpace].
///
/// Fills the entire AppBar header width and height with theme-adaptive visual effects:
/// - 🌸 AMOLED Sakura: Drifting cherry blossom petals across the full header sky.
/// - 🌙 AMOLED: Glowing crescent moon hovering in the night horizon & twinkling diamond stars across the entire width.
/// - 💧 Dark Mode: Concentric water ripple waves washing across the header & rising aquatic micro-bubbles.
/// - 🍃 Light Mode: Autumn and green leaves swirling across the header in a gentle breeze.
class AnimatedHeaderBackground extends StatefulWidget {
  const AnimatedHeaderBackground({super.key});

  @override
  State<AnimatedHeaderBackground> createState() => _AnimatedHeaderBackgroundState();
}

class _AnimatedHeaderBackgroundState extends State<AnimatedHeaderBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  double _burstProgress = 1.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    HeaderAnimationState.burstProgressNotifier.addListener(_onBurstTriggered);
  }

  void _onBurstTriggered() {
    if (mounted) {
      setState(() {
        _burstProgress = HeaderAnimationState.burstProgressNotifier.value;
      });
    }
  }

  @override
  void dispose() {
    HeaderAnimationState.burstProgressNotifier.removeListener(_onBurstTriggered);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeMode>(
      valueListenable: AppThemeService.currentThemeNotifier,
      builder: (context, currentTheme, _) {
        final accentColor = _getThemeAccentColor(currentTheme);

        return IgnorePointer(
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final t = _controller.value;
                if (_burstProgress < 1.0) {
                  _burstProgress = math.min(1.0, _burstProgress + 0.04);
                }

                return ClipRect(
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: _HeaderThemeParticlesPainter(
                      progress: t,
                      burstProgress: _burstProgress,
                      themeMode: currentTheme,
                      accentColor: accentColor,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

/// Interactive header title widget for GitPulse.
///
/// Displays the custom [GitPulseLogo], animated title, and version badge,
/// and triggers interactive burst animations across the entire header on tap.
class AnimatedAppHeader extends StatefulWidget {
  final VoidCallback? onTap;

  const AnimatedAppHeader({super.key, this.onTap});

  @override
  State<AnimatedAppHeader> createState() => _AnimatedAppHeaderState();
}

class _AnimatedAppHeaderState extends State<AnimatedAppHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

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
    HeaderAnimationState.triggerBurst();
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

                return SizedBox(
                  height: 40,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildLogoContainer(currentTheme, accentColor, t),
                      const SizedBox(width: 9),
                      _buildAnimatedTitle(currentTheme, accentColor, t),
                      const SizedBox(width: 8),
                      _buildVersionBadge(accentColor),
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
      child: GitPulseLogo(
        size: 19,
        color: accentColor,
        progress: progress,
      ),
    );
  }

  Widget _buildAnimatedTitle(
    AppThemeMode mode,
    Color accentColor,
    double progress,
  ) {
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

/// GPU-accelerated lightweight Canvas painter for full-width theme ambient particle effects.
class _HeaderThemeParticlesPainter extends CustomPainter {
  final double progress;
  final double burstProgress;
  final AppThemeMode themeMode;
  final Color accentColor;

  static final Paint _fillPaint = Paint()..style = PaintingStyle.fill;
  static final Paint _strokePaint = Paint()..style = PaintingStyle.stroke;
  static final Paint _glowPaint = Paint();
  static final Paint _moonPaint = Paint()
    ..color = const Color(0xFFE0F7FA).withValues(alpha: 0.92)
    ..style = PaintingStyle.fill;
  static final Paint _sparklePaint = Paint()
    ..strokeWidth = 1.0
    ..strokeCap = StrokeCap.round;

  static const List<_ParticleConfig> _petals = [
    _ParticleConfig(baseX: 0.06, speed: 0.75, sway: 12.0, size: 6.0, phase: 0.12),
    _ParticleConfig(baseX: 0.16, speed: 1.10, sway: 16.0, size: 7.5, phase: 0.42),
    _ParticleConfig(baseX: 0.28, speed: 0.85, sway: 14.0, size: 6.8, phase: 0.75),
    _ParticleConfig(baseX: 0.40, speed: 1.25, sway: 18.0, size: 8.5, phase: 0.20),
    _ParticleConfig(baseX: 0.52, speed: 0.70, sway: 11.0, size: 5.8, phase: 0.88),
    _ParticleConfig(baseX: 0.64, speed: 1.15, sway: 17.0, size: 7.8, phase: 0.35),
    _ParticleConfig(baseX: 0.74, speed: 0.90, sway: 15.0, size: 6.5, phase: 0.60),
    _ParticleConfig(baseX: 0.84, speed: 1.30, sway: 19.0, size: 8.2, phase: 0.15),
    _ParticleConfig(baseX: 0.92, speed: 0.80, sway: 13.0, size: 6.2, phase: 0.80),
    _ParticleConfig(baseX: 0.97, speed: 1.05, sway: 14.0, size: 7.0, phase: 0.50),
  ];

  static const List<Offset> _stars = [
    Offset(0.08, 0.28),
    Offset(0.18, 0.72),
    Offset(0.28, 0.32),
    Offset(0.38, 0.78),
    Offset(0.48, 0.24),
    Offset(0.68, 0.26),
    Offset(0.76, 0.74),
    Offset(0.85, 0.35),
    Offset(0.93, 0.68),
    Offset(0.97, 0.22),
  ];

  static const List<_ParticleConfig> _bubbles = [
    _ParticleConfig(baseX: 0.12, speed: 0.85, sway: 7.0, size: 3.2, phase: 0.15),
    _ParticleConfig(baseX: 0.24, speed: 1.15, sway: 9.0, size: 4.2, phase: 0.55),
    _ParticleConfig(baseX: 0.38, speed: 0.75, sway: 6.0, size: 2.8, phase: 0.80),
    _ParticleConfig(baseX: 0.52, speed: 1.25, sway: 10.0, size: 4.5, phase: 0.30),
    _ParticleConfig(baseX: 0.66, speed: 0.90, sway: 8.0, size: 3.6, phase: 0.65),
    _ParticleConfig(baseX: 0.78, speed: 1.10, sway: 9.0, size: 4.0, phase: 0.10),
    _ParticleConfig(baseX: 0.90, speed: 0.80, sway: 7.0, size: 3.0, phase: 0.70),
    _ParticleConfig(baseX: 0.96, speed: 1.05, sway: 8.0, size: 3.8, phase: 0.40),
  ];

  static const List<_LeafConfig> _leaves = [
    _LeafConfig(baseX: 0.08, speed: 0.85, sway: 14.0, size: 6.8, phase: 0.10, color: Color(0xFF2EA043)),
    _LeafConfig(baseX: 0.22, speed: 1.15, sway: 16.0, size: 8.2, phase: 0.45, color: Color(0xFFE28743)),
    _LeafConfig(baseX: 0.36, speed: 0.75, sway: 12.0, size: 6.2, phase: 0.80, color: Color(0xFF1A7F37)),
    _LeafConfig(baseX: 0.50, speed: 1.20, sway: 18.0, size: 8.5, phase: 0.25, color: Color(0xFFD97706)),
    _LeafConfig(baseX: 0.65, speed: 0.90, sway: 15.0, size: 7.2, phase: 0.65, color: Color(0xFF2EA043)),
    _LeafConfig(baseX: 0.78, speed: 1.10, sway: 16.0, size: 8.0, phase: 0.15, color: Color(0xFFE28743)),
    _LeafConfig(baseX: 0.88, speed: 0.80, sway: 13.0, size: 6.5, phase: 0.70, color: Color(0xFF1A7F37)),
    _LeafConfig(baseX: 0.96, speed: 1.05, sway: 15.0, size: 7.4, phase: 0.35, color: Color(0xFFD97706)),
  ];

  _HeaderThemeParticlesPainter({
    required this.progress,
    required this.burstProgress,
    required this.themeMode,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

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
    for (final p in _petals) {
      final t = (progress * p.speed + p.phase) % 1.0;
      final x = (p.baseX * size.width) + math.sin(t * 2 * math.pi + p.phase) * p.sway;
      final y = t * size.height;
      final opacity = (math.sin(t * math.pi) * 0.85).clamp(0.0, 1.0);
      final rotation = (t * 2 * math.pi) + p.phase;

      _fillPaint.color = const Color(0xFFFF85A2).withValues(alpha: opacity);
      _drawSinglePetal(canvas, Offset(x, y), p.size, rotation, _fillPaint);
    }

    // Interactive Tap Burst Petals
    if (burstProgress < 1.0) {
      final burstAlpha = (1.0 - burstProgress) * 0.9;
      _fillPaint.color = const Color(0xFFFF5C8A).withValues(alpha: burstAlpha);
      final origin = Offset(28.0, size.height * 0.55);
      for (int i = 0; i < 8; i++) {
        final angle = (i * math.pi / 4) + (burstProgress * 0.6);
        final dist = 10.0 + burstProgress * 48.0;
        final bx = origin.dx + math.cos(angle) * dist;
        final by = origin.dy + math.sin(angle) * dist;
        _drawSinglePetal(canvas, Offset(bx, by), 7.0, angle, _fillPaint);
      }
    }

    // Delicate sparkling glints in the header sky
    _drawSparkle(canvas, Offset(size.width * 0.45, size.height * 0.30), progress, const Color(0xFFFFD1DC));
    _drawSparkle(canvas, Offset(size.width * 0.88, size.height * 0.45), progress + 0.4, const Color(0xFFFFD1DC));
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
    // 1. Crescent Moon floating peacefully in the open header sky
    final moonCenter = Offset(
      size.width * 0.58,
      size.height * 0.40 + 2.5 * math.sin(progress * 2 * math.pi),
    );
    const moonRadius = 7.0;
    final pulse = 0.7 + 0.3 * math.sin(progress * 2 * math.pi);

    _glowPaint
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.28 * pulse)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(moonCenter, moonRadius + 3, _glowPaint);

    // Direct vector crescent moon without expensive boolean CSG operations
    final crescent = Path()
      ..moveTo(moonCenter.dx, moonCenter.dy - moonRadius)
      ..arcToPoint(
        Offset(moonCenter.dx, moonCenter.dy + moonRadius),
        radius: const Radius.circular(moonRadius),
        clockwise: false,
      )
      ..arcToPoint(
        Offset(moonCenter.dx, moonCenter.dy - moonRadius),
        radius: const Radius.circular(moonRadius * 1.35),
        clockwise: true,
      )
      ..close();
    canvas.drawPath(crescent, _moonPaint);

    // 2. Twinkling Cosmic Stars distributed across the entire header width
    for (int i = 0; i < _stars.length; i++) {
      final pos = Offset(_stars[i].dx * size.width, _stars[i].dy * size.height);
      final phase = (progress + (i * 0.18)) % 1.0;
      final alpha = (math.sin(phase * 2 * math.pi).abs() * 0.85).clamp(0.0, 1.0);
      final starColor = const Color(0xFF00E5FF).withValues(alpha: alpha);
      _drawSparkle(canvas, pos, phase, starColor);
    }

    // Tap burst stars
    if (burstProgress < 1.0) {
      final burstAlpha = (1.0 - burstProgress) * 0.9;
      final origin = Offset(28.0, size.height * 0.55);
      for (int i = 0; i < 7; i++) {
        final angle = (i * math.pi * 2 / 7) + (burstProgress * 0.5);
        final dist = 10.0 + burstProgress * 42.0;
        final pos = Offset(origin.dx + math.cos(angle) * dist, origin.dy + math.sin(angle) * dist);
        _drawSparkle(canvas, pos, 0.5, const Color(0xFF00E5FF).withValues(alpha: burstAlpha));
      }
    }
  }

  void _drawSparkle(Canvas canvas, Offset center, double phase, Color color) {
    final arm = 3.5 + 1.8 * math.sin(phase * 2 * math.pi);
    _sparklePaint.color = color;

    canvas.drawLine(Offset(center.dx - arm, center.dy), Offset(center.dx + arm, center.dy), _sparklePaint);
    canvas.drawLine(Offset(center.dx, center.dy - arm), Offset(center.dx, center.dy + arm), _sparklePaint);
  }

  // ==========================================
  // 3. DARK FLUID WATER RIPPLES & BUBBLES
  // ==========================================
  void _drawWaterRipplesAndBubbles(Canvas canvas, Size size) {
    // 1. Concentric ripples radiating outward across the header from the logo
    final rippleCenter = Offset(28.0, size.height * 0.55);
    _strokePaint.strokeWidth = 1.0;

    for (int i = 0; i < 3; i++) {
      final ringProgress = (progress + (i * 0.33)) % 1.0;
      final radius = 14.0 + (ringProgress * 70.0);
      final ringAlpha = ((1.0 - ringProgress) * 0.32).clamp(0.0, 1.0);

      _strokePaint.color = const Color(0xFF58A6FF).withValues(alpha: ringAlpha);
      canvas.drawCircle(rippleCenter, radius, _strokePaint);
    }

    // 2. Rising aquatic bubbles across the entire header width
    for (final b in _bubbles) {
      final t = (1.0 - ((progress * b.speed + b.phase) % 1.0));
      final x = (b.baseX * size.width) + math.sin(t * 3 * math.pi) * b.sway;
      final y = t * size.height;
      final alpha = (math.sin(t * math.pi) * 0.55).clamp(0.0, 1.0);

      _fillPaint.color = const Color(0xFF58A6FF).withValues(alpha: alpha);
      _glowPaint.color = Colors.white.withValues(alpha: alpha * 0.75);

      canvas.drawCircle(Offset(x, y), b.size, _fillPaint);
      canvas.drawCircle(Offset(x - b.size * 0.3, y - b.size * 0.3), b.size * 0.3, _glowPaint);
    }

    // Tap burst fluid droplet splash
    if (burstProgress < 1.0) {
      final burstAlpha = (1.0 - burstProgress) * 0.85;
      _fillPaint.color = const Color(0xFF79C0FF).withValues(alpha: burstAlpha);
      for (int i = 0; i < 8; i++) {
        final angle = (i * math.pi / 4);
        final dist = 10.0 + burstProgress * 38.0;
        final bx = rippleCenter.dx + math.cos(angle) * dist;
        final by = rippleCenter.dy + math.sin(angle) * dist;
        canvas.drawCircle(Offset(bx, by), 3.2, _fillPaint);
      }
    }
  }

  // ==========================================
  // 4. LIGHT MODE FALLING LEAVES & BREEZE
  // ==========================================
  void _drawFallingLeavesEffect(Canvas canvas, Size size) {
    _strokePaint.strokeWidth = 0.8;

    for (final l in _leaves) {
      final t = (progress * l.speed + l.phase) % 1.0;
      final x = (l.baseX * size.width) + math.sin(t * 2 * math.pi + l.phase) * l.sway;
      final y = t * size.height;
      final alpha = (math.sin(t * math.pi) * 0.8).clamp(0.0, 1.0);
      final rotation = (t * 2 * math.pi) + l.phase;

      _fillPaint.color = l.color.withValues(alpha: alpha);
      _strokePaint.color = Colors.white.withValues(alpha: alpha * 0.6);

      _drawSingleLeaf(canvas, Offset(x, y), l.size, rotation, _fillPaint, _strokePaint);
    }

    // Tap burst leaves
    if (burstProgress < 1.0) {
      final burstAlpha = (1.0 - burstProgress) * 0.85;
      _fillPaint.color = const Color(0xFF2EA043).withValues(alpha: burstAlpha);
      _strokePaint.color = Colors.white.withValues(alpha: burstAlpha * 0.6);
      final origin = Offset(28.0, size.height * 0.55);
      for (int i = 0; i < 7; i++) {
        final angle = (i * math.pi * 2 / 7);
        final dist = 10.0 + burstProgress * 42.0;
        final bx = origin.dx + math.cos(angle) * dist;
        final by = origin.dy + math.sin(angle) * dist;
        _drawSingleLeaf(canvas, Offset(bx, by), 6.5, angle, _fillPaint, _strokePaint);
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

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';
import '../models/contribution_stats.dart';

class AnimatedTierTitle extends StatefulWidget {
  final CommitTitleInfo titleInfo;
  final double fontSize;
  final bool showBadgeContainer;
  final EdgeInsetsGeometry? padding;

  const AnimatedTierTitle({
    super.key,
    required this.titleInfo,
    this.fontSize = 11.5,
    this.showBadgeContainer = true,
    this.padding,
  });

  @override
  State<AnimatedTierTitle> createState() => _AnimatedTierTitleState();
}

class _AnimatedTierTitleState extends State<AnimatedTierTitle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    final tier = widget.titleInfo.tier;
    final durationMs = switch (tier) {
      1 => 2200,
      2 => 1800, // fast energetic electric crackle
      3 => 2400, // digital matrix rhythm
      4 => 2600, // golden sunlight sweep
      5 => 3200, // calm cosmic drift
      _ => 3000, // gentle organic breath
    };
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: durationMs),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tier = widget.titleInfo.tier;
    final cleanTitle = AppLocalizations.of(context)
        .getCommitTierCleanTitle(tier);

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final progress = _controller.value;

          switch (tier) {
            case 1:
              return _buildTier1ArcaneDragonEffect(cleanTitle, progress);
            case 2:
              return _buildTier2GlacialThunderEffect(cleanTitle, progress);
            case 3:
              return _buildTier3SacredBladeEffect(cleanTitle, progress);
            case 4:
              return _buildTier4SunburstGuildEffect(cleanTitle, progress);
            case 5:
              return _buildTier5MoonlitMistEffect(cleanTitle, progress);
            default:
              return _buildTier6VerdantDewEffect(cleanTitle, progress);
          }
        },
      ),
    );
  }

  /// Tier 1 (Mythic Archmage): Arcane Dragonflame with floating magical rune embers
  Widget _buildTier1ArcaneDragonEffect(String title, double t) {
    // Multi-harmonic arcane pulse physics
    final auraPulse = (math.sin(t * 2 * math.pi) + 1) / 2;
    final flameFlutter = (math.sin(t * 4 * math.pi) + 1) / 2;
    final auraIntensity = (auraPulse * 0.70 + flameFlutter * 0.30).clamp(0.0, 1.0);
    final wave = math.sin(t * 2 * math.pi) * 0.22;
    final heatRise = math.sin(t * 2 * math.pi) * 0.08;

    // Prismatic Arcane-Dragon gradient: Crimson Ruby, Royal Violet, Dragon Gold & Starfire
    final textWidget = ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) {
        return LinearGradient(
          begin: Alignment(wave, 1.1 + heatRise),
          end: Alignment(-wave, -1.1 + heatRise),
          colors: const [
            Color(0xFFE11D48), // Deep ruby dragon ember
            Color(0xFF9333EA), // Arcane royal violet
            Color(0xFFF97316), // Dragon flame orange
            Color(0xFFFBBF24), // Celestial solar gold
            Color(0xFFFFFBEB), // White-hot arcane starfire
          ],
          stops: const [0.0, 0.25, 0.55, 0.82, 1.0],
        ).createShader(bounds);
      },
      child: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: widget.fontSize,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
          shadows: [
            Shadow(
              color: const Color(0xFFC026D3)
                  .withValues(alpha: 0.75 + 0.25 * auraIntensity),
              blurRadius: 5.0,
              offset: const Offset(0, -1),
            ),
            Shadow(
              color: const Color(0xFFF59E0B)
                  .withValues(alpha: 0.50 + 0.30 * auraIntensity),
              blurRadius: 8.0,
            ),
          ],
        ),
      ),
    );

    // Overlay orbital drifting arcane rune spark particles
    final enchantedWidget = CustomPaint(
      painter: _ArcaneRuneEmbersPainter(progress: t),
      child: textWidget,
    );

    if (!widget.showBadgeContainer) {
      return enchantedWidget;
    }

    final borderColor = Color.lerp(
      const Color(0xFF9333EA),
      const Color(0xFFF59E0B),
      auraIntensity,
    )!;

    return Container(
      padding: widget.padding ??
          const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1E0A24).withValues(alpha: 0.90),
            const Color(0xFF140307).withValues(alpha: 0.94),
          ],
        ),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: borderColor.withValues(alpha: 0.55 + 0.35 * auraIntensity),
          width: 1.15,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9333EA)
                .withValues(alpha: 0.25 + 0.20 * auraIntensity),
            blurRadius: 9.0,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: const Color(0xFFF97316)
                .withValues(alpha: 0.15 + 0.15 * auraIntensity),
            blurRadius: 12.0,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            size: widget.fontSize * 1.1,
            color: borderColor,
          ),
          const SizedBox(width: 4),
          Flexible(child: enchantedWidget),
        ],
      ),
    );
  }

  /// Tier 2 (Diamond Vanguard): Glacial Thunderstorm Crystal & Lightning Arc
  Widget _buildTier2GlacialThunderEffect(String title, double t) {
    // High-frequency crystal spark & electric micro-jitter
    final crackle = math.sin(t * 8 * math.pi) * 0.18 + math.sin(t * 16 * math.pi) * 0.09;
    final pulse = (math.sin(t * 2 * math.pi) + 1) / 2;
    final sweep = -2.6 + 5.2 * t;

    final textWidget = ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) {
        return LinearGradient(
          begin: Alignment(sweep - 1.2, -0.4),
          end: Alignment(sweep + 1.2, 0.4),
          colors: const [
            Color(0xFF0284C7), // Deep glacial cyan base
            Color(0xFF0284C7),
            Color(0xFF00E5FF), // Diamond crystal cyan
            Color(0xFFF0FDF4), // Glacial frost white core
            Color(0xFF818CF8), // Electric arc violet
            Color(0xFF00E5FF), // Diamond crystal cyan
            Color(0xFF0284C7),
            Color(0xFF0284C7),
          ],
          stops: const [0.0, 0.20, 0.40, 0.50, 0.60, 0.80, 0.90, 1.0],
        ).createShader(bounds);
      },
      child: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: widget.fontSize,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
          shadows: [
            Shadow(
              color: const Color(0xFF00E5FF).withValues(alpha: 0.75 + crackle.abs()),
              blurRadius: 5.5,
              offset: const Offset(0, -0.5),
            ),
            Shadow(
              color: const Color(0xFF6366F1).withValues(alpha: 0.40 + 0.30 * pulse),
              blurRadius: 7.0,
            ),
          ],
        ),
      ),
    );

    if (!widget.showBadgeContainer) {
      return textWidget;
    }

    return Container(
      padding: widget.padding ??
          const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF031526).withValues(alpha: 0.92),
            const Color(0xFF060B24).withValues(alpha: 0.94),
          ],
        ),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: const Color(0xFF00E5FF).withValues(alpha: 0.45 + 0.35 * pulse),
          width: 1.15,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withValues(alpha: 0.30 + 0.25 * pulse),
            blurRadius: 8.0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.bolt_rounded,
            size: widget.fontSize * 1.15,
            color: Color.lerp(
              const Color(0xFF00E5FF),
              const Color(0xFFF0FDF4),
              pulse,
            ),
          ),
          const SizedBox(width: 4),
          Flexible(child: textWidget),
        ],
      ),
    );
  }

  /// Tier 3 (Platinum Artisan): Sacred Emerald Blade Sweep
  Widget _buildTier3SacredBladeEffect(String title, double t) {
    final pulse = (math.sin(t * 2 * math.pi) + 1) / 2;
    final sweep = -2.8 + 5.6 * t;

    final textWidget = ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) {
        return LinearGradient(
          begin: Alignment(sweep - 1.2, -0.2),
          end: Alignment(sweep + 1.2, 0.2),
          colors: const [
            Color(0xFF047857), // Forged deep emerald
            Color(0xFF047857),
            Color(0xFF10B981), // Living jade
            Color(0xFF00FF87), // Radiant sacred emerald
            Color(0xFFF8FAFC), // Pure blade glint highlight
            Color(0xFF6EE7B7), // Mint platinum sheen
            Color(0xFF047857),
            Color(0xFF047857),
          ],
          stops: const [0.0, 0.20, 0.40, 0.49, 0.53, 0.62, 0.82, 1.0],
        ).createShader(bounds);
      },
      child: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: widget.fontSize,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          shadows: [
            Shadow(
              color: const Color(0xFF10B981).withValues(alpha: 0.55 + 0.35 * pulse),
              blurRadius: 5.0,
            ),
          ],
        ),
      ),
    );

    if (!widget.showBadgeContainer) {
      return textWidget;
    }

    return Container(
      padding: widget.padding ??
          const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: const Color(0xFF021E14).withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: 0.40 + 0.30 * pulse),
          width: 1.05,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF047857).withValues(alpha: 0.25 + 0.20 * pulse),
            blurRadius: 7.0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.hardware_rounded,
            size: widget.fontSize * 1.05,
            color: const Color(0xFF00FF87),
          ),
          const SizedBox(width: 4),
          Flexible(child: textWidget),
        ],
      ),
    );
  }

  /// Tier 4 (Gold Adventurer): Sunburst Guild Crest Radiance
  Widget _buildTier4SunburstGuildEffect(String title, double t) {
    final pulse = (math.sin(t * 2 * math.pi) + 1) / 2;
    final sweep = -2.6 + 5.2 * t;

    final textWidget = ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) {
        return LinearGradient(
          begin: Alignment(sweep - 1.2, -0.3),
          end: Alignment(sweep + 1.2, 0.3),
          colors: const [
            Color(0xFFB45309), // Warm antique bronze-gold
            Color(0xFFB45309),
            Color(0xFFF59E0B), // Radiant amber gold
            Color(0xFFFFFBEB), // Sunfire crest glint
            Color(0xFFFCD34D), // Gilded gold
            Color(0xFFB45309),
            Color(0xFFB45309),
          ],
          stops: const [0.0, 0.20, 0.42, 0.50, 0.58, 0.80, 1.0],
        ).createShader(bounds);
      },
      child: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: widget.fontSize,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          shadows: [
            Shadow(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.50 + 0.30 * pulse),
              blurRadius: 4.5,
            ),
          ],
        ),
      ),
    );

    if (!widget.showBadgeContainer) {
      return textWidget;
    }

    return Container(
      padding: widget.padding ??
          const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: const Color(0xFF231604).withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.40 + 0.25 * pulse),
          width: 1.05,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB45309).withValues(alpha: 0.20 + 0.18 * pulse),
            blurRadius: 6.5,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.explore_rounded,
            size: widget.fontSize * 1.05,
            color: const Color(0xFFFCD34D),
          ),
          const SizedBox(width: 4),
          Flexible(child: textWidget),
        ],
      ),
    );
  }

  /// Tier 5 (Silver Explorer): Moonlit Silver Mist
  Widget _buildTier5MoonlitMistEffect(String title, double t) {
    final pulse = (math.sin(t * 2 * math.pi) + 1) / 2;
    final sweep = -2.6 + 5.2 * t;

    final textWidget = ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) {
        return LinearGradient(
          begin: Alignment(sweep - 1.2, 0.0),
          end: Alignment(sweep + 1.2, 0.0),
          colors: const [
            Color(0xFF64748B), // Slate silver base
            Color(0xFF64748B),
            Color(0xFFCBD5E1), // Cool moonlit silver
            Color(0xFFF8FAFC), // Pure starlight highlight
            Color(0xFFDDD6FE), // Soft twilight stardust
            Color(0xFF64748B),
            Color(0xFF64748B),
          ],
          stops: const [0.0, 0.20, 0.42, 0.50, 0.58, 0.80, 1.0],
        ).createShader(bounds);
      },
      child: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: widget.fontSize,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
          shadows: [
            Shadow(
              color: const Color(0xFFC4B5FD).withValues(alpha: 0.35 + 0.20 * pulse),
              blurRadius: 4.5,
            ),
          ],
        ),
      ),
    );

    if (!widget.showBadgeContainer) {
      return textWidget;
    }

    return Container(
      padding: widget.padding ??
          const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: const Color(0xFF94A3B8).withValues(alpha: 0.28 + 0.20 * pulse),
          width: 0.95,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC4B5FD).withValues(alpha: 0.12 + 0.10 * pulse),
            blurRadius: 5.5,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.navigation_rounded,
            size: widget.fontSize * 1.05,
            color: const Color(0xFFCBD5E1),
          ),
          const SizedBox(width: 4),
          Flexible(child: textWidget),
        ],
      ),
    );
  }

  /// Tier 6 (Bronze Novice): Living Verdant Dewdrop Pulse
  Widget _buildTier6VerdantDewEffect(String title, double t) {
    // Gentle natural breath rhythm
    final breath = (math.sin(t * 2 * math.pi) + 1) / 2;

    final textWidget = Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: widget.fontSize,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: Color.lerp(
          const Color(0xFFD97706),
          const Color(0xFF4ADE80),
          breath * 0.75,
        ),
        shadows: [
          Shadow(
            color: const Color(0xFF22C55E).withValues(alpha: 0.20 + 0.25 * breath),
            blurRadius: 4.0,
          ),
        ],
      ),
    );

    if (!widget.showBadgeContainer) {
      return textWidget;
    }

    return Container(
      padding: widget.padding ??
          const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: const Color(0xFF181006).withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Color.lerp(
            const Color(0xFFB45309),
            const Color(0xFF22C55E),
            breath,
          )!.withValues(alpha: 0.35 + 0.20 * breath),
          width: 0.95,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.eco_rounded,
            size: widget.fontSize * 1.05,
            color: Color.lerp(
              const Color(0xFFD97706),
              const Color(0xFF4ADE80),
              breath,
            ),
          ),
          const SizedBox(width: 4),
          Flexible(child: textWidget),
        ],
      ),
    );
  }
}

/// Lightweight hardware-accelerated canvas painter rendering floating arcane rune sparks
class _ArcaneRuneEmbersPainter extends CustomPainter {
  final double progress;

  _ArcaneRuneEmbersPainter({required this.progress});

  static final Paint _glowPaint = Paint();
  static final Paint _corePaint = Paint();

  static const List<_RuneSparkSpec> _sparks = [
    _RuneSparkSpec(xRatio: 0.08, size: 1.6, phase: 0.00, color: Color(0xFFE11D48)), // Ruby
    _RuneSparkSpec(xRatio: 0.22, size: 1.3, phase: 0.25, color: Color(0xFF9333EA)), // Violet
    _RuneSparkSpec(xRatio: 0.38, size: 1.9, phase: 0.50, color: Color(0xFFF59E0B)), // Gold
    _RuneSparkSpec(xRatio: 0.52, size: 1.4, phase: 0.75, color: Color(0xFFC026D3)), // Magenta
    _RuneSparkSpec(xRatio: 0.68, size: 1.7, phase: 0.12, color: Color(0xFFF97316)), // Dragon flame
    _RuneSparkSpec(xRatio: 0.82, size: 1.4, phase: 0.38, color: Color(0xFFFBBF24)), // Gold
    _RuneSparkSpec(xRatio: 0.94, size: 1.8, phase: 0.62, color: Color(0xFF9333EA)), // Violet
    _RuneSparkSpec(xRatio: 0.44, size: 1.2, phase: 0.88, color: Color(0xFFE11D48)), // Ruby
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    for (final spark in _sparks) {
      final t = (progress + spark.phase) % 1.0;
      final y = size.height * 1.05 - t * (size.height * 1.40);
      final sway = math.sin(t * 2 * math.pi) * 3.5;
      final x = (size.width * spark.xRatio + sway).clamp(0.0, size.width);

      final alpha = math.sin(t * math.pi).clamp(0.0, 1.0);
      if (alpha <= 0.01) continue;

      _glowPaint.color = spark.color.withValues(alpha: alpha * 0.75);
      canvas.drawCircle(Offset(x, y), spark.size * 1.3, _glowPaint);

      _corePaint.color = Colors.white.withValues(alpha: alpha * 0.95);
      canvas.drawCircle(Offset(x, y), spark.size * 0.5, _corePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ArcaneRuneEmbersPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _RuneSparkSpec {
  final double xRatio;
  final double size;
  final double phase;
  final Color color;

  const _RuneSparkSpec({
    required this.xRatio,
    required this.size,
    required this.phase,
    required this.color,
  });
}

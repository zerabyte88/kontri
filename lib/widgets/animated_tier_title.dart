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
      1 => 1600,
      2 => 1800,
      3 => 2400,
      4 => 2600,
      5 => 3200,
      _ => 3000,
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

  Widget _buildTier1ArcaneDragonEffect(String title, double t) {
    final auraPulse = (math.sin(t * 2 * math.pi) + 1) / 2;
    final microFlutter =
        math.sin(t * 8 * math.pi) * 0.07 + math.sin(t * 16 * math.pi) * 0.03;
    final flameSurge = (math.sin(t * 2 * math.pi) + 1) / 2;
    final flameIntensity = (auraPulse * 0.65 + microFlutter.abs() * 0.35).clamp(
      0.0,
      1.0,
    );
    final auraIntensity = flameIntensity;

    final shadowAlpha = (0.70 + 0.30 * flameIntensity).clamp(0.0, 1.0);
    final shadowBlur = 4.5 + 5.5 * flameIntensity;

    final textWidget = ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) {
        return LinearGradient(
          begin: Alignment(0.0, 1.15 + microFlutter * 0.4),
          end: Alignment(0.0, -0.95 - flameSurge * 0.55 + microFlutter),
          colors: const [
            Color(0xFFE11D48),
            Color(0xFF9333EA),
            Color(0xFFF97316),
            Color(0xFFFBBF24),
            Color(0xFFFFFBEB),
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
              color: const Color(0xFFC026D3).withValues(alpha: shadowAlpha),
              blurRadius: shadowBlur * 0.65,
              offset: const Offset(0, -1),
            ),
            Shadow(
              color: const Color(0xFFF59E0B).withValues(
                alpha: (0.45 + 0.45 * flameIntensity).clamp(0.0, 1.0),
              ),
              blurRadius: shadowBlur,
              offset: Offset(0, -1.0 - 1.2 * flameIntensity),
            ),
          ],
        ),
      ),
    );

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
      padding:
          widget.padding ??
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

  Widget _buildTier2GlacialThunderEffect(String title, double t) {
    final crackle =
        math.sin(t * 8 * math.pi) * 0.18 + math.sin(t * 16 * math.pi) * 0.09;
    final pulse = (math.sin(t * 2 * math.pi) + 1) / 2;
    final sweep = -2.6 + 5.2 * t;

    final textWidget = ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) {
        return LinearGradient(
          begin: Alignment(sweep - 1.2, -0.4),
          end: Alignment(sweep + 1.2, 0.4),
          colors: const [
            Color(0xFF0284C7),
            Color(0xFF0284C7),
            Color(0xFF00E5FF),
            Color(0xFFF0FDF4),
            Color(0xFF818CF8),
            Color(0xFF00E5FF),
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
              color: const Color(0xFF00E5FF)
                  .withValues(alpha: 0.75 + crackle.abs()),
              blurRadius: 5.5,
              offset: const Offset(0, -0.5),
            ),
            Shadow(
              color: const Color(0xFF6366F1)
                  .withValues(alpha: 0.40 + 0.30 * pulse),
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
      padding:
          widget.padding ??
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
            color: const Color(0xFF0284C7)
                .withValues(alpha: 0.30 + 0.25 * pulse),
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
            Color(0xFF047857),
            Color(0xFF047857),
            Color(0xFF10B981),
            Color(0xFF00FF87),
            Color(0xFFF8FAFC),
            Color(0xFF6EE7B7),
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
              color: const Color(0xFF10B981)
                  .withValues(alpha: 0.55 + 0.35 * pulse),
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
      padding:
          widget.padding ??
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
            color: const Color(0xFF047857)
                .withValues(alpha: 0.25 + 0.20 * pulse),
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
            Color(0xFFB45309),
            Color(0xFFB45309),
            Color(0xFFF59E0B),
            Color(0xFFFFFBEB),
            Color(0xFFFCD34D),
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
              color: const Color(0xFFF59E0B)
                  .withValues(alpha: 0.50 + 0.30 * pulse),
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
      padding:
          widget.padding ??
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
            color: const Color(0xFFB45309)
                .withValues(alpha: 0.20 + 0.18 * pulse),
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
            Color(0xFF64748B),
            Color(0xFF64748B),
            Color(0xFFCBD5E1),
            Color(0xFFF8FAFC),
            Color(0xFFDDD6FE),
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
              color: const Color(0xFFC4B5FD)
                  .withValues(alpha: 0.35 + 0.20 * pulse),
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
      padding:
          widget.padding ??
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
            color: const Color(0xFFC4B5FD)
                .withValues(alpha: 0.12 + 0.10 * pulse),
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

  Widget _buildTier6VerdantDewEffect(String title, double t) {
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
            color: const Color(0xFF22C55E)
                .withValues(alpha: 0.20 + 0.25 * breath),
            blurRadius: 4.0,
          ),
        ],
      ),
    );

    if (!widget.showBadgeContainer) {
      return textWidget;
    }

    return Container(
      padding:
          widget.padding ??
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

class _ArcaneRuneEmbersPainter extends CustomPainter {
  final double progress;

  _ArcaneRuneEmbersPainter({required this.progress});

  static final Paint _glowPaint = Paint();
  static final Paint _corePaint = Paint();

  static const List<_RuneSparkSpec> _sparks = [
    _RuneSparkSpec(
      xRatio: 0.08,
      size: 1.6,
      phase: 0.00,
      color: Color(0xFFE11D48),
    ),
    _RuneSparkSpec(
      xRatio: 0.22,
      size: 1.3,
      phase: 0.25,
      color: Color(0xFF9333EA),
    ),
    _RuneSparkSpec(
      xRatio: 0.38,
      size: 1.9,
      phase: 0.50,
      color: Color(0xFFF59E0B),
    ),
    _RuneSparkSpec(
      xRatio: 0.52,
      size: 1.4,
      phase: 0.75,
      color: Color(0xFFC026D3),
    ),
    _RuneSparkSpec(
      xRatio: 0.68,
      size: 1.7,
      phase: 0.12,
      color: Color(0xFFF97316),
    ),
    _RuneSparkSpec(
      xRatio: 0.82,
      size: 1.4,
      phase: 0.38,
      color: Color(0xFFFBBF24),
    ),
    _RuneSparkSpec(
      xRatio: 0.94,
      size: 1.8,
      phase: 0.62,
      color: Color(0xFF9333EA),
    ),
    _RuneSparkSpec(
      xRatio: 0.44,
      size: 1.2,
      phase: 0.88,
      color: Color(0xFFE11D48),
    ),
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

import 'dart:async';
import 'package:flutter/material.dart';

class RunningText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final bool autoScroll;
  final Duration pauseDuration;

  const RunningText({
    super.key,
    required this.text,
    this.style,
    this.autoScroll = true,
    this.pauseDuration = const Duration(milliseconds: 1500),
  });

  @override
  State<RunningText> createState() => _RunningTextState();
}

class _RunningTextState extends State<RunningText> {
  ScrollController? _scrollController;
  bool _disposed = false;
  bool _isLoopRunning = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoScroll) {
      _scrollController = ScrollController();
    }
  }

  @override
  void didUpdateWidget(RunningText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != oldWidget.text) {
      if (_scrollController != null && _scrollController!.hasClients) {
        _scrollController!.jumpTo(0.0);
      }
      _isLoopRunning = false;
      if (widget.autoScroll) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _startScrollLoop());
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _scrollController?.dispose();
    super.dispose();
  }

  Future<void> _startScrollLoop() async {
    if (_disposed || !mounted || !widget.autoScroll || _isLoopRunning) return;
    _isLoopRunning = true;

    while (mounted && !_disposed && widget.autoScroll) {
      if (_scrollController == null || !_scrollController!.hasClients) {
        await Future.delayed(const Duration(milliseconds: 150));
        continue;
      }

      final maxScroll = _scrollController!.position.maxScrollExtent;
      if (maxScroll <= 0) {
        await Future.delayed(const Duration(milliseconds: 500));
        continue;
      }

      // Initial pause at start
      await Future.delayed(widget.pauseDuration);
      if (!mounted || _disposed || !_scrollController!.hasClients) break;

      // Animate smoothly to end
      final duration = Duration(
        milliseconds: (maxScroll * 35).clamp(1000, 7000).toInt(),
      );

      try {
        await _scrollController!.animateTo(
          maxScroll,
          duration: duration,
          curve: Curves.easeInOut,
        );
      } catch (_) {
        break;
      }

      // Pause at end
      await Future.delayed(widget.pauseDuration);
      if (!mounted || _disposed || !_scrollController!.hasClients) break;

      // Animate back to start
      try {
        await _scrollController!.animateTo(
          0.0,
          duration: duration,
          curve: Curves.easeInOut,
        );
      } catch (_) {
        break;
      }
    }

    _isLoopRunning = false;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final effectiveStyle = widget.style ?? DefaultTextStyle.of(context).style;
        final direction = Directionality.maybeOf(context) ?? TextDirection.ltr;

        final painter = TextPainter(
          text: TextSpan(text: widget.text, style: effectiveStyle),
          maxLines: 1,
          textDirection: direction,
        )..layout(minWidth: 0, maxWidth: double.infinity);

        final textWidth = painter.width;
        final availableWidth = constraints.maxWidth;

        // If text comfortably fits within available space, render standard Text
        if (!availableWidth.isFinite || textWidth <= availableWidth) {
          return Text(
            widget.text,
            style: effectiveStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
        }

        // When text overflows:
        // Manual mode: user can freely scroll horizontally with touch
        if (!widget.autoScroll) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Text(
              widget.text,
              style: effectiveStyle,
              maxLines: 1,
            ),
          );
        }

        // Auto ping-pong scroll mode
        _scrollController ??= ScrollController();
        if (!_isLoopRunning) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _startScrollLoop());
        }

        return SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Text(
            widget.text,
            style: effectiveStyle,
            maxLines: 1,
          ),
        );
      },
    );
  }
}

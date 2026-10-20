import 'package:flutter/material.dart';

/// A widget that fades and slides in when first built.
///
/// Subtle by design: a short fade plus a small upward slide, used to stagger
/// dashboard cards and list rows so a screen assembles instead of popping.
/// The animation runs once on mount — it never replays on rebuild, so a
/// scrolling list does not stutter.
///
/// [delay] staggers siblings: index 0 waits 0ms, index 1 waits 40ms, and so
/// on, capped so a long list still finishes quickly.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = 12,
    this.duration = const Duration(milliseconds: 220),
  });

  final Widget child;
  final Duration delay;

  /// Slide distance in logical pixels (the widget rises by this much).
  final double offset;
  final Duration duration;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      child: widget.child,
      builder: (context, child) {
        return Opacity(
          opacity: _curve.value,
          child: Transform.translate(
            offset: Offset(0, widget.offset * (1 - _curve.value)),
            child: child,
          ),
        );
      },
    );
  }
}

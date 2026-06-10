import 'package:flutter/material.dart';
import '../../core/constants.dart';

/// Smooth page transition for tab switching (fade + slide).
class FadeSlideTransition extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final Offset slideOffset;

  const FadeSlideTransition({
    super.key,
    required this.child,
    this.duration = AppConstants.animDurationNormal,
    this.curve = AppCurves.easeOutExpo,
    this.slideOffset = const Offset(20, 0),
  });

  @override
  State<FadeSlideTransition> createState() => _FadeSlideTransitionState();
}

class _FadeSlideTransitionState extends State<FadeSlideTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );
    _slide = Tween<Offset>(begin: widget.slideOffset, end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant FadeSlideTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.child.key != widget.child.key) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: Transform.translate(
            offset: _slide.value,
            child: widget.child,
          ),
        );
      },
    );
  }
}

/// AnimatedSwitcher wrapper with custom fade+slide transition.
class SmoothSwitcher extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final Offset slideOffset;

  const SmoothSwitcher({
    super.key,
    required this.child,
    this.duration = AppConstants.animDurationNormal,
    this.curve = AppCurves.easeOutExpo,
    this.slideOffset = const Offset(20, 0),
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: curve,
      switchOutCurve: AppCurves.easeInOutCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(begin: slideOffset, end: Offset.zero).animate(
              CurvedAnimation(parent: animation, curve: curve),
            ),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

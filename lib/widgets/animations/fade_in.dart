import 'package:flutter/material.dart';
import '../../core/constants.dart';

/// A reusable fade-in widget that animates its child from transparent to opaque.
/// Optionally supports slide offset and staggered delay.
class FadeIn extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Offset slideOffset;
  final Curve curve;

  const FadeIn({
    super.key,
    required this.child,
    this.duration = AppConstants.animDurationNormal,
    this.delay = Duration.zero,
    this.slideOffset = const Offset(0, 12),
    this.curve = AppCurves.easeOutExpo,
  });

  @override
  State<FadeIn> createState() => _FadeInState();
}

class _FadeInState extends State<FadeIn> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _opacityAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );
    _slideAnim = Tween<Offset>(begin: widget.slideOffset, end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );

    Future.delayed(widget.delay, () {
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
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnim.value,
          child: Transform.translate(
            offset: _slideAnim.value,
            child: widget.child,
          ),
        );
      },
    );
  }
}

/// A list wrapper that staggered-fades its children.
class StaggeredFadeIn extends StatelessWidget {
  final List<Widget> children;
  final Duration baseDelay;
  final Duration itemDelay;
  final Duration duration;
  final Offset slideOffset;
  final Axis direction;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;

  const StaggeredFadeIn({
    super.key,
    required this.children,
    this.baseDelay = Duration.zero,
    this.itemDelay = const Duration(milliseconds: 50),
    this.duration = AppConstants.animDurationNormal,
    this.slideOffset = const Offset(0, 12),
    this.direction = Axis.vertical,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.min,
  });

  @override
  Widget build(BuildContext context) {
    return direction == Axis.vertical
        ? Column(
            mainAxisAlignment: mainAxisAlignment,
            crossAxisAlignment: crossAxisAlignment,
            mainAxisSize: mainAxisSize,
            children: _buildChildren(),
          )
        : Row(
            mainAxisAlignment: mainAxisAlignment,
            crossAxisAlignment: crossAxisAlignment,
            mainAxisSize: mainAxisSize,
            children: _buildChildren(),
          );
  }

  List<Widget> _buildChildren() {
    return List.generate(children.length, (index) {
      return FadeIn(
        delay: baseDelay + itemDelay * index,
        duration: duration,
        slideOffset: slideOffset,
        child: children[index],
      );
    });
  }
}

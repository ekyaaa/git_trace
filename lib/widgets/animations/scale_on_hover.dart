import 'package:flutter/material.dart';
import '../../core/constants.dart';

/// A reusable hover-aware widget that scales its child smoothly.
/// Replaces boilerplate MouseRegion + GestureDetector + AnimatedScale.
class ScaleOnHover extends StatefulWidget {
  final Widget child;
  final double scaleOnHover;
  final double scaleOnPress;
  final Duration duration;
  final Curve curve;
  final VoidCallback? onTap;
  final MouseCursor cursor;

  const ScaleOnHover({
    super.key,
    required this.child,
    this.scaleOnHover = 1.02,
    this.scaleOnPress = 0.98,
    this.duration = AppConstants.animDurationFast,
    this.curve = AppCurves.easeOutExpo,
    this.onTap,
    this.cursor = SystemMouseCursors.click,
  });

  @override
  State<ScaleOnHover> createState() => _ScaleOnHoverState();
}

class _ScaleOnHoverState extends State<ScaleOnHover> {
  bool _isHovered = false;
  bool _isPressed = false;

  double get _scale {
    if (_isPressed) return widget.scaleOnPress;
    if (_isHovered) return widget.scaleOnHover;
    return 1.0;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.cursor,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _scale,
          duration: widget.duration,
          curve: widget.curve,
          child: widget.child,
        ),
      ),
    );
  }
}

/// A builder variant that exposes hover/press state to the child builder.
class ScaleOnHoverBuilder extends StatefulWidget {
  final Widget Function(BuildContext context, bool isHovered, bool isPressed) builder;
  final VoidCallback? onTap;
  final Duration duration;
  final Curve curve;
  final MouseCursor cursor;

  const ScaleOnHoverBuilder({
    super.key,
    required this.builder,
    this.onTap,
    this.duration = AppConstants.animDurationFast,
    this.curve = AppCurves.easeOutExpo,
    this.cursor = SystemMouseCursors.click,
  });

  @override
  State<ScaleOnHoverBuilder> createState() => _ScaleOnHoverBuilderState();
}

class _ScaleOnHoverBuilderState extends State<ScaleOnHoverBuilder> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.cursor,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isPressed ? 0.98 : (_isHovered ? 1.02 : 1.0),
          duration: widget.duration,
          curve: widget.curve,
          child: widget.builder(context, _isHovered, _isPressed),
        ),
      ),
    );
  }
}

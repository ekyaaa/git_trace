import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../core/theme_colors.dart';

class MonthNavigator extends StatelessWidget {
  final int month;
  final int year;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const MonthNavigator({
    super.key,
    required this.month,
    required this.year,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final date = DateTime(year, month);
    final monthName = DateFormat('MMMM yyyy', 'id_ID').format(date);
    final colors = ThemeColors.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _NavButton(icon: Icons.chevron_left, onTap: onPrevious),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: colors.surfaceLight,
            borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
            border: Border.all(
              color: colors.surfaceBorder.withValues(alpha: 0.6),
            ),
            boxShadow: colors.subtleShadow,
          ),
          child: Text(
            monthName.substring(0, 1).toUpperCase() + monthName.substring(1),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
        ),
        const SizedBox(width: 8),
        _NavButton(icon: Icons.chevron_right, onTap: onNext),
      ],
    );
  }
}

class _NavButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _NavButton({required this.icon, required this.onTap});

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.9 : 1.0,
          duration: AppConstants.animDurationFast,
          curve: AppCurves.easeOutExpo,
          child: AnimatedContainer(
            duration: AppConstants.animDurationFast,
            curve: AppCurves.easeOutExpo,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _hovered ? colors.surfaceLight : Colors.transparent,
              borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
              border: Border.all(
                color: _hovered ? colors.surfaceBorder : Colors.transparent,
              ),
              boxShadow: _hovered ? colors.subtleShadow : null,
            ),
            child: Icon(
              widget.icon,
              size: 20,
              color: _hovered ? colors.textPrimary : colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

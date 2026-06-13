import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

enum JFNeumorphicStyle { raised, flat, pressed }

class JFNeumorphicBox extends StatelessWidget {
  final Widget child;
  final JFNeumorphicStyle style;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final Color? color;
  final double intensity; // 0.0 – 1.0, controls shadow strength

  const JFNeumorphicBox({
    super.key,
    required this.child,
    this.style = JFNeumorphicStyle.raised,
    this.borderRadius = 16,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.color,
    this.intensity = 1.0,
  });

  List<BoxShadow> get _shadows {
    switch (style) {
      case JFNeumorphicStyle.raised:
        return [
          BoxShadow(
            color: AppColors.neumorphLight.withValues(alpha: 0.85 * intensity),
            offset: const Offset(-6, -6),
            blurRadius: 14,
          ),
          BoxShadow(
            color: AppColors.neumorphDark.withValues(alpha: 0.6 * intensity),
            offset: const Offset(6, 6),
            blurRadius: 14,
          ),
        ];
      case JFNeumorphicStyle.flat:
        return [
          BoxShadow(
            color: AppColors.neumorphLight.withValues(alpha: 0.55 * intensity),
            offset: const Offset(-4, -4),
            blurRadius: 8,
          ),
          BoxShadow(
            color: AppColors.neumorphDark.withValues(alpha: 0.4 * intensity),
            offset: const Offset(4, 4),
            blurRadius: 8,
          ),
        ];
      case JFNeumorphicStyle.pressed:
        return [
          BoxShadow(
            color: AppColors.neumorphDark.withValues(alpha: 0.5 * intensity),
            offset: const Offset(-3, -3),
            blurRadius: 6,
          ),
          BoxShadow(
            color: AppColors.neumorphLight.withValues(alpha: 0.8 * intensity),
            offset: const Offset(3, 3),
            blurRadius: 6,
          ),
        ];
    }
  }

  // Inner shadow for pressed state
  Decoration get _decoration {
    final baseColor = color ?? AppColors.neumorphBase;
    if (style == JFNeumorphicStyle.pressed) {
      return BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.neumorphInnerLight,
            AppColors.neumorphInnerDark,
          ],
        ),
        boxShadow: _shadows,
      );
    }
    return BoxDecoration(
      color: baseColor,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: _shadows,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      decoration: _decoration,
      child: child,
    );
  }
}

/// Neumorphic icon button — raised, animates to pressed on tap
class JFNeumorphicButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double size;
  final double borderRadius;
  final Color? color;

  const JFNeumorphicButton({
    super.key,
    required this.child,
    this.onTap,
    this.size = 48,
    this.borderRadius = 14,
    this.color,
  });

  @override
  State<JFNeumorphicButton> createState() => _JFNeumorphicButtonState();
}

class _JFNeumorphicButtonState extends State<JFNeumorphicButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: widget.color ?? AppColors.neumorphBase,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: _pressed
              ? [
                  BoxShadow(
                    color: AppColors.neumorphDark.withValues(alpha: 0.5),
                    offset: const Offset(-2, -2),
                    blurRadius: 5,
                  ),
                  BoxShadow(
                    color: AppColors.neumorphLight.withValues(alpha: 0.8),
                    offset: const Offset(2, 2),
                    blurRadius: 5,
                  ),
                ]
              : [
                  BoxShadow(
                    color: AppColors.neumorphLight.withValues(alpha: 0.85),
                    offset: const Offset(-5, -5),
                    blurRadius: 12,
                  ),
                  BoxShadow(
                    color: AppColors.neumorphDark.withValues(alpha: 0.6),
                    offset: const Offset(5, 5),
                    blurRadius: 12,
                  ),
                ],
        ),
        child: Center(child: widget.child),
      ),
    );
  }
}

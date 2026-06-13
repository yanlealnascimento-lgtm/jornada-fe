import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

enum JFButtonVariant { primary, secondary, danger }
enum JFButtonSize { large, medium, small }

class JFButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final JFButtonVariant variant;
  final JFButtonSize size;
  final bool isLoading;
  final Widget? icon;

  const JFButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = JFButtonVariant.primary,
    this.size = JFButtonSize.large,
    this.isLoading = false,
    this.icon,
  });

  @override
  State<JFButton> createState() => _JFButtonState();
}

class _JFButtonState extends State<JFButton> with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _pressAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );
    _pressAnimation = Tween<double>(begin: 0, end: 4).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  Color get _backgroundColor {
    if (widget.onPressed == null) return AppColors.border;
    switch (widget.variant) {
      case JFButtonVariant.primary:
        return AppColors.navy; // #1A2E4A — paleta JourneyFaith
      case JFButtonVariant.secondary:
        return AppColors.background;
      case JFButtonVariant.danger:
        return AppColors.incorrect;
    }
  }

  Color get _shadowColor {
    if (widget.onPressed == null) return Colors.transparent;
    switch (widget.variant) {
      case JFButtonVariant.primary:
        return const Color(0xFF0F1D30); // sombra do azul profundo
      case JFButtonVariant.secondary:
        return AppColors.border;
      case JFButtonVariant.danger:
        return AppColors.buttonShadowRed;
    }
  }

  Color get _textColor {
    if (widget.onPressed == null) return AppColors.textHint;
    switch (widget.variant) {
      case JFButtonVariant.primary:
        return Colors.white;
      case JFButtonVariant.secondary:
        return AppColors.primary;
      case JFButtonVariant.danger:
        return Colors.white;
    }
  }

  double get _height {
    switch (widget.size) {
      case JFButtonSize.large:
        return 56;
      case JFButtonSize.medium:
        return 46;
      case JFButtonSize.small:
        return 38;
    }
  }

  TextStyle get _textStyle {
    switch (widget.size) {
      case JFButtonSize.large:
        return AppTypography.buttonLarge;
      case JFButtonSize.medium:
        return AppTypography.buttonMedium;
      case JFButtonSize.small:
        return AppTypography.buttonMedium.copyWith(fontSize: 13);
    }
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed == null || widget.isLoading) return;
    setState(() => _isPressed = true);
    _pressController.forward();
    HapticFeedback.lightImpact();
  }

  void _onTapUp(TapUpDetails details) {
    if (_isPressed) {
      setState(() => _isPressed = false);
      _pressController.reverse();
    }
  }

  void _onTapCancel() {
    if (_isPressed) {
      setState(() => _isPressed = false);
      _pressController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null || widget.isLoading;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: isDisabled ? null : widget.onPressed,
      child: AnimatedBuilder(
        animation: _pressAnimation,
        builder: (context, child) {
          final pressOffset = _pressAnimation.value;
          return Transform.translate(
            offset: Offset(0, pressOffset),
            child: Container(
              height: _height,
              decoration: BoxDecoration(
                color: _backgroundColor,
                borderRadius: BorderRadius.circular(14),
                border: widget.variant == JFButtonVariant.secondary
                    ? Border.all(color: AppColors.primary, width: 2)
                    : null,
                boxShadow: isDisabled
                    ? null
                    : widget.variant == JFButtonVariant.secondary
                        ? [
                            BoxShadow(
                              color: const Color(0xFFFFFFFF).withValues(alpha: 0.85),
                              offset: Offset(-4 + pressOffset * 0.5, -4 + pressOffset * 0.5),
                              blurRadius: 10,
                            ),
                            BoxShadow(
                              color: const Color(0xFFC8D0D8).withValues(alpha: 0.6),
                              offset: Offset(4 - pressOffset * 0.5, 4 - pressOffset * 0.5),
                              blurRadius: 10,
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: _shadowColor,
                              offset: Offset(0, 4 - pressOffset),
                              blurRadius: 0,
                            ),
                          ],
              ),
              child: Center(
                child: widget.isLoading
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(_textColor),
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.icon != null) ...[
                            widget.icon!,
                            const SizedBox(width: 8),
                          ],
                          Text(
                            widget.label,
                            style: _textStyle.copyWith(color: _textColor),
                          ),
                        ],
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}

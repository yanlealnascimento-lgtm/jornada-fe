import 'package:flutter/material.dart';
import '../../../core/theme/app_typography.dart';

class DoveDialogueBubble extends StatefulWidget {
  final String text;
  final String? subtextBelowDove;
  final double doveSize;

  const DoveDialogueBubble({
    super.key,
    required this.text,
    this.subtextBelowDove,
    this.doveSize = 140,
  });

  @override
  State<DoveDialogueBubble> createState() => _DoveDialogueBubbleState();
}

class _DoveDialogueBubbleState extends State<DoveDialogueBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Speech bubble
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomRight: Radius.circular(20),
              bottomLeft: Radius.circular(6),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF000000).withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            widget.text,
            style: AppTypography.bodyLarge.copyWith(
              fontSize: 17,
              height: 1.5,
              color: const Color(0xFF1A2E4A),
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 16),
        // Dove image with pulse animation
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: child,
            );
          },
          child: Image.asset(
            'assets/images/dove_icon.png',
            width: widget.doveSize,
            height: widget.doveSize,
          ),
        ),
        if (widget.subtextBelowDove != null) ...[
          const SizedBox(height: 8),
          Text(
            widget.subtextBelowDove!,
            style: AppTypography.bodyMedium.copyWith(
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

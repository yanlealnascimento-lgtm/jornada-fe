import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class JFHeartIndicator extends StatefulWidget {
  final int heartsCount;
  final int maxHearts;
  final double size;

  const JFHeartIndicator({
    super.key,
    required this.heartsCount,
    this.maxHearts = 3,
    this.size = 22,
  });

  @override
  State<JFHeartIndicator> createState() => _JFHeartIndicatorState();
}

class _JFHeartIndicatorState extends State<JFHeartIndicator> with TickerProviderStateMixin {
  late List<AnimationController> _shakeControllers;
  late List<Animation<double>> _shakeAnimations;
  int _previousCount = 3;

  @override
  void initState() {
    super.initState();
    _previousCount = widget.heartsCount;
    _shakeControllers = List.generate(
      widget.maxHearts,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      ),
    );
    _shakeAnimations = _shakeControllers.map((ctrl) {
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: ctrl, curve: Curves.elasticOut),
      );
    }).toList();
  }

  @override
  void didUpdateWidget(JFHeartIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.heartsCount < _previousCount) {
      // Animar o coração perdido
      final lostIndex = widget.heartsCount;
      if (lostIndex < widget.maxHearts) {
        _shakeControllers[lostIndex].forward(from: 0);
      }
    }
    _previousCount = widget.heartsCount;
  }

  @override
  void dispose() {
    for (final ctrl in _shakeControllers) {
      ctrl.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.maxHearts, (index) {
        final isFull = index < widget.heartsCount;
        return AnimatedBuilder(
          animation: _shakeAnimations[index],
          builder: (context, child) {
            final shake = _shakeAnimations[index].value;
            return Transform.translate(
              offset: Offset(0, -shake * 4 * (1 - shake)),
              child: Padding(
                padding: const EdgeInsets.only(right: 2),
                child: Icon(
                  isFull ? Icons.favorite : Icons.favorite_border,
                  color: isFull ? AppColors.heartColor : (isDark ? const Color(0xFF5A7A8A) : AppColors.textHint),
                  size: widget.size,
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

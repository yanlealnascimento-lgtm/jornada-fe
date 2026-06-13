import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/trail_constants.dart';
import '../../../shared/models/lesson_model.dart';
import '../../../shared/models/lesson_progress_model.dart';

/// Duolingo-inspired lesson node with:
/// - 3D bottom shadow for tactile depth
/// - Glowing pulse on active node
/// - Segmented stage ring arcs
/// - Dark mode adaptive
class LessonNode extends StatefulWidget {
  final LessonModel lesson;
  final LessonProgressModel? progress;
  final Color unitColor;
  final VoidCallback onTap;

  const LessonNode({
    super.key,
    required this.lesson,
    this.progress,
    required this.unitColor,
    required this.onTap,
  });

  @override
  State<LessonNode> createState() => _LessonNodeState();
}

class _LessonNodeState extends State<LessonNode>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
    if (_isActive) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant LessonNode oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isActive && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!_isActive && _pulse.isAnimating) {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  bool get _isActive =>
      widget.lesson.status == LessonStatus.available ||
      widget.lesson.status == LessonStatus.current;
  bool get _isLocked => widget.lesson.status == LessonStatus.locked;
  bool get _isCompleted => widget.lesson.status == LessonStatus.completed;

  LessonProgressModel get _progress =>
      widget.progress ??
      LessonProgressModel.initial(
        widget.lesson.id,
        stagesTotal: widget.lesson.stagesCount > 0
            ? widget.lesson.stagesCount
            : 1,
      );

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _mainColor {
    if (_isCompleted) return AppColors.nodeCompleted;
    if (_isActive) return widget.unitColor;
    return _isDark ? AppColors.nodeLockedDarkMode : AppColors.nodeLocked;
  }

  Color get _shadowColor {
    if (_isCompleted) return AppColors.nodeCompletedDark;
    if (_isActive) {
      final hsl = HSLColor.fromColor(widget.unitColor);
      return hsl.withLightness((hsl.lightness - 0.15).clamp(0.0, 1.0)).toColor();
    }
    return _isDark ? const Color(0xFF2A3A44) : AppColors.nodeLockedDark;
  }

  IconData get _icon {
    if (widget.lesson.isReview) return Icons.refresh_rounded;
    if (_isCompleted) return Icons.check_rounded;
    if (_isLocked) return Icons.lock_rounded;
    return Icons.menu_book_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final size = TrailConstants.nodeSize;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _isLocked ? null : widget.onTap,
      child: AnimatedBuilder(
        animation: _pulseAnim,
        builder: (context, child) => Transform.scale(
          scale: _isActive ? _pulseAnim.value : 1.0,
          child: Opacity(
            opacity: _isLocked ? 0.45 : 1.0,
            child: SizedBox(
              width: size + 24,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Stage ring + 3D circle node
                  SizedBox(
                    width: size + 24,
                    height: size + 24,
                    child: CustomPaint(
                      painter: _StageRingPainter(
                        stagesTotal: _progress.stagesTotal,
                        stagesCompleted: _progress.stagesCompleted,
                        isCompleted: _isCompleted,
                        isLocked: _isLocked,
                        activeColor: widget.unitColor,
                        nodeSize: size,
                        isDark: _isDark,
                      ),
                      child: Center(
                        child: Container(
                          width: size,
                          height: size + (_isLocked ? 0 : TrailConstants.nodeShadowHeight),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _shadowColor,
                          ),
                          child: Padding(
                            padding: EdgeInsets.only(
                              bottom: _isLocked ? 0 : TrailConstants.nodeShadowHeight,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: _mainColor,
                                shape: BoxShape.circle,
                                boxShadow: _isActive
                                    ? [
                                        BoxShadow(
                                          color: _mainColor.withValues(alpha: 0.5),
                                          blurRadius: 20,
                                          spreadRadius: 3,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Center(
                                child: Icon(
                                  _icon,
                                  size: _isCompleted ? 32 : 28,
                                  color: _isLocked
                                      ? (_isDark
                                          ? const Color(0xFF5A6A74)
                                          : AppColors.textSecondary)
                                      : Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Stage dots
                  if (_progress.isInProgress && _progress.stagesTotal > 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: _StageDots(
                        total: _progress.stagesTotal,
                        completed: _progress.stagesCompleted,
                        activeColor: widget.unitColor,
                        isDark: _isDark,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Stage Ring Painter ───────────────────────────────────────────────────────

class _StageRingPainter extends CustomPainter {
  final int stagesTotal;
  final int stagesCompleted;
  final bool isCompleted;
  final bool isLocked;
  final Color activeColor;
  final double nodeSize;
  final bool isDark;

  _StageRingPainter({
    required this.stagesTotal,
    required this.stagesCompleted,
    required this.isCompleted,
    required this.isLocked,
    required this.activeColor,
    required this.nodeSize,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final center = Offset(canvasSize.width / 2, canvasSize.height / 2);
    final radius = nodeSize / 2 + TrailConstants.ringWidth + TrailConstants.ringPadding;
    final emptyColor = isDark ? const Color(0xFF3A4A54) : const Color(0xFFE5E7EB);

    if (stagesTotal <= 1) {
      final paint = Paint()
        ..color = isCompleted
            ? AppColors.nodeCompleted
            : (isLocked ? emptyColor : activeColor)
        ..strokeWidth = TrailConstants.ringWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawCircle(center, radius, paint);
      return;
    }

    final totalGap = TrailConstants.ringGap * stagesTotal;
    final totalArc = 2 * pi - totalGap;
    final arcLength = totalArc / stagesTotal;
    const startOffset = -pi / 2;

    for (int i = 0; i < stagesTotal; i++) {
      final startAngle = startOffset + i * (arcLength + TrailConstants.ringGap);
      final stageDone = isCompleted || i < stagesCompleted;

      Color arcColor;
      if (isCompleted) {
        arcColor = AppColors.nodeCompleted;
      } else if (stageDone) {
        arcColor = activeColor;
      } else {
        arcColor = emptyColor;
      }

      final paint = Paint()
        ..color = arcColor
        ..strokeWidth = TrailConstants.ringWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        arcLength,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StageRingPainter old) =>
      stagesTotal != old.stagesTotal ||
      stagesCompleted != old.stagesCompleted ||
      isCompleted != old.isCompleted ||
      isLocked != old.isLocked ||
      isDark != old.isDark;
}

// ── Stage Dots ───────────────────────────────────────────────────────────────

class _StageDots extends StatelessWidget {
  final int total;
  final int completed;
  final Color activeColor;
  final bool isDark;

  const _StageDots({
    required this.total,
    required this.completed,
    required this.activeColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(total, (i) {
        final done = i < completed;
        return Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done
                ? activeColor
                : (isDark ? const Color(0xFF3A4A54) : const Color(0xFFE5E7EB)),
            border: done
                ? null
                : Border.all(
                    color: isDark
                        ? const Color(0xFF4A5A64)
                        : const Color(0xFFD1D5DB),
                    width: 1,
                  ),
          ),
        );
      }),
    );
  }
}

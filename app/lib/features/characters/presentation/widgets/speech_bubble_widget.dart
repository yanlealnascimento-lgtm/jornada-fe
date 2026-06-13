import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// A speech‑bubble overlay that displays [text] with a typewriter effect.
///
/// The bubble background uses [color] and the text is rendered in white.
/// A small triangular pointer is drawn at the bottom‑left so that the
/// bubble visually connects to the character avatar beneath it.
class SpeechBubbleWidget extends StatelessWidget {
  const SpeechBubbleWidget({
    super.key,
    required this.text,
    required this.color,
    this.onComplete,
  });

  final String text;
  final Color color;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Bubble body ──
        Container(
          constraints: const BoxConstraints(maxWidth: 260),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: AnimatedTextKit(
            animatedTexts: [
              TypewriterAnimatedText(
                text,
                textStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.4,
                ),
                speed: const Duration(milliseconds: 40),
              ),
            ],
            isRepeatingAnimation: false,
            onFinished: onComplete,
            displayFullTextOnTap: true,
            totalRepeatCount: 1,
          ),
        ),

        // ── Triangle pointer ──
        Padding(
          padding: const EdgeInsets.only(left: 20),
          child: CustomPaint(
            size: const Size(16, 10),
            painter: _TrianglePainter(color: color),
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(duration: 300.ms, curve: Curves.easeOut)
        .slideY(begin: -0.15, end: 0, duration: 300.ms, curve: Curves.easeOut);
  }
}

/// Draws a small downward‑pointing triangle (the bubble pointer).
class _TrianglePainter extends CustomPainter {
  _TrianglePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width * 0.3, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter old) => old.color != color;
}

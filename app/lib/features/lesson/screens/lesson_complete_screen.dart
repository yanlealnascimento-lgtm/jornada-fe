import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// Shown after completing a stage or the entire lesson.
/// Duolingo-style celebration with logo, PF, accuracy, and time.
class LessonCompleteScreen extends StatefulWidget {
  final int pfEarned;
  final int errorCount;
  final String lessonId;
  final int accuracyPercent;
  final int elapsedSeconds;
  final bool isLastStage;

  const LessonCompleteScreen({
    super.key,
    required this.pfEarned,
    required this.errorCount,
    required this.lessonId,
    this.accuracyPercent = 100,
    this.elapsedSeconds = 0,
    this.isLastStage = true,
  });

  @override
  State<LessonCompleteScreen> createState() => _LessonCompleteScreenState();
}

class _LessonCompleteScreenState extends State<LessonCompleteScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late Animation<double> _logoScale;
  late AnimationController _cardsController;
  late Animation<double> _cardsFade;

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _cardsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _cardsFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _cardsController, curve: Curves.easeOut),
    );

    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _cardsController.forward();
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _cardsController.dispose();
    super.dispose();
  }

  bool get _isPerfect => widget.errorCount == 0;

  String get _title {
    if (widget.isLastStage) {
      return _isPerfect ? 'Perfeito!' : 'Lição Concluída!';
    }
    return _isPerfect ? 'Perfeito!' : 'Etapa Concluída!';
  }

  String get _elapsedFormatted {
    final minutes = widget.elapsedSeconds ~/ 60;
    final seconds = widget.elapsedSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String get _accuracyLabel {
    if (widget.accuracyPercent >= 100) return 'INCRÍVEL';
    if (widget.accuracyPercent >= 80) return 'ÓTIMO';
    if (widget.accuracyPercent >= 60) return 'BOM';
    return 'CONTINUE';
  }

  String get _timeLabel {
    if (widget.elapsedSeconds < 60) return 'SUPER ÁGIL';
    if (widget.elapsedSeconds < 120) return 'RÁPIDO';
    return 'DEDICADO';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF1B2838),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const Spacer(flex: 2),

                // Logo with bounce animation
                AnimatedBuilder(
                  animation: _logoScale,
                  builder: (context, child) => Transform.scale(
                    scale: _logoScale.value,
                    child: child,
                  ),
                  child: Image.asset(
                    'assets/images/dove_icon.png',
                    width: 140,
                    height: 140,
                  ),
                ),

                const SizedBox(height: 28),

                // Title
                Text(
                  _title,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    fontFamily: 'Nunito',
                  ),
                ),

                const SizedBox(height: 40),

                // Stats cards row (fade in)
                AnimatedBuilder(
                  animation: _cardsFade,
                  builder: (context, child) => Opacity(
                    opacity: _cardsFade.value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - _cardsFade.value)),
                      child: child,
                    ),
                  ),
                  child: Row(
                    children: [
                      // PF card
                      Expanded(
                        child: _StatCard(
                          label: 'TOTAL DE PF',
                          value: '+${widget.pfEarned}',
                          icon: Icons.bolt_rounded,
                          borderColor: const Color(0xFFF59E0B),
                          bgColor: const Color(0xFFFEF3C7),
                          iconColor: const Color(0xFFF59E0B),
                          valueColor: const Color(0xFF92400E),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Accuracy card
                      Expanded(
                        child: _StatCard(
                          label: _accuracyLabel,
                          value: '${widget.accuracyPercent}%',
                          icon: Icons.check_circle_rounded,
                          borderColor: const Color(0xFF84CC16),
                          bgColor: const Color(0xFFECFCCB),
                          iconColor: const Color(0xFF65A30D),
                          valueColor: const Color(0xFF3F6212),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Time card
                      Expanded(
                        child: _StatCard(
                          label: _timeLabel,
                          value: _elapsedFormatted,
                          icon: Icons.schedule_rounded,
                          borderColor: const Color(0xFF38BDF8),
                          bgColor: const Color(0xFFE0F2FE),
                          iconColor: const Color(0xFF0284C7),
                          valueColor: const Color(0xFF075985),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 3),

                // CTA button
                AnimatedBuilder(
                  animation: _cardsFade,
                  builder: (context, child) => Opacity(
                    opacity: _cardsFade.value,
                    child: child,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => context.go('/streak-celebration'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF58CC02),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'RECEBER PF',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Stat Card (Duolingo-style) ──────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color borderColor;
  final Color bgColor;
  final Color iconColor;
  final Color valueColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.borderColor,
    required this.bgColor,
    required this.iconColor,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: valueColor,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: iconColor),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: valueColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

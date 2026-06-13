import 'dart:async';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/jf_button.dart';

class PfCelebrationScreen extends StatefulWidget {
  final int pfEarned;

  const PfCelebrationScreen({super.key, required this.pfEarned});

  @override
  State<PfCelebrationScreen> createState() => _PfCelebrationScreenState();
}

class _PfCelebrationScreenState extends State<PfCelebrationScreen> {
  late final ConfettiController _confettiController;
  int _displayedPf = 0;
  Timer? _pfTimer;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    _confettiController.play();

    // Animated PF counter
    final stepCount = widget.pfEarned;
    if (stepCount > 0) {
      int current = 0;
      _pfTimer = Timer.periodic(const Duration(milliseconds: 60), (timer) {
        current++;
        if (current >= stepCount) {
          timer.cancel();
          current = stepCount;
        }
        if (mounted) setState(() => _displayedPf = current);
      });
    }
  }

  @override
  void dispose() {
    _pfTimer?.cancel();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F7FF),
      body: Stack(
        children: [
          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              numberOfParticles: 30,
              maxBlastForce: 20,
              minBlastForce: 8,
              emissionFrequency: 0.06,
              gravity: 0.2,
              colors: const [
                AppColors.primary,
                AppColors.xpColor,
                AppColors.correct,
                AppColors.streakColor,
              ],
            ),
          ),
          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  // Dove
                  Image.asset(
                    'assets/images/dove_icon.png',
                    width: 140,
                    height: 140,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '\uD83C\uDF89 Incr\u00edvel!',
                    style: AppTypography.displayLarge.copyWith(
                      fontSize: 34,
                      color: const Color(0xFF1A2E4A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Voc\u00ea completou sua primeira li\u00e7\u00e3o!',
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  // PF badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 18),
                    decoration: BoxDecoration(
                      color: AppColors.xpColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.xpColor.withValues(alpha: 0.4),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('\u2728',
                            style: TextStyle(fontSize: 28)),
                        const SizedBox(width: 10),
                        Text(
                          '+$_displayedPf PF',
                          style: AppTypography.displayMedium.copyWith(
                            color: const Color(0xFFD4A017),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Streak badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.streakColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      '\uD83D\uDD25 Devo\u00e7\u00e3o: 1 dia',
                      style: AppTypography.headingMedium.copyWith(
                        color: AppColors.streakColor,
                      ),
                    ),
                  ),
                  const Spacer(flex: 3),
                  JFButton(
                    label: 'CONTINUAR',
                    onPressed: () => context.go('/onboarding/streak'),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

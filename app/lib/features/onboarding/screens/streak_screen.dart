import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/jf_button.dart';
import '../models/onboarding_data.dart';

class StreakOnboardingScreen extends ConsumerWidget {
  const StreakOnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(onboardingDataProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F7FF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              // Flame icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.streakColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('\uD83D\uDD25',
                      style: TextStyle(fontSize: 64)),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Sua Devoção começou!',
                style: AppTypography.displayMedium.copyWith(
                  color: const Color(0xFF1A2E4A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.streakColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '1 dia seguido \uD83D\uDD25',
                  style: AppTypography.headingLarge.copyWith(
                    color: AppColors.streakColor,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Sua meta: ${data.dailyGoalMinutes} min/dia',
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              // Quote
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color:
                          const Color(0xFF000000).withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '"Seja constante na oração"\n— Rm 12:12',
                  style: AppTypography.bodyLarge.copyWith(
                    fontStyle: FontStyle.italic,
                    color: const Color(0xFF1A2E4A),
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const Spacer(flex: 3),
              JFButton(
                label: 'CONTINUAR',
                onPressed: () =>
                    context.go('/onboarding/create-account'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/jf_button.dart';

class CreateAccountPromptScreen extends StatelessWidget {
  const CreateAccountPromptScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F7FF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              // Dove happy
              Image.asset(
                'assets/images/dove_icon.png',
                width: 120,
                height: 120,
              ),
              const SizedBox(height: 24),
              Text(
                'Salve seu progresso!',
                style: AppTypography.displayMedium.copyWith(
                  color: const Color(0xFF1A2E4A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Summary badges
              Container(
                width: double.infinity,
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
                child: Column(
                  children: [
                    _badgeRow('\u2728', '10 Manás'),
                    const SizedBox(height: 10),
                    _badgeRow(
                        '\uD83D\uDD25', '1 dia de devoção'),
                    const SizedBox(height: 10),
                    _badgeRow(
                        '\uD83D\uDCD6', 'Lição 1 concluída'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Não perca seu progresso!\nCrie uma conta grátis',
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 3),
              JFButton(
                label: 'CRIAR CONTA GRÁTIS',
                onPressed: () => context.go('/onboarding/register'),
              ),
              const SizedBox(height: 12),
              JFButton(
                label: 'FAZER LOGIN',
                variant: JFButtonVariant.secondary,
                onPressed: () => context.go('/login'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/home'),
                child: Text(
                  'Depois \u2192',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _badgeRow(String emoji, String text) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 12),
        Text(
          text,
          style: AppTypography.headingMedium.copyWith(
            color: const Color(0xFF1A2E4A),
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

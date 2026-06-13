import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/providers/user_provider.dart';
import '../../shared/widgets/jf_button.dart';

class DailyGoalScreen extends ConsumerStatefulWidget {
  const DailyGoalScreen({super.key});

  @override
  ConsumerState<DailyGoalScreen> createState() => _DailyGoalScreenState();
}

class _DailyGoalScreenState extends ConsumerState<DailyGoalScreen> {
  int _selectedMinutes = 10; // Padrão recomendado

  static const List<_GoalOption> _options = [
    _GoalOption(emoji: '😊', label: '5 minutos', subtitle: 'Uma vela acesa', minutes: 5),
    _GoalOption(emoji: '🌟', label: '10 minutos', subtitle: 'Uma boa prática', minutes: 10, isRecommended: true),
    _GoalOption(emoji: '💪', label: '15 minutos', subtitle: 'Devoto', minutes: 15),
    _GoalOption(emoji: '🔥', label: '20 minutos+', subtitle: 'Fogo do Espírito', minutes: 20),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Caleb pequeno
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(child: Text('⚔️', style: TextStyle(fontSize: 26))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Quanto tempo por dia para sua fé?',
                      style: AppTypography.headingLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Expanded(
                child: ListView(
                  children: _options.map((option) {
                    final isSelected = _selectedMinutes == option.minutes;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedMinutes = option.minutes),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primaryLight : AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.border,
                            width: isSelected ? 2 : 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(option.emoji, style: const TextStyle(fontSize: 28)),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        option.label,
                                        style: AppTypography.headingMedium.copyWith(
                                          color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                        ),
                                      ),
                                      if (option.isRecommended) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.xpColor,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'Recomendado',
                                            style: AppTypography.caption.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  Text(
                                    option.subtitle,
                                    style: AppTypography.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle, color: AppColors.primary, size: 22),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              JFButton(
                label: 'Continuar',
                onPressed: () {
                  ref.read(onboardingDataProvider.notifier).setDailyGoal(_selectedMinutes);
                  context.push('/onboarding/register');
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoalOption {
  final String emoji;
  final String label;
  final String subtitle;
  final int minutes;
  final bool isRecommended;
  const _GoalOption({
    required this.emoji,
    required this.label,
    required this.subtitle,
    required this.minutes,
    this.isRecommended = false,
  });
}

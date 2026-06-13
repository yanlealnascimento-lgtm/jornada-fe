import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/providers/user_provider.dart';

class DailyGoalSettingsScreen extends ConsumerStatefulWidget {
  const DailyGoalSettingsScreen({super.key});

  @override
  ConsumerState<DailyGoalSettingsScreen> createState() => _DailyGoalSettingsScreenState();
}

class _DailyGoalSettingsScreenState extends ConsumerState<DailyGoalSettingsScreen> {
  int? _selectedMinutes;

  static const List<_GoalOption> _options = [
    _GoalOption(emoji: '😊', label: '5 minutos', subtitle: 'Uma vela acesa', minutes: 5),
    _GoalOption(emoji: '🌟', label: '10 minutos', subtitle: 'Uma boa prática', minutes: 10, isRecommended: true),
    _GoalOption(emoji: '💪', label: '15 minutos', subtitle: 'Devoto', minutes: 15),
    _GoalOption(emoji: '🔥', label: '20 minutos+', subtitle: 'Fogo do Espírito', minutes: 20),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider).valueOrNull;
      if (user != null && mounted) {
        setState(() => _selectedMinutes = user.dailyGoalMinutes);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(currentUserProvider).valueOrNull;
    final currentGoal = _selectedMinutes ?? user?.dailyGoalMinutes ?? 10;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Meta Diária'),
        actions: [
          TextButton(
            onPressed: () => _save(currentGoal),
            child: Text(
              'Salvar',
              style: AppTypography.buttonMedium.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(child: Text('⚔️', style: TextStyle(fontSize: 26))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Quanto tempo por dia para sua fé?',
                    style: AppTypography.headingLarge.copyWith(
                      color: isDark ? AppColors.darkTextPrimary : null,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Expanded(
              child: ListView(
                children: _options.map((option) {
                  final isSelected = currentGoal == option.minutes;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedMinutes = option.minutes),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark ? AppColors.primary.withValues(alpha: 0.15) : AppColors.primaryLight)
                            : (isDark ? AppColors.darkSurface : AppColors.surface),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.border),
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
                                        color: isSelected
                                            ? AppColors.primary
                                            : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
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
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: isDark ? AppColors.darkTextSecond : null,
                                  ),
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
          ],
        ),
      ),
    );
  }

  Future<void> _save(int minutes) async {
    try {
      await ref.read(currentUserProvider.notifier).updateProfile(
        dailyGoalMinutes: minutes,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Meta diária atualizada!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e')),
        );
      }
    }
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

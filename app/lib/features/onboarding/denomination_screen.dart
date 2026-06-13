import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/providers/user_provider.dart';
import '../../shared/widgets/jf_button.dart';

class DenominationScreen extends ConsumerStatefulWidget {
  const DenominationScreen({super.key});

  @override
  ConsumerState<DenominationScreen> createState() => _DenominationScreenState();
}

class _DenominationScreenState extends ConsumerState<DenominationScreen> {
  String? _selected;

  static const List<_DenominationOption> _options = [
    _DenominationOption(emoji: '✝️', label: 'Evangélico', value: 'evangelical'),
    _DenominationOption(emoji: '✝️', label: 'Católico', value: 'catholic'),
    _DenominationOption(emoji: '✡️', label: 'Espírita Cristão', value: 'spiritist'),
    _DenominationOption(emoji: '🕊️', label: 'Protestante', value: 'protestant'),
    _DenominationOption(emoji: '🌿', label: 'Outra tradição', value: 'other'),
    _DenominationOption(emoji: '❓', label: 'Prefiro não dizer', value: null),
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
              Text('Qual é a sua tradição?', style: AppTypography.displayMedium),
              const SizedBox(height: 6),
              Text(
                'Isso é opcional e não muda o conteúdo do app',
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: 28),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.4,
                  ),
                  itemCount: _options.length,
                  itemBuilder: (context, index) {
                    final option = _options[index];
                    final isSelected = _selected == option.value;
                    return GestureDetector(
                      onTap: () => setState(() => _selected = option.value),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primaryLight : AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.border,
                            width: isSelected ? 2 : 1.5,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(option.emoji, style: const TextStyle(fontSize: 30)),
                            const SizedBox(height: 6),
                            Text(
                              option.label,
                              style: AppTypography.label.copyWith(
                                color: isSelected ? AppColors.primary : AppColors.textPrimary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              JFButton(
                label: 'Continuar',
                onPressed: () {
                  ref.read(onboardingDataProvider.notifier).setDenomination(_selected);
                  context.push('/onboarding/daily-goal');
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

class _DenominationOption {
  final String emoji;
  final String label;
  final String? value;
  const _DenominationOption({required this.emoji, required this.label, this.value});
}

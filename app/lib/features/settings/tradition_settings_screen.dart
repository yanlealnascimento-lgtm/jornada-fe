import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/providers/user_provider.dart';

class TraditionSettingsScreen extends ConsumerStatefulWidget {
  const TraditionSettingsScreen({super.key});

  @override
  ConsumerState<TraditionSettingsScreen> createState() => _TraditionSettingsScreenState();
}

class _TraditionSettingsScreenState extends ConsumerState<TraditionSettingsScreen> {
  String? _selected;

  static const List<_TraditionOption> _options = [
    _TraditionOption(emoji: '✝️', label: 'Evangélico', value: 'evangelical'),
    _TraditionOption(emoji: '✝️', label: 'Católico', value: 'catholic'),
    _TraditionOption(emoji: '✡️', label: 'Espírita Cristão', value: 'spiritist'),
    _TraditionOption(emoji: '🕊️', label: 'Protestante', value: 'protestant'),
    _TraditionOption(emoji: '🌿', label: 'Outra tradição', value: 'other'),
    _TraditionOption(emoji: '❓', label: 'Prefiro não dizer', value: null),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider).valueOrNull;
      if (user != null && mounted) {
        setState(() => _selected = user.denomination);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Tradição Cristã'),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(
              'Salvar',
              style: AppTypography.buttonMedium.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                'Qual é a sua tradição?',
                style: AppTypography.displayMedium.copyWith(
                  color: isDark ? AppColors.darkTextPrimary : null,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Isso é opcional e não muda o conteúdo do app',
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? AppColors.darkTextSecond : null,
                ),
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
                          color: isSelected
                              ? (isDark ? AppColors.primary.withValues(alpha: 0.15) : AppColors.primaryLight)
                              : (isDark ? AppColors.darkSurface : AppColors.surface),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.border),
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
                                color: isSelected
                                    ? AppColors.primary
                                    : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
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
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    try {
      await ref.read(currentUserProvider.notifier).updateProfile(
        denomination: _selected,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tradição atualizada!')),
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

class _TraditionOption {
  final String emoji;
  final String label;
  final String? value;
  const _TraditionOption({required this.emoji, required this.label, this.value});
}

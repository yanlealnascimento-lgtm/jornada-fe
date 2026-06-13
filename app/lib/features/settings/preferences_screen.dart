import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class PreferencesScreen extends StatelessWidget {
  const PreferencesScreen({super.key});

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
        title: const Text('Preferências'),
      ),
      body: ListView(
        children: [
          _SectionTitle(title: 'Experiência', isDark: isDark),
          _PreferenceCard(
            isDark: isDark,
            children: [
              _SwitchTile(title: 'Efeitos sonoros', value: true, isDark: isDark, enabled: false),
              _divider(isDark),
              _SwitchTile(title: 'Vibração', value: true, isDark: isDark, enabled: false),
              _divider(isDark),
              _SwitchTile(title: 'Animações', value: true, isDark: isDark, enabled: false),
              _divider(isDark),
              _SwitchTile(title: 'Mensagens motivacionais', value: true, isDark: isDark, enabled: false),
              _divider(isDark),
              _SwitchTile(title: 'Exercícios de escuta', value: true, isDark: isDark, enabled: false),
              _divider(isDark),
              _SwitchTile(title: 'Missão dos amigos', value: true, isDark: isDark, enabled: false),
              _divider(isDark),
              _SwitchTile(title: 'Ofensivas dos amigos', value: true, isDark: isDark, enabled: false),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  static Widget _divider(bool isDark) {
    return Divider(
      height: 1,
      color: isDark ? AppColors.darkBorder : AppColors.border,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final bool isDark;
  const _SectionTitle({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Text(
        title,
        style: AppTypography.headingMedium.copyWith(
          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _PreferenceCard extends StatelessWidget {
  final bool isDark;
  final List<Widget> children;
  const _PreferenceCard({required this.isDark, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: Column(children: children),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String title;
  final bool value;
  final bool isDark;
  final bool enabled;
  const _SwitchTile({
    required this.title,
    required this.value,
    required this.isDark,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: enabled ? (_) {} : null,
            activeTrackColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

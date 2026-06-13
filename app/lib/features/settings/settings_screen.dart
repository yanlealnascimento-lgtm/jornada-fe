import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/providers/user_provider.dart';
import 'preferences_screen.dart';
import 'notifications_screen.dart';
import 'daily_goal_settings_screen.dart';
import 'tradition_settings_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Configurações'),
      ),
      body: ListView(
        children: [
          // ── CONTA ──────────────────────────────────────────────
          const _SectionHeader(title: 'Conta'),
          _SettingsItem(
            icon: Icons.tune_outlined,
            title: 'Preferências',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const PreferencesScreen())),
          ),
          _SettingsItem(
            icon: Icons.person_outline,
            title: 'Editar Perfil',
            onTap: () => context.push('/profile/edit'),
          ),
          _SettingsItem(
            icon: Icons.notifications_outlined,
            title: 'Notificações',
            subtitle: 'Lembretes de streak e conquistas',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen())),
          ),

          // ── APARÊNCIA ──────────────────────────────────────────
          const _SectionHeader(title: 'Aparência'),
          Consumer(
            builder: (context, ref, _) {
              final themeMode = ref.watch(themeModeProvider);
              final currentlyDark = themeMode == ThemeMode.dark;
              final notifier = ref.read(themeModeProvider.notifier);

              return _SettingsItem(
                icon: currentlyDark
                    ? Icons.wb_sunny_rounded
                    : Icons.dark_mode_rounded,
                title: currentlyDark ? 'Modo Claro' : 'Modo Escuro',
                subtitle: currentlyDark
                    ? 'Trocar para tema claro'
                    : 'Trocar para tema escuro',
                trailing: Switch.adaptive(
                  value: currentlyDark,
                  onChanged: (_) => notifier.toggle(),
                  activeTrackColor: AppColors.primary,
                ),
                onTap: () => notifier.toggle(),
              );
            },
          ),

          // ── APRENDIZADO ────────────────────────────────────────
          const _SectionHeader(title: 'Aprendizado'),
          Consumer(
            builder: (context, ref, _) {
              final user = ref.watch(currentUserProvider).valueOrNull;
              final minutes = user?.dailyGoalMinutes ?? 10;
              return _SettingsItem(
                icon: Icons.flag_outlined,
                title: 'Meta Diária',
                subtitle: '$minutes minutos por dia',
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const DailyGoalSettingsScreen())),
              );
            },
          ),
          Consumer(
            builder: (context, ref, _) {
              final user = ref.watch(currentUserProvider).valueOrNull;
              final denomination = user?.denomination;
              String? subtitle;
              if (denomination != null) {
                const labels = {
                  'evangelical': 'Evangélico',
                  'catholic': 'Católico',
                  'spiritist': 'Espírita Cristão',
                  'protestant': 'Protestante',
                  'other': 'Outra tradição',
                };
                subtitle = labels[denomination];
              }
              return _SettingsItem(
                icon: Icons.church_outlined,
                title: 'Tradição Cristã',
                subtitle: subtitle,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const TraditionSettingsScreen())),
              );
            },
          ),

          // ── SOCIAL ─────────────────────────────────────────────
          const _SectionHeader(title: 'Social'),
          _SettingsItem(
            icon: Icons.forum_outlined,
            title: 'Falar com Teólogo',
            trailing: _ComingSoonBadge(isDark: isDark),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Em desenvolvimento')),
              );
            },
          ),
          _SettingsItem(
            icon: Icons.videocam_outlined,
            title: 'Vídeo Chamada',
            trailing: _ComingSoonBadge(isDark: isDark),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Em desenvolvimento')),
              );
            },
          ),

          // ── SUPORTE ────────────────────────────────────────────
          const _SectionHeader(title: 'Suporte'),
          _SettingsItem(
            icon: Icons.help_outline,
            title: 'Central de Ajuda',
            onTap: () {},
          ),
          _SettingsItem(
            icon: Icons.rate_review_outlined,
            title: 'Fazer Comentários',
            onTap: () {},
          ),
          _SettingsItem(
            icon: Icons.description_outlined,
            title: 'Termos de Uso',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Em breve')),
              );
            },
          ),
          _SettingsItem(
            icon: Icons.policy_outlined,
            title: 'Política de Privacidade',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Em breve')),
              );
            },
          ),

          // ── SAIR DA CONTA ──────────────────────────────────────
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: OutlinedButton(
              onPressed: () => _showLogoutDialog(context, ref),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.incorrect,
                side: BorderSide(
                  color: isDark
                      ? const Color(0xFF7F1D1D)
                      : const Color(0xFFFECACA),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Sair da conta'),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        title: Text(
          'Sair da conta',
          style: AppTypography.headingMedium.copyWith(
            color: isDark ? AppColors.darkTextPrimary : null,
          ),
        ),
        content: Text(
          'Tem certeza que deseja sair da sua conta?',
          style: AppTypography.bodyMedium.copyWith(
            color: isDark ? AppColors.darkTextSecond : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: isDark ? AppColors.darkTextSecond : AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(currentUserProvider.notifier).logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
            child: const Text(
              'Sair',
              style: TextStyle(color: AppColors.incorrect),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Badge "Em breve" ─────────────────────────────────────────────────────────

class _ComingSoonBadge extends StatelessWidget {
  final bool isDark;
  const _ComingSoonBadge({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.primary.withValues(alpha: 0.15)
            : AppColors.primaryLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Em breve',
        style: AppTypography.caption.copyWith(
          color: AppColors.primary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Text(
        title.toUpperCase(),
        style: AppTypography.caption.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: isDark ? const Color(0xFF5A7A8A) : AppColors.textHint,
        ),
      ),
    );
  }
}

// ── Settings Item ────────────────────────────────────────────────────────────

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  const _SettingsItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title, style: AppTypography.bodyLarge.copyWith(
        color: isDark ? AppColors.darkTextPrimary : null,
      )),
      subtitle: subtitle != null
          ? Text(subtitle!, style: AppTypography.caption.copyWith(
              color: isDark ? AppColors.darkTextSecond : null,
            ))
          : null,
      trailing: trailing ?? Icon(Icons.arrow_forward_ios,
          size: 14, color: isDark ? const Color(0xFF5A7A8A) : AppColors.textHint),
      onTap: onTap,
    );
  }
}

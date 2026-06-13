import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

// ── Main Notifications Screen ────────────────────────────────────────────────

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

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
        title: const Text('Notificações'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          _NotifCard(
            isDark: isDark,
            children: [
              _NotifCategory(
                title: 'Lembretes',
                subtitle: 'Lembretes de prática diária e de ofensiva.',
                isDark: isDark,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const _RemindersScreen())),
              ),
              _divider(isDark),
              _NotifCategory(
                title: 'Amigos',
                subtitle: 'Atualizações sobre novos seguidores e conquistas dos seus amigos.',
                isDark: isDark,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const _FriendsNotifScreen())),
              ),
              _divider(isDark),
              _NotifCategory(
                title: 'Ligas',
                subtitle: 'Atualizações sobre o seu progresso na divisão.',
                isDark: isDark,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const _LeaguesNotifScreen())),
              ),
              _divider(isDark),
              _NotifCategory(
                title: 'Toques dos amigos',
                subtitle: 'Lembretes de quem você conhece.',
                isDark: isDark,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const _FriendNudgesNotifScreen())),
              ),
              _divider(isDark),
              _NotifCategory(
                title: 'Avisos',
                subtitle: 'Atualizações sobre novos recursos, promoções e eventos.',
                isDark: isDark,
                disabledCount: 1,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const _AnnouncementsNotifScreen())),
              ),
            ],
          ),
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

// ── Shared Widgets ───────────────────────────────────────────────────────────

class _NotifCard extends StatelessWidget {
  final bool isDark;
  final List<Widget> children;
  const _NotifCard({required this.isDark, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
      ),
      child: Column(children: children),
    );
  }
}

class _NotifCategory extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isDark;
  final VoidCallback onTap;
  final int disabledCount;

  const _NotifCategory({
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.onTap,
    this.disabledCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.caption.copyWith(
                      color: isDark ? AppColors.darkTextSecond : AppColors.textSecondary,
                    ),
                  ),
                  if (disabledCount > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      '$disabledCount notificação desativada',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: isDark ? const Color(0xFF5A7A8A) : AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Toggle icon buttons (push / email) ───────────────────────────────────────

class _ChannelToggle extends StatelessWidget {
  final IconData icon;
  final bool active;
  final bool isDark;
  final VoidCallback? onTap;

  const _ChannelToggle({
    required this.icon,
    required this.active,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: active
              ? (isDark ? AppColors.primary.withValues(alpha: 0.2) : AppColors.primaryLight)
              : (isDark ? AppColors.darkBorder : AppColors.border.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active
                ? AppColors.primary.withValues(alpha: 0.5)
                : (isDark ? AppColors.darkBorder : AppColors.border),
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: active
              ? AppColors.primary
              : (isDark ? AppColors.darkTextSecond.withValues(alpha: 0.5) : AppColors.textHint),
        ),
      ),
    );
  }
}

class _NotifItemRow extends StatelessWidget {
  final String title;
  final bool pushActive;
  final bool emailActive;
  final bool isDark;

  const _NotifItemRow({
    required this.title,
    required this.pushActive,
    required this.emailActive,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
          _ChannelToggle(icon: Icons.phone_android, active: pushActive, isDark: isDark),
          const SizedBox(width: 8),
          _ChannelToggle(icon: Icons.email_outlined, active: emailActive, isDark: isDark),
        ],
      ),
    );
  }
}

Widget _subDivider(bool isDark) {
  return Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.border);
}

// ── Reminders Sub-screen ─────────────────────────────────────────────────────

class _RemindersScreen extends StatelessWidget {
  const _RemindersScreen();

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
        title: const Text('Lembretes'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          _NotifCard(isDark: isDark, children: [
            _NotifItemRow(title: 'Lembrete para praticar', pushActive: true, emailActive: true, isDark: isDark),
            _subDivider(isDark),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Lembretes inteligentes',
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Switch.adaptive(
                    value: true,
                    onChanged: (_) {},
                    activeTrackColor: AppColors.primary,
                  ),
                ],
              ),
            ),
            _subDivider(isDark),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Horário do lembrete',
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextSecond
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Text(
                    '17:00',
                    style: AppTypography.bodyLarge.copyWith(
                      color: isDark ? AppColors.darkTextSecond : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 16),
          _NotifCard(isDark: isDark, children: [
            _NotifItemRow(title: 'Bloqueio de ofensiva utilizado', pushActive: true, emailActive: true, isDark: isDark),
            _subDivider(isDark),
            _NotifItemRow(title: 'Ofensiva em perigo', pushActive: true, emailActive: false, isDark: isDark),
            _subDivider(isDark),
            _NotifItemRow(title: 'Progresso semanal', pushActive: false, emailActive: true, isDark: isDark),
          ]),
        ],
      ),
    );
  }
}

// ── Friends Notifications Sub-screen ─────────────────────────────────────────

class _FriendsNotifScreen extends StatelessWidget {
  const _FriendsNotifScreen();

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
        title: const Text('Amigos'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          _NotifCard(isDark: isDark, children: [
            _NotifItemRow(title: 'Novos seguidores', pushActive: true, emailActive: true, isDark: isDark),
            _subDivider(isDark),
            _NotifItemRow(title: 'Atividade de amigos', pushActive: true, emailActive: true, isDark: isDark),
          ]),
        ],
      ),
    );
  }
}

// ── Leagues Notifications Sub-screen ─────────────────────────────────────────

class _LeaguesNotifScreen extends StatelessWidget {
  const _LeaguesNotifScreen();

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
        title: const Text('Ligas'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          _NotifCard(isDark: isDark, children: [
            _NotifItemRow(title: 'Atualização de divisão', pushActive: true, emailActive: true, isDark: isDark),
            _subDivider(isDark),
            _NotifItemRow(title: 'Progresso na liga', pushActive: true, emailActive: false, isDark: isDark),
          ]),
        ],
      ),
    );
  }
}

// ── Friend Nudges Notifications Sub-screen ───────────────────────────────────

class _FriendNudgesNotifScreen extends StatelessWidget {
  const _FriendNudgesNotifScreen();

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
        title: const Text('Toques dos amigos'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          _NotifCard(isDark: isDark, children: [
            _NotifItemRow(title: 'Toques recebidos', pushActive: true, emailActive: true, isDark: isDark),
            _subDivider(isDark),
            _NotifItemRow(title: 'Lembretes de amigos', pushActive: true, emailActive: false, isDark: isDark),
          ]),
        ],
      ),
    );
  }
}

// ── Announcements Notifications Sub-screen ───────────────────────────────────

class _AnnouncementsNotifScreen extends StatelessWidget {
  const _AnnouncementsNotifScreen();

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
        title: const Text('Avisos'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          _NotifCard(isDark: isDark, children: [
            _NotifItemRow(title: 'Novidades e promoções', pushActive: false, emailActive: true, isDark: isDark),
            _subDivider(isDark),
            _NotifItemRow(title: 'Atualizações de produto e dicas de aprendizado', pushActive: true, emailActive: true, isDark: isDark),
            _subDivider(isDark),
            _NotifItemRow(title: 'Convites de pesquisa', pushActive: false, emailActive: true, isDark: isDark),
          ]),
        ],
      ),
    );
  }
}

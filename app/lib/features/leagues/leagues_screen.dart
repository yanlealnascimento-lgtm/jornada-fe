import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/user_provider.dart';
import '../../shared/models/league_model.dart';
import 'providers/league_provider.dart';

const _kPromotion = Color(0xFF58CC02);
const _kDemotion = Color(0xFFFF4B4B);

class LeaguesScreen extends ConsumerStatefulWidget {
  const LeaguesScreen({super.key});

  @override
  ConsumerState<LeaguesScreen> createState() => _LeaguesScreenState();
}

class _LeaguesScreenState extends ConsumerState<LeaguesScreen> {
  late Timer _countdownTimer;
  Duration _timeLeft = Duration.zero;

  @override
  void initState() {
    super.initState();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateCountdown();
    });
  }

  void _updateCountdown() {
    final now = DateTime.now();
    final daysUntilSunday = DateTime.sunday - now.weekday;
    final endOfWeek = DateTime(now.year, now.month, now.day + (daysUntilSunday <= 0 ? 7 : daysUntilSunday), 23, 59, 59);
    if (mounted) {
      setState(() {
        _timeLeft = endOfWeek.difference(now);
      });
    }
  }

  @override
  void dispose() {
    _countdownTimer.cancel();
    super.dispose();
  }

  String get _countdownText {
    if (_timeLeft.inDays > 0) return '${_timeLeft.inDays} DIAS';
    if (_timeLeft.inHours > 0) return '${_timeLeft.inHours}H ${_timeLeft.inMinutes % 60}MIN';
    return '${_timeLeft.inMinutes}MIN';
  }

  @override
  Widget build(BuildContext context) {
    final leagueAsync = ref.watch(leagueLeaderboardProvider);
    final currentUserId = ref.watch(currentUserProvider).valueOrNull?.id ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: leagueAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(
            color: isDark ? AppColors.darkTextPrimary : AppColors.primary,
          ),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: _kDemotion, size: 48),
                const SizedBox(height: 12),
                Text(
                  'Erro ao carregar liga',
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$e',
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextSecond : AppColors.textSecondary,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(leagueLeaderboardProvider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
                  ),
                  child: Text(
                    'Tentar novamente',
                    style: TextStyle(
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        data: (league) => _buildContent(context, league, currentUserId, isDark),
      ),
    );
  }

  Widget _buildContent(BuildContext context, LeagueLeaderboard league, String currentUserId, bool isDark) {
    final tierColor = league.tier.color;

    return SafeArea(
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Column(
              children: [
                Text(
                  league.tier.emoji,
                  style: const TextStyle(fontSize: 52),
                ),
                const SizedBox(height: 6),
                Text(
                  'Liga ${league.tier.displayName}',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: tierColor,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _countdownText,
                    style: TextStyle(
                      color: isDark ? AppColors.darkTextSecond : AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Tier icons horizontais ──────────────────────────────
          SizedBox(
            height: 56,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: LeagueTier.values.length,
              itemBuilder: (context, index) {
                final t = LeagueTier.values[index];
                final isCurrent = t == league.tier;
                return GestureDetector(
                  onTap: () {},
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    width: 44,
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? t.color.withValues(alpha: 0.25)
                          : (isDark ? AppColors.darkSurface : AppColors.surface),
                      borderRadius: BorderRadius.circular(12),
                      border: isCurrent
                          ? Border.all(color: t.color, width: 2)
                          : Border.all(color: Colors.transparent, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        t.emoji,
                        style: TextStyle(fontSize: isCurrent ? 22 : 18),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // ── Leaderboard list ────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              children: _buildLeaderboardItems(league, currentUserId, tierColor, isDark),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildLeaderboardItems(
    LeagueLeaderboard league,
    String currentUserId,
    Color tierColor,
    bool isDark,
  ) {
    final items = <Widget>[];
    final total = league.members.length;
    final promoBottom = league.promotionZoneBottom;
    final hasDemotion = !league.tier.noDemotion && total > 5;
    final demotionStart = total - 4;

    for (int i = 0; i < total; i++) {
      final member = league.members[i];
      final position = member.position;
      final isCurrentUser = member.memberId == currentUserId;

      if (position == promoBottom + 1 && i > 0) {
        items.add(_buildZoneSeparator(
          text: '\u2B06 ZONA DE PROMOÇÃO \u2B06',
          color: _kPromotion,
        ));
      }

      if (hasDemotion && position == demotionStart && i > 0) {
        items.add(_buildZoneSeparator(
          text: '\u2B07 ZONA DE REBAIXAMENTO \u2B07',
          color: _kDemotion,
        ));
      }

      items.add(_buildMemberRow(member, isCurrentUser, tierColor, league, isDark));
    }

    return items;
  }

  Widget _buildZoneSeparator({required String text, required Color color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        children: [
          Expanded(child: Divider(color: color.withValues(alpha: 0.4), thickness: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ),
          Expanded(child: Divider(color: color.withValues(alpha: 0.4), thickness: 1)),
        ],
      ),
    );
  }

  Widget _buildMemberRow(
    LeaderboardMember member,
    bool isCurrentUser,
    Color tierColor,
    LeagueLeaderboard league,
    bool isDark,
  ) {
    final isPromotion = league.isInPromotionZone(member.position);
    final isDemotion = league.isInDemotionZone(member.position);

    Color bgColor;
    if (isCurrentUser) {
      bgColor = tierColor.withValues(alpha: 0.15);
    } else {
      bgColor = Colors.transparent;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: isCurrentUser
            ? Border.all(color: tierColor.withValues(alpha: 0.4), width: 1.5)
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            // ── Position / Medal ──
            SizedBox(
              width: 32,
              child: _buildPosition(member.position, isDark),
            ),
            const SizedBox(width: 10),

            // ── Avatar ──
            CircleAvatar(
              radius: 20,
              backgroundColor: isCurrentUser
                  ? tierColor.withValues(alpha: 0.3)
                  : (isDark ? AppColors.darkSurface : AppColors.surface),
              child: Text(
                member.displayName.isNotEmpty
                    ? member.displayName[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  color: isCurrentUser
                      ? tierColor
                      : (isDark ? AppColors.darkTextSecond : AppColors.textSecondary),
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // ── Name ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isCurrentUser ? '${member.displayName} (VOCE)' : member.displayName,
                    style: TextStyle(
                      color: isCurrentUser
                          ? tierColor
                          : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                      fontWeight: isCurrentUser ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 15,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // ── Faith Points ──
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${member.faithPoints}',
                  style: TextStyle(
                    color: isCurrentUser
                        ? tierColor
                        : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 3),
                Text(
                  'PF',
                  style: TextStyle(
                    color: isCurrentUser
                        ? tierColor.withValues(alpha: 0.7)
                        : (isDark ? AppColors.darkTextSecond : AppColors.textSecondary),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                if (isPromotion || isDemotion) ...[
                  const SizedBox(width: 6),
                  Icon(
                    isPromotion ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                    color: isPromotion ? _kPromotion : _kDemotion,
                    size: 16,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPosition(int position, bool isDark) {
    if (position == 1) {
      return const Text('🥇', style: TextStyle(fontSize: 22), textAlign: TextAlign.center);
    }
    if (position == 2) {
      return const Text('🥈', style: TextStyle(fontSize: 22), textAlign: TextAlign.center);
    }
    if (position == 3) {
      return const Text('🥉', style: TextStyle(fontSize: 22), textAlign: TextAlign.center);
    }
    return Text(
      '$position',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: isDark ? AppColors.darkTextSecond : AppColors.textSecondary,
        fontWeight: FontWeight.w700,
        fontSize: 16,
      ),
    );
  }
}

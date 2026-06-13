import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/models/mission_model.dart';
import 'providers/mission_provider.dart';

class MissionsScreen extends ConsumerWidget {
  const MissionsScreen({super.key});

  Map<String, UserMissionModel?> _pickMissions(Map<String, List<UserMissionModel>> all) {
    final rng = Random(DateTime.now().day * 31 + DateTime.now().month);
    final daily = all['daily'] ?? [];
    final weekly = all['weekly'] ?? [];
    final oneTime = all['one_time'] ?? [];

    return {
      'daily': daily.isNotEmpty ? daily[rng.nextInt(daily.length)] : null,
      'weekly': weekly.isNotEmpty ? weekly[rng.nextInt(weekly.length)] : null,
      'random': oneTime.isNotEmpty ? oneTime[rng.nextInt(oneTime.length)] : null,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final missionsAsync = ref.watch(missionsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF0F7FF),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF0F7FF),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Conquistas',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            fontFamily: 'Nunito',
            color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1A2E4A),
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.emoji_events_rounded, color: Color(0xFFF59E0B), size: 28),
          ),
        ],
      ),
      body: missionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('\u{1F614}', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text('Erro ao carregar conquistas',
                  style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1A2E4A),
                  )),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(missionsProvider),
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
        data: (allMissions) {
          final picks = _pickMissions(allMissions);

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(missionsProvider),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _MotivationalBanner(isDark: isDark),
                const SizedBox(height: 20),
                if (picks['daily'] != null)
                  _QuestCard(
                    sectionTitle: 'Conquista do Dia',
                    sectionEmoji: '📅',
                    sectionSubtitle: 'Renova a meia-noite',
                    accentColor: const Color(0xFF4A90E2),
                    mission: picks['daily']!,
                    isDark: isDark,
                  ),
                const SizedBox(height: 16),
                if (picks['weekly'] != null)
                  _QuestCard(
                    sectionTitle: 'Conquista da Semana',
                    sectionEmoji: '📆',
                    sectionSubtitle: 'Renova toda segunda-feira',
                    accentColor: const Color(0xFF8B5CF6),
                    mission: picks['weekly']!,
                    isDark: isDark,
                  ),
                const SizedBox(height: 16),
                if (picks['random'] != null)
                  _QuestCard(
                    sectionTitle: 'Desafio Especial',
                    sectionEmoji: '🏆',
                    sectionSubtitle: 'Conquista permanente',
                    accentColor: const Color(0xFFF59E0B),
                    mission: picks['random']!,
                    isDark: isDark,
                  ),
                if (picks.values.every((v) => v == null))
                  Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Center(
                      child: Text(
                        'Nenhuma conquista disponível.\nFaça o seed no painel admin.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDark ? AppColors.darkTextSecond : const Color(0xFF9CA3AF),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Motivational Banner ─────────────────────────────────────────────────────

class _MotivationalBanner extends StatelessWidget {
  final bool isDark;
  const _MotivationalBanner({required this.isDark});

  static const _phrases = [
    'Sua jornada de hoje começa aqui! 🌅',
    '"Seja constante na oração." Rm 12:12 🙏',
    'Pequenos passos, grandes conquistas! ✝️',
    'Você já fez isso antes. Pode fazer de novo! 💪',
    '"Os que esperam no Senhor renovarão as forças." Is 40:31 🔥',
  ];

  @override
  Widget build(BuildContext context) {
    final phrase = _phrases[DateTime.now().day % _phrases.length];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF1E4A6B) : const Color(0xFFBFDBFE),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Color(0xFF4A90E2), size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              phrase,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1A2E4A),
                fontStyle: FontStyle.italic,
                fontFamily: 'Nunito',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Quest Card ──────────────────────────────────────────────────────────────

class _QuestCard extends StatelessWidget {
  final String sectionTitle;
  final String sectionEmoji;
  final String sectionSubtitle;
  final Color accentColor;
  final UserMissionModel mission;
  final bool isDark;

  const _QuestCard({
    required this.sectionTitle,
    required this.sectionEmoji,
    required this.sectionSubtitle,
    required this.accentColor,
    required this.mission,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(sectionEmoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sectionTitle,
                      style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800, fontFamily: 'Nunito',
                        color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1A2E4A),
                      )),
                  Text(sectionSubtitle,
                      style: TextStyle(fontSize: 11,
                        color: isDark ? AppColors.darkTextSecond : const Color(0xFF9CA3AF),
                      )),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? accentColor.withValues(alpha: 0.4)
                  : accentColor.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.2)
                    : accentColor.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isDark
                      ? accentColor.withValues(alpha: 0.2)
                      : accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(mission.iconEmoji, style: const TextStyle(fontSize: 28)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mission.title,
                      style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1A2E4A),
                        fontFamily: 'Nunito',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mission.description,
                      style: TextStyle(fontSize: 12,
                        color: isDark ? AppColors.darkTextSecond : const Color(0xFF6B7280)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _Badge(
                          label: '+${mission.pfReward} PF',
                          color: const Color(0xFFF59E0B),
                          bgColor: isDark ? const Color(0xFF3D3510) : const Color(0xFFFEF3C7),
                        ),
                        if (mission.difficulty.isNotEmpty)
                          _Badge(
                            label: mission.difficultyLabel,
                            color: mission.difficultyColor,
                            bgColor: isDark
                                ? mission.difficultyColor.withValues(alpha: 0.15)
                                : mission.difficultyBgColor,
                          ),
                        _Badge(
                          label: mission.rarityLabel,
                          color: mission.rarityColor,
                          bgColor: isDark
                              ? mission.rarityColor.withValues(alpha: 0.15)
                              : mission.rarityColor.withValues(alpha: 0.1),
                        ),
                        _Badge(
                          label: '${mission.triggerLabel}: ${mission.triggerValue}',
                          color: const Color(0xFF4A90E2),
                          bgColor: isDark ? const Color(0xFF0F2A3F) : const Color(0xFFDBEAFE),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;

  const _Badge({required this.label, required this.color, required this.bgColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

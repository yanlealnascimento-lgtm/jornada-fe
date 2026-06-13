import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../gamification/providers/gamification_providers.dart';

class StoreScreen extends ConsumerWidget {
  const StoreScreen({super.key});

  static const _cardDark = Color(0xFF1E1E2E);
  static const _borderDark = Color(0xFF2A2A3E);
  static const _green = Color(0xFF58CC02);
  static const _greenShadow = Color(0xFF46A302);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final crystals = ref.watch(crystalProvider);

    final bgColor = isDark ? AppColors.darkBackground : AppColors.background;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecond : AppColors.textSecondary;
    final cardBg = isDark ? _cardDark : Colors.white;
    final borderColor = isDark ? _borderDark : AppColors.border;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────
            _buildHeader(context, crystals, textPrimary),

            // ── Body ────────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Premium Banner ───────────────────────────────────
                    _buildPremiumBanner(context),
                    const SizedBox(height: 16),

                    // ── Escolher plano ideal ─────────────────────────────
                    _buildChoosePlanCard(context, cardBg, borderColor, textPrimary, textSecondary),
                    const SizedBox(height: 28),

                    // ── Ofertas especiais ────────────────────────────────
                    _sectionTitle('Ofertas especiais', textPrimary),
                    const SizedBox(height: 12),
                    _buildDevocionalCard(
                      context,
                      emoji: '\u{1F305}',
                      title: 'Devocional da Manh\u00e3',
                      description: 'Fa\u00e7a um devocional entre 5h e meio-dia',
                      reward: '+50 Cristais + b\u00f4nus PF',
                      verse: '"De manh\u00e3 ouvir\u00e1s a minha voz" \u2014 Sl 5:3',
                      startHour: 5,
                      endHour: 12,
                      cardBg: cardBg,
                      borderColor: borderColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                    const SizedBox(height: 10),
                    _buildDevocionalCard(
                      context,
                      emoji: '\u2600\uFE0F',
                      title: 'Devocional da Tarde',
                      description: 'Fa\u00e7a um devocional entre 12h e 18h',
                      reward: '+30 Cristais',
                      verse: '"Meditar\u00e1s nele de dia" \u2014 Js 1:8',
                      startHour: 12,
                      endHour: 18,
                      cardBg: cardBg,
                      borderColor: borderColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                    const SizedBox(height: 10),
                    _buildDevocionalCard(
                      context,
                      emoji: '\u{1F319}',
                      title: 'Devocional Noturno',
                      description: 'Fa\u00e7a um devocional entre 18h e meia-noite',
                      reward: '+40 Cristais + b\u00f4nus PF',
                      verse: '"Quando me lembro de ti no meu leito" \u2014 Sl 63:6',
                      startHour: 18,
                      endHour: 24,
                      cardBg: cardBg,
                      borderColor: borderColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                    const SizedBox(height: 28),

                    // ── Cristais (IAP) ──────────────────────────────────
                    _sectionTitle('Cristais', textPrimary),
                    const SizedBox(height: 12),
                    _buildCrystalPacksRow(context, cardBg, borderColor, textPrimary, textSecondary),
                    const SizedBox(height: 28),

                    // ── Superpoderes ─────────────────────────────────────
                    _sectionTitle('Superpoderes', textPrimary),
                    const SizedBox(height: 12),
                    _buildShopItem(
                      context,
                      icon: Icons.timer_outlined,
                      iconColor: const Color(0xFFFFA726),
                      title: 'Esticatempo',
                      subtitle: 'Ganhe mais tempo nos desafios cronometrados!',
                      actionText: '450',
                      isCrystalPrice: true,
                      cardBg: cardBg,
                      borderColor: borderColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                    const SizedBox(height: 28),

                    // ── Energia ──────────────────────────────────────────
                    _sectionTitle('Energia', textPrimary),
                    const SizedBox(height: 12),
                    _buildShopItem(
                      context,
                      icon: Icons.all_inclusive,
                      iconColor: AppColors.heartColor,
                      title: 'Energia Ilimitada',
                      subtitle: 'Super / Premium',
                      actionText: 'TESTAR GR\u00c1TIS',
                      isCrystalPrice: false,
                      isGreenButton: true,
                      cardBg: cardBg,
                      borderColor: borderColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                    const SizedBox(height: 10),
                    _buildShopItem(
                      context,
                      icon: Icons.bolt,
                      iconColor: const Color(0xFFFFD600),
                      title: 'Recarga',
                      subtitle: 'Recarregue toda a energia',
                      actionText: '350',
                      isCrystalPrice: true,
                      cardBg: cardBg,
                      borderColor: borderColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                    const SizedBox(height: 28),

                    // ── Cupom de desconto ────────────────────────────────
                    _sectionTitle('Cupom de desconto', textPrimary),
                    const SizedBox(height: 12),
                    _buildCouponCard(context, cardBg, borderColor, textPrimary, textSecondary),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Header
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildHeader(
    BuildContext context,
    AsyncValue<int> crystals,
    Color textPrimary,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Close button
          GestureDetector(
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.withValues(alpha: 0.15),
              ),
              child: Icon(Icons.close, size: 20, color: textPrimary),
            ),
          ),

          const Spacer(),

          // Title
          Text(
            'Loja',
            style: AppTypography.headingLarge.copyWith(color: textPrimary),
          ),

          const Spacer(),

          // Crystal count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: AppColors.mana.withValues(alpha: 0.12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('\u{1F48E}', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 4),
                crystals.when(
                  data: (value) => Text(
                    value.toString(),
                    style: AppTypography.label.copyWith(color: AppColors.mana),
                  ),
                  loading: () => const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.mana),
                  ),
                  error: (_, __) => Text(
                    '---',
                    style: AppTypography.label.copyWith(color: AppColors.mana),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Premium Banner
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildPremiumBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.workspace_premium, color: Color(0xFFFFD700), size: 22),
                    const SizedBox(width: 6),
                    Text(
                      'PREMIUM',
                      style: AppTypography.label.copyWith(
                        color: const Color(0xFFFFD700),
                        fontSize: 14,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Acesse o plano Premium e desbloqueie toda a jornada!',
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                _greenButton(
                  text: 'TESTE 1 SEMANA GR\u00c1TIS',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const _PremiumTrialScreen()),
                  ),
                  compact: true,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Dove mascot
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.08),
            ),
            child: const Center(
              child: Text('\u{1F54A}\uFE0F', style: TextStyle(fontSize: 36)),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Devocional Card
  // ═══════════════════════════════════════════════════════════════════════════
  // ═══════════════════════════════════════════════════════════════════════════
  // Choose Plan Card
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildChoosePlanCard(
    BuildContext context,
    Color cardBg,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const _SubscriptionPlansScreen()),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF1A237E), Color(0xFF283593)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: const Color(0xFF3F51B5).withValues(alpha: 0.4), width: 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.compare_arrows_rounded, color: Color(0xFF82B1FF), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'COMPARE OS PLANOS',
                        style: TextStyle(
                          color: const Color(0xFF82B1FF),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Escolha o plano ideal para sua jornada',
                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Super, Familia ou Max',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 28),
            ),
          ],
        ),
      ),
    );
  }

  // TODO: Implementar sistema de Ofertas Especiais (Devocionais com IA)
  // ─────────────────────────────────────────────────────────────────────
  // Regra: O usuario deve completar uma licao/estudo de IA dentro do
  // horario proposto para desbloquear a recompensa:
  //   - Manha (5h-12h): +50 Cristais + Bonus PF
  //   - Tarde (12h-18h): +30 Cristais
  //   - Noite (18h-00h): +40 Cristais + Bonus PF
  //
  // Prerequisito: Sistema de Estudos com IA precisa estar implementado.
  // Quando implementado, ao clicar em "ABRIR" (dentro do horario):
  //   1. Verificar se o usuario completou um estudo de IA hoje naquele turno
  //   2. Se sim: conceder cristais + PF bonus via backend
  //   3. Se nao: redirecionar para a tela de estudos IA
  //   4. Cada bau so pode ser aberto 1x por dia/turno
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildDevocionalCard(
    BuildContext context, {
    required String emoji,
    required String title,
    required String description,
    required String reward,
    required String verse,
    required int startHour,
    required int endHour,
    required Color cardBg,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final currentHour = DateTime.now().hour;
    final isAvailable = currentHour >= startHour && currentHour < endHour;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.label.copyWith(
                        color: textPrimary,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: AppTypography.caption.copyWith(
                        color: textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Reward badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.mana.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              reward,
              style: AppTypography.caption.copyWith(
                color: AppColors.mana,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Verse
          Text(
            verse,
            style: AppTypography.caption.copyWith(
              color: textSecondary.withValues(alpha: 0.7),
              fontStyle: FontStyle.italic,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 12),
          // Action button
          SizedBox(
            width: double.infinity,
            child: isAvailable
                ? _greenButton(
                    text: 'INICIAR DEVOCIONAL',
                    onTap: () => _showSnackBar(context, 'Em breve!'),
                  )
                : _blockedButton(),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Crystal Packs Row
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildCrystalPacksRow(
    BuildContext context,
    Color cardBg,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Row(
      children: [
        Expanded(
          child: _crystalPackCard(
            context,
            amount: '1.200',
            price: 'R\$ 24,99',
            badge: null,
            cardBg: cardBg,
            borderColor: borderColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _crystalPackCard(
            context,
            amount: '3.000',
            price: 'R\$ 48,99',
            badge: 'MAIS POPULAR',
            cardBg: cardBg,
            borderColor: borderColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _crystalPackCard(
            context,
            amount: '6.500',
            price: 'R\$ 98,99',
            badge: null,
            cardBg: cardBg,
            borderColor: borderColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _crystalPackCard(
    BuildContext context, {
    required String amount,
    required String price,
    required String? badge,
    required Color cardBg,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final hasBadge = badge != null;

    return GestureDetector(
      onTap: () => _showSnackBar(context, 'Em breve!'),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasBadge ? AppColors.mana : borderColor,
            width: hasBadge ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            if (hasBadge) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.mana,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: AppTypography.caption.copyWith(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ] else
              const SizedBox(height: 18),
            const Text('\u{1F48E}', style: TextStyle(fontSize: 28)),
            const SizedBox(height: 6),
            Text(
              amount,
              style: AppTypography.label.copyWith(
                color: textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.mana.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                price,
                textAlign: TextAlign.center,
                style: AppTypography.caption.copyWith(
                  color: AppColors.mana,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Generic Shop Item
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildShopItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String actionText,
    required bool isCrystalPrice,
    bool isGreenButton = false,
    required Color cardBg,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),

          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.label.copyWith(
                    color: textPrimary,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.caption.copyWith(
                    color: textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Action
          if (isGreenButton)
            _greenButton(
              text: actionText,
              onTap: () => _showSnackBar(context, 'Em breve!'),
              compact: true,
              fontSize: 11,
            )
          else
            _crystalPriceButton(
              context,
              price: actionText,
              onTap: () => _showSnackBar(context, 'Em breve!'),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Coupon Card
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildCouponCard(
    BuildContext context,
    Color cardBg,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.confirmation_number_outlined, color: _green, size: 22),
              const SizedBox(width: 8),
              Text(
                'Utilize um cupom',
                style: AppTypography.label.copyWith(
                  color: textPrimary,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: textSecondary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor),
                  ),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Insira um c\u00f3digo promocional',
                    style: AppTypography.caption.copyWith(
                      color: textSecondary.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _greenButton(
                text: 'UTILIZAR',
                onTap: () => _showSnackBar(context, 'Em breve!'),
                compact: true,
                fontSize: 12,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Shared Widgets
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _sectionTitle(String title, Color color) {
    return Text(
      title,
      style: AppTypography.headingMedium.copyWith(color: color),
    );
  }

  Widget _greenButton({
    required String text,
    required VoidCallback onTap,
    bool compact = false,
    double fontSize = 13,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 14 : 20,
          vertical: compact ? 8 : 12,
        ),
        decoration: BoxDecoration(
          color: _green,
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: _greenShadow,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: AppTypography.buttonMedium.copyWith(
            color: Colors.white,
            fontSize: fontSize,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _blockedButton() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, size: 16, color: Colors.grey[500]),
          const SizedBox(width: 6),
          Text(
            'BLOQUEADO',
            style: AppTypography.buttonMedium.copyWith(
              color: Colors.grey[500],
              fontSize: 13,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _crystalPriceButton(
    BuildContext context, {
    required String price,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.mana.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.mana.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('\u{1F48E}', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(
              price,
              style: AppTypography.label.copyWith(
                color: AppColors.mana,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// ─── Premium Trial Screen ──────────────────────────────────────────────────

class _PremiumTrialScreen extends StatelessWidget {
  const _PremiumTrialScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, color: Colors.white, size: 28),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF00C853)]),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'SUPER',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // Dove mascot illustration
                    Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF1A237E).withValues(alpha: 0.5),
                      ),
                      child: const Center(
                        child: Text('\u{1F54A}', style: TextStyle(fontSize: 80)),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Title
                    const Text(
                      'Desbloqueie todo o potencial da sua jornada espiritual!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Benefits card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A2E),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          _buildBenefitRow(
                            Icons.all_inclusive_rounded,
                            const Color(0xFF4FC3F7),
                            'Energia ilimitada',
                          ),
                          const SizedBox(height: 20),
                          _buildBenefitRow(
                            Icons.block_rounded,
                            const Color(0xFF66BB6A),
                            'Sem anuncios',
                          ),
                          const SizedBox(height: 20),
                          _buildBenefitRow(
                            Icons.auto_awesome_rounded,
                            const Color(0xFFFFD54F),
                            'Estudos com IA personalizada',
                          ),
                          const SizedBox(height: 20),
                          _buildBenefitRow(
                            Icons.shield_rounded,
                            const Color(0xFFCE93D8),
                            'Escudo de Devocao ilimitado',
                          ),
                          const SizedBox(height: 20),
                          _buildBenefitRow(
                            Icons.favorite_rounded,
                            const Color(0xFFEF5350),
                            'Pratica personalizada',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Cancel info
                    const Text(
                      'Cancele quando quiser, sem multas ou taxas',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // Bottom buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Em desenvolvimento'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFA5F3C0),
                    foregroundColor: const Color(0xFF0D0D1A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'EXPERIMENTE POR R\$ 0,00',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'AGORA NAO',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white70,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildBenefitRow(IconData icon, Color color, String text) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Subscription Plans Screen (Assinatura) ────────────────────────────────

class _SubscriptionPlansScreen extends StatelessWidget {
  const _SubscriptionPlansScreen();

  static const _bgColor = Color(0xFF0D0D1A);
  static const _cardBg = Color(0xFF1A1A2E);
  static const _borderColor = Color(0xFF2A2A3E);
  static const _checkColor = Color(0xFF6C63FF);

  void _showComingSoon(BuildContext context, String plan) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$plan - Em desenvolvimento'), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Assinatura',
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),

            // Scrollable plans
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      'COMPARE OS PLANOS:',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Super Ovelha (Recommended) ─────────────────────
                    _buildPlanCard(
                      context,
                      name: 'Super Ovelha',
                      recommended: true,
                      gradientColors: const [Color(0xFF00C853), Color(0xFF4FC3F7)],
                      icon: Container(
                        width: 64,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF7C4DFF), Color(0xFF448AFF)]),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Center(
                          child: Icon(Icons.all_inclusive_rounded, color: Colors.white, size: 32),
                        ),
                      ),
                      benefits: [
                        'Energia ilimitada',
                        'Sem anuncios',
                      ],
                      buttonLabel: 'TESTAR SUPER POR R\$ 0,00',
                    ),
                    const SizedBox(height: 16),

                    // ── Super Familia ───────────────────────────────────
                    _buildPlanCard(
                      context,
                      name: 'Super Familia',
                      icon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF1A237E),
                            ),
                            child: const Center(child: Text('\u{1F9D1}\u200D\u{1F3A8}', style: TextStyle(fontSize: 24))),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF6C63FF),
                              border: Border.all(color: _bgColor, width: 2),
                            ),
                            child: const Center(
                              child: Text('+4', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                            ),
                          ),
                        ],
                      ),
                      benefits: [
                        'Energia ilimitada',
                        'Sem anuncios',
                        'Ate 6 pessoas',
                        'Economize ate 76% no Super',
                      ],
                      buttonLabel: 'TESTAR SUPER FAMILIA POR R\$ 0,00',
                    ),
                    const SizedBox(height: 16),

                    // ── Max ─────────────────────────────────────────────
                    _buildPlanCard(
                      context,
                      name: 'Max',
                      icon: Container(
                        width: 64,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF7C4DFF), Color(0xFFE040FB)]),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Center(
                          child: Icon(Icons.auto_awesome, color: Colors.white, size: 28),
                        ),
                      ),
                      benefits: [
                        'Energia ilimitada',
                        'Sem anuncios',
                        'Estudos com IA personalizada',
                      ],
                      buttonLabel: 'TESTAR MAX POR R\$ 0,00',
                    ),
                    const SizedBox(height: 16),

                    // ── Max Familia ─────────────────────────────────────
                    _buildPlanCard(
                      context,
                      name: 'Max Familia',
                      icon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF1A237E),
                            ),
                            child: const Center(child: Text('\u{1F468}\u200D\u{1F469}\u200D\u{1F467}', style: TextStyle(fontSize: 22))),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFE040FB),
                              border: Border.all(color: _bgColor, width: 2),
                            ),
                            child: const Center(
                              child: Text('+4', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                            ),
                          ),
                        ],
                      ),
                      benefits: [
                        'Energia ilimitada',
                        'Sem anuncios',
                        'Estudos com IA personalizada',
                        'Ate 6 pessoas',
                        'Economize ate 76% no Max',
                      ],
                      buttonLabel: 'TESTAR MAX FAMILIA POR R\$ 0,00',
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(
    BuildContext context, {
    required String name,
    required Widget icon,
    required List<String> benefits,
    required String buttonLabel,
    bool recommended = false,
    List<Color>? gradientColors,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: recommended ? Colors.transparent : _borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recommended badge
          if (recommended)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradientColors ?? [_checkColor, _checkColor]),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: const Center(
                child: Text(
                  'RECOMENDADO',
                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1.5),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + icon row
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                      ),
                    ),
                    icon,
                  ],
                ),
                const SizedBox(height: 16),

                // Benefits
                ...benefits.map((b) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.check_rounded, color: _checkColor, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          b,
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                )),
                const SizedBox(height: 12),

                // CTA button
                GestureDetector(
                  onTap: () => _showComingSoon(context, name),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        buttonLabel,
                        style: TextStyle(
                          color: _checkColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

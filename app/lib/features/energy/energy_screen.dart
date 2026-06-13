import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_colors.dart';
import '../gamification/providers/gamification_providers.dart';
import '../gamification/services/lives_service.dart';
import '../gamification/services/crystal_service.dart';

class EnergyScreen extends ConsumerStatefulWidget {
  const EnergyScreen({super.key});

  @override
  ConsumerState<EnergyScreen> createState() => _EnergyScreenState();
}

class _EnergyScreenState extends ConsumerState<EnergyScreen> {
  static const int _maxEnergy = 20;
  static const Color _energyPink = Color(0xFFF48FB1);
  static const Color _cardBorder = Color(0xFF37474F);
  static const String _keyLastFreeRecharge = 'energy_last_free_recharge';
  static const int _freeEnergyAmount = 4;
  static const Duration _freeCooldown = Duration(hours: 4);
  static const int _freeEnergyThreshold = 17;

  Timer? _timer;
  LivesState? _livesState;
  int _crystals = 0;
  bool _freeAvailable = false;
  Duration _freeNextIn = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _checkFreeAvailability();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          if (!_freeAvailable && _freeNextIn.inSeconds > 0) {
            _freeNextIn -= const Duration(seconds: 1);
            if (_freeNextIn.inSeconds <= 0) {
              _freeAvailable = true;
            }
          }
        });
      }
    });
  }

  Future<void> _checkFreeAvailability() async {
    final prefs = await SharedPreferences.getInstance();
    final lastMs = prefs.getInt(_keyLastFreeRecharge) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final elapsed = now - lastMs;
    if (elapsed >= _freeCooldown.inMilliseconds || lastMs == 0) {
      setState(() {
        _freeAvailable = true;
        _freeNextIn = Duration.zero;
      });
    } else {
      setState(() {
        _freeAvailable = false;
        _freeNextIn = Duration(milliseconds: _freeCooldown.inMilliseconds - elapsed);
      });
    }
  }

  Future<void> _claimFreeEnergy() async {
    if (!_freeAvailable) return;

    final current = _livesState?.current ?? 0;
    if (current >= _freeEnergyThreshold) {
      _showEnergyFullDialog(current);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyLastFreeRecharge, DateTime.now().millisecondsSinceEpoch);

    final newLives = (current + _freeEnergyAmount).clamp(0, _maxEnergy);
    await prefs.setInt('lives_count', newLives);
    if (newLives >= _maxEnergy) {
      await prefs.remove('lives_last_lost_timestamp');
    }

    ref.invalidate(livesProvider);
    setState(() {
      _freeAvailable = false;
      _freeNextIn = _freeCooldown;
    });

    if (!mounted) return;
    _showEnergyGainedDialog(_freeEnergyAmount);
  }

  Future<void> _rechargeWithCrystals() async {
    if (_crystals < 350) {
      _showInsufficientCrystalsDialog();
      return;
    }
    final success = await CrystalService.consumeCrystals(350);
    if (!success) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lives_count', _maxEnergy);
    await prefs.remove('lives_last_lost_timestamp');

    ref.invalidate(livesProvider);
    ref.invalidate(crystalProvider);
  }

  void _showEnergyFullDialog(int current) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _isDark ? const Color(0xFF1C2B33) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _energyPink.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.bolt_rounded, size: 36, color: _energyPink),
            ),
            const SizedBox(height: 16),
            Text(
              'Sua energia esta quase cheia!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Voce ja tem $current de $_maxEnergy energias. Use algumas licoes antes de recarregar para aproveitar ao maximo!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: _textSecondary, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ENTENDI', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          ),
        ],
      ),
    );
  }

  void _showEnergyGainedDialog(int amount) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _EnergyGainedScreen(
          amount: amount,
          currentEnergy: min((_livesState?.current ?? 0) + amount, _maxEnergy),
        ),
      ),
    );
  }

  void _showInsufficientCrystalsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _isDark ? const Color(0xFF1C2B33) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.mana.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.diamond_rounded, size: 36, color: AppColors.mana),
            ),
            const SizedBox(height: 16),
            Text(
              'Cristais insuficientes',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Voce precisa de 350 cristais para recarregar. Voce tem $_crystals.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: _textSecondary, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          ),
        ],
      ),
    );
  }

  void _showSuperScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const _SuperTrialScreen()),
    );
  }

  void _showComingSoon(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label - Em breve!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Color _energyBarColor(int current) {
    if (current >= 15) return _energyPink;
    if (current >= 8) return const Color(0xFFFFD54F);
    if (current >= 1) return const Color(0xFFEF5350);
    return Colors.grey;
  }

  String _formatCooldown(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return 'Prox em ${h}h${m > 0 ? ' ${m}m' : ''}';
    return 'Prox em ${m}m';
  }

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _backgroundColor => _isDark ? AppColors.darkBackground : AppColors.background;
  Color get _textPrimary => _isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
  Color get _textSecondary => _isDark ? AppColors.darkTextSecond : AppColors.textSecondary;

  @override
  Widget build(BuildContext context) {
    final livesAsync = ref.watch(livesProvider);
    final crystalAsync = ref.watch(crystalProvider);

    livesAsync.whenData((state) {
      _livesState = state;
    });
    crystalAsync.whenData((c) => _crystals = c);

    final currentLives = _livesState?.current ?? 0;

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  children: [
                    _buildEnergySection(currentLives),
                    const SizedBox(height: 24),
                    _buildSuperBanner(),
                    const SizedBox(height: 24),
                    _buildOptionCard(
                      icon: _buildBatteryIcon('$_maxEnergy', _energyPink),
                      title: 'Recarregar',
                      trailing: _buildCrystalButton(350, onTap: _rechargeWithCrystals),
                    ),
                    const SizedBox(height: 24),
                    _buildOptionCard(
                      icon: _buildBatteryIcon('+8', const Color(0xFF58CC02)),
                      title: 'Uncao do Widget',
                      trailing: _buildTextButton('INSTALAR', onTap: () => _showComingSoon('Uncao do Widget')),
                    ),
                    const SizedBox(height: 24),
                    _buildOptionCard(
                      icon: _buildBatteryIcon('+5', Colors.amber),
                      title: '+5 energias',
                      subtitle: 'Anuncio',
                      trailing: _buildTextButton('VER ANUNCIO', onTap: () => _showComingSoon('Ver Anuncio')),
                    ),
                    const SizedBox(height: 24),
                    _buildOptionCard(
                      icon: _buildBatteryIcon('+$_freeEnergyAmount', _energyPink),
                      title: '+$_freeEnergyAmount energias',
                      trailing: _freeAvailable
                          ? _buildTextButton('GRATIS', onTap: _claimFreeEnergy)
                          : _buildTextButton(_formatCooldown(_freeNextIn)),
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
            child: Icon(Icons.close_rounded, color: _textSecondary, size: 32),
          ),
          const Spacer(),
          Text(
            'Energia',
            style: TextStyle(
              color: _textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.diamond_rounded, size: 20, color: AppColors.mana),
              const SizedBox(width: 4),
              Text(
                '$_crystals',
                style: const TextStyle(
                  color: AppColors.mana,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnergySection(int currentLives) {
    final barColor = _energyBarColor(currentLives);
    final progress = currentLives / _maxEnergy;
    final isFull = currentLives >= _maxEnergy;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _isDark ? const Color(0xFF1C2B33) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isDark ? _cardBorder : AppColors.border,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              isFull ? 'COMPLETO' : 'CARREGANDO',
              style: TextStyle(
                color: _textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 30,
                      decoration: BoxDecoration(
                        color: _isDark ? const Color(0xFF2A3A44) : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: progress.clamp(0.0, 1.0),
                      child: Container(
                        height: 30,
                        decoration: BoxDecoration(
                          color: barColor,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: barColor.withValues(alpha: 0.4),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 30,
                      child: Center(
                        child: Text(
                          '$currentLives / $_maxEnergy',
                          style: TextStyle(
                            color: progress > 0.3 ? Colors.white : _textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Transform.rotate(
                angle: 1.5708,
                child: Icon(
                  isFull
                      ? Icons.battery_full
                      : currentLives > _maxEnergy ~/ 2
                          ? Icons.battery_5_bar
                          : currentLives > 0
                              ? Icons.battery_2_bar
                              : Icons.battery_0_bar,
                  color: barColor,
                  size: 34,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuperBanner() {
    return GestureDetector(
      onTap: _showSuperScreen,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6C63FF), Color(0xFF42A5F5)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C63FF).withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0x44FFFFFF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'SUPER',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ilimitada',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Energia infinita para sua jornada',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'TESTAR GRATIS',
                style: TextStyle(
                  color: Color(0xFF6C63FF),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required Widget icon,
    required String title,
    String? subtitle,
    required Widget trailing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: _isDark ? const Color(0xFF1C2B33) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isDark ? _cardBorder : AppColors.border,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          icon,
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle,
                      style: TextStyle(color: _textSecondary, fontSize: 13),
                    ),
                  ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  Widget _buildBatteryIcon(String label, Color color) {
    return SizedBox(
      width: 56,
      height: 44,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          // Battery body
          Container(
            width: 50,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          // Battery terminal (right nub)
          Positioned(
            right: 0,
            child: Container(
              width: 6,
              height: 16,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(4)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCrystalButton(int cost, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.mana.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.mana, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.diamond_rounded, size: 18, color: AppColors.mana),
            const SizedBox(width: 4),
            Text(
              '$cost',
              style: const TextStyle(
                color: AppColors.mana,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextButton(String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.mana,
          fontSize: 14,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// --- Energy Gained Screen ---

class _EnergyGainedScreen extends StatelessWidget {
  final int amount;
  final int currentEnergy;

  const _EnergyGainedScreen({required this.amount, required this.currentEnergy});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Transform.rotate(
                      angle: 1.5708,
                      child: const Icon(Icons.battery_charging_full_rounded, size: 22, color: Color(0xFFF48FB1)),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$currentEnergy',
                      style: const TextStyle(color: Color(0xFFF48FB1), fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            Container(
              width: 140,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFFF48FB1),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    left: 14,
                    top: 14,
                    child: Container(
                      width: 20,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const Icon(Icons.bolt_rounded, size: 60, color: Colors.white),
                  Positioned(
                    right: -8,
                    child: Container(
                      width: 16,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF48FB1).withValues(alpha: 0.7),
                        borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white, height: 1.4),
                  children: [
                    const TextSpan(text: 'Voce ganhou '),
                    TextSpan(
                      text: '+$amount de energia',
                      style: const TextStyle(color: Color(0xFFF48FB1), fontWeight: FontWeight.w800),
                    ),
                    const TextSpan(text: '!\nReceba a proxima carga gratis de energia em '),
                    const TextSpan(text: '4 horas', style: TextStyle(fontWeight: FontWeight.w800)),
                    const TextSpan(text: '.'),
                  ],
                ),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF87CEEB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text('OK!', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Super Trial Screen ---

class _SuperTrialScreen extends StatelessWidget {
  const _SuperTrialScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A237E),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 32),
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
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: 'Tenha '),
                    TextSpan(
                      text: 'energia ilimitada',
                      style: TextStyle(color: Color(0xFF4FC3F7)),
                    ),
                    TextSpan(text: ' para crescer espiritualmente na versao Super'),
                  ],
                ),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white, height: 1.3),
              ),
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Com zero anuncios, as licoes vao passar voando!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.white70, height: 1.4),
              ),
            ),
            const Spacer(),
            Container(
              width: 160,
              height: 130,
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C63FF).withValues(alpha: 0.4),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.all_inclusive_rounded, size: 80, color: Colors.white),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Em desenvolvimento'), duration: Duration(seconds: 2)),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'COMECAR SEMANA GRATIS',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/providers/user_provider.dart';
import '../../core/providers/trail_provider.dart';
import '../../shared/widgets/jf_button.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showPassword = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final onboardingData = ref.read(onboardingDataProvider);

    try {
      await ref.read(currentUserProvider.notifier).register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        denomination: onboardingData.denomination,
        dailyGoalMinutes: onboardingData.dailyGoalMinutes,
      );

      if (mounted) {
        // Ir direto para a primeira lição
        final lessonId = await fetchFirstLessonId(ref);
        if (mounted) {
          context.go(lessonId != null ? '/lesson/$lessonId' : '/home');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao criar conta. Tente novamente.'),
            backgroundColor: AppColors.incorrect,
          ),
        );
      }
    }
  }

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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 8),
                // Caleb pequeno no topo
                Container(
                  width: 70,
                  height: 70,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(child: Text('⚔️', style: TextStyle(fontSize: 36))),
                ),
                const SizedBox(height: 16),
                Text('Crie sua conta', style: AppTypography.displayMedium),
                const SizedBox(height: 6),
                Text(
                  'Comece sua jornada hoje!',
                  style: AppTypography.bodyMedium,
                ),
                const SizedBox(height: 32),

                // Nome completo
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome completo',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Como você se chama?';
                    if (v.trim().length < 2) return 'Nome muito curto';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // E-mail
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Qual é o seu e-mail?';
                    if (!v.contains('@') || !v.contains('.')) return 'E-mail inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Senha
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_showPassword,
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _showPassword = !_showPassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Crie uma senha segura';
                    if (v.length < 6) return 'A senha precisa ter pelo menos 6 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 28),

                JFButton(
                  label: 'Criar Conta',
                  isLoading: _isLoading,
                  onPressed: _isLoading ? null : _register,
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('ou', style: AppTypography.bodyMedium),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 16),

                JFButton(
                  label: 'Entrar com Google',
                  variant: JFButtonVariant.secondary,
                  icon: const Text('G', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary)),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Em breve! 🙏')),
                    );
                  },
                ),
                const SizedBox(height: 12),

                JFButton(
                  label: 'Entrar com Apple',
                  variant: JFButtonVariant.secondary,
                  icon: const Icon(Icons.apple, color: AppColors.textPrimary),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Em breve! 🙏')),
                    );
                  },
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

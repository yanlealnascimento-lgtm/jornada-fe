import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/providers/user_provider.dart';
import '../../shared/widgets/jf_button.dart';
import '../../shared/widgets/jf_neumorphic.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _showPassword = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      await ref.read(currentUserProvider.notifier).login(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = _friendlyError(e.toString());
        });
      }
    }
  }

  String _friendlyError(String raw) {
    if (raw.contains('401') || raw.contains('Credenciais')) return 'E-mail ou senha incorretos.';
    if (raw.contains('timeout') || raw.contains('Timeout')) return 'Servidor não disponível. Verifique sua conexão.';
    if (raw.contains('connection') || raw.contains('Connection') || raw.contains('refused')) return 'Sem conexão com o servidor. Tente novamente mais tarde.';
    return 'Erro ao entrar. Tente novamente.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 48),
                // Logo
                JFNeumorphicBox(
                  borderRadius: 24,
                  padding: const EdgeInsets.all(18),
                  child: SizedBox(
                    width: 72,
                    height: 72,
                    child: Image.asset('assets/images/dove_icon.png', fit: BoxFit.contain),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Bem-vindo de volta!', style: AppTypography.displayMedium, textAlign: TextAlign.center),
                const SizedBox(height: 6),
                Text('Continue sua jornada de fé', style: AppTypography.bodyMedium, textAlign: TextAlign.center),
                const SizedBox(height: 36),

                // E-mail
                _NeumorphicField(
                  controller: _emailCtrl,
                  label: 'E-mail, telefone ou nome de usuário',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Informe seu e-mail';
                    if (!v.contains('@') || !v.contains('.')) return 'E-mail inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Senha
                _NeumorphicField(
                  controller: _passwordCtrl,
                  label: 'Senha',
                  icon: Icons.lock_outline,
                  obscureText: !_showPassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: AppColors.textHint,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _showPassword = !_showPassword),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Informe sua senha';
                    return null;
                  },
                ),
                const SizedBox(height: 8),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: Text('Esqueci minha senha', style: AppTypography.label.copyWith(color: AppColors.primary)),
                  ),
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.incorrectLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.incorrect, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_errorMessage!, style: AppTypography.label.copyWith(color: AppColors.incorrectDark))),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),
                JFButton(label: 'Entrar', isLoading: _isLoading, onPressed: _isLoading ? null : _login),
                const SizedBox(height: 20),

                Row(children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('ou', style: AppTypography.bodyMedium),
                  ),
                  const Expanded(child: Divider()),
                ]),
                const SizedBox(height: 16),

                JFButton(
                  label: 'Criar conta gratuita',
                  variant: JFButtonVariant.secondary,
                  onPressed: () => context.push('/onboarding/register'),
                ),
                const SizedBox(height: 20),

                // Social login divider
                Row(children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('ou entre com',
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.textHint)),
                  ),
                  const Expanded(child: Divider()),
                ]),
                const SizedBox(height: 16),

                // Social login buttons (mock)
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Login com Google em breve! 🙏')),
                      ),
                      icon: const Text('G', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFFDB4437))),
                      label: const Text('Google'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Login com Facebook em breve! 🙏')),
                      ),
                      icon: const Text('f', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1877F2))),
                      label: const Text('Facebook'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NeumorphicField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final TextInputType keyboardType;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const _NeumorphicField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.neumorphBase,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.neumorphDark.withValues(alpha: 0.5),
            offset: const Offset(3, 3),
            blurRadius: 8,
          ),
          BoxShadow(
            color: AppColors.neumorphLight.withValues(alpha: 0.9),
            offset: const Offset(-3, -3),
            blurRadius: 8,
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        style: AppTypography.bodyMedium,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20, color: AppColors.textSecondary),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: Colors.transparent,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.incorrect, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.incorrect, width: 1.5),
          ),
        ),
      ),
    );
  }
}

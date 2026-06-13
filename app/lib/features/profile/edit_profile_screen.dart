import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/providers/user_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  bool _obscurePassword = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider).valueOrNull;
      if (user != null && mounted) {
        setState(() {
          _nameController.text = user.name;
          _usernameController.text = user.username ?? '';
          _emailController.text = user.email;
          _phoneController.text = user.phone ?? '';
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Perfil'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Salvar',
                    style: AppTypography.buttonMedium.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Avatar ──────────────────────────────────────────
            Center(
              child: GestureDetector(
                onTap: _pickPhoto,
                child: Consumer(
                  builder: (context, ref, _) {
                    final user = ref.watch(currentUserProvider).valueOrNull;
                    final avatarUrl = user?.avatarUrl;
                    final hasLocal = avatarUrl != null &&
                        avatarUrl.startsWith('/') &&
                        File(avatarUrl).existsSync();
                    final hasNetwork = avatarUrl != null &&
                        avatarUrl.startsWith('http');

                    return Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: isDark
                              ? AppColors.darkSurface
                              : AppColors.primaryLight,
                          backgroundImage: hasLocal
                              ? FileImage(File(avatarUrl))
                              : hasNetwork
                                  ? NetworkImage(avatarUrl) as ImageProvider
                                  : null,
                          child: (!hasLocal && !hasNetwork)
                              ? Icon(
                                  Icons.person,
                                  size: 50,
                                  color: isDark
                                      ? AppColors.darkTextSecond
                                      : AppColors.primary,
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark
                                    ? AppColors.darkBackground
                                    : AppColors.background,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ── Nome ────────────────────────────────────────────
            _buildField(
              label: 'Nome',
              controller: _nameController,
              hintText: 'Seu nome completo',
              isDark: isDark,
            ),
            const SizedBox(height: 16),

            // ── Usuário ─────────────────────────────────────────
            _buildField(
              label: 'Usuário',
              controller: _usernameController,
              hintText: 'seu_usuario',
              isDark: isDark,
              prefixText: '@ ',
            ),
            const SizedBox(height: 16),

            // ── Senha ───────────────────────────────────────────
            _buildLabel('Senha', isDark),
            const SizedBox(height: 8),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: _inputDecoration(isDark).copyWith(
                hintText: 'Nova senha (deixe vazio para manter)',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: isDark ? AppColors.darkTextSecond : AppColors.textHint,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              style: TextStyle(
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            // ── E-mail ──────────────────────────────────────────
            _buildField(
              label: 'E-mail',
              controller: _emailController,
              hintText: 'seu@email.com',
              isDark: isDark,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            // ── Telefone ────────────────────────────────────────
            _buildLabel('Telefone', isDark),
            const SizedBox(height: 8),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _PhoneMaskFormatter(),
              ],
              decoration: _inputDecoration(isDark).copyWith(
                hintText: '(XX) XXXXX-XXXX',
              ),
              style: TextStyle(
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 40),

            // ── Excluir Conta ───────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _showDeleteDialog(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.incorrect,
                  side: BorderSide(
                    color: isDark
                        ? const Color(0xFF7F1D1D)
                        : const Color(0xFFFECACA),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Excluir Conta'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _buildLabel(String text, bool isDark) {
    return Text(
      text,
      style: AppTypography.label.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required bool isDark,
    String? prefixText,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label, isDark),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: _inputDecoration(isDark).copyWith(
            hintText: hintText,
            prefixText: prefixText,
            prefixStyle: TextStyle(
              color: isDark ? AppColors.darkTextSecond : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(bool isDark) {
    return InputDecoration(
      filled: true,
      fillColor: isDark ? AppColors.darkSurface : Colors.white,
      hintStyle: TextStyle(
        color: isDark ? AppColors.darkTextSecond : AppColors.textHint,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }

  Future<void> _pickAndSaveAvatar(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked == null) return;

    // Copia para diretório persistente do app
    final appDir = Directory('${File(picked.path).parent.parent.path}/app_flutter');
    if (!appDir.existsSync()) appDir.createSync(recursive: true);
    final savedPath = '${appDir.path}/avatar_profile.jpg';
    await File(picked.path).copy(savedPath);

    final user = ref.read(currentUserProvider).valueOrNull;
    if (user != null) {
      ref.read(currentUserProvider.notifier).updateLocally(
        user.copyWith(avatarUrl: savedPath),
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto de perfil atualizada!')),
      );
    }
  }

  void _pickPhoto() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBorder : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Foto de Perfil',
              style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1A2E4A),
                fontFamily: 'Nunito',
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFEFF6FF),
                child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF4A90E2)),
              ),
              title: Text('Tirar foto', style: TextStyle(color: isDark ? AppColors.darkTextPrimary : null)),
              onTap: () {
                Navigator.pop(context);
                _pickAndSaveAvatar(ImageSource.camera);
              },
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFEFF6FF),
                child: const Icon(Icons.photo_library_rounded, color: Color(0xFF4A90E2)),
              ),
              title: Text('Escolher da galeria', style: TextStyle(color: isDark ? AppColors.darkTextPrimary : null)),
              onTap: () {
                Navigator.pop(context);
                _pickAndSaveAvatar(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: isDark ? const Color(0xFF3F1515) : Colors.red.shade50,
                child: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              ),
              title: Text('Remover foto',
                  style: TextStyle(color: isDark ? const Color(0xFFFF6B6B) : Colors.red)),
              onTap: () {
                Navigator.pop(context);
                final user = ref.read(currentUserProvider).valueOrNull;
                if (user != null) {
                  ref.read(currentUserProvider.notifier).updateLocally(
                    user.copyWith(avatarUrl: ''),
                  );
                }
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);

    try {
      await ref.read(currentUserProvider.notifier).updateProfile(
        name: _nameController.text.trim(),
        username: _usernameController.text.trim(),
        phone: _phoneController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil salvo com sucesso!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showDeleteDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        title: Text(
          'Excluir conta',
          style: AppTypography.headingMedium.copyWith(
            color: AppColors.incorrect,
          ),
        ),
        content: Text(
          'Tem certeza que deseja excluir sua conta? Esta ação não pode ser desfeita.',
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
                color: isDark
                    ? AppColors.darkTextSecond
                    : AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Exclusão de conta em desenvolvimento')),
              );
            },
            child: const Text(
              'Excluir',
              style: TextStyle(color: AppColors.incorrect),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Phone Mask Formatter ─────────────────────────────────────────────────────
// Formats digits as (XX) XXXXX-XXXX — no external package needed.

class _PhoneMaskFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();

    for (int i = 0; i < digits.length && i < 11; i++) {
      if (i == 0) buffer.write('(');
      if (i == 2) buffer.write(') ');
      if (i == 7) buffer.write('-');
      buffer.write(digits[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

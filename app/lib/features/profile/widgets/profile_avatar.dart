import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class ProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  final String displayName;
  final String leagueTier;
  final bool isEditable;
  final VoidCallback? onCameraTap;

  const ProfileAvatar({
    super.key,
    this.imageUrl,
    required this.displayName,
    this.leagueTier = 'bronze',
    this.isEditable = false,
    this.onCameraTap,
  });

  static const Map<String, Color> _borders = {
    'bronze': Color(0xFF4A90E2),
    'silver': Color(0xFFC0C0C0),
    'gold': Color(0xFFFFD700),
    'sapphire': Color(0xFF0F52BA),
    'onyx': Color(0xFF353839),
    'diamond': Color(0xFF7DD3FC),
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = _borders[leagueTier] ?? const Color(0xFF4A90E2);

    return GestureDetector(
      onTap: isEditable ? onCameraTap : null,
      child: Stack(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: borderColor, width: 3),
              color: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFEBF5FF),
            ),
            child: ClipOval(
              child: imageUrl != null
                  ? _buildImage(imageUrl!, borderColor, isDark)
                  : _initialWidget(borderColor, isDark),
            ),
          ),
          if (isEditable)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: const Color(0xFF4A90E2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    width: 2,
                  ),
                ),
                child: const Icon(Icons.camera_alt_rounded,
                    color: Colors.white, size: 13),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImage(String url, Color borderColor, bool isDark) {
    // Local file path (starts with /)
    if (url.startsWith('/')) {
      final file = File(url);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover, width: 90, height: 90,
            errorBuilder: (_, __, ___) => _initialWidget(borderColor, isDark));
      }
      return _initialWidget(borderColor, isDark);
    }
    // Network URL
    return Image.network(url, fit: BoxFit.cover, width: 90, height: 90,
        errorBuilder: (_, __, ___) => _initialWidget(borderColor, isDark));
  }

  Widget _initialWidget(Color color, bool isDark) {
    return Center(
      child: Text(
        displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w700,
          color: color,
          fontFamily: 'Nunito',
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  static TextStyle get displayLarge => GoogleFonts.nunito(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        height: 1.2,
      );

  static TextStyle get displayMedium => GoogleFonts.nunito(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        height: 1.2,
      );

  static TextStyle get headingLarge => GoogleFonts.nunito(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.3,
      );

  static TextStyle get headingMedium => GoogleFonts.nunito(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.3,
      );

  static TextStyle get bodyLarge => GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.5,
      );

  static TextStyle get bodyMedium => GoogleFonts.nunito(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.5,
      );

  static TextStyle get label => GoogleFonts.nunito(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.4,
        letterSpacing: 0.3,
      );

  static TextStyle get xpText => GoogleFonts.nunito(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: AppColors.xpColor,
        height: 1.2,
      );

  static TextStyle get buttonLarge => GoogleFonts.nunito(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.3,
        height: 1.2,
      );

  static TextStyle get buttonMedium => GoogleFonts.nunito(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
        height: 1.2,
      );

  static TextStyle get caption => GoogleFonts.nunito(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textHint,
        height: 1.4,
      );

  static TextStyle get streakNumber => GoogleFonts.nunito(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: AppColors.streakColor,
        height: 1.0,
      );
}

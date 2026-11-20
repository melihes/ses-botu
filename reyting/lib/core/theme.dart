import 'package:flutter/material.dart';

/// Reyting'in kendi renk kimliği:
/// koyu mor "stüdyo karanlığı" zemin, "REC" mercan kırmızısı ana vurgu,
/// turkuaz ikincil vurgu. Para/kâr yeşil, zarar kırmızı.
class AppColors {
  static const bg = Color(0xFF130F1D);
  static const sidebar = Color(0xFF0D0A15);
  static const panel = Color(0xFF1E182B);
  static const panelHi = Color(0xFF282038);
  static const border = Color(0xFF3B3052);
  static const accent = Color(0xFFFF5C7A); // REC kırmızısı
  static const accent2 = Color(0xFFFF8F5C); // gün batımı turuncusu
  static const cyan = Color(0xFF36D6E7);
  static const green = Color(0xFF5BE49B);
  static const red = Color(0xFFFF5D5D);
  static const yellow = Color(0xFFFFD166);
  static const orange = Color(0xFFFFA45C);
  static const blue = Color(0xFF6C9BFF);
  static const purple = Color(0xFFB07CFF);
  static const pink = Color(0xFFFF7EC8);
  static const teal = Color(0xFF2FC4A5);
  static const text = Color(0xFFF4F1FA);
  static const textDim = Color(0xFFA79DBD);
  static const textFaint = Color(0xFF706688);

  static const accentGradient = LinearGradient(
    colors: [accent, accent2],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.accent,
      secondary: AppColors.cyan,
      surface: AppColors.panel,
      error: AppColors.red,
    ),
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.text,
      displayColor: AppColors.text,
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: AppColors.cyan,
      inactiveTrackColor: AppColors.border,
      thumbColor: AppColors.accent,
      overlayColor: Color(0x33FF5C7A),
      trackHeight: 6,
    ),
    dialogTheme: const DialogThemeData(backgroundColor: AppColors.panel),
  );
}

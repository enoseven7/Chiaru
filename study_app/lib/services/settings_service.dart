import 'dart:ui';

import 'package:flutter/material.dart';

enum ThemePreset { dark, light, amoled, sunset, ocean, forest, retro, custom }

class AppSettings {
  AppSettings({
    required this.preset,
    required this.brightness,
    required this.primary,
    required this.secondary,
    required this.surface,
    required this.panel,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.outline,
    required this.gradientStart,
    required this.gradientEnd,
    this.useGradient = true,
    this.fontScale = 1.0,
    this.highContrast = false,
    this.reduceMotion = false,
    this.aiDailyLimit = 1000,
    this.aiOnlineAllowed = true,
  });

  final ThemePreset preset;
  final Brightness brightness;
  final Color primary;
  final Color secondary;
  final Color surface;
  final Color panel;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color outline;
  final Color gradientStart;
  final Color gradientEnd;
  final bool useGradient;
  final double fontScale;
  final bool highContrast;
  final bool reduceMotion;
  final int aiDailyLimit;
  final bool aiOnlineAllowed;

  AppSettings copyWith({
    ThemePreset? preset,
    Brightness? brightness,
    Color? primary,
    Color? secondary,
    Color? surface,
    Color? panel,
    Color? onSurface,
    Color? onSurfaceVariant,
    Color? outline,
    Color? gradientStart,
    Color? gradientEnd,
    bool? useGradient,
    double? fontScale,
    bool? highContrast,
    bool? reduceMotion,
    int? aiDailyLimit,
    bool? aiOnlineAllowed,
  }) {
    return AppSettings(
      preset: preset ?? this.preset,
      brightness: brightness ?? this.brightness,
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      surface: surface ?? this.surface,
      panel: panel ?? this.panel,
      onSurface: onSurface ?? this.onSurface,
      onSurfaceVariant: onSurfaceVariant ?? this.onSurfaceVariant,
      outline: outline ?? this.outline,
      gradientStart: gradientStart ?? this.gradientStart,
      gradientEnd: gradientEnd ?? this.gradientEnd,
      useGradient: useGradient ?? this.useGradient,
      fontScale: fontScale ?? this.fontScale,
      highContrast: highContrast ?? this.highContrast,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      aiDailyLimit: aiDailyLimit ?? this.aiDailyLimit,
      aiOnlineAllowed: aiOnlineAllowed ?? this.aiOnlineAllowed,
    );
  }

  factory AppSettings.fromPreset(ThemePreset preset) {
    switch (preset) {
      case ThemePreset.light:
        return AppSettings(
          preset: preset,
          brightness: Brightness.light,
          primary: const Color(0xFF2563EB),
          secondary: const Color(0xFF475569),
          surface: const Color(0xFFF8FAFC),
          panel: const Color(0xFFE2E8F0),
          onSurface: const Color(0xFF0F172A),
          onSurfaceVariant: const Color(0xFF475569),
          outline: const Color(0xFFCBD5E1),
          gradientStart: const Color(0xFFF8FAFC),
          gradientEnd: const Color(0xFFE2E8F0),
          useGradient: true,
        );
      case ThemePreset.amoled:
        return AppSettings(
          preset: preset,
          brightness: Brightness.dark,
          primary: const Color(0xFF4B8BFE),
          secondary: const Color(0xFF94A3B8),
          surface: const Color(0xFF000000),
          panel: const Color(0xFF0A0A0A),
          onSurface: const Color(0xFFE5E7EB),
          onSurfaceVariant: const Color(0xFF94A3B8),
          outline: Colors.white.withOpacity(0.08),
          gradientStart: const Color(0xFF000000),
          gradientEnd: const Color(0xFF111111),
          useGradient: false,
        );
      case ThemePreset.sunset:
        return AppSettings(
          preset: preset,
          brightness: Brightness.dark,
          primary: const Color(0xFFF97316),
          secondary: const Color(0xFFF59E0B),
          surface: const Color(0xFF0F172A),
          panel: const Color(0xFF111827),
          onSurface: const Color(0xFFF8FAFC),
          onSurfaceVariant: const Color(0xFFFCD34D),
          outline: Colors.white.withOpacity(0.08),
          gradientStart: const Color(0xFF1F1031),
          gradientEnd: const Color(0xFF312E81),
          useGradient: true,
        );
      case ThemePreset.ocean:
        return AppSettings(
          preset: preset,
          brightness: Brightness.dark,
          primary: const Color(0xFF0EA5E9),
          secondary: const Color(0xFF22C55E),
          surface: const Color(0xFF071422),
          panel: const Color(0xFF0B1926),
          onSurface: const Color(0xFFE2F3FF),
          onSurfaceVariant: const Color(0xFFA5F3FC),
          outline: Colors.white.withOpacity(0.08),
          gradientStart: const Color(0xFF0F2027),
          gradientEnd: const Color(0xFF203A43),
          useGradient: true,
        );
      case ThemePreset.forest:
        return AppSettings(
          preset: preset,
          brightness: Brightness.dark,
          primary: const Color(0xFF22C55E),
          secondary: const Color(0xFF16A34A),
          surface: const Color(0xFF0A120C),
          panel: const Color(0xFF0F1A11),
          onSurface: const Color(0xFFE2F3E7),
          onSurfaceVariant: const Color(0xFF86EFAC),
          outline: Colors.white.withOpacity(0.08),
          gradientStart: const Color(0xFF0C1B13),
          gradientEnd: const Color(0xFF122719),
          useGradient: true,
        );
      case ThemePreset.retro:
        // Windows XP/Vista inspired theme
        // Classic Windows blue with Luna silver/olive tones
        return AppSettings(
          preset: preset,
          brightness: Brightness.light,
          primary: const Color(0xFF0053D6), // Windows XP blue
          secondary: const Color(0xFF5B9BD5), // Windows Vista glass blue
          surface: const Color(0xFFECE9D8), // Windows XP olive/silver background
          panel: const Color(0xFFD4D0C8), // Classic Windows gray
          onSurface: const Color(0xFF000000), // Classic black text
          onSurfaceVariant: const Color(0xFF3C3C3C), // Dark gray text
          outline: const Color(0xFF8B8680), // Classic border gray
          gradientStart: const Color(0xFFECE9D8), // XP olive
          gradientEnd: const Color(0xFFD4D0C8), // Classic gray
          useGradient: true,
        );
      case ThemePreset.custom:
        return AppSettings.fromPreset(ThemePreset.dark).copyWith(preset: ThemePreset.custom);
      case ThemePreset.dark:
        return AppSettings(
          preset: ThemePreset.dark,
          brightness: Brightness.dark,
          primary: const Color(0xFF4B8BFE),
          secondary: const Color(0xFF94A3B8),
          surface: const Color(0xFF0E1116),
          panel: const Color(0xFF12161C),
          onSurface: const Color(0xFFE2E8F0),
          onSurfaceVariant: const Color(0xFF94A3B8),
          outline: Colors.white.withOpacity(0.04),
          gradientStart: const Color(0xFF0E1116),
          gradientEnd: const Color(0xFF161B22),
          useGradient: true,
        );
    }
  }
}

final ValueNotifier<AppSettings> appSettingsNotifier =
    ValueNotifier(AppSettings.fromPreset(ThemePreset.dark));

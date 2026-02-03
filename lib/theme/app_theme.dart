import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryText = Color(0xFF3A2A17);
  static const Color secondaryText = Color(0xFF7A6550);
  static const Color border = Color(0xFFCBB28F);
  static const Color background = Color(0xFFFDF7F0);
}

class ThemePalette {
  const ThemePalette({
    required this.name,
    required this.background,
    required this.text,
    this.gradient,
  });

  final String name;
  final Color background;
  final Color text;
  final LinearGradient? gradient;
}

class ReadingThemePalette {
  const ReadingThemePalette({
    required this.name,
    required this.background,
    required this.text,
    this.gradient,
    this.description,
  });

  final String name;
  final Color background;
  final Color text;
  final LinearGradient? gradient;
  final String? description;
}

const Map<String, ThemePalette> globalThemes = {
  'light': ThemePalette(
    name: 'Light',
    background: Color(0xFFFDF7F0),
    text: Color(0xFF3A2A17),
  ),
  'black-white': ThemePalette(
    name: 'White',
    background: Color(0xFFFFFFFF),
    text: Color(0xFF121212),
  ),
  'dark': ThemePalette(
    name: 'Dark',
    background: Color(0xFF1C140E),
    text: Colors.white,
  ),
  'nature': ThemePalette(
    name: 'Nature',
    background: Color(0xFFEAF4EA),
    text: Color(0xFF1E2F21),
  ),
  'ocean': ThemePalette(
    name: 'Ocean',
    background: Color(0xFFE6F3FF),
    text: Color(0xFF0E2A3B),
  ),
  'sunset': ThemePalette(
    name: 'Sunset',
    background: Color(0xFFFFF0E6),
    text: Color(0xFF4B1D11),
  ),
  'midnight': ThemePalette(
    name: 'Midnight',
    background: Color(0xFF0B0B0F),
    text: Color(0xFFF5F5F5),
  ),
  'coffee': ThemePalette(
    name: 'Coffee',
    background: Color(0xFF2B1F15),
    text: Color(0xFFF3E9DD),
  ),
};

const Map<String, ReadingThemePalette> readingThemes = {
  'default': ReadingThemePalette(
    name: 'Coffee Shop',
    background: Color(0xFFFDF7F0),
    text: Color(0xFF3A2A17),
    description: 'Warm cafe vibes',
  ),
  'black-white': ReadingThemePalette(
    name: 'Black & White',
    background: Color(0xFFFFFFFF),
    text: Color(0xFF121212),
    description: 'Bright and clean',
  ),
  'rainforest': ReadingThemePalette(
    name: 'Rainforest',
    background: Color(0xFFE5F2E5),
    text: Color(0xFF1D3323),
    description: 'Lush greens',
  ),
  'mystery': ReadingThemePalette(
    name: 'Mystery',
    background: Color(0xFF1E1B2E),
    text: Color(0xFFE6D5FF),
    description: 'Moody and dark',
  ),
  'paper': ReadingThemePalette(
    name: 'Paper',
    background: Color(0xFFF6F1E6),
    text: Color(0xFF2F2620),
    description: 'Soft paper tone',
  ),
  'ocean-depth': ReadingThemePalette(
    name: 'Ocean Depth',
    background: Color(0xFFE3F2FD),
    text: Color(0xFF0C2A43),
    description: 'Deep blue calm',
  ),
  'sunset': ReadingThemePalette(
    name: 'Sunset',
    background: Color(0xFFFFEDE1),
    text: Color(0xFF4B1D11),
    description: 'Warm orange glow',
  ),
  'midnight': ReadingThemePalette(
    name: 'Midnight',
    background: Color(0xFF0D0E16),
    text: Color(0xFFF1F1F1),
    description: 'Low light comfort',
  ),
  'lavender-dream': ReadingThemePalette(
    name: 'Lavender Dream',
    background: Color(0xFFF1E9FF),
    text: Color(0xFF3C2A53),
    description: 'Soft lavender',
  ),
  'custom': ReadingThemePalette(
    name: 'Custom',
    background: Color(0xFFFDF7F0),
    text: Color(0xFF3A2A17),
    description: 'Use your colors',
  ),
};

ThemePalette themeForGlobal(String key, {DateTime? now}) {
  if (key == 'auto') {
    final hour = (now ?? DateTime.now()).hour;
    if (hour >= 6 && hour < 17) {
      return globalThemes['light']!;
    }
    if (hour >= 17 && hour < 21) {
      return globalThemes['sunset']!;
    }
    return globalThemes['midnight']!;
  }
  if (key == 'weather') {
    return globalThemes['ocean']!;
  }
  return globalThemes[key] ?? globalThemes['light']!;
}

ReadingThemePalette readingThemeForKey(String key, {DateTime? now}) {
  if (key == 'auto') {
    final hour = (now ?? DateTime.now()).hour;
    if (hour >= 6 && hour < 17) {
      return readingThemes['default']!;
    }
    if (hour >= 17 && hour < 21) {
      return readingThemes['sunset']!;
    }
    return readingThemes['midnight']!;
  }
  if (key == 'weather') {
    return readingThemes['ocean-depth']!;
  }
  return readingThemes[key] ?? readingThemes['default']!;
}

import 'package:flutter/material.dart';

import '../models/book.dart';
import '../theme/app_theme.dart';

class GlobalThemeButton extends StatelessWidget {
  const GlobalThemeButton({
    super.key,
    required this.preferences,
    required this.onPreferencesChange,
  });

  final UserPreferences preferences;
  final ValueChanged<UserPreferences> onPreferencesChange;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.settings),
      tooltip: 'Global Theme Settings',
      onPressed: () => _openSheet(context),
    );
  }

  void _openSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: GlobalThemeSheet(
            preferences: preferences,
            onPreferencesChange: onPreferencesChange,
          ),
        );
      },
    );
  }
}

class GlobalThemeSheet extends StatelessWidget {
  const GlobalThemeSheet({
    super.key,
    required this.preferences,
    required this.onPreferencesChange,
  });

  final UserPreferences preferences;
  final ValueChanged<UserPreferences> onPreferencesChange;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? Colors.white : AppColors.primaryText;
    final secondaryText =
        isDark ? Colors.white.withValues(alpha: 0.7) : AppColors.secondaryText;
    final now = DateTime.now();
    final autoLabel = _autoLabelForHour(now.hour);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            'Global App Theme',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: primaryText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Choose a theme that affects the library, navigation, and controls.',
            style: TextStyle(color: secondaryText),
          ),
          if (preferences.globalTheme == 'auto') ...[
            const SizedBox(height: 8),
            Text(
              'Auto theme: $autoLabel',
              style: TextStyle(color: secondaryText, fontSize: 12),
            ),
          ],
          if (preferences.globalTheme == 'weather') ...[
            const SizedBox(height: 8),
            Text(
              'Weather mode uses the Ocean theme in this demo.',
              style: TextStyle(color: secondaryText, fontSize: 12),
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _themeOptions.map((entry) {
              final isSelected = preferences.globalTheme == entry.key;
              return ChoiceChip(
                label: Text(entry.label),
                selected: isSelected,
                labelStyle: TextStyle(
                  color: primaryText,
                ),
                onSelected: (_) {
                  onPreferencesChange(
                    preferences.copyWith(globalTheme: entry.key),
                  );
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  String _autoLabelForHour(int hour) {
    if (hour >= 6 && hour < 12) return 'Morning theme';
    if (hour >= 12 && hour < 17) return 'Afternoon theme';
    if (hour >= 17 && hour < 21) return 'Evening theme';
    return 'Night theme';
  }
}

class _ThemeOption {
  const _ThemeOption(this.key, this.label);

  final String key;
  final String label;
}

const List<_ThemeOption> _themeOptions = [
  _ThemeOption('light', 'Light'),
  _ThemeOption('black-white', 'Black & White'),
  _ThemeOption('dark', 'Dark'),
  _ThemeOption('nature', 'Nature'),
  _ThemeOption('ocean', 'Ocean'),
  _ThemeOption('sunset', 'Sunset'),
  _ThemeOption('midnight', 'Midnight'),
  _ThemeOption('coffee', 'Coffee'),
  _ThemeOption('auto', 'Auto'),
  _ThemeOption('weather', 'Weather'),
];

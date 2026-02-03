import 'package:flutter/material.dart';

import '../models/book.dart';
import '../theme/app_theme.dart';

class ReaderSettingsButton extends StatelessWidget {
  const ReaderSettingsButton({
    super.key,
    required this.preferences,
    required this.onPreferencesChange,
    this.currentBook,
  });

  final UserPreferences preferences;
  final ValueChanged<UserPreferences> onPreferencesChange;
  final Book? currentBook;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.tune),
      tooltip: 'Reading Settings',
      onPressed: () => _openSheet(context),
    );
  }

  void _openSheet(BuildContext context) {
    showModalBottomSheet<void>(
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
          child: ReaderSettingsSheet(
            preferences: preferences,
            onPreferencesChange: onPreferencesChange,
            currentBook: currentBook,
          ),
        );
      },
    );
  }
}

class ReaderSettingsSheet extends StatefulWidget {
  const ReaderSettingsSheet({
    super.key,
    required this.preferences,
    required this.onPreferencesChange,
    this.currentBook,
  });

  final UserPreferences preferences;
  final ValueChanged<UserPreferences> onPreferencesChange;
  final Book? currentBook;

  @override
  State<ReaderSettingsSheet> createState() => _ReaderSettingsSheetState();
}

class _ReaderSettingsSheetState extends State<ReaderSettingsSheet> {
  late UserPreferences _local;

  @override
  void initState() {
    super.initState();
    _local = widget.preferences;
  }

  @override
  void didUpdateWidget(covariant ReaderSettingsSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.preferences != widget.preferences) {
      _local = widget.preferences;
    }
  }

  void _update(UserPreferences next) {
    setState(() => _local = next);
    widget.onPreferencesChange(next);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? Colors.white : AppColors.primaryText;
    final secondaryText =
        isDark ? Colors.white.withValues(alpha: 0.7) : AppColors.secondaryText;

    return DefaultTabController(
      length: 5,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reading Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: primaryText,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Customize appearance, audio, and reading flow.',
              style: TextStyle(color: secondaryText),
            ),
            const SizedBox(height: 12),
            const TabBar(
              isScrollable: true,
              tabs: [
                Tab(text: 'Appearance'),
                Tab(text: 'Audio'),
                Tab(text: 'Flow'),
                Tab(text: 'Interaction'),
                Tab(text: 'Smart'),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 420,
              child: TabBarView(
                children: [
                  _AppearanceTab(
                    preferences: _local,
                    onPreferencesChange: _update,
                    currentBook: widget.currentBook,
                  ),
                  _AudioTab(
                    preferences: _local,
                    onPreferencesChange: _update,
                  ),
                  _FlowTab(
                    preferences: _local,
                    onPreferencesChange: _update,
                  ),
                  _InteractionTab(
                    preferences: _local,
                    onPreferencesChange: _update,
                  ),
                  _SmartTab(
                    preferences: _local,
                    onPreferencesChange: _update,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _AppearanceTab extends StatelessWidget {
  const _AppearanceTab({
    required this.preferences,
    required this.onPreferencesChange,
    this.currentBook,
  });

  final UserPreferences preferences;
  final ValueChanged<UserPreferences> onPreferencesChange;
  final Book? currentBook;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _SectionTitle(title: 'Reading Theme'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _themeOptions.map((option) {
            final isSelected = preferences.readingTheme == option.key;
            return ChoiceChip(
              label: Text(option.label),
              selected: isSelected,
              onSelected: (_) => _applyReadingTheme(option.key),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        _SectionTitle(title: 'Font Family'),
        DropdownButtonFormField<String>(
          value: preferences.fontFamily,
          items: _fontFamilies
              .map(
                (font) => DropdownMenuItem(
                  value: font,
                  child: Text(font, style: TextStyle(fontFamily: font)),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            onPreferencesChange(preferences.copyWith(fontFamily: value));
          },
        ),
        const SizedBox(height: 16),
        _SectionTitle(title: 'Font Size (${preferences.fontSize.round()}px)'),
        Slider(
          min: 12,
          max: 32,
          divisions: 20,
          value: preferences.fontSize,
          onChanged: (value) {
            onPreferencesChange(preferences.copyWith(fontSize: value));
          },
        ),
        _SectionTitle(
          title: 'Line Height (${preferences.lineHeight.toStringAsFixed(1)})',
        ),
        Slider(
          min: 1.2,
          max: 2.5,
          divisions: 13,
          value: preferences.lineHeight,
          onChanged: (value) {
            onPreferencesChange(preferences.copyWith(lineHeight: value));
          },
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  void _applyReadingTheme(String key) {
    if (key == 'ai-auto' && currentBook != null) {
      final selection = _aiSelectTheme(currentBook!);
      onPreferencesChange(
        preferences.copyWith(
          readingTheme: key,
          backgroundColor: selection.palette.background,
          textColor: selection.palette.text,
          backgroundNoise: selection.suggestedAmbience,
        ),
      );
      return;
    }

    final palette = readingThemeForKey(key);
    onPreferencesChange(
      preferences.copyWith(
        readingTheme: key,
        backgroundColor: palette.background,
        textColor: palette.text,
      ),
    );
  }

  _AiThemeSelection _aiSelectTheme(Book book) {
    final genres = book.genre.map((g) => g.toLowerCase()).toList();
    if (genres.any((g) => g.contains('mystery') || g.contains('thriller'))) {
      return _AiThemeSelection(
        palette: readingThemes['mystery']!,
        suggestedAmbience: 'urban',
      );
    }
    if (genres.any((g) => g.contains('fantasy') || g.contains('adventure'))) {
      return _AiThemeSelection(
        palette: readingThemes['rainforest']!,
        suggestedAmbience: 'forest',
      );
    }
    if (genres.any((g) => g.contains('romance') || g.contains('drama'))) {
      return _AiThemeSelection(
        palette: readingThemes['sunset']!,
        suggestedAmbience: 'cafe',
      );
    }
    if (genres.any((g) => g.contains('science') || g.contains('space'))) {
      return _AiThemeSelection(
        palette: readingThemes['midnight']!,
        suggestedAmbience: 'soft-beats',
      );
    }
    return _AiThemeSelection(
      palette: readingThemes['default']!,
      suggestedAmbience: 'none',
    );
  }
}

class _AudioTab extends StatelessWidget {
  const _AudioTab({
    required this.preferences,
    required this.onPreferencesChange,
  });

  final UserPreferences preferences;
  final ValueChanged<UserPreferences> onPreferencesChange;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _SectionTitle(title: 'Background Ambience'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _ambienceOptions.map((option) {
            final isSelected = preferences.backgroundNoise == option.key;
            return ChoiceChip(
              label: Text(option.label),
              selected: isSelected,
              onSelected: (_) {
                onPreferencesChange(
                  preferences.copyWith(backgroundNoise: option.key),
                );
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        if (preferences.backgroundNoise != 'none')
          _SectionTitle(
            title:
                'Volume ${(preferences.noiseVolume * 100).round()}%',
          ),
        if (preferences.backgroundNoise != 'none')
          Slider(
            min: 0,
            max: 1,
            divisions: 10,
            value: preferences.noiseVolume,
            onChanged: (value) {
              onPreferencesChange(preferences.copyWith(noiseVolume: value));
            },
          ),
        const SizedBox(height: 12),
        SwitchListTile(
          value: preferences.ttsEnabled,
          onChanged: (value) {
            if (!value) {
              onPreferencesChange(preferences.copyWith(ttsEnabled: false));
              return;
            }
            onPreferencesChange(preferences.copyWith(ttsEnabled: value));
          },
          title: const Text('Text-to-Speech'),
        ),
        if (preferences.ttsEnabled) ...[
          const SizedBox(height: 8),
          _SectionTitle(title: 'Narrator Voice'),
          DropdownButtonFormField<String>(
            value: preferences.ttsVoice,
            items: _ttsVoices
                .map(
                  (voice) => DropdownMenuItem(
                    value: voice.value,
                    child: Text(voice.label),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              onPreferencesChange(preferences.copyWith(ttsVoice: value));
            },
          ),
          const SizedBox(height: 12),
          _SectionTitle(title: 'Reading Tone'),
          DropdownButtonFormField<String>(
            value: preferences.ttsTone,
            items: _ttsTones
                .map(
                  (tone) => DropdownMenuItem(
                    value: tone.value,
                    child: Text(tone.label),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              onPreferencesChange(preferences.copyWith(ttsTone: value));
            },
          ),
          const SizedBox(height: 12),
          _SectionTitle(
            title: 'Reading Speed ${preferences.ttsSpeed.toStringAsFixed(1)}x',
          ),
          Slider(
            min: 0.5,
            max: 2,
            divisions: 15,
            value: preferences.ttsSpeed,
            onChanged: (value) {
              onPreferencesChange(preferences.copyWith(ttsSpeed: value));
            },
          ),
        ],
      ],
    );
  }
}

class _FlowTab extends StatelessWidget {
  const _FlowTab({
    required this.preferences,
    required this.onPreferencesChange,
  });

  final UserPreferences preferences;
  final ValueChanged<UserPreferences> onPreferencesChange;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _SectionTitle(title: 'Reading Flow Mode'),
        RadioListTile<String>(
          value: 'none',
          groupValue: preferences.readingFlowMode,
          onChanged: (value) {
            onPreferencesChange(preferences.copyWith(readingFlowMode: value));
          },
          title: const Text('Manual Reading'),
          subtitle: const Text('Scroll and navigate manually'),
        ),
        RadioListTile<String>(
          value: 'auto-scroll',
          groupValue: preferences.readingFlowMode,
          onChanged: (value) {
            onPreferencesChange(preferences.copyWith(readingFlowMode: value));
          },
          title: const Text('Auto Scroll'),
          subtitle: const Text('Automatically scrolls the page'),
        ),
        RadioListTile<String>(
          value: 'word-cursor',
          groupValue: preferences.readingFlowMode,
          onChanged: (value) {
            onPreferencesChange(preferences.copyWith(readingFlowMode: value));
          },
          title: const Text('Word Cursor'),
          subtitle: const Text('Highlights words as you read'),
        ),
        if (preferences.readingFlowMode == 'auto-scroll') ...[
          const SizedBox(height: 8),
          _SectionTitle(
            title: 'Scroll Speed ${preferences.scrollSpeed.toStringAsFixed(1)}x',
          ),
          Slider(
            min: 0.5,
            max: 3,
            divisions: 25,
            value: preferences.scrollSpeed,
            onChanged: (value) {
              onPreferencesChange(preferences.copyWith(scrollSpeed: value));
            },
          ),
        ],
        if (preferences.readingFlowMode == 'word-cursor') ...[
          const SizedBox(height: 8),
          _SectionTitle(title: 'Cursor Style'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _cursorOptions.map((option) {
              final isSelected = preferences.readingCursorType == option.key;
              return ChoiceChip(
                label: Text(option.label),
                selected: isSelected,
                onSelected: (_) {
                  onPreferencesChange(
                    preferences.copyWith(readingCursorType: option.key),
                  );
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          _SectionTitle(
            title:
                'Reading Speed ${preferences.readingCursorSpeed.toStringAsFixed(1)}x',
          ),
          Slider(
            min: 0.2,
            max: 1.6,
            divisions: 14,
            value: preferences.readingCursorSpeed.clamp(0.2, 1.6),
            onChanged: (value) {
              onPreferencesChange(
                preferences.copyWith(readingCursorSpeed: value),
              );
            },
          ),
        ],
      ],
    );
  }
}

class _InteractionTab extends StatelessWidget {
  const _InteractionTab({
    required this.preferences,
    required this.onPreferencesChange,
  });

  final UserPreferences preferences;
  final ValueChanged<UserPreferences> onPreferencesChange;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        SwitchListTile(
          value: preferences.voiceCommandsEnabled,
          onChanged: (value) {
            onPreferencesChange(
              preferences.copyWith(voiceCommandsEnabled: value),
            );
          },
          title: const Text('Voice Commands'),
          subtitle: const Text('Control reading with voice'),
        ),
      ],
    );
  }
}

class _SmartTab extends StatelessWidget {
  const _SmartTab({
    required this.preferences,
    required this.onPreferencesChange,
  });

  final UserPreferences preferences;
  final ValueChanged<UserPreferences> onPreferencesChange;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        SwitchListTile(
          value: preferences.contextualSuggestionsEnabled,
          onChanged: (value) {
            onPreferencesChange(
              preferences.copyWith(contextualSuggestionsEnabled: value),
            );
          },
          title: const Text('Contextual Suggestions'),
          subtitle: const Text('Recommendations based on time and habits'),
        ),
        SwitchListTile(
          value: preferences.emotionTrackingEnabled,
          onChanged: (value) {
            onPreferencesChange(
              preferences.copyWith(emotionTrackingEnabled: value),
            );
          },
          title: const Text('Emotion Tracking'),
          subtitle: const Text('Analyze reading patterns'),
        ),
        SwitchListTile(
          value: preferences.adaptiveBrightnessEnabled,
          onChanged: (value) {
            onPreferencesChange(
              preferences.copyWith(adaptiveBrightnessEnabled: value),
            );
          },
          title: const Text('Adaptive Brightness'),
          subtitle: const Text('Adjust theme based on lighting'),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ThemeOption {
  const _ThemeOption(this.key, this.label);

  final String key;
  final String label;
}

class _AiThemeSelection {
  const _AiThemeSelection({
    required this.palette,
    required this.suggestedAmbience,
  });

  final ReadingThemePalette palette;
  final String suggestedAmbience;
}

const List<String> _fontFamilies = [
  'Inter',
  'Georgia',
  'Times New Roman',
  'Palatino',
  'Garamond',
  'Arial',
  'Helvetica',
  'Open Sans',
  'Roboto',
];

const List<_ThemeOption> _themeOptions = [
  _ThemeOption('ai-auto', 'AI Auto-Select'),
  _ThemeOption('auto', 'Auto (Time)'),
  _ThemeOption('weather', 'Weather'),
  _ThemeOption('default', 'Coffee Shop'),
  _ThemeOption('black-white', 'Black & White'),
  _ThemeOption('rainforest', 'Rainforest'),
  _ThemeOption('mystery', 'Mystery'),
  _ThemeOption('paper', 'Paper'),
  _ThemeOption('ocean-depth', 'Ocean Depth'),
  _ThemeOption('sunset', 'Sunset'),
  _ThemeOption('midnight', 'Midnight'),
  _ThemeOption('lavender-dream', 'Lavender Dream'),
];

class _AmbienceOption {
  const _AmbienceOption(this.key, this.label);

  final String key;
  final String label;
}

const List<_AmbienceOption> _ambienceOptions = [
  _AmbienceOption('ai-auto', 'AI Auto'),
  _AmbienceOption('none', 'None'),
  _AmbienceOption('rain', 'Rain'),
  _AmbienceOption('forest', 'Forest'),
  _AmbienceOption('ocean', 'Ocean'),
  _AmbienceOption('cafe', 'Cafe'),
  _AmbienceOption('urban', 'Urban'),
  _AmbienceOption('soft-beats', 'Soft Beats'),
  _AmbienceOption('wind', 'Wind'),
  _AmbienceOption('horror', 'Horror'),
];

class _CursorOption {
  const _CursorOption(this.key, this.label);

  final String key;
  final String label;
}

const List<_CursorOption> _cursorOptions = [
  _CursorOption('bubble', 'Bubble'),
];

class _SelectOption {
  const _SelectOption(this.value, this.label);

  final String value;
  final String label;
}

const List<_SelectOption> _ttsVoices = [
  _SelectOption('male-calm', 'Male - Calm'),
  _SelectOption('male-energetic', 'Male - Energetic'),
  _SelectOption('female-calm', 'Female - Calm'),
  _SelectOption('female-energetic', 'Female - Energetic'),
  _SelectOption('neutral', 'Neutral'),
];

const List<_SelectOption> _ttsTones = [
  _SelectOption('narrative', 'Narrative'),
  _SelectOption('conversational', 'Conversational'),
  _SelectOption('dramatic', 'Dramatic'),
  _SelectOption('professional', 'Professional'),
  _SelectOption('soothing', 'Soothing'),
];

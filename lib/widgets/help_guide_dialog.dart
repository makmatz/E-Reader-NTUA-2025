import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class HelpGuideButton extends StatelessWidget {
  const HelpGuideButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.help_outline),
      tooltip: 'Help Guide',
      onPressed: () => showDialog<void>(
        context: context,
        builder: (context) => const HelpGuideDialog(),
      ),
    );
  }
}

class HelpGuideDialog extends StatelessWidget {
  const HelpGuideDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? Colors.white : AppColors.primaryText;
    final secondaryText =
        isDark ? Colors.white.withValues(alpha: 0.7) : AppColors.secondaryText;
    final cardColor = Theme.of(context).cardColor;
    return Dialog(
      backgroundColor: cardColor,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: SizedBox(
        width: 680,
        height: 520,
        child: DefaultTabController(
          length: 4,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'App Guide & Features',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: primaryText,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Learn how to use the reading tools and smart features.',
                      style: TextStyle(color: secondaryText),
                    ),
                  ],
                ),
              ),
              TabBar(
                labelColor: primaryText,
                unselectedLabelColor: secondaryText,
                isScrollable: true,
                tabs: const [
                  Tab(text: 'Getting Started'),
                  Tab(text: 'Reading'),
                  Tab(text: 'Advanced'),
                  Tab(text: 'Tips'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _GuideSection(
                      primaryText: primaryText,
                      secondaryText: secondaryText,
                      items: [
                        _GuideItem(
                          title: 'Basic Navigation',
                          body:
                              'Use Library, For You, and Statistics to move through the app. On larger screens, the sidebar keeps these handy.',
                        ),
                        _GuideItem(
                          title: 'Login & Logout',
                          body:
                              'When the app opens, tap Log In or Sign Up (demo) to enter. Use the logout icon in the top app bar to exit.',
                        ),
                        _GuideItem(
                          title: 'Open a Book',
                          body:
                              'Tap any book card to open the reader, then use Next/Previous to move pages.',
                        ),
                        _GuideItem(
                          title: 'Global Theme',
                          body:
                              'Use the settings icon in the main app bar to change the global theme (Light, Dark, Nature, Ocean, Sunset, Midnight, Coffee, Auto, Weather).',
                        ),
                      ],
                    ),
                    _GuideSection(
                      primaryText: primaryText,
                      secondaryText: secondaryText,
                      items: [
                        _GuideItem(
                          title: 'Bookmarks',
                          body:
                              'Tap the bookmark icon to save your current page for quick access later.',
                        ),
                        _GuideItem(
                          title: 'Quick Summary',
                          body:
                              'Use the sparkle icon to review a short summary of what you have read so far.',
                        ),
                        _GuideItem(
                          title: 'Reader Settings',
                          body:
                              'Use the settings icon in the reader to adjust fonts, themes, audio options, and reading flow.',
                        ),
                        _GuideItem(
                          title: 'Voice Commands',
                          body:
                              'Enable Voice Commands in settings and use wake words like "reader" followed by your command (e.g., "reader next page").',
                        ),
                      ],
                    ),
                    _GuideSection(
                      primaryText: primaryText,
                      secondaryText: secondaryText,
                      items: [
                        _GuideItem(
                          title: 'Progress Saving',
                          body:
                              'Your reading progress is saved automatically as you move between pages.',
                        ),
                        _GuideItem(
                          title: 'Collections & Stats',
                          body:
                              'Use Collections and Statistics to revisit favorites and track your habits.',
                        ),
                        _GuideItem(
                          title: 'Smart Companion',
                          body:
                              'Open the floating sparkle button while reading for explain, summary, translate, and Q&A tools.',
                        ),
                        _GuideItem(
                          title: 'Bookmarks',
                          body:
                              'Bookmark pages while reading, then open the Bookmarks tab in the Library to revisit bookmarked books.',
                        ),
                      ],
                    ),
                    _GuideSection(
                      primaryText: primaryText,
                      secondaryText: secondaryText,
                      items: [
                        _GuideItem(
                          title: 'Stay Consistent',
                          body:
                              'Check statistics to keep a daily reading streak.',
                        ),
                        _GuideItem(
                          title: 'Try New Genres',
                          body:
                              'Use the For You tab to explore recommendations.',
                        ),
                        _GuideItem(
                          title: 'Reading Flow Modes',
                          body:
                              'Try Auto Scroll or Word Cursor for a hands-free reading rhythm.',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Close',
                      style: TextStyle(color: primaryText),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuideSection extends StatelessWidget {
  const _GuideSection({
    required this.items,
    required this.primaryText,
    required this.secondaryText,
  });

  final List<_GuideItem> items;
  final Color primaryText;
  final Color secondaryText;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: items
          .map(
            (item) => ExpansionTile(
              title: Text(
                item.title,
                style: TextStyle(
                  color: primaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              childrenPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                Text(
                  item.body,
                  style: TextStyle(color: secondaryText),
                ),
              ],
            ),
          )
          .toList(),
    );
  }
}

class _GuideItem {
  _GuideItem({required this.title, required this.body});

  final String title;
  final String body;
}

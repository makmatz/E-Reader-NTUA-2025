import 'package:flutter/material.dart';

import 'data/mock_data.dart';
import 'models/book.dart';
import 'screens/library_screen.dart';
import 'screens/login_screen.dart';
import 'screens/reader_screen.dart';
import 'screens/reading_stats_screen.dart';
import 'screens/recommendations_screen.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';
import 'widgets/global_theme_sheet.dart';
import 'widgets/help_guide_dialog.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  final StorageService _storage = StorageService();
  UserPreferences _preferences = UserPreferences.defaults();
  Map<String, ReadingProgress> _progress = {};
  bool _loading = true;
  int _tabIndex = 0;
  Book? _currentBook;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await _storage.loadPreferences();
    final progress = await _storage.loadProgress();
    setState(() {
      _preferences = prefs;
      _progress = progress;
      _loading = false;
    });
  }

  void _updatePreferences(UserPreferences preferences) {
    setState(() {
      _preferences = preferences;
    });
    _storage.savePreferences(preferences);
  }

  void _updateProgress(ReadingProgress progress) {
    final updated = Map<String, ReadingProgress>.from(_progress);
    updated[progress.bookId] = progress;
    setState(() {
      _progress = updated;
    });
    _storage.saveProgress(updated);
  }

  void _selectBook(Book book) {
    if (!_progress.containsKey(book.id)) {
      _updateProgress(
        ReadingProgress(
          bookId: book.id,
          currentPage: 0,
          lastRead: DateTime.now(),
          totalTimeSpentSeconds: 0,
          bookmarkedPages: [],
          highlights: [],
        ),
      );
    }

    setState(() {
      _currentBook = book;
    });
  }

  void _backToLibrary() {
    setState(() {
      _currentBook = null;
    });
  }

  void _handleLogin() {
    setState(() {
      _isLoggedIn = true;
    });
  }

  void _handleLogout() {
    setState(() {
      _isLoggedIn = false;
      _currentBook = null;
      _tabIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = themeForGlobal(_preferences.globalTheme);
    final brightness = palette.background.computeLuminance() > 0.5
        ? Brightness.light
        : Brightness.dark;
    final cardColor = brightness == Brightness.dark
        ? const Color(0xFF2B1F15)
        : Colors.white;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: brightness,
        scaffoldBackgroundColor: palette.background,
        fontFamily: _preferences.fontFamily,
        cardColor: cardColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryText,
          brightness: brightness,
        ),
      ),
      home: _loading
          ? const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            )
          : _buildHome(palette),
    );
  }

  Widget _buildHome(ThemePalette palette) {
    if (!_isLoggedIn) {
      return LoginScreen(onLogin: _handleLogin);
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: _currentBook != null
          ? ReaderScreen(
              key: const ValueKey('reader'),
              book: _currentBook!,
              progress: _progress[_currentBook!.id] ??
                  ReadingProgress(
                    bookId: _currentBook!.id,
                    currentPage: 0,
                    lastRead: DateTime.now(),
                    totalTimeSpentSeconds: 0,
                    bookmarkedPages: [],
                    highlights: [],
                  ),
              preferences: _preferences,
              onProgressChange: _updateProgress,
              onPreferencesChange: _updatePreferences,
              onBack: _backToLibrary,
            )
          : Scaffold(
              key: const ValueKey('shell'),
              appBar: AppBar(
                title: const Text('BookReader'),
                backgroundColor: palette.background,
                foregroundColor: palette.text,
                elevation: 0,
                actions: [
                  const HelpGuideButton(),
                  IconButton(
                    icon: const Icon(Icons.logout),
                    tooltip: 'Log out',
                    onPressed: _handleLogout,
                  ),
                  GlobalThemeButton(
                    preferences: _preferences,
                    onPreferencesChange: _updatePreferences,
                  ),
                ],
              ),
              body: IndexedStack(
                index: _tabIndex,
                children: [
                  LibraryScreen(
                    books: mockBooks,
                    progress: _progress,
                    onBookSelect: _selectBook,
                  ),
                  RecommendationsScreen(
                    books: mockBooks,
                    progress: _progress,
                    onBookSelect: _selectBook,
                  ),
                  ReadingStatsScreen(
                    books: mockBooks,
                    progress: _progress,
                  ),
                ],
              ),
              bottomNavigationBar: BottomNavigationBar(
                currentIndex: _tabIndex,
                onTap: (index) => setState(() => _tabIndex = index),
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.library_books),
                    label: 'Library',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.auto_awesome),
                    label: 'For You',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.bar_chart),
                    label: 'Statistics',
                  ),
                ],
              ),
            ),
    );
  }
}

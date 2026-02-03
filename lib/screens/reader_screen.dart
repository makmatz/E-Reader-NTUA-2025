import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_recognition_error.dart';

import '../models/book.dart';
import '../services/ambience_service.dart';
import '../theme/app_theme.dart';
import '../widgets/reader_settings_sheet.dart';
import '../widgets/smart_companion_sheet.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({
    super.key,
    required this.book,
    required this.progress,
    required this.preferences,
    required this.onProgressChange,
    required this.onPreferencesChange,
    required this.onBack,
  });

  final Book book;
  final ReadingProgress progress;
  final UserPreferences preferences;
  final ValueChanged<ReadingProgress> onProgressChange;
  final ValueChanged<UserPreferences> onPreferencesChange;
  final VoidCallback onBack;

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  static const double _swipeVelocityThreshold = 300;
  late int _currentPage;
  late ScrollController _scrollController;
  Timer? _progressTimer;
  Timer? _autoScrollTimer;
  Timer? _wordCursorTimer;
  DateTime _lastTimeUpdate = DateTime.now();
  bool _isTtsPlaying = false;
  late FlutterTts _flutterTts;
  late SpeechToText _speechToText;
  bool _speechAvailable = false;
  bool _isListening = false;
  bool _wakeArmed = false;
  bool _isCursorPaused = false;
  int _currentWordIndex = 0;
  List<_WordRange> _wordRanges = [];
  double _textLayoutWidth = 0;
  String _selectedText = '';
  String _currentAmbience = 'none';
  final AmbienceService _ambienceService = AmbienceService.instance;
  bool _isCompanionOpen = false;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.progress.currentPage;
    _scrollController = ScrollController();
    _flutterTts = FlutterTts();
    _configureTts();
    _speechToText = SpeechToText();
    _initSpeech();
    _startProgressTimer();
    _maybeShowSummary();
    _buildWordRanges();
    _configureFlowTimers();
    _updateAmbience(notify: false);
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _autoScrollTimer?.cancel();
    _wordCursorTimer?.cancel();
    _flutterTts.stop();
    _stopListening();
    _ambienceService.stop();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ReaderScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.preferences.readingFlowMode !=
            widget.preferences.readingFlowMode ||
        oldWidget.preferences.readingCursorSpeed !=
            widget.preferences.readingCursorSpeed ||
        oldWidget.preferences.scrollSpeed != widget.preferences.scrollSpeed) {
      _configureFlowTimers();
    }
    if (oldWidget.preferences.ttsSpeed != widget.preferences.ttsSpeed ||
        oldWidget.preferences.ttsTone != widget.preferences.ttsTone) {
      _configureTts();
    }
    if (oldWidget.preferences.ttsEnabled &&
        !widget.preferences.ttsEnabled) {
      _stopTts();
    }
    if (oldWidget.preferences.voiceCommandsEnabled !=
        widget.preferences.voiceCommandsEnabled) {
      if (widget.preferences.voiceCommandsEnabled) {
        _startListening();
      } else {
        _stopListening();
      }
    }
    if (oldWidget.book.id != widget.book.id ||
        oldWidget.preferences.fontFamily != widget.preferences.fontFamily ||
        oldWidget.preferences.fontSize != widget.preferences.fontSize ||
        oldWidget.preferences.lineHeight != widget.preferences.lineHeight) {
      _buildWordRanges();
    }
    if (oldWidget.preferences.backgroundNoise !=
            widget.preferences.backgroundNoise ||
        oldWidget.preferences.noiseVolume != widget.preferences.noiseVolume) {
      _updateAmbience();
    }
  }

  void _startProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _saveProgress(addTime: true);
    });
  }

  void _saveProgress({required bool addTime}) {
    final now = DateTime.now();
    final deltaSeconds =
        addTime ? now.difference(_lastTimeUpdate).inSeconds : 0;
    _lastTimeUpdate = now;
    final updated = widget.progress.copyWith(
      currentPage: _currentPage,
      lastRead: now,
      totalTimeSpentSeconds:
          widget.progress.totalTimeSpentSeconds + deltaSeconds,
    );
    widget.onProgressChange(updated);
  }

  void _configureFlowTimers() {
    _autoScrollTimer?.cancel();
    _wordCursorTimer?.cancel();
    if (_isCursorPaused) return;

    if (widget.preferences.readingFlowMode == 'auto-scroll') {
      _autoScrollTimer = Timer.periodic(
        const Duration(milliseconds: 40),
        (_) => _autoScrollStep(),
      );
    }

    if (widget.preferences.readingFlowMode == 'word-cursor') {
      final speed = widget.preferences.readingCursorSpeed.clamp(0.3, 3.0);
      final msPerWord = (60000 / (200 * speed)).round();
      _wordCursorTimer = Timer.periodic(
        Duration(milliseconds: math.max(80, msPerWord)),
        (_) => _advanceWordCursor(),
      );
    }
  }

  Future<void> _initSpeech() async {
    final granted = await _ensureMicPermission();
    if (!granted) {
      return;
    }
    _speechAvailable = await _speechToText.initialize(
      onStatus: _handleSpeechStatus,
      onError: _handleSpeechError,
    );
    if (widget.preferences.voiceCommandsEnabled && _speechAvailable) {
      _startListening();
    }
  }

  Future<bool> _ensureMicPermission() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      _showSnack('Microphone permission is required for voice commands.');
      return false;
    }
    return true;
  }

  void _handleSpeechStatus(String status) {
    if (!mounted) return;
    if (status == 'notListening' || status == 'done') {
      setState(() => _isListening = false);
      if (widget.preferences.voiceCommandsEnabled) {
        _startListening();
      }
    }
  }

  void _handleSpeechError(SpeechRecognitionError error) {
    if (!mounted) return;
    setState(() => _isListening = false);
    if (widget.preferences.voiceCommandsEnabled) {
      _startListening();
    }
  }

  Future<void> _startListening() async {
    final granted = await _ensureMicPermission();
    if (!granted) return;
    if (!_speechAvailable || _isListening) return;
    setState(() => _isListening = true);
    await _speechToText.listen(
      onResult: _handleSpeechResult,
      listenMode: ListenMode.dictation,
      partialResults: true,
      cancelOnError: true,
    );
  }

  Future<void> _stopListening() async {
    if (!_isListening) return;
    await _speechToText.stop();
    if (mounted) {
      setState(() => _isListening = false);
    }
  }

  void _handleSpeechResult(SpeechRecognitionResult result) {
    final raw = result.recognizedWords.toLowerCase().trim();
    if (raw.isEmpty) return;
    final command = _extractWakeCommand(raw);
    if (command != null) {
      _wakeArmed = command.isEmpty;
      if (_wakeArmed) {
        _showSnack('Listening for command...');
      } else {
        _handleVoiceCommand(command);
      }
      return;
    }
    if (_wakeArmed && result.finalResult) {
      _wakeArmed = false;
      _handleVoiceCommand(raw);
    }
  }

  String? _extractWakeCommand(String raw) {
    const wakeWords = ['reader', 'book reader', 'hey reader'];
    for (final wake in wakeWords) {
      if (raw.startsWith(wake)) {
        return raw.substring(wake.length).trim();
      }
      if (raw.contains(' $wake ')) {
        final parts = raw.split(wake);
        return parts.last.trim();
      }
    }
    return null;
  }

  void _handleVoiceCommand(String command) {
    if (command.contains('next')) {
      _goToNextPage();
      return;
    }
    if (command.contains('previous') || command.contains('back')) {
      _goToPreviousPage();
      return;
    }
    if (command.contains('bookmark')) {
      _toggleBookmark();
      return;
    }
    if (command.contains('summary') || command.contains('recap')) {
      _showSummary();
      return;
    }
    if (command.contains('start reading') ||
        command.contains('play') ||
        command.contains('read aloud')) {
      if (widget.preferences.ttsEnabled) {
        _startTts();
      } else {
        _showSnack('Enable text-to-speech first.');
      }
      return;
    }
    if (command.contains('stop reading') || command.contains('pause')) {
      _stopTts();
      return;
    }
    if (command.contains('library') || command.contains('go back')) {
      widget.onBack();
      return;
    }
  }

  void _autoScrollStep() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    if (maxScroll <= 0) return;
    final delta = 1.5 * widget.preferences.scrollSpeed;
    final nextOffset = (_scrollController.offset + delta).clamp(0.0, maxScroll);
    _scrollController.jumpTo(nextOffset);
  }

  void _advanceWordCursor() {
    if (_wordRanges.isEmpty) return;
    setState(() {
      _currentWordIndex = (_currentWordIndex + 1) % _wordRanges.length;
    });
    _scrollToWord(_currentWordIndex);
  }

  void _scrollToWord(int index) {
    if (!_scrollController.hasClients || _textLayoutWidth <= 0) return;
    final rect = _wordRectForIndex(index);
    if (rect == null) return;
    final viewport = _scrollController.position.viewportDimension;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final target = (rect.top - viewport * 0.4).clamp(0.0, maxScroll);
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  Rect? _wordRectForIndex(int index) {
    if (_wordRanges.isEmpty || _textLayoutWidth <= 0) return null;
    final range = _wordRanges[index];
    final textPainter = TextPainter(
      text: TextSpan(
        text: widget.book.content[_currentPage],
        style: _readerTextStyle(),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: _textLayoutWidth);
    final boxes = textPainter.getBoxesForSelection(
      TextSelection(baseOffset: range.start, extentOffset: range.end),
    );
    if (boxes.isEmpty) return null;
    return boxes.first.toRect();
  }

  void _maybeShowSummary() {
    final daysSinceLastRead =
        DateTime.now().difference(widget.progress.lastRead).inDays;
    if (daysSinceLastRead >= 2 && widget.progress.currentPage > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSummary();
      });
    }
  }

  String _generateSummary() {
    final content = widget.book.content.take(_currentPage + 1).join(' ');
    if (content.isEmpty) {
      return widget.book.description;
    }
    return content.length > 280 ? '${content.substring(0, 280)}...' : content;
  }

  void _goToNextPage() {
    if (_currentPage >= widget.book.content.length - 1) return;
    setState(() {
      _currentPage += 1;
      _currentWordIndex = 0;
      _selectedText = '';
    });
    _stopTts();
    _scrollController.jumpTo(0);
    _saveProgress(addTime: false);
    _buildWordRanges();
    _configureFlowTimers();
    _updateAmbience();
  }

  void _goToPreviousPage() {
    if (_currentPage <= 0) return;
    setState(() {
      _currentPage -= 1;
      _currentWordIndex = 0;
      _selectedText = '';
    });
    _stopTts();
    _scrollController.jumpTo(0);
    _saveProgress(addTime: false);
    _buildWordRanges();
    _configureFlowTimers();
    _updateAmbience();
  }

  void _handleHorizontalSwipe(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond.dx;
    if (velocity.abs() < _swipeVelocityThreshold) {
      return;
    }
    if (velocity < 0) {
      _goToNextPage();
    } else {
      _goToPreviousPage();
    }
  }

  bool get _isBookmarked {
    return widget.progress.bookmarkedPages.contains(_currentPage);
  }

  void _toggleBookmark() {
    final bookmarks = List<int>.from(widget.progress.bookmarkedPages);
    if (_isBookmarked) {
      bookmarks.remove(_currentPage);
    } else {
      bookmarks.add(_currentPage);
    }
    widget.onProgressChange(
      widget.progress.copyWith(bookmarkedPages: bookmarks),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isBookmarked ? 'Bookmark removed' : 'Page bookmarked',
        ),
      ),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _toggleTts() {
    if (_isTtsPlaying) {
      _stopTts();
    } else {
      _startTts();
    }
  }

  void _toggleFlowPause() {
    setState(() {
      _isCursorPaused = !_isCursorPaused;
    });
    _configureFlowTimers();
  }

  void _configureTts() {
    final speed = widget.preferences.ttsSpeed.clamp(0.5, 2.0);
    final speechRate = (speed / 2.0).clamp(0.2, 1.0);
    _flutterTts.setSpeechRate(speechRate);
    _flutterTts.setPitch(_toneToPitch(widget.preferences.ttsTone));
    _flutterTts.setVolume(1.0);
    _flutterTts.setCompletionHandler(() {
      if (mounted) {
        setState(() => _isTtsPlaying = false);
      }
    });
    _flutterTts.setCancelHandler(() {
      if (mounted) {
        setState(() => _isTtsPlaying = false);
      }
    });
  }

  double _toneToPitch(String tone) {
    switch (tone) {
      case 'dramatic':
        return 1.2;
      case 'conversational':
        return 1.05;
      case 'professional':
        return 0.95;
      case 'soothing':
        return 0.85;
      default:
        return 1.0;
    }
  }

  Future<void> _startTts() async {
    final text = widget.book.content[_currentPage];
    if (text.trim().isEmpty) return;
    await _flutterTts.stop();
    await _flutterTts.awaitSpeakCompletion(true);
    setState(() => _isTtsPlaying = true);
    await _flutterTts.speak(text);
  }

  Future<void> _stopTts() async {
    await _flutterTts.stop();
    if (mounted) {
      setState(() => _isTtsPlaying = false);
    }
  }

  void _buildWordRanges() {
    final text = widget.book.content[_currentPage];
    final matches = RegExp(r'\S+').allMatches(text);
    _wordRanges = matches
        .map((match) => _WordRange(match.start, match.end))
        .toList();
  }

  TextStyle _readerTextStyle() {
    final colors = _resolveReaderColors();
    return TextStyle(
      color: colors.text,
      fontSize: widget.preferences.fontSize,
      height: widget.preferences.lineHeight,
      fontFamily: widget.preferences.fontFamily,
    );
  }

  TextSpan _buildReaderTextSpan() {
    final text = widget.book.content[_currentPage];
    if (widget.preferences.readingFlowMode != 'word-cursor' ||
        _wordRanges.isEmpty) {
      return TextSpan(text: text, style: _readerTextStyle());
    }

    final spans = <TextSpan>[];
    int lastIndex = 0;
    for (int i = 0; i < _wordRanges.length; i++) {
      final range = _wordRanges[i];
      if (range.start > lastIndex) {
        spans.add(
          TextSpan(
            text: text.substring(lastIndex, range.start),
            style: _readerTextStyle(),
          ),
        );
      }
      final isActive = i == _currentWordIndex;
      spans.add(
        TextSpan(
          text: text.substring(range.start, range.end),
          style: _readerTextStyle().copyWith(
            backgroundColor: isActive
                ? _cursorBackgroundColor(widget.preferences.readingCursorType)
                : null,
            decoration: _cursorDecoration(widget.preferences.readingCursorType),
            decorationColor:
                _cursorDecorationColor(widget.preferences.readingCursorType),
            decorationThickness: 2,
          ),
        ),
      );
      lastIndex = range.end;
    }
    if (lastIndex < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(lastIndex),
          style: _readerTextStyle(),
        ),
      );
    }
    return TextSpan(children: spans);
  }

  Color? _cursorBackgroundColor(String? cursorType) {
    switch (cursorType) {
      case 'bubble':
        return const Color(0x3364B5F6);
      case 'highlight':
        return const Color(0x33FFEB3B);
      default:
        return null;
    }
  }

  TextDecoration? _cursorDecoration(String? cursorType) {
    if (cursorType == 'pointer') {
      return TextDecoration.underline;
    }
    return null;
  }

  Color? _cursorDecorationColor(String? cursorType) {
    if (cursorType == 'pointer') {
      return const Color(0xFFE53935);
    }
    return null;
  }

  void _updateAmbience({bool notify = true}) {
    final noise = widget.preferences.backgroundNoise;
    String nextAmbience;
    if (noise == 'none') {
      nextAmbience = 'none';
    } else if (noise != 'ai-auto') {
      nextAmbience = noise;
    } else {
      nextAmbience = _detectAmbience(widget.book.content[_currentPage]);
    }
    if (nextAmbience != _currentAmbience) {
      if (notify) {
        setState(() {
          _currentAmbience = nextAmbience;
        });
      } else {
        _currentAmbience = nextAmbience;
      }
    }

    if (_currentAmbience == 'none') {
      _ambienceService.stop();
    } else {
      _ambienceService.play(
        _currentAmbience,
        widget.preferences.noiseVolume,
      );
    }
  }

  String _detectAmbience(String content) {
    final text = content.toLowerCase();
    if (text.contains('rain') || text.contains('storm')) return 'rain';
    if (text.contains('forest') || text.contains('trees')) return 'forest';
    if (text.contains('ocean') || text.contains('sea')) return 'ocean';
    if (text.contains('cafe') || text.contains('coffee')) return 'cafe';
    if (text.contains('city') || text.contains('street')) return 'urban';
    if (text.contains('wind') || text.contains('mountain')) return 'wind';
    if (text.contains('music') || text.contains('dance')) return 'soft-beats';
    if (text.contains('horror') || text.contains('fear')) return 'horror';
    return 'none';
  }

  _ReaderColors _resolveReaderColors() {
    final background = widget.preferences.backgroundColor;
    final text = widget.preferences.textColor;
    if (!widget.preferences.adaptiveBrightnessEnabled) {
      return _ReaderColors(background: background, text: text);
    }
    final hour = DateTime.now().hour;
    final isNight = hour < 6 || hour >= 21;
    final adjustedBackground = _blendColor(
      background,
      isNight ? Colors.black : Colors.white,
      isNight ? 0.2 : 0.12,
    );
    final adjustedText = _blendColor(
      text,
      isNight ? Colors.white : Colors.black,
      0.15,
    );
    return _ReaderColors(
      background: adjustedBackground,
      text: adjustedText,
    );
  }

  Color _blendColor(Color base, Color target, double amount) {
    return Color.lerp(base, target, amount) ?? base;
  }

  void _showSummary() {
    final summary = _generateSummary();
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Story Summary'),
          content: SingleChildScrollView(child: Text(summary)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Continue Reading'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = _resolveReaderColors();
    final progressPercent =
        (_currentPage + 1) / widget.book.content.length.clamp(1, 9999);
    final readerBackground = colors.background;
    final readerText = colors.text;

    return Scaffold(
      backgroundColor: readerBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(readerText),
            LinearProgressIndicator(
              value: progressPercent,
              minHeight: 3,
              backgroundColor: readerBackground,
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.border.withValues(alpha: 0.7),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onHorizontalDragEnd: _handleHorizontalSwipe,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: widget.preferences.pageWidth,
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          _textLayoutWidth = math.min(
                            constraints.maxWidth,
                            widget.preferences.pageWidth,
                          );
                          return SelectableText.rich(
                            _buildReaderTextSpan(),
                            onSelectionChanged: (selection, cause) {
                              final start = selection.start;
                              final end = selection.end;
                              if (start < 0 || end < 0 || start == end) {
                                setState(() => _selectedText = '');
                                return;
                              }
                              final text = widget.book.content[_currentPage];
                              final safeStart = math.min(start, end);
                              final safeEnd = math.max(start, end);
                              if (safeStart >= 0 && safeEnd <= text.length) {
                                setState(() {
                                  _selectedText =
                                      text.substring(safeStart, safeEnd);
                                });
                                if (cause == SelectionChangedCause.longPress ||
                                    cause == SelectionChangedCause.drag) {
                                  return;
                                }
                                _openCompanionIfNeeded();
                              }
                            },
                            style: _readerTextStyle(),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
            _buildFooter(readerText),
          ],
        ),
      ),
      floatingActionButton: SmartCompanionButton(
        book: widget.book,
        currentPage: _currentPage,
        currentContent: widget.book.content[_currentPage],
        selectedText: _selectedText,
      ),
    );
  }

  void _openCompanionIfNeeded() {
    if (_isCompanionOpen) return;
    if (_selectedText.trim().isEmpty) return;
    _isCompanionOpen = true;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SmartCompanionSheet(
          book: widget.book,
          currentPage: _currentPage,
          currentContent: widget.book.content[_currentPage],
          selectedText: _selectedText,
        );
      },
    ).whenComplete(() {
      _isCompanionOpen = false;
    });
  }

  Widget _buildHeader(Color textColor) {
    final showSummary = _currentPage > 0;
    final showFlowControls = widget.preferences.readingFlowMode != 'none';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              _saveProgress(addTime: true);
              widget.onBack();
            },
            icon: const Icon(Icons.arrow_back),
            color: textColor,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.book.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  widget.book.author,
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (_isListening)
            Container(
              padding: const EdgeInsets.all(6),
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.mic, size: 14),
            ),
          if (_currentAmbience != 'none')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.volume_up, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    _currentAmbience,
                    style: const TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
          if (showSummary)
            IconButton(
              onPressed: _showSummary,
              icon: const Icon(Icons.auto_awesome),
              color: textColor,
              tooltip: 'Summary',
            ),
          IconButton(
            onPressed: _toggleBookmark,
            icon: Icon(
              _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
            ),
            color: textColor,
          ),
          if (widget.preferences.ttsEnabled)
            IconButton(
              onPressed: _toggleTts,
              icon: Icon(_isTtsPlaying ? Icons.pause : Icons.play_arrow),
              color: textColor,
              tooltip: _isTtsPlaying ? 'Stop' : 'Play',
            ),
          if (showFlowControls)
            IconButton(
              onPressed: _toggleFlowPause,
              icon: Icon(_isCursorPaused ? Icons.play_arrow : Icons.pause),
              color: _isCursorPaused ? Colors.orange : textColor,
              tooltip: _isCursorPaused ? 'Resume' : 'Pause',
            ),
          ReaderSettingsButton(
            preferences: widget.preferences,
            onPreferencesChange: widget.onPreferencesChange,
            currentBook: widget.book,
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(Color textColor) {
    final progressPercent =
        (_currentPage + 1) / widget.book.content.length.clamp(1, 9999);
    final colors = _resolveReaderColors();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(top: BorderSide(color: textColor.withValues(alpha: 0.2))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          OutlinedButton.icon(
            onPressed: _currentPage == 0 ? null : _goToPreviousPage,
            icon: const Icon(Icons.chevron_left),
            label: const Text('Previous'),
          ),
          Column(
            children: [
              Text(
                'Page ${_currentPage + 1} of ${widget.book.content.length}',
                style: TextStyle(color: textColor, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                '${(progressPercent * 100).round()}% complete',
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.7),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          OutlinedButton.icon(
            onPressed: _currentPage == widget.book.content.length - 1
                ? null
                : _goToNextPage,
            icon: const Icon(Icons.chevron_right),
            label: const Text('Next'),
          ),
        ],
      ),
    );
  }
}

class _WordRange {
  _WordRange(this.start, this.end);

  final int start;
  final int end;
}

class _ReaderColors {
  const _ReaderColors({required this.background, required this.text});

  final Color background;
  final Color text;
}

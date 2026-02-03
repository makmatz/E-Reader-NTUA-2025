import 'package:flutter/material.dart';

class Book {
  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.cover,
    required this.genre,
    required this.description,
    required this.content,
    required this.totalPages,
    required this.publishYear,
    required this.rating,
  });

  final String id;
  final String title;
  final String author;
  final String cover;
  final List<String> genre;
  final String description;
  final List<String> content;
  final int totalPages;
  final int publishYear;
  final double rating;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'author': author,
        'cover': cover,
        'genre': genre,
        'description': description,
        'content': content,
        'totalPages': totalPages,
        'publishYear': publishYear,
        'rating': rating,
      };

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] as String,
      title: json['title'] as String,
      author: json['author'] as String,
      cover: json['cover'] as String,
      genre: (json['genre'] as List<dynamic>).cast<String>(),
      description: json['description'] as String,
      content: (json['content'] as List<dynamic>).cast<String>(),
      totalPages: json['totalPages'] as int,
      publishYear: json['publishYear'] as int,
      rating: (json['rating'] as num).toDouble(),
    );
  }
}

class Highlight {
  Highlight({
    required this.id,
    required this.pageNumber,
    required this.text,
    required this.color,
    this.note,
  });

  final String id;
  final int pageNumber;
  final String text;
  final Color color;
  final String? note;

  Map<String, dynamic> toJson() => {
        'id': id,
        'pageNumber': pageNumber,
        'text': text,
        'color': color.toARGB32(),
        'note': note,
      };

  factory Highlight.fromJson(Map<String, dynamic> json) {
    return Highlight(
      id: json['id'] as String,
      pageNumber: json['pageNumber'] as int,
      text: json['text'] as String,
      color: Color(json['color'] as int),
      note: json['note'] as String?,
    );
  }
}

class ReadingProgress {
  ReadingProgress({
    required this.bookId,
    required this.currentPage,
    required this.lastRead,
    required this.totalTimeSpentSeconds,
    required this.bookmarkedPages,
    required this.highlights,
  });

  final String bookId;
  final int currentPage;
  final DateTime lastRead;
  final int totalTimeSpentSeconds;
  final List<int> bookmarkedPages;
  final List<Highlight> highlights;

  ReadingProgress copyWith({
    String? bookId,
    int? currentPage,
    DateTime? lastRead,
    int? totalTimeSpentSeconds,
    List<int>? bookmarkedPages,
    List<Highlight>? highlights,
  }) {
    return ReadingProgress(
      bookId: bookId ?? this.bookId,
      currentPage: currentPage ?? this.currentPage,
      lastRead: lastRead ?? this.lastRead,
      totalTimeSpentSeconds:
          totalTimeSpentSeconds ?? this.totalTimeSpentSeconds,
      bookmarkedPages: bookmarkedPages ?? this.bookmarkedPages,
      highlights: highlights ?? this.highlights,
    );
  }

  Map<String, dynamic> toJson() => {
        'bookId': bookId,
        'currentPage': currentPage,
        'lastRead': lastRead.toIso8601String(),
        'totalTimeSpentSeconds': totalTimeSpentSeconds,
        'bookmarkedPages': bookmarkedPages,
        'highlights': highlights.map((h) => h.toJson()).toList(),
      };

  factory ReadingProgress.fromJson(Map<String, dynamic> json) {
    return ReadingProgress(
      bookId: json['bookId'] as String,
      currentPage: json['currentPage'] as int,
      lastRead: DateTime.parse(json['lastRead'] as String),
      totalTimeSpentSeconds: json['totalTimeSpentSeconds'] as int,
      bookmarkedPages: (json['bookmarkedPages'] as List<dynamic>).cast<int>(),
      highlights: (json['highlights'] as List<dynamic>)
          .map((item) => Highlight.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

typedef ReadingTheme = String;
typedef GlobalTheme = String;

typedef ReadingFlowMode = String;
typedef ReadingCursorType = String;

typedef BackgroundNoise = String;

typedef ThemeModeName = String;

class UserPreferences {
  UserPreferences({
    required this.fontSize,
    required this.fontFamily,
    required this.colorTheme,
    required this.readingTheme,
    required this.backgroundColor,
    required this.textColor,
    required this.lineHeight,
    required this.pageWidth,
    required this.globalTheme,
    required this.backgroundNoise,
    required this.noiseVolume,
    required this.ttsEnabled,
    required this.ttsVoice,
    required this.ttsTone,
    required this.ttsSpeed,
    required this.voiceCommandsEnabled,
    required this.readingFlowMode,
    required this.readingCursorType,
    required this.readingCursorSpeed,
    required this.scrollSpeed,
    required this.contextualSuggestionsEnabled,
    required this.emotionTrackingEnabled,
    required this.smartNotificationsEnabled,
    required this.adaptiveBrightnessEnabled,
  });

  final double fontSize;
  final String fontFamily;
  final ThemeModeName colorTheme;
  final ReadingTheme readingTheme;
  final Color backgroundColor;
  final Color textColor;
  final double lineHeight;
  final double pageWidth;
  final GlobalTheme globalTheme;
  final BackgroundNoise backgroundNoise;
  final double noiseVolume;
  final bool ttsEnabled;
  final String ttsVoice;
  final String ttsTone;
  final double ttsSpeed;
  final bool voiceCommandsEnabled;
  final ReadingFlowMode readingFlowMode;
  final ReadingCursorType readingCursorType;
  final double readingCursorSpeed;
  final double scrollSpeed;
  final bool contextualSuggestionsEnabled;
  final bool emotionTrackingEnabled;
  final bool smartNotificationsEnabled;
  final bool adaptiveBrightnessEnabled;

  static UserPreferences defaults() {
    return UserPreferences(
      fontSize: 16,
      fontFamily: 'Inter',
      colorTheme: 'light',
      readingTheme: 'default',
      backgroundColor: const Color(0xFFFDF7F0),
      textColor: const Color(0xFF3A2A17),
      lineHeight: 1.6,
      pageWidth: 680,
      globalTheme: 'light',
      backgroundNoise: 'none',
      noiseVolume: 0.4,
      ttsEnabled: false,
      ttsVoice: 'neutral',
      ttsTone: 'narrative',
      ttsSpeed: 1.0,
      voiceCommandsEnabled: false,
      readingFlowMode: 'none',
      readingCursorType: 'highlight',
      readingCursorSpeed: 1.0,
      scrollSpeed: 1.0,
      contextualSuggestionsEnabled: true,
      emotionTrackingEnabled: false,
      smartNotificationsEnabled: false,
      adaptiveBrightnessEnabled: false,
    );
  }

  UserPreferences copyWith({
    double? fontSize,
    String? fontFamily,
    ThemeModeName? colorTheme,
    ReadingTheme? readingTheme,
    Color? backgroundColor,
    Color? textColor,
    double? lineHeight,
    double? pageWidth,
    GlobalTheme? globalTheme,
    BackgroundNoise? backgroundNoise,
    double? noiseVolume,
    bool? ttsEnabled,
    String? ttsVoice,
    String? ttsTone,
    double? ttsSpeed,
    bool? voiceCommandsEnabled,
    ReadingFlowMode? readingFlowMode,
    ReadingCursorType? readingCursorType,
    double? readingCursorSpeed,
    double? scrollSpeed,
    bool? contextualSuggestionsEnabled,
    bool? emotionTrackingEnabled,
    bool? smartNotificationsEnabled,
    bool? adaptiveBrightnessEnabled,
  }) {
    return UserPreferences(
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      colorTheme: colorTheme ?? this.colorTheme,
      readingTheme: readingTheme ?? this.readingTheme,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      lineHeight: lineHeight ?? this.lineHeight,
      pageWidth: pageWidth ?? this.pageWidth,
      globalTheme: globalTheme ?? this.globalTheme,
      backgroundNoise: backgroundNoise ?? this.backgroundNoise,
      noiseVolume: noiseVolume ?? this.noiseVolume,
      ttsEnabled: ttsEnabled ?? this.ttsEnabled,
      ttsVoice: ttsVoice ?? this.ttsVoice,
      ttsTone: ttsTone ?? this.ttsTone,
      ttsSpeed: ttsSpeed ?? this.ttsSpeed,
      voiceCommandsEnabled: voiceCommandsEnabled ?? this.voiceCommandsEnabled,
      readingFlowMode: readingFlowMode ?? this.readingFlowMode,
      readingCursorType: readingCursorType ?? this.readingCursorType,
      readingCursorSpeed: readingCursorSpeed ?? this.readingCursorSpeed,
      scrollSpeed: scrollSpeed ?? this.scrollSpeed,
      contextualSuggestionsEnabled:
          contextualSuggestionsEnabled ?? this.contextualSuggestionsEnabled,
      emotionTrackingEnabled:
          emotionTrackingEnabled ?? this.emotionTrackingEnabled,
      smartNotificationsEnabled:
          smartNotificationsEnabled ?? this.smartNotificationsEnabled,
      adaptiveBrightnessEnabled:
          adaptiveBrightnessEnabled ?? this.adaptiveBrightnessEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
        'fontSize': fontSize,
        'fontFamily': fontFamily,
        'colorTheme': colorTheme,
        'readingTheme': readingTheme,
        'backgroundColor': backgroundColor.toARGB32(),
        'textColor': textColor.toARGB32(),
        'lineHeight': lineHeight,
        'pageWidth': pageWidth,
        'globalTheme': globalTheme,
        'backgroundNoise': backgroundNoise,
        'noiseVolume': noiseVolume,
        'ttsEnabled': ttsEnabled,
        'ttsVoice': ttsVoice,
        'ttsTone': ttsTone,
        'ttsSpeed': ttsSpeed,
        'voiceCommandsEnabled': voiceCommandsEnabled,
        'readingFlowMode': readingFlowMode,
        'readingCursorType': readingCursorType,
        'readingCursorSpeed': readingCursorSpeed,
        'scrollSpeed': scrollSpeed,
        'contextualSuggestionsEnabled': contextualSuggestionsEnabled,
        'emotionTrackingEnabled': emotionTrackingEnabled,
        'smartNotificationsEnabled': smartNotificationsEnabled,
        'adaptiveBrightnessEnabled': adaptiveBrightnessEnabled,
      };

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      fontSize: (json['fontSize'] as num).toDouble(),
      fontFamily: json['fontFamily'] as String,
      colorTheme: json['colorTheme'] as String,
      readingTheme: json['readingTheme'] as String,
      backgroundColor: Color(json['backgroundColor'] as int),
      textColor: Color(json['textColor'] as int),
      lineHeight: (json['lineHeight'] as num).toDouble(),
      pageWidth: (json['pageWidth'] as num).toDouble(),
      globalTheme: json['globalTheme'] as String,
      backgroundNoise: json['backgroundNoise'] as String,
      noiseVolume: (json['noiseVolume'] as num).toDouble(),
      ttsEnabled: json['ttsEnabled'] as bool,
      ttsVoice: json['ttsVoice'] as String,
      ttsTone: json['ttsTone'] as String,
      ttsSpeed: (json['ttsSpeed'] as num).toDouble(),
      voiceCommandsEnabled: json['voiceCommandsEnabled'] as bool,
      readingFlowMode: json['readingFlowMode'] as String,
      readingCursorType: json['readingCursorType'] as String,
      readingCursorSpeed: (json['readingCursorSpeed'] as num).toDouble(),
      scrollSpeed: (json['scrollSpeed'] as num).toDouble(),
      contextualSuggestionsEnabled:
          json['contextualSuggestionsEnabled'] as bool,
      emotionTrackingEnabled: json['emotionTrackingEnabled'] as bool,
      smartNotificationsEnabled: json['smartNotificationsEnabled'] as bool,
      adaptiveBrightnessEnabled: json['adaptiveBrightnessEnabled'] as bool,
    );
  }
}

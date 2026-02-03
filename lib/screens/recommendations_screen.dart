import 'package:flutter/material.dart';

import '../models/book.dart';
import '../theme/app_theme.dart';
import '../widgets/book_card.dart';

class RecommendationsScreen extends StatelessWidget {
  const RecommendationsScreen({
    super.key,
    required this.books,
    required this.progress,
    required this.onBookSelect,
  });

  final List<Book> books;
  final Map<String, ReadingProgress> progress;
  final ValueChanged<Book> onBookSelect;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? Colors.white : AppColors.primaryText;
    final secondaryText =
        isDark ? Colors.white.withValues(alpha: 0.7) : AppColors.secondaryText;
    final recommendations = _buildRecommendations();
    final contextInfo = _environmentContext();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'For You',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: primaryText,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Personalized book recommendations based on your reading habits.',
          style: TextStyle(color: secondaryText),
        ),
        const SizedBox(height: 20),
        _buildContextCard(
          context,
          contextInfo,
          primaryText,
          secondaryText,
        ),
        const SizedBox(height: 20),
        if (recommendations.isEmpty)
          Text(
            'No recommendations yet. Start reading to unlock suggestions.',
            style: TextStyle(color: secondaryText),
          )
        else
          for (final item in recommendations)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _buildRecommendationItem(
                item,
                primaryText,
                secondaryText,
              ),
            ),
        _buildReadingTip(
          context,
          contextInfo,
          primaryText,
          secondaryText,
        ),
      ],
    );
  }

  List<_Recommendation> _buildRecommendations() {
    final inProgressGenres = <String>{};
    for (final entry in progress.entries) {
      if (entry.value.currentPage > 0) {
        final book = books.firstWhere(
          (b) => b.id == entry.key,
          orElse: () => books.first,
        );
        inProgressGenres.addAll(book.genre);
      }
    }

    final candidates = books
        .where((book) => !progress.containsKey(book.id))
        .toList()
      ..sort((a, b) => b.rating.compareTo(a.rating));

    return candidates.take(4).map((book) {
      final matchesGenre = book.genre.any(inProgressGenres.contains);
      final confidence = matchesGenre ? 0.82 : 0.62;
      final reason = matchesGenre
          ? 'Because you read ${book.genre.first}.'
          : 'Top rated in your library.';
      return _Recommendation(
        book: book,
        reason: reason,
        confidence: confidence,
      );
    }).toList();
  }

  _EnvironmentContext _environmentContext() {
    final hour = DateTime.now().hour;
    final timeOfDay = hour < 6
        ? _TimeOfDayLabel.night
        : hour < 12
            ? _TimeOfDayLabel.morning
            : hour < 18
                ? _TimeOfDayLabel.afternoon
                : _TimeOfDayLabel.evening;
    return _EnvironmentContext(timeOfDay: timeOfDay);
  }

  Widget _buildContextCard(
    BuildContext context,
    _EnvironmentContext contextInfo,
    Color primaryText,
    Color secondaryText,
  ) {
    final label = contextInfo.timeOfDay.label;
    final cardColor = Theme.of(context).cardColor;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.border.withValues(alpha: 0.25),
            child: Icon(
              contextInfo.timeOfDay.icon,
              color: primaryText,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Smart Recommendations',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: primaryText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Based on your reading habits and the $label.',
                  style: TextStyle(color: secondaryText, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationItem(
    _Recommendation item,
    Color primaryText,
    Color secondaryText,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.lightbulb_outline, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.reason,
                    style: TextStyle(color: secondaryText),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: item.confidence,
                      minHeight: 4,
                      backgroundColor: AppColors.background,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.border,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(item.confidence * 100).round()}% match',
                    style: TextStyle(color: secondaryText, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        BookCard(
          book: item.book,
          progress: progress[item.book.id],
          onTap: () => onBookSelect(item.book),
        ),
      ],
    );
  }

  Widget _buildReadingTip(
    BuildContext context,
    _EnvironmentContext contextInfo,
    Color primaryText,
    Color secondaryText,
  ) {
    final tip = switch (contextInfo.timeOfDay) {
      _TimeOfDayLabel.morning =>
        'Morning is a great time for focused reading. Try non-fiction.',
      _TimeOfDayLabel.night =>
        'Consider switching to Midnight theme for comfortable night reading.',
      _TimeOfDayLabel.evening =>
        'Evening reads pair well with lighter genres and a warm theme.',
      _TimeOfDayLabel.afternoon =>
        'Take short breaks to keep focus and comprehension strong.',
    };
    final cardColor = Theme.of(context).cardColor;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.tips_and_updates_outlined, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reading Tip',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: primaryText,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  tip,
                  style: TextStyle(color: secondaryText, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Recommendation {
  _Recommendation({
    required this.book,
    required this.reason,
    required this.confidence,
  });

  final Book book;
  final String reason;
  final double confidence;
}

class _EnvironmentContext {
  _EnvironmentContext({required this.timeOfDay});

  final _TimeOfDayLabel timeOfDay;
}

enum _TimeOfDayLabel {
  morning('morning', Icons.wb_sunny_outlined),
  afternoon('afternoon', Icons.wb_cloudy_outlined),
  evening('evening', Icons.nights_stay_outlined),
  night('night', Icons.dark_mode_outlined);

  const _TimeOfDayLabel(this.label, this.icon);

  final String label;
  final IconData icon;
}

import 'package:flutter/material.dart';

import '../models/book.dart';
import '../theme/app_theme.dart';

class ReadingStatsScreen extends StatelessWidget {
  const ReadingStatsScreen({
    super.key,
    required this.books,
    required this.progress,
  });

  final List<Book> books;
  final Map<String, ReadingProgress> progress;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? Colors.white : AppColors.primaryText;
    final secondaryText =
        isDark ? Colors.white.withValues(alpha: 0.7) : AppColors.secondaryText;
    final stats = _buildStats();
    final cardColor = Theme.of(context).cardColor;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Reading Statistics',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: primaryText,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Track your reading journey and progress.',
          style: TextStyle(color: secondaryText),
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            int count = 2;
            if (width >= 900) {
              count = 3;
            }
            final aspectRatio = width < 600 ? 1.5 : 1.6;
            return GridView.count(
              crossAxisCount: count,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: aspectRatio,
              children: stats
                  .map((stat) => _StatCard(
                        label: stat.label,
                        value: stat.value,
                        icon: stat.icon,
                        subValue: stat.subValue,
                        primaryText: primaryText,
                        secondaryText: secondaryText,
                      ))
                  .toList(),
            );
          },
        ),
        const SizedBox(height: 24),
        _buildProgressSection(primaryText, secondaryText, cardColor),
      ],
    );
  }

  List<_StatEntry> _buildStats() {
    final progressList = progress.values.toList();
    final totalBooksStarted =
        progressList.where((p) => p.currentPage > 0).length;
    final totalBooksCompleted = progressList.where((p) {
      final book = books.firstWhere(
        (b) => b.id == p.bookId,
        orElse: () => Book(
          id: '',
          title: '',
          author: '',
          cover: '',
          genre: const [],
          description: '',
          content: const [],
          totalPages: 0,
          publishYear: 0,
          rating: 0,
        ),
      );
      return book.id.isNotEmpty && p.currentPage >= book.totalPages - 1;
    }).length;

    final totalTimeMinutes = progressList.fold<int>(
        0, (sum, p) => sum + (p.totalTimeSpentSeconds ~/ 60));
    final totalPagesRead =
        progressList.fold<int>(0, (sum, p) => sum + p.currentPage);

    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    final recentActivity = progressList
        .where((p) => p.lastRead.isAfter(sevenDaysAgo))
        .length;

    final avgSessionMinutes = totalBooksStarted == 0
        ? 0
        : (totalTimeMinutes / totalBooksStarted).round();
    final completionRate = totalBooksStarted == 0
        ? 0
        : ((totalBooksCompleted / totalBooksStarted) * 100).round();

    return [
      _StatEntry(
        label: 'Books Started',
        value: '$totalBooksStarted',
        icon: Icons.book,
      ),
      _StatEntry(
        label: 'Books Completed',
        value: '$totalBooksCompleted',
        icon: Icons.emoji_events_outlined,
      ),
      _StatEntry(
        label: 'Reading Time',
        value: '${totalTimeMinutes}m',
        subValue: '${avgSessionMinutes}m avg',
        icon: Icons.schedule_outlined,
      ),
      _StatEntry(
        label: 'Pages Read',
        value: '$totalPagesRead',
        icon: Icons.menu_book_outlined,
      ),
      _StatEntry(
        label: 'Completion Rate',
        value: '$completionRate%',
        subValue: 'Progressed titles',
        icon: Icons.trending_up,
      ),
      _StatEntry(
        label: 'Recent Activity',
        value: '$recentActivity',
        subValue: 'Last 7 days',
        icon: Icons.calendar_today_outlined,
      ),
    ];
  }

  Widget _buildProgressSection(
    Color primaryText,
    Color secondaryText,
    Color cardColor,
  ) {
    final activeBooks = progress.values.where((p) {
      final book = books.firstWhere(
        (b) => b.id == p.bookId,
        orElse: () => Book(
          id: '',
          title: '',
          author: '',
          cover: '',
          genre: const [],
          description: '',
          content: const [],
          totalPages: 0,
          publishYear: 0,
          rating: 0,
        ),
      );
      return book.id.isNotEmpty &&
          p.currentPage > 0 &&
          p.currentPage < book.totalPages - 1;
    }).toList();

    if (activeBooks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Reading Progress',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: primaryText,
            ),
          ),
          const SizedBox(height: 12),
          for (final progress in activeBooks)
            _buildProgressRow(progress, primaryText, secondaryText),
        ],
      ),
    );
  }

  Widget _buildProgressRow(
    ReadingProgress progress,
    Color primaryText,
    Color secondaryText,
  ) {
    final book = books.firstWhere((b) => b.id == progress.bookId);
    final percent = ((progress.currentPage + 1) / book.totalPages)
        .clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  book.title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: primaryText,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(percent * 100).round()}%',
                style: TextStyle(
                  color: secondaryText,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 4,
              backgroundColor: AppColors.background,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.border),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatEntry {
  _StatEntry({
    required this.label,
    required this.value,
    required this.icon,
    this.subValue,
  });

  final String label;
  final String value;
  final IconData icon;
  final String? subValue;
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.subValue,
    required this.primaryText,
    required this.secondaryText,
  });

  final String label;
  final String value;
  final IconData icon;
  final String? subValue;
  final Color primaryText;
  final Color secondaryText;

  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).cardColor;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: secondaryText,
                    fontSize: 12,
                  ),
                ),
              ),
              Icon(icon, size: 20, color: secondaryText),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: primaryText,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subValue != null) ...[
            const SizedBox(height: 4),
            Text(
              subValue!,
              style: TextStyle(
                color: secondaryText,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

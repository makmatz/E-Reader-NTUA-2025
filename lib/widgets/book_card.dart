import 'package:flutter/material.dart';

import '../models/book.dart';
import '../theme/app_theme.dart';

class BookCard extends StatelessWidget {
  const BookCard({
    super.key,
    required this.book,
    required this.onTap,
    this.progress,
  });

  final Book book;
  final ReadingProgress? progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final percent = progress == null
        ? 0.0
        : ((progress!.currentPage + 1) / book.totalPages).clamp(0.0, 1.0);
    final hasStarted = progress != null && progress!.currentPage > 0;
    final cardColor = Theme.of(context).cardColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? Colors.white : AppColors.primaryText;
    final secondaryText =
        isDark ? Colors.white.withValues(alpha: 0.7) : AppColors.secondaryText;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact =
              constraints.maxHeight.isFinite && constraints.maxHeight < 320;
          final imageHeight = isCompact ? 120.0 : 150.0;
          final descriptionVisible = !isCompact;
          final genreCount = isCompact ? 1 : 2;
          final spacingLg = isCompact ? 6.0 : 10.0;
          final spacingMd = isCompact ? 6.0 : 8.0;
          final spacingSm = isCompact ? 4.0 : 6.0;

          return Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
              color: cardColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Container(
                      height: imageHeight,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                        gradient: LinearGradient(
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                          colors: [
                            Colors.black.withValues(alpha: 0.12),
                            Colors.black.withValues(alpha: 0.04),
                          ],
                        ),
                      ),
                      child: book.cover.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: _buildCoverImage(book.cover),
                            )
                          : const SizedBox.shrink(),
                    ),
                    if (hasStarted)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: cardColor.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            '${(percent * 100).round()}%',
                            style: TextStyle(
                              fontSize: 11,
                              color: secondaryText,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: spacingLg),
                Text(
                  book.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: primaryText,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: spacingSm),
                Text(
                  book.author,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: secondaryText,
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: spacingMd),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: book.genre.take(genreCount).map((genre) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        genre,
                        style: TextStyle(
                          color: secondaryText,
                          fontSize: 11,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (descriptionVisible) ...[
                  SizedBox(height: spacingMd),
                  Text(
                    book.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: secondaryText,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
                if (hasStarted) ...[
                  SizedBox(height: spacingMd),
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
                  SizedBox(height: spacingSm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Page ${progress!.currentPage + 1} of ${book.totalPages}',
                        style: TextStyle(
                          color: secondaryText,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        '${(progress!.totalTimeSpentSeconds / 60).round()}m',
                        style: TextStyle(
                          color: secondaryText,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  SizedBox(height: spacingMd),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${book.totalPages} pages',
                        style: TextStyle(
                          color: secondaryText,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        '★ ${book.rating.toStringAsFixed(1)}',
                        style: TextStyle(
                          color: secondaryText,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCoverImage(String cover) {
    if (cover.startsWith('http')) {
      return Image.network(
        cover,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }
    return Image.asset(
      cover,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
    );
  }
}

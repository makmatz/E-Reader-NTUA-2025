import 'package:flutter/material.dart';

import '../models/book.dart';
import '../theme/app_theme.dart';
import '../widgets/book_card.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({
    super.key,
    required this.books,
    required this.progress,
    required this.onBookSelect,
  });

  final List<Book> books;
  final Map<String, ReadingProgress> progress;
  final ValueChanged<Book> onBookSelect;

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedGenre;
  late TabController _tabController;
  final ScrollController _tabScrollController = ScrollController();
  final GlobalKey _tabBarKey = GlobalKey();
  late final List<GlobalKey> _tabKeys;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabKeys = List.generate(4, (_) => GlobalKey());
    _tabController.addListener(_handleTabChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerSelectedTab();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _tabScrollController.dispose();
    super.dispose();
  }

  List<String> get _allGenres {
    final genres = <String>{};
    for (final book in widget.books) {
      genres.addAll(book.genre);
    }
    final list = genres.toList()..sort();
    return list;
  }

  List<Book> get _filteredBooks {
    final query = _searchController.text.trim().toLowerCase();
    return widget.books.where((book) {
      final matchesQuery = query.isEmpty ||
          book.title.toLowerCase().contains(query) ||
          book.author.toLowerCase().contains(query) ||
          book.description.toLowerCase().contains(query);
      final matchesGenre =
          _selectedGenre == null || book.genre.contains(_selectedGenre);
      return matchesQuery && matchesGenre;
    }).toList();
  }

  List<Book> get _continueReading {
    final books = widget.books.where((book) {
      final progress = widget.progress[book.id];
      return progress != null &&
          progress.currentPage > 0 &&
          progress.currentPage < book.totalPages - 1;
    }).toList();

    books.sort((a, b) {
      final aDate = widget.progress[a.id]?.lastRead ?? DateTime(1970);
      final bDate = widget.progress[b.id]?.lastRead ?? DateTime(1970);
      return bDate.compareTo(aDate);
    });
    return books;
  }

  List<Book> get _recentlyAdded {
    final books = [...widget.books];
    books.sort((a, b) => b.publishYear.compareTo(a.publishYear));
    return books.take(4).toList();
  }

  List<Book> get _bookmarkedBooks {
    final bookmarkedIds = widget.progress.entries
        .where((entry) => entry.value.bookmarkedPages.isNotEmpty)
        .map((entry) => entry.key)
        .toSet();
    return widget.books.where((book) => bookmarkedIds.contains(book.id)).toList();
  }

  List<Book> get _topRated {
    final books = [...widget.books];
    books.sort((a, b) => b.rating.compareTo(a.rating));
    return books.take(4).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? Colors.white : AppColors.primaryText;
    final secondaryText =
        isDark ? Colors.white.withValues(alpha: 0.7) : AppColors.secondaryText;
    final continueCount = _continueReading.length;
    final bookmarkCount = _bookmarkedBooks.length;
    return Scaffold(
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Library',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: primaryText,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${widget.books.length} books · ${_continueReading.length} in progress',
                        style: TextStyle(
                          color: secondaryText,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSearchBar(),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildGenreChip('All Genres', selected: true),
                          for (final genre in _allGenres)
                            _buildGenreChip(genre),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _TabBarDelegate(
                  _buildCenteredTabBar(
                    primaryText,
                    secondaryText,
                    continueCount,
                    bookmarkCount,
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildAllBooksTab(),
              _buildContinueTab(),
              _buildCollectionsTab(),
              _buildBookmarkedTab(),
            ],
          ),
        ),
      ),
    );
  }

  void _handleTabChange() {
    setState(() {});
    if (!_tabController.indexIsChanging) {
      _centerSelectedTab();
    }
  }

  void _centerSelectedTab() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_tabScrollController.hasClients) return;
      final scrollBox =
          _tabBarKey.currentContext?.findRenderObject() as RenderBox?;
      final tabBox =
          _tabKeys[_tabController.index].currentContext?.findRenderObject()
              as RenderBox?;
      if (scrollBox == null || tabBox == null) return;
      final tabOffset = tabBox.localToGlobal(
        Offset.zero,
        ancestor: scrollBox,
      );
      final tabCenter = tabOffset.dx + tabBox.size.width / 2;
      final target =
          _tabScrollController.offset + tabCenter - scrollBox.size.width / 2;
      final maxScroll = _tabScrollController.position.maxScrollExtent;
      final clamped = target.clamp(0.0, maxScroll);
      _tabScrollController.animateTo(
        clamped,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  Widget _buildCenteredTabBar(
    Color primaryText,
    Color secondaryText,
    int continueCount,
    int bookmarkCount,
  ) {
    return SizedBox(
      height: 46,
      child: ListView(
        key: _tabBarKey,
        controller: _tabScrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          _buildTabItem(
            index: 0,
            label: 'All Books',
            icon: Icons.library_books,
            primaryText: primaryText,
            secondaryText: secondaryText,
          ),
          _buildTabItem(
            index: 1,
            label: 'Continue Reading',
            icon: Icons.schedule,
            primaryText: primaryText,
            secondaryText: secondaryText,
            badge: continueCount > 0 ? '$continueCount' : null,
          ),
          _buildTabItem(
            index: 2,
            label: 'Collections',
            icon: Icons.auto_graph,
            primaryText: primaryText,
            secondaryText: secondaryText,
          ),
          _buildTabItem(
            index: 3,
            label: 'Bookmarks',
            icon: Icons.bookmark_border,
            primaryText: primaryText,
            secondaryText: secondaryText,
            badge: bookmarkCount > 0 ? '$bookmarkCount' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem({
    required int index,
    required String label,
    required IconData icon,
    required Color primaryText,
    required Color secondaryText,
    String? badge,
  }) {
    final isSelected = _tabController.index == index;
    final color = isSelected ? primaryText : secondaryText;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: InkWell(
        key: _tabKeys[index],
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          _tabController.animateTo(index);
          _centerSelectedTab();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 18, color: color),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  if (badge != null) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: primaryText.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          color: primaryText,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 2,
                width: isSelected ? 36 : 0,
                decoration: BoxDecoration(
                  color: primaryText,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: _searchController,
      onChanged: (_) => setState(() {}),
      style: TextStyle(
        color: isDark ? Colors.white : AppColors.primaryText,
      ),
      decoration: InputDecoration(
        hintText: 'Search books, authors, or genres...',
        prefixIcon: Icon(
          Icons.search,
          size: 18,
          color: isDark ? Colors.white : AppColors.secondaryText,
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF2B1F15) : Colors.white,
        hintStyle: TextStyle(
          color: isDark
              ? Colors.white.withValues(alpha: 0.7)
              : AppColors.secondaryText,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primaryText),
        ),
      ),
    );
  }

  Widget _buildGenreChip(String label, {bool selected = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = selected
        ? _selectedGenre == null
        : _selectedGenre == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: isDark ? const Color(0xFF3A2A17) : Colors.white,
      backgroundColor:
          isDark ? const Color(0xFF241A12) : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border),
      ),
      labelStyle: TextStyle(
        color: isDark
            ? Colors.white
            : (isSelected ? AppColors.primaryText : AppColors.secondaryText),
        fontSize: 12,
      ),
      onSelected: (_) {
        setState(() {
          if (selected) {
            _selectedGenre = null;
          } else {
            _selectedGenre = label;
          }
        });
      },
    );
  }

  Widget _buildAllBooksTab() {
    final books = _filteredBooks;
    if (books.isEmpty) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Center(
        child: Text(
          'No books found matching your search.',
          style: TextStyle(
            color: isDark
                ? Colors.white.withValues(alpha: 0.7)
                : AppColors.secondaryText,
          ),
        ),
      );
    }
    return _buildBookGrid(books, padding: const EdgeInsets.all(20));
  }

  Widget _buildContinueTab() {
    final books = _continueReading;
    if (books.isEmpty) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Center(
        child: Text(
          'No books in progress yet.',
          style: TextStyle(
            color: isDark
                ? Colors.white.withValues(alpha: 0.7)
                : AppColors.secondaryText,
          ),
        ),
      );
    }
    return _buildBookGrid(books, padding: const EdgeInsets.all(20));
  }

  Widget _buildCollectionsTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildSectionTitle('Recently Added'),
        const SizedBox(height: 12),
        _buildBookGrid(_recentlyAdded, shrinkWrap: true),
        const SizedBox(height: 24),
        _buildSectionTitle('Top Rated'),
        const SizedBox(height: 12),
        _buildBookGrid(_topRated, shrinkWrap: true),
      ],
    );
  }

  Widget _buildBookmarkedTab() {
    final books = _bookmarkedBooks;
    if (books.isEmpty) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Center(
        child: Text(
          'No bookmarked books yet.',
          style: TextStyle(
            color: isDark
                ? Colors.white.withValues(alpha: 0.7)
                : AppColors.secondaryText,
          ),
        ),
      );
    }
    return _buildBookGrid(books, padding: const EdgeInsets.all(20));
  }

  Widget _buildSectionTitle(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: isDark ? Colors.white : AppColors.primaryText,
      ),
    );
  }

  Widget _buildBookGrid(List<Book> books,
      {bool shrinkWrap = false, EdgeInsets? padding}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int count = 2;
        if (width >= 900) {
          count = 4;
        } else if (width >= 600) {
          count = 3;
        }
        final horizontalPadding = padding?.horizontal ?? 0;
        final tileWidth =
            (width - horizontalPadding - ((count - 1) * 16)) / count;
        final childAspectRatio = tileWidth < 170
            ? 0.68
            : tileWidth < 210
                ? 0.7
                : 0.74;
        return GridView.builder(
          itemCount: books.length,
          shrinkWrap: shrinkWrap,
          physics: shrinkWrap
              ? const NeverScrollableScrollPhysics()
              : const AlwaysScrollableScrollPhysics(),
          padding: padding,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: count,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: childAspectRatio,
          ),
          itemBuilder: (context, index) {
            final book = books[index];
            return BookCard(
              book: book,
              progress: widget.progress[book.id],
              onTap: () => widget.onBookSelect(book),
            );
          },
        );
      },
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  _TabBarDelegate(this.child);

  final Widget child;

  @override
  double get minExtent => 46;

  @override
  double get maxExtent => 46;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: child,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) => true;
}

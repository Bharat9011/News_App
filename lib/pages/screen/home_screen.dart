import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:news_app/state_mangement/news_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  final Set<int> _bookmarkedIndices = {};
  final Set<int> _likedIndices = {};

  // Search state
  bool _searchVisible = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  String _searchQuery = '';

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Search bar slide + fade animation
  late AnimationController _searchAnimController;
  late Animation<double> _searchSlideAnim;
  late Animation<double> _searchFadeAnim;

  // Refresh spin animation
  bool _isRefreshing = false;
  late AnimationController _refreshSpinController;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();

    _searchAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _searchSlideAnim = Tween<double>(begin: -60, end: 0).animate(
      CurvedAnimation(
        parent: _searchAnimController,
        curve: Curves.easeOutCubic,
      ),
    );
    _searchFadeAnim = CurvedAnimation(
      parent: _searchAnimController,
      curve: Curves.easeIn,
    );

    _refreshSpinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _searchAnimController.dispose();
    _refreshSpinController.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _toggleSearch() {}

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;
    HapticFeedback.mediumImpact();
    setState(() => _isRefreshing = true);
    _refreshSpinController.repeat();

    ref.refresh(newsProvider);
    await Future.delayed(const Duration(milliseconds: 1500));

    if (mounted) {
      _refreshSpinController.stop();
      _refreshSpinController.reset();
      setState(() {
        _isRefreshing = false;
        _currentIndex = 0;
      });
      _pageController.jumpToPage(0);
    }
  }

  String _estimateReadTime(String? content) {
    if (content == null || content.isEmpty) return '1 min read';
    final words = content.split(' ').length;
    final minutes = (words / 200).ceil();
    return '$minutes min read';
  }

  String _formatSource(String? author) {
    if (author == null || author.isEmpty) return 'News';
    return author.split(',').first.trim();
  }

  Widget _buildShimmer() {
    return Stack(
      children: [
        PageView.builder(
          scrollDirection: Axis.vertical,
          itemCount: 5,
          itemBuilder: (context, index) {
            return Shimmer.fromColors(
              baseColor: const Color(0xFF1A1A2E),
              highlightColor: const Color(0xFF2D2D44),
              child: Stack(
                children: [
                  Container(color: const Color(0xFF1A1A2E)),
                  Positioned(
                    bottom: 100,
                    left: 20,
                    right: 80,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 14,
                          width: 80,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 22,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 22,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          height: 14,
                          width: 120,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 120,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xCC000000), Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGlassButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isActive = false,
    Color activeColor = Colors.redAccent,
    String? label,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withOpacity(0.25)
              : Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? activeColor.withOpacity(0.6)
                : Colors.white.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isActive ? activeColor : Colors.white, size: 26),
            if (label != null) ...[
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? activeColor : Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFE63946),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        category.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildScrollIndicator(int total) {
    final count = total > 6 ? 6 : total;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final isActive = i == (_currentIndex % count);
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(vertical: 3),
          width: isActive ? 6 : 4,
          height: isActive ? 24 : 8,
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.white38,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }

  /// Animated search bar sliding down from below the AppBar
  Widget _buildSearchBar() {
    return AnimatedBuilder(
      animation: _searchAnimController,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, _searchSlideAnim.value),
        child: Opacity(opacity: _searchFadeAnim.value, child: child),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: Colors.white54, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocus,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                cursorColor: const Color(0xFFE63946),
                decoration: const InputDecoration(
                  hintText: 'Search headlines...',
                  hintStyle: TextStyle(color: Colors.white38, fontSize: 15),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            if (_searchQuery.isNotEmpty)
              GestureDetector(
                onTap: () => _searchController.clear(),
                child: const Icon(Icons.close, color: Colors.white54, size: 18),
              ),
          ],
        ),
      ),
    );
  }

  /// Spinning refresh button pinned top-left below the AppBar
  Widget _buildRefreshButton(double topPadding) {
    return Positioned(
      top: topPadding + 56,
      left: 16,
      child: GestureDetector(
        onTap: _handleRefresh,
        child: AnimatedBuilder(
          animation: _refreshSpinController,
          builder: (context, child) => Transform.rotate(
            angle: _isRefreshing
                ? _refreshSpinController.value * 2 * 3.14159
                : 0,
            child: child,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _isRefreshing
                  ? const Color(0xFFE63946).withOpacity(0.25)
                  : Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _isRefreshing
                    ? const Color(0xFFE63946).withOpacity(0.6)
                    : Colors.white24,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              Icons.refresh_rounded,
              color: _isRefreshing ? const Color(0xFFE63946) : Colors.white,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final newsAsync = ref.watch(newsProvider);
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xCC000000), Colors.transparent],
            ),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFE63946),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.bolt, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Text(
              'NEWSFLASH',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        actions: [
          // Search toggle — icon changes to X when active
          GestureDetector(
            onTap: _toggleSearch,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _searchVisible
                    ? const Color(0xFFE63946).withOpacity(0.25)
                    : Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _searchVisible
                      ? const Color(0xFFE63946).withOpacity(0.7)
                      : Colors.white24,
                ),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  _searchVisible ? Icons.close : Icons.search,
                  key: ValueKey(_searchVisible),
                  color: _searchVisible
                      ? const Color(0xFFE63946)
                      : Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
      body: newsAsync.when(
        loading: _buildShimmer,
        error: (err, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.wifi_off_rounded,
                color: Colors.white38,
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'Could not load news',
                style: TextStyle(color: Colors.white60, fontSize: 16),
              ),
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: () => ref.refresh(newsProvider),
                icon: const Icon(Icons.refresh, color: Color(0xFFE63946)),
                label: const Text(
                  'Retry',
                  style: TextStyle(color: Color(0xFFE63946)),
                ),
              ),
            ],
          ),
        ),
        data: (news) {
          // Live filter by search query
          final filtered = _searchQuery.isEmpty
              ? news
              : news
                    .where(
                      (item) =>
                          (item.title ?? '').toLowerCase().contains(
                            _searchQuery,
                          ) ||
                          (item.description ?? '').toLowerCase().contains(
                            _searchQuery,
                          ) ||
                          (item.author ?? '').toLowerCase().contains(
                            _searchQuery,
                          ),
                    )
                    .toList();

          return FadeTransition(
            opacity: _fadeAnimation,
            child: Stack(
              children: [
                // ── MAIN PAGE VIEW ──
                filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.search_off_rounded,
                              color: Colors.white24,
                              size: 64,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No results for "$_searchQuery"',
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      )
                    : NotificationListener<ScrollNotification>(
                        onNotification: (notification) {
                          // Detect overscroll at the top → trigger refresh
                          if (notification is OverscrollNotification &&
                              notification.overscroll < 0 &&
                              _currentIndex == 0 &&
                              !_isRefreshing) {
                            _handleRefresh();
                          }
                          return false;
                        },
                        child: PageView.builder(
                          controller: _pageController,
                          scrollDirection: Axis.vertical,
                          itemCount: filtered.length,
                          onPageChanged: (index) {
                            setState(() => _currentIndex = index);
                            HapticFeedback.lightImpact();
                          },
                          itemBuilder: (context, index) {
                            final item = filtered[index];
                            final isBookmarked = _bookmarkedIndices.contains(
                              index,
                            );
                            final isLiked = _likedIndices.contains(index);
                            final hasImage =
                                item.urlToImage != null &&
                                item.urlToImage!.isNotEmpty;

                            return GestureDetector(
                              onTap: () {
                                // Dismiss search on tap if open
                                if (_searchVisible) {
                                  _toggleSearch();
                                  return;
                                }
                                Navigator.pushNamed(
                                  context,
                                  "/screen/viewnewsartical",
                                  arguments: {
                                    "image": hasImage
                                        ? item.urlToImage!
                                        : "assets/images/news_placeholder.png",
                                    "title": item.title,
                                    "author": item.author,
                                    "description":
                                        (item.description != null &&
                                            item.description!.isNotEmpty)
                                        ? item.description
                                        : "",
                                    "content": item.content,
                                    "url": item.url,
                                  },
                                );
                              },
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  // ── BACKGROUND IMAGE ──
                                  hasImage
                                      ? Image.network(
                                          item.urlToImage!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Image.asset(
                                            "assets/images/news_placeholder.png",
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : Image.asset(
                                          "assets/images/news_placeholder.png",
                                          fit: BoxFit.cover,
                                        ),

                                  // ── CINEMATIC GRADIENT ──
                                  Container(
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        stops: [0.0, 0.35, 0.65, 1.0],
                                        colors: [
                                          Color(0x99000000),
                                          Colors.transparent,
                                          Color(0x66000000),
                                          Color(0xEE000000),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // ── BOTTOM CONTENT ──
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 70,
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        20,
                                        0,
                                        16,
                                        48,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          _buildCategoryChip('Latest'),
                                          const SizedBox(height: 12),
                                          Text(
                                            item.title ?? '',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 22,
                                              fontWeight: FontWeight.w800,
                                              height: 1.3,
                                              letterSpacing: -0.3,
                                              shadows: [
                                                Shadow(
                                                  blurRadius: 12,
                                                  color: Colors.black87,
                                                ),
                                              ],
                                            ),
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 14),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.person_outline,
                                                color: Colors.white60,
                                                size: 14,
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  _formatSource(item.author),
                                                  style: const TextStyle(
                                                    color: Colors.white60,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Container(
                                                width: 3,
                                                height: 3,
                                                decoration: const BoxDecoration(
                                                  color: Colors.white38,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              const Icon(
                                                Icons.schedule_outlined,
                                                color: Colors.white60,
                                                size: 14,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                _estimateReadTime(item.content),
                                                style: const TextStyle(
                                                  color: Colors.white60,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 14),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(
                                                0.15,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(24),
                                              border: Border.all(
                                                color: Colors.white24,
                                              ),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  'Read full story',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                SizedBox(width: 6),
                                                Icon(
                                                  Icons.arrow_forward_rounded,
                                                  color: Colors.white,
                                                  size: 14,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // ── ACTION BUTTONS ──
                                  Positioned(
                                    right: 12,
                                    bottom: 80,
                                    child: Column(
                                      children: [
                                        _buildGlassButton(
                                          icon: isLiked
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                          isActive: isLiked,
                                          activeColor: Colors.redAccent,
                                          label: 'Like',
                                          onTap: () {
                                            HapticFeedback.mediumImpact();
                                            setState(
                                              () => isLiked
                                                  ? _likedIndices.remove(index)
                                                  : _likedIndices.add(index),
                                            );
                                          },
                                        ),
                                        const SizedBox(height: 12),
                                        _buildGlassButton(
                                          icon: isBookmarked
                                              ? Icons.bookmark
                                              : Icons.bookmark_border,
                                          isActive: isBookmarked,
                                          activeColor: const Color(0xFFFFBB33),
                                          label: 'Save',
                                          onTap: () {
                                            HapticFeedback.mediumImpact();
                                            setState(
                                              () => isBookmarked
                                                  ? _bookmarkedIndices.remove(
                                                      index,
                                                    )
                                                  : _bookmarkedIndices.add(
                                                      index,
                                                    ),
                                            );
                                            ScaffoldMessenger.of(context)
                                              ..clearSnackBars()
                                              ..showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    isBookmarked
                                                        ? 'Removed from saved'
                                                        : 'Article saved!',
                                                  ),
                                                  behavior:
                                                      SnackBarBehavior.floating,
                                                  backgroundColor: const Color(
                                                    0xFF1E1E2E,
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  duration: const Duration(
                                                    seconds: 2,
                                                  ),
                                                ),
                                              );
                                          },
                                        ),
                                        const SizedBox(height: 12),
                                        _buildGlassButton(
                                          icon: Icons.share_rounded,
                                          label: 'Share',
                                          onTap: () => Share.share(
                                            '${item.title}\n${item.url ?? ''}',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // ── SWIPE HINT (first card only) ──
                                  if (index == 0 && _currentIndex == 0)
                                    const Positioned(
                                      bottom: 16,
                                      left: 0,
                                      right: 0,
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.keyboard_arrow_up_rounded,
                                            color: Colors.white38,
                                            size: 28,
                                          ),
                                          Text(
                                            'Swipe up for more',
                                            style: TextStyle(
                                              color: Colors.white38,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ), // NotificationListener
                // ── PULL-TO-REFRESH INDICATOR (top centre) ──
                if (_isRefreshing)
                  Positioned(
                    top: topPadding + 56,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _refreshSpinController,
                        builder: (context, child) => Transform.rotate(
                          angle: _refreshSpinController.value * 2 * 3.14159,
                          child: child,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE63946).withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFE63946).withOpacity(0.6),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFE63946).withOpacity(0.3),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.refresh_rounded,
                            color: Color(0xFFE63946),
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ),

                // ── SEARCH BAR (slides in below AppBar) ──

                // ── REFRESH BUTTON ──
                _buildRefreshButton(topPadding),

                // ── SCROLL INDICATOR (hidden while searching) ──
                if (!_searchVisible)
                  Positioned(
                    right: 6,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _buildScrollIndicator(filtered.length),
                    ),
                  ),

                // ── ARTICLE COUNTER (hidden while searching) ──
                if (!_searchVisible)
                  Positioned(
                    top: topPadding + 60,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Text(
                        '${_currentIndex + 1} / ${filtered.length}',
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

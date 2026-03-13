import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:news_app/domin/api/search_news.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with TickerProviderStateMixin {
  // ── Controllers ──
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final SearchNews _searchService = SearchNews();

  // ── State ──
  String _query = '';
  bool _isFocused = false;
  bool _isLoading = false;
  String? _errorMessage;
  List<dynamic> _results = [];
  final List<String> _recentSearches = [];
  Timer? _debounce;

  // ── Static data ──
  final List<String> _trendingTopics = [
    'Technology',
    'Politics',
    'Sports',
    'Finance',
    'Climate',
    'Health',
    'AI',
    'Space',
  ];

  // ── Animations ──
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;
  late AnimationController _chipController;
  late Animation<double> _chipAnim;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

    _chipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _chipAnim = CurvedAnimation(
      parent: _chipController,
      curve: Curves.easeOutCubic,
    );

    _focusNode.addListener(
      () => setState(() => _isFocused = _focusNode.hasFocus),
    );

    _searchController.addListener(() {
      final text = _searchController.text.trim();
      setState(() => _query = text);

      // Debounce — search 500 ms after user stops typing
      _debounce?.cancel();
      if (text.isEmpty) {
        setState(() {
          _results = [];
          _isLoading = false;
          _errorMessage = null;
        });
        return;
      }
      _debounce = Timer(
        const Duration(milliseconds: 500),
        () => _doSearch(text),
      );
    });

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _focusNode.requestFocus(),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    _fadeController.dispose();
    _chipController.dispose();
    super.dispose();
  }

  // ── API call ──
  Future<void> _doSearch(String query) async {
    if (query.isEmpty) return;

    print("Searching for: $query");

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _results = [];
    });

    try {
      final articles = await _searchService.searchNews(query);

      print("API RESULT: $articles");

      setState(() {
        _results = articles;
        _isLoading = false;
      });
    } catch (e) {
      print("API ERROR: $e");

      setState(() {
        _errorMessage = 'Could not load results';
        _isLoading = false;
      });
    }
  }

  void _fillSearch(String topic) {
    HapticFeedback.lightImpact();
    _searchController.text = topic;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: topic.length),
    );
  }

  void _navigateToArticle(dynamic article) {
    final image =
        (article['urlToImage'] != null &&
            (article['urlToImage'] as String).isNotEmpty)
        ? article['urlToImage'] as String
        : 'assets/images/news_placeholder.png';

    Navigator.pushNamed(
      context,
      '/screen/viewnewsartical',
      arguments: {
        'image': image,
        'title': article['title'] ?? '',
        'author': article['author'] ?? '',
        'description': article['description'] ?? '',
        'content': article['content'] ?? '',
        "url": article['url'] ?? '',
      },
    );
  }

  // ────────────────────────────────────────────
  //  BUILD
  // ────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: topPadding + 14),

            // ── SEARCH BAR ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _isFocused
                            ? Colors.white.withOpacity(0.10)
                            : Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _isFocused
                              ? const Color(0xFFE63946).withOpacity(0.65)
                              : Colors.white12,
                          width: _isFocused ? 1.5 : 1,
                        ),
                        boxShadow: _isFocused
                            ? [
                                BoxShadow(
                                  color: const Color(
                                    0xFFE63946,
                                  ).withOpacity(0.14),
                                  blurRadius: 18,
                                  spreadRadius: 1,
                                ),
                              ]
                            : [],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search_rounded,
                            color: _isFocused
                                ? const Color(0xFFE63946)
                                : Colors.white38,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              focusNode: _focusNode,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                              cursorColor: const Color(0xFFE63946),
                              textInputAction: TextInputAction.search,
                              onSubmitted: _doSearch,
                              decoration: const InputDecoration(
                                hintText: 'Search headlines, topics...',
                                hintStyle: TextStyle(
                                  color: Colors.white30,
                                  fontSize: 15,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 11,
                                ),
                              ),
                            ),
                          ),
                          if (_isLoading)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFFE63946),
                              ),
                            )
                          else if (_query.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                _focusNode.requestFocus();
                              },
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  color: Colors.white24,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 13,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // ── BODY ──
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeOut,
                child: _buildBody(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_query.isEmpty) return _buildDiscovery(key: const ValueKey('disc'));
    if (_isLoading) return _buildShimmer(key: const ValueKey('load'));
    if (_errorMessage != null) return _buildError(key: const ValueKey('err'));
    if (_results.isEmpty) return _buildEmpty(key: const ValueKey('empty'));
    return _buildResultList(key: const ValueKey('results'));
  }

  // ────────────────────────────────────────────
  //  DISCOVERY VIEW
  // ────────────────────────────────────────────
  Widget _buildDiscovery({Key? key}) {
    return SingleChildScrollView(
      key: key,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_recentSearches.isNotEmpty) ...[
            _sectionLabel(
              'Recent',
              Icons.history_rounded,
              onClear: () {
                setState(() => _recentSearches.clear());
              },
            ),
            const SizedBox(height: 10),
            ..._recentSearches.map(_recentTile),
            const SizedBox(height: 28),
          ],
          _sectionLabel('Trending', Icons.local_fire_department_rounded),
          const SizedBox(height: 12),
          _buildChipCloud(),
          const SizedBox(height: 30),
          _sectionLabel('Explore Categories', Icons.grid_view_rounded),
          const SizedBox(height: 12),
          _buildCategoryGrid(),
        ],
      ),
    );
  }

  Widget _sectionLabel(String title, IconData icon, {VoidCallback? onClear}) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFE63946), size: 15),
        const SizedBox(width: 7),
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
        const Spacer(),
        if (onClear != null)
          GestureDetector(
            onTap: onClear,
            child: const Text(
              'Clear',
              style: TextStyle(color: Colors.white30, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _recentTile(String term) {
    return GestureDetector(
      onTap: () => _fillSearch(term),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            const Icon(Icons.history_rounded, color: Colors.white24, size: 16),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                term,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ),
            GestureDetector(
              onTap: () => setState(() => _recentSearches.remove(term)),
              child: const Icon(Icons.close, color: Colors.white24, size: 15),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChipCloud() {
    const emojis = ['💻', '🏛️', '⚽', '📈', '🌍', '🏥', '🤖', '🚀'];
    return AnimatedBuilder(
      animation: _chipAnim,
      builder: (context, child) => Opacity(
        opacity: _chipAnim.value,
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - _chipAnim.value)),
          child: child,
        ),
      ),
      child: Wrap(
        spacing: 9,
        runSpacing: 9,
        children: _trendingTopics.asMap().entries.map((e) {
          return GestureDetector(
            onTap: () => _fillSearch(e.value),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    emojis[e.key % emojis.length],
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    e.value,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategoryGrid() {
    final cats = [
      ('World', Icons.public_rounded, const Color(0xFF2196F3)),
      ('Business', Icons.business_center_rounded, const Color(0xFF4CAF50)),
      ('Science', Icons.science_rounded, const Color(0xFF9C27B0)),
      ('Entertainment', Icons.movie_rounded, const Color(0xFFFF9800)),
      ('Sports', Icons.sports_soccer_rounded, const Color(0xFF00BCD4)),
      ('Health', Icons.favorite_rounded, const Color(0xFFE63946)),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.1,
      ),
      itemCount: cats.length,
      itemBuilder: (context, i) {
        final (label, icon, color) = cats[i];
        return GestureDetector(
          onTap: () => _fillSearch(label),
          child: Container(
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withOpacity(0.22)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.16),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: color.withOpacity(0.85),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ────────────────────────────────────────────
  //  RESULTS LIST
  // ────────────────────────────────────────────
  Widget _buildResultList({Key? key}) {
    return ListView.builder(
      key: key,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      itemCount: _results.length,
      itemBuilder: (context, i) {
        final article = _results[i];
        return _resultCard(article);
      },
    );
  }

  Widget _resultCard(dynamic article) {
    final title = article['title'] as String? ?? '';
    final author = article['author'] as String? ?? '';
    final imageUrl = article['urlToImage'] as String? ?? '';
    final source = article['source']?['name'] as String? ?? '';

    return GestureDetector(
      onTap: () => _navigateToArticle(article),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            // ── Thumbnail ──
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: imageUrl.startsWith('http')
                  ? Image.network(
                      imageUrl,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _thumbPlaceholder(),
                    )
                  : _thumbPlaceholder(),
            ),

            // ── Info ──
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Source pill
                    if (source.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE63946).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          source.toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFFE63946),
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),

                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.person_outline,
                          color: Colors.white30,
                          size: 11,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            author.isEmpty ? 'Unknown' : author,
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 11,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const Padding(
              padding: EdgeInsets.only(right: 10),
              child: Icon(
                Icons.chevron_right_rounded,
                color: Colors.white24,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _thumbPlaceholder() => Container(
    width: 100,
    height: 100,
    color: Colors.white.withOpacity(0.06),
    child: const Icon(Icons.image_outlined, color: Colors.white24, size: 26),
  );

  // ────────────────────────────────────────────
  //  SHIMMER LOADING
  // ────────────────────────────────────────────
  Widget _buildShimmer({Key? key}) {
    return ListView.builder(
      key: key,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      itemCount: 6,
      itemBuilder: (_, __) => _shimmerCard(),
    );
  }

  Widget _shimmerCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          // Image placeholder
          Container(
            width: 100,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
          ),
          // Text placeholders
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _shimmerLine(width: 60, height: 10),
                  const SizedBox(height: 8),
                  _shimmerLine(width: double.infinity, height: 13),
                  const SizedBox(height: 6),
                  _shimmerLine(width: 120, height: 13),
                  const SizedBox(height: 8),
                  _shimmerLine(width: 80, height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _shimmerLine({required double width, required double height}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 0.08),
      duration: const Duration(milliseconds: 900),
      builder: (_, opacity, __) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(opacity),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────
  //  EMPTY  &  ERROR  STATES
  // ────────────────────────────────────────────
  Widget _buildEmpty({Key? key}) {
    return Center(
      key: key,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white12),
            ),
            child: const Icon(
              Icons.search_off_rounded,
              color: Colors.white30,
              size: 36,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'No results found',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different keyword for "$_query"',
            style: const TextStyle(color: Colors.white38, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildError({Key? key}) {
    return Center(
      key: key,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFE63946).withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFE63946).withOpacity(0.3),
              ),
            ),
            child: const Icon(
              Icons.wifi_off_rounded,
              color: Color(0xFFE63946),
              size: 36,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Something went wrong',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? '',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white38, fontSize: 13),
          ),
          const SizedBox(height: 22),
          GestureDetector(
            onTap: () => _doSearch(_query),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE63946),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE63946).withOpacity(0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Text(
                'Try Again',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

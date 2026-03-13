import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class ViewNewsArtical extends ConsumerStatefulWidget {
  final String image;
  final String title;
  final String author;
  final String description;
  final String content;
  final String url;

  const ViewNewsArtical({
    super.key,
    required this.image,
    required this.title,
    required this.author,
    required this.description,
    required this.content,
    required this.url,
  });

  @override
  ConsumerState<ViewNewsArtical> createState() => _ViewNewsArticalState();
}

class _ViewNewsArticalState extends ConsumerState<ViewNewsArtical>
    with SingleTickerProviderStateMixin {
  bool _isBookmarked = false;
  bool _isLiked = false;
  late ScrollController _scrollController;
  double _scrollProgress = 0.0;

  late AnimationController _entryController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  String get _cleanContent =>
      widget.content.replaceAll(RegExp(r'\[\+\d+ chars\]'), '').trim();

  String get _estimateReadTime {
    final words =
        _cleanContent.split(' ').length +
        widget.description.split(' ').length +
        widget.title.split(' ').length;
    final minutes = (words / 200).ceil();
    return '$minutes min read';
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    _scrollController = ScrollController()
      ..addListener(() {
        final maxScroll = _scrollController.position.maxScrollExtent;
        if (maxScroll > 0) {
          setState(() {
            _scrollProgress = (_scrollController.offset / maxScroll).clamp(
              0.0,
              1.0,
            );
          });
        }
      });

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entryController,
            curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
          ),
        );

    _entryController.forward();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Stack(
        children: [
          // ── MAIN SCROLL ──
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── HERO IMAGE ──
              SliverAppBar(
                expandedHeight: size.height * 0.48,
                pinned: true,
                backgroundColor: const Color(0xFF0D0D0D),
                elevation: 0,
                automaticallyImplyLeading: false,
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.parallax,
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Hero image
                      widget.image.startsWith('http')
                          ? Image.network(
                              widget.image,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Image.asset(
                                'assets/images/news_placeholder.png',
                                fit: BoxFit.cover,
                              ),
                            )
                          : Image.asset(widget.image, fit: BoxFit.cover),

                      // Deep cinematic gradient
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: [0.0, 0.4, 0.75, 1.0],
                            colors: [
                              Color(0x88000000),
                              Colors.transparent,
                              Color(0xAA000000),
                              Color(0xFF0D0D0D),
                            ],
                          ),
                        ),
                      ),

                      // Top bar inside hero
                      Positioned(
                        top: topPadding + 8,
                        left: 16,
                        right: 16,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _heroButton(
                              icon: Icons.arrow_back_ios_new_rounded,
                              onTap: () => Navigator.pop(context),
                            ),
                            Row(
                              children: [
                                _heroButton(
                                  icon: _isBookmarked
                                      ? Icons.bookmark
                                      : Icons.bookmark_border,
                                  isActive: _isBookmarked,
                                  activeColor: const Color(0xFFFFBB33),
                                  onTap: () => setState(
                                    () => _isBookmarked = !_isBookmarked,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                _heroButton(
                                  icon: Icons.share_rounded,
                                  onTap: () => Share.share(
                                    '${widget.title}\n\n${widget.description}',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Category + read time pill at bottom of hero
                      Positioned(
                        bottom: 20,
                        left: 20,
                        child: Row(
                          children: [
                            _pill('BREAKING', const Color(0xFFE63946)),
                            const SizedBox(width: 8),
                            _pill(_estimateReadTime, Colors.white24),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── ARTICLE BODY ──
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(22, 8, 22, 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── TITLE ──
                          Text(
                            widget.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              height: 1.28,
                              letterSpacing: -0.5,
                            ),
                          ),

                          const SizedBox(height: 18),

                          // ── AUTHOR ROW ──
                          Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(
                                    0xFFE63946,
                                  ).withOpacity(0.2),
                                  border: Border.all(
                                    color: const Color(
                                      0xFFE63946,
                                    ).withOpacity(0.5),
                                    width: 1.5,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.person_outline,
                                  color: Color(0xFFE63946),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.author.isEmpty
                                          ? 'Unknown Author'
                                          : widget.author,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const Text(
                                      'Staff Reporter',
                                      style: TextStyle(
                                        color: Colors.white38,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // ── DIVIDER ──
                          Row(
                            children: [
                              Container(
                                width: 4,
                                height: 4,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE63946),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Container(
                                  height: 1,
                                  color: Colors.white10,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // ── DESCRIPTION (lead paragraph) ──
                          if (widget.description.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.04),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white10),
                                // Left accent bar
                              ),
                              child: IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Container(
                                      width: 3,
                                      margin: const EdgeInsets.only(right: 14),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE63946),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        widget.description,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          height: 1.6,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 28),
                          ],

                          // ── CONTENT ──
                          if (_cleanContent.isNotEmpty)
                            Text(
                              _cleanContent,
                              style: const TextStyle(
                                color: Color(0xFFCCCCCC),
                                fontSize: 16,
                                height: 1.8,
                                letterSpacing: 0.1,
                              ),
                            ),

                          const SizedBox(height: 36),

                          // ── BOTTOM ACTION ROW ──
                          Row(
                            children: [
                              // Like button
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    HapticFeedback.mediumImpact();
                                    setState(() => _isLiked = !_isLiked);
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _isLiked
                                          ? Colors.redAccent.withOpacity(0.18)
                                          : Colors.white.withOpacity(0.06),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: _isLiked
                                            ? Colors.redAccent.withOpacity(0.5)
                                            : Colors.white12,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          _isLiked
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                          color: _isLiked
                                              ? Colors.redAccent
                                              : Colors.white54,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _isLiked ? 'Liked' : 'Like',
                                          style: TextStyle(
                                            color: _isLiked
                                                ? Colors.redAccent
                                                : Colors.white54,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 12),

                              // Share button
                              Expanded(
                                child: GestureDetector(
                                  onTap: () async {
                                    final Uri uri = Uri.parse(widget.url);

                                    if (!await launchUrl(
                                      uri,
                                      mode: LaunchMode
                                          .externalApplication, // opens in browser
                                    )) {
                                      throw Exception('Could not launch $uri');
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE63946),
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(
                                            0xFFE63946,
                                          ).withOpacity(0.35),
                                          blurRadius: 16,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.open_in_browser,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'See More',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ── READING PROGRESS BAR (top) ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 50),
              height: 3,
              width: MediaQuery.of(context).size.width * _scrollProgress,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFE63946), Color(0xFFFF6B6B)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── HERO GLASS BUTTON ──
  Widget _heroButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isActive = false,
    Color activeColor = Colors.white,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withOpacity(0.2)
              : Colors.black.withOpacity(0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? activeColor.withOpacity(0.6) : Colors.white24,
          ),
        ),
        child: Icon(
          icon,
          color: isActive ? activeColor : Colors.white,
          size: 20,
        ),
      ),
    );
  }

  // ── PILL BADGE ──
  Widget _pill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

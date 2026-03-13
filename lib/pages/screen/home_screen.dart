import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:news_app/state_mangement/news_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Widget buildShimmer() {
    return PageView.builder(
      scrollDirection: Axis.vertical,
      itemCount: 5,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey.shade800,
          highlightColor: Colors.grey.shade700,
          child: Container(color: Colors.black),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newsAsync = ref.watch(newsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("News App"), centerTitle: true),

      body: newsAsync.when(
        loading: () => buildShimmer(),

        error: (err, stack) => const Center(child: Text("Error loading news")),

        data: (news) {
          return PageView.builder(
            scrollDirection: Axis.vertical,
            itemCount: news.length,
            itemBuilder: (context, index) {
              final item = news[index];

              return InkWell(
                onTap: () {},
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    /// IMAGE
                    item.urlToImage != null && item.urlToImage!.isNotEmpty
                        ? Image.network(
                            item.urlToImage!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset(
                                "assets/images/news_placeholder.png",
                                fit: BoxFit.cover,
                              );
                            },
                          )
                        : Image.asset(
                            "assets/images/news_placeholder.png",
                            fit: BoxFit.cover,
                          ),

                    /// GRADIENT
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.center,
                          colors: [Colors.black, Colors.transparent],
                        ),
                      ),
                    ),

                    /// TITLE
                    Positioned(
                      bottom: 80,
                      left: 16,
                      right: 16,
                      child: Text(
                        item.title ?? "",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    /// ACTION BUTTONS
                    Positioned(
                      right: 10,
                      bottom: 120,
                      child: Column(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.bookmark_border,
                              color: Colors.white,
                              size: 32,
                            ),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Saved")),
                              );
                            },
                          ),

                          const SizedBox(height: 20),

                          IconButton(
                            icon: const Icon(
                              Icons.share,
                              color: Colors.white,
                              size: 32,
                            ),
                            onPressed: () {
                              Share.share("${item.title}\n${item.url ?? ""}");
                            },
                          ),

                          const SizedBox(height: 20),

                          IconButton(
                            icon: const Icon(
                              Icons.more_vert,
                              color: Colors.white,
                              size: 32,
                            ),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

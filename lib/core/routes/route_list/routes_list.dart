import 'package:flutter/material.dart';
import 'package:news_app/pages/screen/home_screen.dart';
import 'package:news_app/pages/screen/search_news.dart';
import 'package:news_app/pages/screen/view_news_artical.dart';

Map<String, WidgetBuilder> pages = {
  "/": (context) => const HomeScreen(),
  "/screen/viewnewsartical": (context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    return ViewNewsArtical(
      image: args["image"],
      title: args["title"],
      author: args["author"],
      description: args["description"],
      content: args["content"],
      url: args["url"],
    );
  },
  "/screen/searchnews": (context) => const SearchScreen(),
};

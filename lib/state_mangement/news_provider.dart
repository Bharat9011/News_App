import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:news_app/domin/api/top_headlines.dart';
import 'package:news_app/domin/model/top_headline_model.dart';

final newsProvider = FutureProvider<List<Article>>((ref) async {
  return TopHeadlines.getTopHeadlines();
});

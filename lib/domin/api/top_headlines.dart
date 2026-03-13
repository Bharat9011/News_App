import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:news_app/domin/app_url.dart';
import 'package:news_app/domin/model/top_headline_model.dart';

class TopHeadlines {
  static Future<List<Article>> getTopHeadlines() async {
    try {
      var response = await http.get(
        Uri.parse(AppUrl.get_top_headlines),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);

        List jsonList = data["articles"];
        return jsonList.map((val) => Article.fromJson(val)).toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:news_app/domin/app_url.dart';
import 'package:news_app/services/key_services.dart';

class SearchNews {
  Future<List<dynamic>> searchNews(String query) async {
    final url = Uri.parse(
      "${AppUrl.search_news}$query&apiKey=${KeyServices.baseUrl}",
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["articles"];
    } else {
      throw Exception("Failed to load news");
    }
  }
}

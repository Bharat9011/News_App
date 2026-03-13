import 'package:news_app/services/key_services.dart';

class AppUrl {
  static final String hostName = "https://newsapi.org/v2";

  static final String get_top_headlines =
      "$hostName/everything?domains=wsj.com&apiKey=${KeyServices.baseUrl}";
}

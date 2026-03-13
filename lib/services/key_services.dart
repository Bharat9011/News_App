import 'package:flutter_dotenv/flutter_dotenv.dart';

class KeyServices {
  static String baseUrl = dotenv.env['NEWS_API_KEY'] ?? 'default_url';
}

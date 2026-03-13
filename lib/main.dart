import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:news_app/core/routes/oberver_routes/universal_route.dart';
import 'package:news_app/core/routes/route_list/routes_list.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: "assets/env_file/.env");
  await Hive.initFlutter();

  await Hive.openBox('login');
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorObservers: [observerRoute],
      debugShowCheckedModeBanner: false,
      initialRoute: "/",
      routes: pages,
    );
  }
}

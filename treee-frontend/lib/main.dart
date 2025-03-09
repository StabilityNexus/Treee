import 'package:flutter/material.dart';
import 'package:treee/pages/home.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  // WidgetsFlutterBinding.ensureInitialized();
  // await dotenv.load(fileName: ".env"); 

  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: Home(),
    );
  }
}

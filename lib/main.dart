import 'package:flutter/material.dart';
import 'pages/overview.dart';
import 'includes/app_bar.dart';
import 'includes/nav_bar.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LandmarkGO',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orangeAccent),
      ),
      home: homeOverview(),
    );
  }

  Scaffold homeOverview() {
    return Scaffold(
      appBar: TitleAppBar(title: 'Home'),
      bottomNavigationBar: NavBar(currentIndex: 0, onTap: (index) {}),
      body: Center(child: Text('Hello World!')),
    );
  }
}

import 'package:flutter/material.dart';
import 'pages/overview.dart';
import 'pages/records.dart';
import 'pages/new_entry.dart';
import 'includes/app_bar.dart';
import 'includes/nav_bar.dart';
import 'includes/globals.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    OverviewPage(),
    RecordsPage(),
    NewEntryPage(),
  ];

  final List<String> _titles = const [
    'Home',
    'All Landmarks',
    'Edit Landmarks',
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkTheme,
      builder: (context, isDark, _) {
        return MaterialApp(
          title: 'LandmarkGO',
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          home: Scaffold(
            appBar: TitleAppBar(
              title: _titles[_currentIndex],
              onToggleTheme: _toggleTheme,
            ),
            bottomNavigationBar: NavBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
            ),
            body: _pages[_currentIndex],
          ),
        );
      },
    );
  }

  void _toggleTheme() {
    isDarkTheme.value = !isDarkTheme.value;
  }
}

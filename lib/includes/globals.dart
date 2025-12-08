import 'package:flutter/material.dart';

/// Global theme toggle state.
final ValueNotifier<bool> isDarkTheme = ValueNotifier(false);

// Light palette
const Color _lightTitle = Color(0xFFE0C4A8);
const Color _lightSelected = Color(0xFF4A3A3A);
const Color _lightUnselected = Color(0xFF6B5A5A);
const Color _lightBackground = Color(0xFFF4E6D9);

// Dark palette
const Color _darkTitle = Color(0xFF2C1E19);
const Color _darkSelected = Color(0xFFFFD9A0);
const Color _darkUnselected = Color(0xFFB89C8A);
const Color _darkBackground = Color(0xFF3A2B24);

Color get colorTitle => isDarkTheme.value ? _darkTitle : _lightTitle;
Color get colorSelectedItem => isDarkTheme.value ? _darkSelected : _lightSelected;
Color get colorUnselectedItem => isDarkTheme.value ? _darkUnselected : _lightUnselected;
Color get colorBackground => isDarkTheme.value ? _darkBackground : _lightBackground;

ThemeData get lightTheme => ThemeData(
			colorScheme: ColorScheme.fromSeed(seedColor: _lightTitle),
			scaffoldBackgroundColor: _lightBackground,
			appBarTheme: const AppBarTheme(backgroundColor: _lightTitle),
			useMaterial3: true,
		);

ThemeData get darkTheme => ThemeData(
			colorScheme: ColorScheme.fromSeed(
				seedColor: _darkSelected,
				brightness: Brightness.dark,
			),
			scaffoldBackgroundColor: _darkBackground,
			appBarTheme: const AppBarTheme(backgroundColor: _darkTitle),
			bottomNavigationBarTheme: const BottomNavigationBarThemeData(
				backgroundColor: _darkTitle,
			),
			useMaterial3: true,
		);
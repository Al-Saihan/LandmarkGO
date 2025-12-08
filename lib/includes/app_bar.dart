import 'package:flutter/material.dart';
import 'globals.dart';

class TitleAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback onToggleTheme;

  const TitleAppBar({super.key, required this.title, required this.onToggleTheme});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: TextStyle(color: colorSelectedItem, fontWeight: FontWeight.bold),
      ),
      centerTitle: true,
      backgroundColor: colorTitle,
      iconTheme: IconThemeData(color: Colors.white),
      actions: [
        IconButton(
          icon: Icon(
            isDarkTheme.value ? Icons.dark_mode : Icons.wb_sunny,
            color: colorSelectedItem,
          ),
          onPressed: onToggleTheme,
        ),
      ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}

import 'package:flutter/material.dart';
import 'globals.dart';

class TitleAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const TitleAppBar({super.key, required this.title});

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
          icon: Icon(Icons.brightness_5, color: colorSelectedItem,),
          onPressed: () {
            // Add theme switching logic here
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}

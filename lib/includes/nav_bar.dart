import 'package:flutter/material.dart';
import 'globals.dart';

class NavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const NavBar({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      backgroundColor: colorTitle,
      elevation: 0,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: colorSelectedItem, 
      unselectedItemColor: colorUnselectedItem, 
      items: [
        BottomNavigationBarItem(
          label: "Overview",
          icon: _NavIcon(
            icon: Icons.location_on,
            isSelected: currentIndex == 0,
          ),
        ),
        BottomNavigationBarItem(
          label: "Records",
          icon: _NavIcon(icon: Icons.bookmark, isSelected: currentIndex == 1),
        ),
        BottomNavigationBarItem(
          label: "New Entry",
          icon: _NavIcon(icon: Icons.edit, isSelected: currentIndex == 2),
        ),
      ],
    );
  }
}

// ! Selected Item Background Color Workaround
class _NavIcon extends StatelessWidget {
  final IconData icon;
  final bool isSelected;

  const _NavIcon({required this.icon, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: isSelected
          ? BoxDecoration(
              color: colorBackground, 
              borderRadius: BorderRadius.circular(15),
            )
          : null,
      child: Icon(
        icon,
        size: 26,
        color: isSelected ? colorSelectedItem : colorUnselectedItem,
      ),
    );
  }
}

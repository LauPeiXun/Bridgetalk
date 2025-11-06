import 'package:flutter/material.dart';
import 'package:bridgetalk/application/controller/navigation/nav_bar_controller.dart';

class CustomNavBar extends StatelessWidget {
  final int currentIndex;
  final NavBarController navBarController = NavBarController();
  CustomNavBar({super.key, required this.currentIndex});

  Future<void> _handleNavigation(BuildContext context, int index) async {
    if (index == currentIndex) return;

    // Redirect to the target page
    final targetPage = await navBarController.getNavigationTarget(index);
    if (targetPage != null && context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => targetPage),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.only(),
        child: Container(
          padding: const EdgeInsets.only(
            left: 21,
            right: 21,
            bottom: 10,
            top: 8,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_navItems.length, (index) {
              final item = _navItems[index];
              final isSelected =
                  index == currentIndex &&
                  currentIndex >= 0 &&
                  currentIndex < _navItems.length;

              return GestureDetector(
                onTap: () => _handleNavigation(context, index),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? const Color(0xFFFFE8DB)
                                : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        item.icon,
                        color:
                            isSelected ? Colors.orange : Colors.grey.shade400,
                        size: 26,
                      ),
                    ),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 13,
                        color:
                            isSelected ? Colors.orange : Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;

  _NavItem(this.icon, this.label);
}

final List<_NavItem> _navItems = [
  _NavItem(Icons.chat_bubble_outline, 'Chat'),
  _NavItem(Icons.sports_esports, 'Games'),
  _NavItem(Icons.emoji_emotions, 'Mood'),
  _NavItem(Icons.whatshot, 'Spark'),
  _NavItem(Icons.person_outline, 'Profile'),
];

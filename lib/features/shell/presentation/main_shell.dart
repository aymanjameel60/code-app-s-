import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child, required this.location});
  final Widget child;
  final String location;
  int get _index { if (location.startsWith('/profile')) return 0; if (location.startsWith('/offers')) return 1; if (location.startsWith('/cart')) return 3; return 2; }
  @override Widget build(BuildContext context) => Scaffold(
    body: child,
    bottomNavigationBar: NavigationBar(
      selectedIndex: _index,
      onDestinationSelected: (index) { const routes = ['/profile', '/offers', '/', '/cart']; context.go(routes[index]); },
      destinations: const [
        NavigationDestination(icon: Icon(LucideIcons.userRound, size: 23), selectedIcon: Icon(LucideIcons.userRound, size: 23, color: Colors.black), label: 'حسابي'),
        NavigationDestination(icon: Icon(LucideIcons.badgePercent, size: 23), selectedIcon: Icon(LucideIcons.badgePercent, size: 23, color: Colors.black), label: 'العروض'),
        NavigationDestination(icon: Icon(LucideIcons.home, size: 23), selectedIcon: Icon(LucideIcons.home, size: 23, color: Colors.black), label: 'الرئيسية'),
        NavigationDestination(icon: Icon(LucideIcons.shoppingBag, size: 23), selectedIcon: Icon(LucideIcons.shoppingBag, size: 23, color: Colors.black), label: 'السلة'),
      ],
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/home/presentation/home_screen.dart';
import '../features/market/presentation/market_screen.dart';
import '../features/garage/presentation/garage_screen.dart';
import '../features/ai/presentation/ai_screen.dart';
import '../features/profile/presentation/profile_screen.dart';

final appRouter = GoRouter(
  routes: [
    ShellRoute(
      builder: (context, state, child) => RootScaffold(child: child),
      routes: [
        GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
        GoRoute(path: '/garage', builder: (_, __) => const GarageScreen()),
        GoRoute(path: '/market', builder: (_, __) => const MarketScreen()),
        GoRoute(path: '/ai', builder: (_, __) => const AiScreen()),
        GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
      ],
    ),
  ],
);

class RootScaffold extends StatelessWidget {
  const RootScaffold({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).uri.path;
    const tabs = ['/', '/garage', '/market', '/ai', '/profile'];
    final idx = tabs.indexOf(loc).clamp(0, 4);
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: (v) => context.go(tabs[v]),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Главная'),
          NavigationDestination(icon: Icon(Icons.directions_car), label: 'Гараж'),
          NavigationDestination(icon: Icon(Icons.store), label: 'Маркет'),
          NavigationDestination(icon: Icon(Icons.smart_toy), label: 'AI'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Профиль'),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:evverse_app/features/auth/screens/login_screen.dart';
import 'package:evverse_app/features/auth/screens/register_screen.dart';
import 'package:evverse_app/features/events/screens/home_screen.dart';


// Simple placeholders (replace with real screens in Phase 1+)
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$title screen',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => context.go('/events'),
              child: const Text('Go to Events'),
            ),
          ],
        ),
      ),
    );
  }
}

final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
    GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
    GoRoute(path: '/events', builder: (_, __) => const _PlaceholderScreen('Events List')),
    GoRoute(path: '/event/create', builder: (_, __) => const _PlaceholderScreen('Create Event')),
    GoRoute(
      path: '/event/:id',
      builder: (_, state) {
        final id = state.pathParameters['id'];
        return _PlaceholderScreen('Event $id');
      },
    ),
    GoRoute(path: '/profile', builder: (_, __) => const _PlaceholderScreen('Profile')),
  ],
);
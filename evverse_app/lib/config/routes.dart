import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:evverse_app/features/auth/screens/login_screen.dart';
import 'package:evverse_app/features/auth/screens/register_screen.dart';
import 'package:evverse_app/features/events/screens/home_screen.dart';
import 'package:evverse_app/features/events/screens/event_list_screen.dart';
import 'package:evverse_app/features/events/screens/create_event_screen.dart';
import 'package:evverse_app/features/profile/screens/profile_screen.dart';
import 'package:evverse_app/features/events/screens/event_detail_screen.dart';
import 'package:evverse_app/features/events/screens/edit_event_screen.dart';
import 'package:evverse_app/features/profile/screens/public_profile_screen.dart';
import 'package:evverse_app/features/admin/screens/admin_users_screen.dart';
import 'package:evverse_app/features/events/screens/my_events_screen.dart';
import 'package:evverse_app/features/events/screens/my_rsvps_screen.dart';

/// Simple placeholders (for routes not yet implemented)
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          '$title screen',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
}

final GoRouter appRouter = GoRouter(
  // Let the guard decide where to send the user based on auth state.
  initialLocation: '/home',

  // Re-run redirect when auth state changes (login/logout).
  refreshListenable:
      GoRouterRefreshStream(FirebaseAuth.instance.authStateChanges()),

  redirect: (context, state) {
    final bool loggedIn = FirebaseAuth.instance.currentUser != null;
    // In newer go_router versions, use uri.path instead of subloc
    final String currentLoc = state.uri.path; // e.g. '/login', '/home', '/events'

    final bool goingToAuth =
        currentLoc == '/login' || currentLoc == '/register';

    // Not logged in and trying to access anything except login/register → go to /login.
    if (!loggedIn && !goingToAuth) {
      return '/login';
    }

    // Logged in and trying to go to login/register → send to /home.
    if (loggedIn && goingToAuth) {
      return '/home';
    }

    // No redirect.
    return null;
  },

  routes: [
    GoRoute(
      path: '/login',
      builder: (_, __) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (_, __) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (_, __) => const HomeScreen(),
    ),
    GoRoute(
      path: '/events',
      builder: (_, __) => const EventListScreen(),
    ),
    GoRoute(
      path: '/event/create',
      builder: (_, __) => const CreateEventScreen(),
    ),
   GoRoute(
  path: '/event/:id',
  builder: (_, state) {
    final id = state.pathParameters['id']!;
    return EventDetailScreen(eventId: id);
  },
),
GoRoute(
  path: '/event/:id/edit',
  builder: (_, state) {
    final id = state.pathParameters['id']!;
    return EditEventScreen(eventId: id);
  },
),
    GoRoute(
      path: '/profile',
      builder: (_, __) => const ProfileScreen(),
    ),

    GoRoute(
  path: '/user/:id',
  builder: (_, state) {
    final id = state.pathParameters['id']!;
    return PublicProfileScreen(userId: id);
  },
),
GoRoute(
  path: '/admin/users',
  builder: (_, __) => const AdminUsersScreen(),
),
GoRoute(
  path: '/my-events',
  builder: (_, __) => const MyEventsScreen(),
),
GoRoute(
  path: '/my-rsvps',
  builder: (_, __) => const MyRsvpsScreen(),
),
  ],
  
);

/// Simple helper to turn a Stream into a Listenable for GoRouter.refreshListenable
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Same admin UID(s) as in rules and AdminUsersScreen
const Set<String> kAdminUids = {
  'NJWRiLVrTibqfOc8vbSlst3dlhL2',
  // 'ANOTHER_ADMIN_UID_HERE',
};

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    context.go('/login');
  }

  void _goToProfile(BuildContext context) {
    context.push('/profile');
  }

  void _goToEvents(BuildContext context) {
    context.push('/events');
  }

  void _goToMyEvents(BuildContext context) {
    context.push('/my-events');
  }

  void _goToMyRsvps(BuildContext context) {
    context.push('/my-rsvps');
  }

  bool _isAdmin(User? user) =>
      user != null && kAdminUids.contains(user.uid);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isAdmin = _isAdmin(user);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () => _signOut(context),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  user != null
                      ? 'Logged in as ${user.email ?? user.uid}'
                      : 'Not logged in',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Profile button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _goToProfile(context),
                    icon: const Icon(Icons.person),
                    label: const Text('View profile'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // All events
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _goToEvents(context),
                    icon: const Icon(Icons.event),
                    label: const Text('View all events'),
                  ),
                ),
                const SizedBox(height: 12),

                if (user != null) ...[
                  // My events
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _goToMyEvents(context),
                      icon: const Icon(Icons.event_note),
                      label: const Text('My events'),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // My RSVPs
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _goToMyRsvps(context),
                      icon: const Icon(Icons.calendar_today),
                      label: const Text('My RSVPs'),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Create event button only for organizers
                if (user != null)
                  _CreateEventButtonForOrganizer(userId: user.uid),

                const SizedBox(height: 24),

                // Admin section
                if (isAdmin)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/admin/users'),
                      icon: const Icon(Icons.admin_panel_settings),
                      label: const Text('Admin: Manage users'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CreateEventButtonForOrganizer extends StatelessWidget {
  final String userId;

  const _CreateEventButtonForOrganizer({required this.userId});

  @override
  Widget build(BuildContext context) {
    final userDoc =
        FirebaseFirestore.instance.collection('users').doc(userId);

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: userDoc.get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data?.data();
        final role = data?['role'] as String?;
        final isOrganizer = role == 'organizer';

        if (!isOrganizer) {
          return const SizedBox.shrink();
        }

        return SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => context.push('/event/create'),
            icon: const Icon(Icons.add),
            label: const Text('Create event'),
          ),
        );
      },
    );
  }
}
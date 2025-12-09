import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:evverse_app/features/events/widgets/event_card.dart';

// Same admin UID(s) as in your Firestore rules (isAdmin() function)
const Set<String> kAdminUids = {
  'NJWRiLVrTibqfOc8vbSlst3dlhL2', // <-- replace with your actual admin UID(s)
  // 'ANOTHER_ADMIN_UID_HERE',
};

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Event categories used for interest mapping
  final List<String> _categories = const [
    'general',
    'party',
    'sports',
    'lectures',
    'spiritual',
    'business',
    'other',
  ];

  // Categories recommended based on user interests
  Set<String> _preferredCategories = {};

  bool _isOrganizer = false;
  bool _isLoadingUserPrefs = true;

  @override
  void initState() {
    super.initState();
    _loadUserPrefs();
  }

  bool _isAdmin(User? user) =>
      user != null && kAdminUids.contains(user.uid);

  Future<void> _loadUserPrefs() async {
    final user = _auth.currentUser;
    if (user == null) {
      setState(() {
        _isLoadingUserPrefs = false;
      });
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = doc.data();
      if (data == null) {
        setState(() {
          _isLoadingUserPrefs = false;
        });
        return;
      }

      // Interests -> preferred categories
      final interestsText = (data['interests'] as String?) ?? '';
      final interests = interestsText
          .split(',')
          .map((e) => e.trim().toLowerCase())
          .where((e) => e.isNotEmpty)
          .toList();

      final preferred = <String>{};

      for (final interest in interests) {
        for (final cat in _categories) {
          if (interest.contains(cat)) {
            preferred.add(cat);
          }
        }
      }

      // Organizer role
      final role = data['role'] as String?;
      final isOrganizer = role == 'organizer';

      setState(() {
        _preferredCategories = preferred;
        _isOrganizer = isOrganizer;
        _isLoadingUserPrefs = false;
      });
    } catch (e, st) {
      debugPrint('Error loading user prefs: $e');
      debugPrint('Stack trace:\n$st');
      setState(() {
        _isLoadingUserPrefs = false;
      });
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _eventStream() {
    return FirebaseFirestore.instance
        .collection('events')
        .orderBy('date')
        .snapshots();
  }

  Future<void> _signOut(BuildContext context) async {
    await _auth.signOut();
    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
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
      drawer: _buildDrawer(context, user, isAdmin),
      body: user == null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('You need to be logged in to see events.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Go to login'),
                  ),
                ],
              ),
            )
          : _buildRecommendedEventsBody(context),
    );
  }

  Widget _buildDrawer(BuildContext context, User? user, bool isAdmin) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            if (user != null) ...[
              ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(user.email ?? user.uid),
                subtitle: const Text('Logged in'),
              ),
              const Divider(),
            ],
            Expanded(
              child: ListView(
                children: [
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text('View profile'),
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/profile');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.event),
                    title: const Text('View all events'),
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/events');
                    },
                  ),
                  if (user != null) ...[
                    ListTile(
                      leading: const Icon(Icons.event_note),
                      title: const Text('My events'),
                      onTap: () {
                        Navigator.of(context).pop();
                        context.push('/my-events');
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('My RSVPs'),
                      onTap: () {
                        Navigator.of(context).pop();
                        context.push('/my-rsvps');
                      },
                    ),
                    if (_isOrganizer)
                      ListTile(
                        leading: const Icon(Icons.add),
                        title: const Text('Create event'),
                        onTap: () {
                          Navigator.of(context).pop();
                          context.push('/event/create');
                        },
                      ),
                  ],
                  if (isAdmin)
                    ListTile(
                      leading: const Icon(Icons.admin_panel_settings),
                      title: const Text('Admin: Manage users'),
                      onTap: () {
                        Navigator.of(context).pop();
                        context.push('/admin/users');
                      },
                    ),
                ],
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Log out'),
              onTap: () => _signOut(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendedEventsBody(BuildContext context) {
    if (_isLoadingUserPrefs) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _eventStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading events: ${snapshot.error}'),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
            child: Text('No events yet. Be the first to create one!'),
          );
        }

        final now = DateTime.now();

        // Upcoming events only
        final upcomingDocs = docs.where((doc) {
          final data = doc.data();
          final ts = data['date'] as Timestamp?;
          final dt = ts?.toDate();
          return dt == null || dt.isAfter(now);
        }).toList();

        if (upcomingDocs.isEmpty) {
          return const Center(
            child: Text('No upcoming events right now.'),
          );
        }

        // Recommended events based on preferred categories
        List<QueryDocumentSnapshot<Map<String, dynamic>>> recommendedDocs;
        if (_preferredCategories.isEmpty) {
          // No interests or no match → fall back to all upcoming
          recommendedDocs = upcomingDocs;
        } else {
          recommendedDocs = upcomingDocs.where((doc) {
            final data = doc.data();
            final cat =
                (data['category'] as String?) ?? 'general';
            return _preferredCategories.contains(cat);
          }).toList();

          if (recommendedDocs.isEmpty) {
            // No category match → fall back to upcoming
            recommendedDocs = upcomingDocs;
          }
        }

        return ListView(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                _preferredCategories.isEmpty
                    ? 'Upcoming events'
                    : 'Recommended events for you',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ...recommendedDocs.map((doc) {
              final data = doc.data();
              final id = doc.id;
              final title =
                  (data['title'] as String?) ?? 'Untitled event';
              final description =
                  (data['description'] as String?) ?? '';
              final location =
                  (data['location'] as String?) ?? '';
              final ts = data['date'] as Timestamp?;
              final date = ts?.toDate();
              final category =
                  (data['category'] as String?) ?? 'general';

              final isRecommended =
                  _preferredCategories.contains(category);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isRecommended && _preferredCategories.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 16.0, bottom: 4.0),
                      child: Text(
                        'Recommended for you',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.green),
                      ),
                    ),
                  EventCard(
                    id: id,
                    title: title,
                    description: description,
                    date: date,
                    location: location,
                    category: category,
                  ),
                ],
              );
            }),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}
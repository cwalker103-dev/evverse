import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:evverse_app/features/events/widgets/event_card.dart';

class EventListScreen extends StatefulWidget {
  const EventListScreen({super.key});

  @override
  State<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  final List<String> _categories = const [
    'all',
    'general',
    'party',
    'sports',
    'lectures',
    'spiritual',
    'business',
    'other',
  ];
  String _selectedCategory = 'all';

  // Categories recommended based on user interests
  Set<String> _preferredCategories = {};

  // Search
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadPreferredCategories();
    _searchCtrl.addListener(() {
      setState(() {
        _searchQuery = _searchCtrl.text.trim();
      });
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPreferredCategories() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = doc.data();
      if (data == null) return;

      final interestsText = (data['interests'] as String?) ?? '';
      final interests = interestsText
          .split(',')
          .map((e) => e.trim().toLowerCase())
          .where((e) => e.isNotEmpty)
          .toList();

      final preferred = <String>{};

      // Simple mapping: if interest text contains the category word, prefer that category
      for (final interest in interests) {
        for (final cat in _categories.where((c) => c != 'all')) {
          if (interest.contains(cat)) {
            preferred.add(cat);
          }
        }
      }

      setState(() {
        _preferredCategories = preferred;
      });
    } catch (e, st) {
      debugPrint('Error loading preferred categories: $e');
      debugPrint('Stack trace:\n$st');
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _eventStream() {
    return FirebaseFirestore.instance
        .collection('events')
        .orderBy('date')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Events'),
      ),
      body: user == null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('You need to be logged in to view events.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Go to login'),
                  ),
                ],
              ),
            )
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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

                // 1) Category filter
                var filteredDocs = _selectedCategory == 'all'
                    ? docs
                    : docs.where((doc) {
                        final data = doc.data();
                        final cat =
                            (data['category'] as String?) ?? 'general';
                        return cat == _selectedCategory;
                      }).toList();

                // 2) Search filter (title / description / location), case-insensitive
                if (_searchQuery.isNotEmpty) {
                  final q = _searchQuery.toLowerCase();
                  filteredDocs = filteredDocs.where((doc) {
                    final data = doc.data();
                    final t =
                        (data['title'] as String? ?? '').toLowerCase();
                    final desc =
                        (data['description'] as String? ?? '').toLowerCase();
                    final loc =
                        (data['location'] as String? ?? '').toLowerCase();
                    return t.contains(q) ||
                        desc.contains(q) ||
                        loc.contains(q);
                  }).toList();
                }

                if (filteredDocs.isEmpty) {
                  return Column(
                    children: [
                      _buildSearchField(),
                      const SizedBox(height: 8),
                      _buildCategoryFilterChips(),
                      const SizedBox(height: 16),
                      const Expanded(
                        child: Center(
                          child: Text('No events match your filters.'),
                        ),
                      ),
                    ],
                  );
                }

                final now = DateTime.now();

                // 3) Split filtered docs into upcoming and past
                final upcomingDocs =
                    <QueryDocumentSnapshot<Map<String, dynamic>>>[];
                final pastDocs =
                    <QueryDocumentSnapshot<Map<String, dynamic>>>[];

                for (final doc in filteredDocs) {
                  final data = doc.data();
                  final ts = data['date'] as Timestamp?;
                  final dt = ts?.toDate();

                  if (dt == null || dt.isAfter(now)) {
                    upcomingDocs.add(doc);
                  } else {
                    pastDocs.add(doc);
                  }
                }

                return Column(
                  children: [
                    _buildSearchField(),
                    const SizedBox(height: 8),
                    _buildCategoryFilterChips(),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView(
                        children: [
                          if (upcomingDocs.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: Text(
                                'Upcoming events',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium,
                              ),
                            ),
                            ...upcomingDocs.map((doc) {
                              final data = doc.data();
                              final id = doc.id;
                              final title =
                                  (data['title'] as String?) ??
                                      'Untitled event';
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
                                  if (isRecommended)
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
                          ],
                          if (pastDocs.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: Text(
                                'Past events',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium,
                              ),
                            ),
                            ...pastDocs.map((doc) {
                              final data = doc.data();
                              final id = doc.id;
                              final title =
                                  (data['title'] as String?) ??
                                      'Untitled event';
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
                                  if (isRecommended)
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
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
      floatingActionButton: user == null
          ? null
          : _CreateEventFabForOrganizer(userId: user.uid),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _searchCtrl,
        decoration: InputDecoration(
          labelText: 'Search events',
          hintText: 'Search by title, description, or location',
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchCtrl.clear();
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildCategoryFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: _categories.map((cat) {
          final isSelected = _selectedCategory == cat;
          final label = cat[0].toUpperCase() + cat.substring(1);
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = selected ? cat : 'all';
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CreateEventFabForOrganizer extends StatelessWidget {
  final String userId;

  const _CreateEventFabForOrganizer({required this.userId});

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

        return FloatingActionButton(
          onPressed: () => context.push('/event/create'),
          child: const Icon(Icons.add),
        );
      },
    );
  }
}
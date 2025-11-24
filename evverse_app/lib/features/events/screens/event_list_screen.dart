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

                // Apply category filtering in memory
                final filteredDocs = _selectedCategory == 'all'
                    ? docs
                    : docs.where((doc) {
                        final data = doc.data();
                        final cat =
                            (data['category'] as String?) ?? 'general';
                        return cat == _selectedCategory;
                      }).toList();

                if (filteredDocs.isEmpty) {
                  return Column(
                    children: [
                      _buildCategoryFilterChips(),
                      const SizedBox(height: 16),
                      const Expanded(
                        child: Center(
                          child: Text('No events match this category.'),
                        ),
                      ),
                    ],
                  );
                }

                return Column(
                  children: [
                    _buildCategoryFilterChips(),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredDocs.length,
                        itemBuilder: (context, index) {
                          final doc = filteredDocs[index];
                          final data = doc.data();
                          final id = doc.id;
                          final title =
                              (data['title'] as String?) ?? 'Untitled event';
                          final description =
                              (data['description'] as String?) ?? '';
                          final location =
                              (data['location'] as String?) ?? '';
                          final timestamp = data['date'] as Timestamp?;
                          final date = timestamp?.toDate();
                          final category =
                              (data['category'] as String?) ?? 'general';

                          return EventCard(
                            id: id,
                            title: title,
                            description: description,
                            date: date,
                            location: location,
                            category: category,
                          );
                        },
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
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:evverse_app/features/events/widgets/event_card.dart';

class MyEventsScreen extends StatefulWidget {
  const MyEventsScreen({super.key});

  @override
  State<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends State<MyEventsScreen> {
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

  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
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

  Stream<QuerySnapshot<Map<String, dynamic>>> _myEventsStream(String uid) {
    return FirebaseFirestore.instance
        .collection('events')
        .where('createdBy', isEqualTo: uid)
        .orderBy('date')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My events')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('You need to be logged in to see your events.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/login'),
                child: const Text('Go to login'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My events')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _myEventsStream(user.uid),
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
              child: Text('You haven’t created any events yet.'),
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
              return t.contains(q) || desc.contains(q) || loc.contains(q);
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
                    child:
                        Text('No events match your filters in My events.'),
                  ),
                ),
              ],
            );
          }

          return Column(
            children: [
              _buildSearchField(),
              const SizedBox(height: 8),
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
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _searchCtrl,
        decoration: InputDecoration(
          labelText: 'Search my events',
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
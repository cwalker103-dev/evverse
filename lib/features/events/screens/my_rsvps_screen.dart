import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MyRsvpsScreen extends StatefulWidget {
  const MyRsvpsScreen({super.key});

  @override
  State<MyRsvpsScreen> createState() => _MyRsvpsScreenState();
}

class _MyRsvpsScreenState extends State<MyRsvpsScreen> {
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

  Stream<QuerySnapshot<Map<String, dynamic>>> _myRsvpsStream(String uid) {
    // Read from the user's own RSVPs subcollection
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('rsvps')
        .orderBy('updatedAt', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My RSVPs')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('You need to be logged in to see your RSVPs.'),
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
      appBar: AppBar(title: const Text('My RSVPs')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _myRsvpsStream(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading RSVPs: ${snapshot.error}'),
            );
          }

          final rsvpDocs = snapshot.data?.docs ?? [];
          if (rsvpDocs.isEmpty) {
            return const Center(
              child: Text('You haven’t RSVPed to any events yet.'),
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
                  itemCount: rsvpDocs.length,
                  itemBuilder: (context, index) {
                    final rsvpDoc = rsvpDocs[index];
                    final rsvpData = rsvpDoc.data();
                    final status = rsvpData['status'] as String? ?? '';
                    final eventId = rsvpData['eventId'] as String?;
                    if (eventId == null) {
                      return const ListTile(
                        title: Text('Invalid RSVP entry'),
                      );
                    }

                    final statusLabel =
                        status == 'going' ? 'Going' :
                        status == 'interested' ? 'Interested' :
                        'RSVP’d';

                    // Get the event document from /events/{eventId}
                    final eventRef = FirebaseFirestore.instance
                        .collection('events')
                        .doc(eventId);

                    return FutureBuilder<
                        DocumentSnapshot<Map<String, dynamic>>>(
                      future: eventRef.get(),
                      builder: (context, eventSnap) {
                        if (eventSnap.connectionState ==
                            ConnectionState.waiting) {
                          return const ListTile(
                            title: Text('Loading event...'),
                          );
                        }

                        if (eventSnap.hasError) {
                          return ListTile(
                            title: const Text('Error loading event'),
                            subtitle: Text('${eventSnap.error}'),
                          );
                        }

                        final eventDoc = eventSnap.data;
                        if (eventDoc == null || !eventDoc.exists) {
                          return const ListTile(
                            title: Text('Event no longer exists'),
                          );
                        }

                        final data = eventDoc.data()!;
                        final title =
                            (data['title'] as String?) ??
                                'Untitled event';
                        final description =
                            (data['description'] as String?) ?? '';
                        final location =
                            (data['location'] as String?) ?? '';
                        final ts = data['date'] as Timestamp?;
                        final date = ts?.toDate();
                        final dateStr = date != null
                            ? '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
                              '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}'
                            : 'Date not set';
                        final category =
                            (data['category'] as String?) ?? 'general';

                        // Apply filters (category + search) at card level
                        final matchesCategory =
                            _selectedCategory == 'all' ||
                            category == _selectedCategory;

                        final q = _searchQuery.toLowerCase();
                        final matchesSearch = _searchQuery.isEmpty ||
                            title.toLowerCase().contains(q) ||
                            description.toLowerCase().contains(q) ||
                            location.toLowerCase().contains(q);

                        if (!matchesCategory || !matchesSearch) {
                          return const SizedBox.shrink();
                        }

                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: ListTile(
                            title: Text(title),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(statusLabel),
                                Text(dateStr),
                                if (location.isNotEmpty) Text(location),
                                if (description.isNotEmpty)
                                  Text(
                                    description,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                            onTap: () => context.push('/event/$eventId'),
                          ),
                        );
                      },
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
          labelText: 'Search my RSVPs',
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
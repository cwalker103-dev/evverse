import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:evverse_app/features/events/widgets/event_card.dart';

class MyEventsScreen extends StatelessWidget {
  const MyEventsScreen({super.key});

  Stream<QuerySnapshot<Map<String, dynamic>>> _myEventsStream(String uid) {
    // Events created by the current user, ordered by date
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

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
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
          );
        },
      ),
    );
  }
}
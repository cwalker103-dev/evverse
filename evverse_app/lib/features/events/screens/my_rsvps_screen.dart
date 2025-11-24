import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MyRsvpsScreen extends StatelessWidget {
  const MyRsvpsScreen({super.key});

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

          return ListView.builder(
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

              return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                future: eventRef.get(),
                builder: (context, eventSnap) {
                  if (eventSnap.connectionState == ConnectionState.waiting) {
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
                      (data['title'] as String?) ?? 'Untitled event';
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

                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          );
        },
      ),
    );
  }
}
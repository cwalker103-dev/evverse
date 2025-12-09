import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class EventDetailScreen extends StatefulWidget {
  final String eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  String _formatDate(Timestamp? ts) {
    if (ts == null) return 'Date not set';
    final d = ts.toDate().toLocal();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _deleteEvent() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete event'),
        content: const Text('Are you sure you want to delete this event?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.eventId)
          .delete();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event deleted')),
      );
      context.pop(); // back to list
    } catch (e, st) {
      if (!mounted) return;
      debugPrint('Error deleting event: $e');
      debugPrint('Stack trace:\n$st');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete event: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final docRef =
        FirebaseFirestore.instance.collection('events').doc(widget.eventId);
    final currentUser = FirebaseAuth.instance.currentUser;

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: docRef.get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Event details'),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Event details'),
            ),
            body: Center(
              child: Text('Error loading event: ${snapshot.error}'),
            ),
          );
        }

        final doc = snapshot.data;
        if (doc == null || !doc.exists) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Event details'),
            ),
            body: const Center(
              child: Text('Event not found'),
            ),
          );
        }

        final data = doc.data()!;
        final title = (data['title'] as String?) ?? 'Untitled event';
        final description = (data['description'] as String?) ?? '';
        final location = (data['location'] as String?) ?? '';
        final dateTs = data['date'] as Timestamp?;
        final createdAtTs = data['createdAt'] as Timestamp?;
        final createdBy = data['createdBy'] as String?;
        final createdByName = data['createdByName'] as String?;

        final bool isOwner =
            currentUser != null && createdBy != null && currentUser.uid == createdBy;

        final String creatorDisplay =
            isOwner ? 'You' : (createdByName ?? 'Organizer');

        return Scaffold(
          appBar: AppBar(
            title: Text(title),
            actions: [
              if (isOwner)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      context.push('/event/${widget.eventId}/edit');
                    } else if (value == 'delete') {
                      _deleteEvent();
                    }
                  },
                  itemBuilder: (ctx) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit event'),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete event'),
                    ),
                  ],
                ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                Text(
                  _formatDate(dateTs),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (location.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    location,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
                const SizedBox(height: 16),
                if (description.isNotEmpty)
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  )
                else
                  const Text('No description provided.'),
                const SizedBox(height: 24),

                // RSVP buttons for current user (writes both event and user rsvps)
                _RsvpSection(eventId: widget.eventId),

                const SizedBox(height: 16),

                // Summary of RSVPs (counts from event-side attendees)
                _AttendeeSummary(eventId: widget.eventId),

                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Created by: $creatorDisplay',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    if (!isOwner && createdBy != null)
                      TextButton(
                        onPressed: () => context.push('/user/$createdBy'),
                        child: const Text('View organizer'),
                      ),
                  ],
                ),
                if (createdAtTs != null)
                  Text(
                    'Created at: ${_formatDate(createdAtTs)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RsvpSection extends StatelessWidget {
  final String eventId;

  const _RsvpSection({required this.eventId});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RSVP',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Log in to RSVP for this event.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => context.go('/login'),
            child: const Text('Go to login'),
          ),
        ],
      );
    }

    final eventRsvpRef = FirebaseFirestore.instance
        .collection('events')
        .doc(eventId)
        .collection('attendees')
        .doc(user.uid);

    final userRsvpRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('rsvps')
        .doc(eventId);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: eventRsvpRef.snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final currentStatus = data != null ? data['status'] as String? : null;

        Future<void> setStatus(String status) async {
          try {
            // Event-side RSVP
            await eventRsvpRef.set({
              'userId': user.uid,
              'displayName': user.displayName ?? user.email ?? 'User',
              'status': status,
              'updatedAt': FieldValue.serverTimestamp(),
            });

            // User-side RSVP mirror
            await userRsvpRef.set({
              'eventId': eventId,
              'status': status,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          } catch (e, st) {
            debugPrint('Error setting RSVP: $e');
            debugPrint('Stack trace:\n$st');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to update RSVP: $e')),
            );
          }
        }

        Future<void> clearStatus() async {
          try {
            await eventRsvpRef.delete();
            await userRsvpRef.delete();
          } catch (e, st) {
            debugPrint('Error clearing RSVP: $e');
            debugPrint('Stack trace:\n$st');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to clear RSVP: $e')),
            );
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your RSVP',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Going'),
                  selected: currentStatus == 'going',
                  onSelected: (selected) {
                    if (selected) {
                      setStatus('going');
                    } else {
                      clearStatus();
                    }
                  },
                ),
                ChoiceChip(
                  label: const Text('Interested'),
                  selected: currentStatus == 'interested',
                  onSelected: (selected) {
                    if (selected) {
                      setStatus('interested');
                    } else {
                      clearStatus();
                    }
                  },
                ),
                if (currentStatus != null)
                  TextButton(
                    onPressed: clearStatus,
                    child: const Text('Clear RSVP'),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _AttendeeSummary extends StatelessWidget {
  final String eventId;

  const _AttendeeSummary({required this.eventId});

  @override
  Widget build(BuildContext context) {
    final collRef = FirebaseFirestore.instance
        .collection('events')
        .doc(eventId)
        .collection('attendees');

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: collRef.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Text(
            'No RSVPs yet.',
            style: Theme.of(context).textTheme.bodySmall,
          );
        }

        int going = 0;
        int interested = 0;
        for (final doc in docs) {
          final status = doc.data()['status'] as String?;
          if (status == 'going') going++;
          if (status == 'interested') interested++;
        }

        final parts = <String>[];
        if (going > 0) parts.add('$going going');
        if (interested > 0) parts.add('$interested interested');

        final summary = parts.join(' • ');

        return Text(
          summary,
          style: Theme.of(context).textTheme.bodySmall,
        );
      },
    );
  }
}
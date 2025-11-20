import 'package:flutter/material.dart';

class EventDetailScreen extends StatelessWidget {
  final String eventId;
  const EventDetailScreen({required this.eventId, super.key});

  @override
  Widget build(BuildContext context) {
    // Placeholder details
    return Scaffold(
      appBar: AppBar(title: Text('Event $eventId')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Event $eventId', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text('This is a placeholder for event details.'),
        ]),
      ),
    );
  }
}

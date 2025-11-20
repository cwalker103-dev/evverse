import 'package:flutter/material.dart';
import 'package:evverse_app/features/events/widgets/event_card.dart';

class EventListScreen extends StatelessWidget {
  const EventListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final events = List.generate(
      6,
      (i) => {
        'id': '$i',
        'title': 'Event #$i',
        'description': 'Sample event $i',
      },
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Events')),
      body: ListView.builder(
        itemCount: events.length,
        itemBuilder: (context, index) {
          final e = events[index];
          return EventCard(
            id: e['id']!,
            title: e['title']!,
            subtitle: e['description']!,
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        // better to use go_router as well:
        // onPressed: () => context.go('/event/create'),
        onPressed: () => Navigator.of(context).pushNamed('/event/create'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
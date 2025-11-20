import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // for context.go

class EventCard extends StatelessWidget {
  final String id;
  final String title;
  final String subtitle;

  const EventCard({
    super.key,
    required this.id,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        onTap: () {
          // Navigate to the event details route defined in routes.dart: /event/:id
          context.go('/event/$id');
        },
      ),
    );
  }
}
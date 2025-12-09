import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class EventCard extends StatelessWidget {
  final String id;
  final String title;
  final String? description;
  final DateTime? date;
  final String? location;
  final String? category;

  const EventCard({
    super.key,
    required this.id,
    required this.title,
    this.description,
    this.date,
    this.location,
    this.category,
  });

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'Date not set';
    final d = dt.toLocal();
    final y = d.year.toString();
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    final h = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '$y-$m-$day • $h:$min';
  }

  @override
  Widget build(BuildContext context) {
    final subtitleLines = <Widget>[];

    if (description != null && description!.isNotEmpty) {
      subtitleLines.add(
        Text(
          description!,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    subtitleLines.add(
      Text(
        _formatDate(date),
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );

    if (location != null && location!.isNotEmpty) {
      subtitleLines.add(
        Text(
          location!,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Row(
          children: [
            Expanded(child: Text(title)),
            if (category != null && category!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Chip(
                  label: Text(
                    category![0].toUpperCase() + category!.substring(1),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: subtitleLines,
        ),
        onTap: () => context.push('/event/$id'),
      ),
    );
  }
}
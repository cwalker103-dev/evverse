import 'package:flutter/material.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});
  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Event')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          TextField(controller: _title, decoration: const InputDecoration(labelText: 'Title')),
          TextField(controller: _desc, decoration: const InputDecoration(labelText: 'Description')),
          const SizedBox(height: 12),
          if (_saving) const CircularProgressIndicator(),
          if (!_saving)
            ElevatedButton(
              onPressed: () async {
                setState(() { _saving = true; });
                // TODO: call service to create
                await Future.delayed(const Duration(milliseconds: 700));
                setState(() { _saving = false; });
                if (mounted) Navigator.of(context).pop();
              },
              child: const Text('Create'),
            ),
        ]),
      ),
    );
  }
}

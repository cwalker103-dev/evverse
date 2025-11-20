import 'package:flutter/material.dart';

class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const ErrorView({required this.message, this.onRetry, super.key});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Error: $message', style: const TextStyle(color: Colors.red)),
        const SizedBox(height: 8),
        if (onRetry != null)
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
      ]),
    );
  }
}

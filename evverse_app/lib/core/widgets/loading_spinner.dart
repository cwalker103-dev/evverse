import 'package:flutter/material.dart';

class LoadingSpinner extends StatelessWidget {
  final String? message;
  const LoadingSpinner({this.message, super.key});
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(),
        if (message != null) ...[
          const SizedBox(height: 8),
          Text(message!),
        ],
      ],
    );
  }
}

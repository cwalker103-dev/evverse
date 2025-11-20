import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    // placeholder: will be replaced with profile_provider later
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: const Center(child: Text('User profile placeholder')),
    );
  }
}

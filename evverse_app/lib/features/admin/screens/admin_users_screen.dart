import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({super.key});

  // Same admin UID(s) as in Firestore rules
  static const Set<String> adminUids = {
    'NJWRiLVrTibqfOc8vbSlst3dlhL2',
    // 'ANOTHER_ADMIN_UID_HERE',
  };

  bool _isAdmin(User? user) =>
      user != null && adminUids.contains(user.uid);

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (!_isAdmin(currentUser)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin: Users')),
        body: const Center(
          child: Text('Access denied. You are not an admin.'),
        ),
      );
    }

    final usersRef = FirebaseFirestore.instance.collection('users');

    return Scaffold(
      appBar: AppBar(title: const Text('Admin: Users')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: usersRef.orderBy('email').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading users: ${snapshot.error}'),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(child: Text('No users found.'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final doc = docs[i];
              final data = doc.data();
              final uid = doc.id;
              final email = data['email'] as String? ?? '';
              final displayName = data['displayName'] as String? ?? '';
              final role = data['role'] as String? ?? 'user';

              final isSelf = currentUser != null && currentUser.uid == uid;

              return ListTile(
                title: Text(
                  displayName.isNotEmpty ? displayName : email,
                ),
                subtitle: Text('UID: $uid\nRole: $role'),
                isThreeLine: true,
                trailing: DropdownButton<String>(
                  value: role,
                  items: const [
                    DropdownMenuItem(
                      value: 'user',
                      child: Text('User'),
                    ),
                    DropdownMenuItem(
                      value: 'organizer',
                      child: Text('Organizer'),
                    ),
                  ],
                  onChanged: isSelf
                      ? null // prevent accidentally demoting yourself
                      : (value) async {
                          if (value == null) return;
                          try {
                            await usersRef.doc(uid).update({'role': value});
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text('Failed to update role: $e')),
                            );
                          }
                        },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
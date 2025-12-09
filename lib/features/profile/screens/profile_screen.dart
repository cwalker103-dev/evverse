import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _displayNameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _interestsCtrl = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingAvatar = false;
  bool _hasChanges = false;

  String? _photoUrl;

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _displayNameCtrl.dispose();
    _bioCtrl.dispose();
    _phoneCtrl.dispose();
    _locationCtrl.dispose();
    _interestsCtrl.dispose();
    super.dispose();
  }

  void _markDirty() {
    setState(() {
      _hasChanges = true;
    });
  }

  List<String> _parseInterests(String text) {
    return text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Future<void> _loadProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      context.go('/login');
      return;
    }

    try {
      final docRef = _firestore.collection('users').doc(user.uid);
      final snapshot = await docRef.get();

      String displayName = user.displayName ?? '';
      String bio = '';
      String phone = '';
      String location = '';
      String interests = '';
      String? photoUrl = user.photoURL;

      if (snapshot.exists) {
        final data = snapshot.data();
        if (data != null) {
          displayName = (data['displayName'] as String?) ?? displayName;
          bio = (data['bio'] as String?) ?? '';
          phone = (data['phone'] as String?) ?? '';
          location = (data['location'] as String?) ?? '';
          interests = (data['interests'] as String?) ?? '';
          photoUrl = (data['photoUrl'] as String?) ?? photoUrl;
        }
      } else {
        await docRef.set({
          'email': user.email,
          'displayName': displayName.isEmpty ? null : displayName,
          'bio': null,
          'phone': null,
          'location': null,
          'interests': null,
          'photoUrl': user.photoURL,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      if (!mounted) return;
      setState(() {
        _displayNameCtrl.text = displayName;
        _bioCtrl.text = bio;
        _phoneCtrl.text = phone;
        _locationCtrl.text = location;
        _interestsCtrl.text = interests;
        _photoUrl = photoUrl;
        _isLoading = false;
        _hasChanges = false;
      });
    } catch (e, st) {
      if (!mounted) return;
      debugPrint('Error loading profile: $e');
      debugPrint('Stack trace:\n$st');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load profile')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      context.go('/login');
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final displayName = _displayNameCtrl.text.trim();
    final bio = _bioCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final location = _locationCtrl.text.trim();
    final interests = _interestsCtrl.text.trim();

    setState(() {
      _isSaving = true;
    });

    try {
      if (displayName.isNotEmpty || _photoUrl != null) {
        await user.updateDisplayName(
          displayName.isEmpty ? null : displayName,
        );
        if (_photoUrl != null) {
          await user.updatePhotoURL(_photoUrl);
        }
      }

      await _firestore.collection('users').doc(user.uid).set(
        {
          'displayName': displayName.isEmpty ? null : displayName,
          'bio': bio.isEmpty ? null : bio,
          'phone': phone.isEmpty ? null : phone,
          'location': location.isEmpty ? null : location,
          'interests': interests.isEmpty ? null : interests,
          'photoUrl': _photoUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;
      setState(() {
        _hasChanges = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );
    } catch (e, st) {
      if (!mounted) return;
      debugPrint('Error saving profile: $e');
      debugPrint('Stack trace:\n$st');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save profile: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    final user = _auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      context.go('/login');
      return;
    }

    try {
      setState(() => _isUploadingAvatar = true);

      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (picked == null) {
        return;
      }

      String url;

      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        final ref = _storage.ref().child('users/${user.uid}/avatar.jpg');
        await ref.putData(
          bytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );
        url = await ref.getDownloadURL();
      } else {
        final file = File(picked.path);
        final ref = _storage.ref().child('users/${user.uid}/avatar.jpg');
        await ref.putFile(
          file,
          SettableMetadata(contentType: 'image/jpeg'),
        );
        url = await ref.getDownloadURL();
      }

      if (!mounted) return;
      setState(() {
        _photoUrl = url;
        _hasChanges = true;
      });

      await _saveProfile();
    } catch (e, st) {
      if (!mounted) return;
      debugPrint('Error uploading avatar: $e');
      debugPrint('Stack trace:\n$st');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload avatar: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _isUploadingAvatar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : user == null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Not logged in'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => context.go('/login'),
                        child: const Text('Go to login'),
                      ),
                    ],
                  ),
                )
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Avatar
                            Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                CircleAvatar(
                                  radius: 40,
                                  backgroundImage: _photoUrl != null
                                      ? NetworkImage(_photoUrl!)
                                      : null,
                                  child: _photoUrl == null
                                      ? Text(
                                          (user.displayName ??
                                                  user.email ??
                                                  'U')
                                              .characters
                                              .first
                                              .toUpperCase(),
                                          style:
                                              const TextStyle(fontSize: 28),
                                        )
                                      : null,
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: InkWell(
                                    onTap: _isUploadingAvatar
                                        ? null
                                        : _pickAndUploadAvatar,
                                    borderRadius: BorderRadius.circular(16),
                                    child: CircleAvatar(
                                      radius: 16,
                                      backgroundColor: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                      child: _isUploadingAvatar
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child:
                                                  CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(Colors.white),
                                              ),
                                            )
                                          : const Icon(
                                              Icons.camera_alt,
                                              size: 16,
                                              color: Colors.white,
                                            ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              user.email ?? '',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 24),

                            // Name
                            TextFormField(
                              controller: _displayNameCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Name',
                                border: OutlineInputBorder(),
                              ),
                              maxLength: 50,
                              onChanged: (_) => _markDirty(),
                              validator: (value) {
                                if (value != null && value.length > 50) {
                                  return 'Name is too long';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 8),

                            // Phone
                            TextFormField(
                              controller: _phoneCtrl,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'Phone',
                                border: OutlineInputBorder(),
                              ),
                              maxLength: 20,
                              onChanged: (_) => _markDirty(),
                              validator: (value) {
                                final v = value?.trim() ?? '';
                                if (v.isEmpty) return null;
                                final regex =
                                    RegExp(r'^\+?[0-9 ]{7,20}$');
                                if (!regex.hasMatch(v)) {
                                  return 'Enter a valid phone number';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 8),

                            // Location
                            TextFormField(
                              controller: _locationCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Location',
                                border: OutlineInputBorder(),
                              ),
                              maxLength: 100,
                              onChanged: (_) => _markDirty(),
                              validator: (value) {
                                if (value != null && value.length > 100) {
                                  return 'Location is too long';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 8),

                            // Interests
                            TextFormField(
                              controller: _interestsCtrl,
                              maxLines: 2,
                              decoration: const InputDecoration(
                                labelText: 'Interests (comma-separated)',
                                border: OutlineInputBorder(),
                              ),
                              maxLength: 200,
                              onChanged: (_) => _markDirty(),
                            ),
                            const SizedBox(height: 8),

                            // Interests chips view
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Builder(
                                builder: (context) {
                                  final interests =
                                      _parseInterests(_interestsCtrl.text);
                                  if (interests.isEmpty) {
                                    return Text(
                                      'No interests added yet',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    );
                                  }
                                  return Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: interests
                                        .map((i) => Chip(label: Text(i)))
                                        .toList(),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Bio
                            TextFormField(
                              controller: _bioCtrl,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                labelText: 'Bio',
                                border: OutlineInputBorder(),
                              ),
                              maxLength: 300,
                              onChanged: (_) => _markDirty(),
                            ),
                            const SizedBox(height: 24),

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isSaving || !_hasChanges
                                    ? null
                                    : _saveProfile,
                                child: _isSaving
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      )
                                    : const Text('Save changes'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
    );
  }
}
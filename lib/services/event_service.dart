import 'package:cloud_firestore/cloud_firestore.dart';

class EventService {
  final _col = FirebaseFirestore.instance.collection('events');

  Stream<List<Map<String, dynamic>>> getEventsStream() {
    return _col.snapshots().map((snap) => snap.docs.map((d) {
          final m = d.data();
          m['id'] = d.id;
          return m;
        }).toList());
  }

  Future<void> createEvent(Map<String, dynamic> data) => _col.add(data);
  Future<Map<String, dynamic>?> getEvent(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    final m = doc.data()!;
    m['id'] = doc.id;
    return m;
  }
}

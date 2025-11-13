import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/mood.dart';
import 'package:intl/intl.dart';

class MoodService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Stream<List<Mood>> listenUserMoods() {
    final uid = _auth.currentUser!.uid;
    return _db
        .collection('moods')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Mood.fromDoc(d)).toList());
  }

  Future<void> saveMood(String emoji, String label, DateTime date) async {
    final uid = _auth.currentUser!.uid;
    final docId = '$uid-${DateFormat('yyyyMMdd').format(date)}';
    final mood = Mood(
      userId: uid,
      emoji: emoji,
      label: label,
      date: date,
    );
    await _db.collection('moods').doc(docId).set(mood.toMap());
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/habit.dart';
import 'package:intl/intl.dart';

class HabitService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Stream<List<Habit>> listenUserHabits() {
    final uid = _auth.currentUser!.uid;
    return _db
        .collection('habits')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Habit.fromDoc(d)).toList());
  }

  Future<void> addHabit(String name) async {
    final uid = _auth.currentUser!.uid;
    final docId = '$uid-$name';
    final habit = Habit(
      userId: uid,
      name: name,
      doneDates: [],
      createdAt: DateTime.now(),
    );
    await _db.collection('habits').doc(docId).set(habit.toMap());
  }

  Future<void> toggleHabitDone(String name, DateTime date) async {
    final uid = _auth.currentUser!.uid;
    final docId = '$uid-$name';
    final dateStr = DateFormat('yyyy-MM-dd').format(date);

    final ref = _db.collection('habits').doc(docId);
    final snap = await ref.get();

    if (!snap.exists) return;

    final habit = Habit.fromDoc(snap);
    final doneDates = List<String>.from(habit.doneDates);

    if (doneDates.contains(dateStr)) {
      doneDates.remove(dateStr); // desmarcar
    } else {
      doneDates.add(dateStr); // marcar completado
    }

    await ref.update({'doneDates': doneDates});
  }
}

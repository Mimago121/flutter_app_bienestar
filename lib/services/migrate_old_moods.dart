import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

/// Ejecuta esta función una sola vez para migrar moods antiguos
Future<void> migrateOldMoods() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    print('⚠️ No hay usuario autenticado');
    return;
  }

  final db = FirebaseFirestore.instance;
  final uid = user.uid;

  print('🔍 Buscando moods antiguos para $uid...');

  // leer todos los moods antiguos
  final oldSnap = await db.collection('users').doc(uid).collection('moods').get();
  if (oldSnap.docs.isEmpty) {
    print('✅ No hay moods antiguos que migrar.');
    return;
  }

  for (var doc in oldSnap.docs) {
    final data = doc.data();
    DateTime? date;
    final rawDate = data['date'] ?? data['created_at'];
    if (rawDate is Timestamp) {
      date = rawDate.toDate();
    } else if (rawDate is String && rawDate.isNotEmpty) {
      try {
        date = DateTime.parse(rawDate);
      } catch (_) {}
    }
    if (date == null) continue;

    final emoji = data['emoji'] ?? data['mood']?.toString().split(' ').first ?? '';
    final label = data['label'] ?? 'Sin etiqueta';
    final docId = '$uid-${DateFormat('yyyyMMdd').format(date)}';

    await db.collection('moods').doc(docId).set({
      'userId': uid,
      'emoji': emoji,
      'label': label,
      'date': DateFormat('yyyy-MM-dd').format(date),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    print('✅ Migrado: $docId ($emoji)');
  }

  print('🎉 Migración completada. Los moods antiguos ya están en /moods.');
}

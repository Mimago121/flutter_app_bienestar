import 'package:cloud_firestore/cloud_firestore.dart';

class Mood {
  final String userId;
  final String emoji;
  final String label;
  final DateTime date;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Mood({
    required this.userId,
    required this.emoji,
    required this.label,
    required this.date,
    this.createdAt,
    this.updatedAt,
  });

  /// Convierte un documento de Firestore en un objeto Mood
  factory Mood.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    DateTime? getDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
      return null;
    }

    return Mood(
      userId: data['userId'] ?? '',
      emoji: data['emoji'] ?? '',
      label: data['label'] ?? '',
      date: getDate(data['date']) ?? DateTime.now(),
      createdAt: getDate(data['createdAt']),
      updatedAt: getDate(data['updatedAt']),
    );
  }

  /// Convierte el objeto a un mapa para Firestore
  Map<String, dynamic> toMap() => {
        'userId': userId,
        'emoji': emoji,
        'label': label,
        'date': date.toIso8601String(),
        'createdAt': createdAt ?? FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
}

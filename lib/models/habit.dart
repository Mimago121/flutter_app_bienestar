import 'package:cloud_firestore/cloud_firestore.dart';

class Habit {
  final String userId;
  final String name;
  final List<String> doneDates;
  final DateTime createdAt;

  Habit({
    required this.userId,
    required this.name,
    required this.doneDates,
    required this.createdAt,
  });

  factory Habit.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Habit(
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      doneDates: List<String>.from(data['doneDates'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'name': name,
        'doneDates': doneDates,
        'createdAt': createdAt,
      };
}

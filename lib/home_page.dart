import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final user = FirebaseAuth.instance.currentUser!;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  Map<String, String> moodsByDay = {};
  String? _selectedMood;

  final List<Map<String, String>> moods = [
    {'emoji': '😊', 'label': 'Feliz'},
    {'emoji': '😔', 'label': 'Triste'},
    {'emoji': '😴', 'label': 'Cansado'},
    {'emoji': '😡', 'label': 'Enojado'},
    {'emoji': '😌', 'label': 'Tranquilo'},
    {'emoji': '🤩', 'label': 'Motivado'},
  ];

  /// 🔁 Stream en tiempo real de los moods del usuario
  Stream<Map<String, String>> moodsStream() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('moods')
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) {
      final Map<String, String> data = {};
      for (var doc in snapshot.docs) {
        final date = (doc['date'] as Timestamp).toDate();
        final key = "${date.year}-${date.month}-${date.day}";
        data[key] = doc['emoji'];
      }
      return data;
    });
  }

  /// Guarda o actualiza un estado de ánimo
  Future<void> _saveMood(String emoji, String label) async {
    final today = DateTime.now();
    final difference = _selectedDay
        .difference(DateTime(today.year, today.month, today.day))
        .inDays;

    // 🚫 Evitar registrar días futuros
    if (difference > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No puedes registrar estados futuros 🚫')),
      );
      return;
    }

    // ⏳ Limitar edición a 7 días atrás
    if (difference < -7) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Solo puedes modificar hasta 7 días atrás ⏳')),
      );
      return;
    }

    // 🔑 Generar clave de día normalizada
    String pad(int n) => n.toString().padLeft(2, '0');
    final dayKey =
        "${_selectedDay.year}-${pad(_selectedDay.month)}-${pad(_selectedDay.day)}";

    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('moods');

    final existing =
        await ref.where('dayKey', isEqualTo: dayKey).limit(1).get();

    if (existing.docs.isNotEmpty) {
      // Actualizar
      await ref.doc(existing.docs.first.id).update({
        'emoji': emoji,
        'mood': label,
        'date': _selectedDay,
      });
    } else {
      // Crear nuevo
      await ref.add({
        'emoji': emoji,
        'mood': label,
        'date': _selectedDay,
        'dayKey': dayKey,
      });
    }

    setState(() {
      moodsByDay[dayKey] = emoji;
      _selectedMood = emoji;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Estado de ánimo guardado: $emoji $label ✅')),
    );
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MindTrack 🧠'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: StreamBuilder<Map<String, String>>(
        stream: moodsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 🔄 Actualizar mapa de estados en tiempo real
          if (snapshot.hasData) {
            moodsByDay = snapshot.data!;
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                TableCalendar(
                  firstDay: DateTime.utc(2024, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                      final key =
                          "${selectedDay.year}-${selectedDay.month}-${selectedDay.day}";
                      _selectedMood = moodsByDay[key];
                    });
                  },
                  calendarBuilders: CalendarBuilders(
                    defaultBuilder: (context, day, _) {
                      final key = "${day.year}-${day.month}-${day.day}";
                      final emoji = moodsByDay[key];
                      return Center(
                        child: Text(
                          emoji ?? day.day.toString(),
                          style: TextStyle(fontSize: emoji != null ? 20 : 14),
                        ),
                      );
                    },
                    todayBuilder: (context, day, _) => Container(
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.shade100,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        moodsByDay["${day.year}-${day.month}-${day.day}"] ??
                            day.day.toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    selectedBuilder: (context, day, _) => Container(
                      decoration: BoxDecoration(
                        color: Colors.deepPurple,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        moodsByDay["${day.year}-${day.month}-${day.day}"] ??
                            day.day.toString(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Selecciona tu estado de ánimo:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Wrap(
                  spacing: 8,
                  children: moods.map((m) {
                    final selected = _selectedMood == m['emoji'];
                    return ChoiceChip(
                      label: Text("${m['emoji']} ${m['label']}"),
                      selected: selected,
                      onSelected: (_) => _saveMood(m['emoji']!, m['label']!),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }
}

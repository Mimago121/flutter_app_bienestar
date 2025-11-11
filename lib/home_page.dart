import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final user = FirebaseAuth.instance.currentUser!;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  /// fecha 'yyyy-MM-dd' -> emoji
  Map<String, String> moodsByDay = {};

  final List<Map<String, String>> moods = const [
    {'emoji': '😊', 'label': 'Feliz'},
    {'emoji': '😔', 'label': 'Triste'},
    {'emoji': '😴', 'label': 'Cansado'},
    {'emoji': '😡', 'label': 'Enojado'},
  ];

  @override
  void initState() {
    super.initState();
    _listenMoods();
  }

  /// Normaliza a medianoche local
  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// 'yyyy-MM-dd'
  String _keyOf(DateTime d) => DateFormat('yyyy-MM-dd').format(_dateOnly(d));

  /// Extrae el emoji: soporta `emoji` o `mood: "😡 Enojado"`
  String? _emojiFromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    if (data.containsKey('emoji')) return data['emoji']?.toString();
    if (data.containsKey('mood')) {
      final s = data['mood']?.toString() ?? '';
      if (s.isEmpty) return null;
      // Toma el primer “token” (el emoji) antes del espacio
      return s.split(' ').first;
    }
    return null;
  }

  /// Lee en tiempo real TODOS los moods del usuario y los pinta
  void _listenMoods() {
    FirebaseFirestore.instance
        .collection('moods')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .listen((qs) {
      final map = <String, String>{};
      for (final doc in qs.docs) {
        final data = doc.data();
        // date puede ser Timestamp o String
        DateTime? date;
        final rawDate = data['date'];
        if (rawDate is Timestamp) {
          date = rawDate.toDate();
        } else if (rawDate is String && rawDate.isNotEmpty) {
          // fallback para datos antiguos
          try {
            date = DateTime.parse(rawDate);
          } catch (_) {}
        }
        if (date == null) continue;

        final emoji = _emojiFromDoc(doc);
        if (emoji == null || emoji.isEmpty) continue;

        final k = _keyOf(date);
        map[k] = emoji; // si hubiera duplicados antiguos, el último gana
      }
      setState(() => moodsByDay = map);
    });
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _selectMood(String emoji) async {
    final today = _dateOnly(DateTime.now());
    final sel = _dateOnly(_selectedDay);

    if (sel.isAfter(today)) {
      _showError('No puedes registrar un estado de ánimo en un día futuro.');
      return;
    }
    final diff = today.difference(sel).inDays; // 0..∞
    if (diff > 3) {
      _showError('Solo puedes modificar los estados de los últimos 3 días.');
      return;
    }

    final docId = '${user.uid}-${DateFormat('yyyyMMdd').format(sel)}';
    await FirebaseFirestore.instance
        .collection('moods')
        .doc(docId) // <- UN MOOD POR DÍA (sobrescribe)
        .set({
      'userId': user.uid,
      'date': Timestamp.fromDate(sel), // guarda normalizado a día
      'emoji': emoji,
      // opcional: también guarda label por si lo quieres mostrar en detalles
      'label': moods.firstWhere((m) => m['emoji'] == emoji)['label'],
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: false));

    // Refresco local inmediato
    setState(() => moodsByDay[_keyOf(sel)] = emoji);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi Estado de Ánimo')),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2035, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, _) {
                final k = _keyOf(day);
                final emoji = moodsByDay[k];
                if (emoji != null) {
                  return Center(child: Text(emoji, style: const TextStyle(fontSize: 22)));
                }
                return Center(child: Text(DateFormat('d').format(day)));
              },
              todayBuilder: (context, day, _) {
                final k = _keyOf(day);
                final emoji = moodsByDay[k];
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(emoji ?? DateFormat('d').format(day),
                        style: const TextStyle(fontSize: 18)),
                  ),
                );
              },
              selectedBuilder: (context, day, _) {
                final k = _keyOf(day);
                final emoji = moodsByDay[k];
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.28),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(emoji ?? DateFormat('d').format(day),
                        style: const TextStyle(fontSize: 18)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            children: moods.map((m) {
              return ElevatedButton(
                onPressed: () => _selectMood(m['emoji']!),
                child: Text('${m['emoji']} ${m['label']}'),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

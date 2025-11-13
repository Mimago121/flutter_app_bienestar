
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/mood_service.dart';
import '../widgets/mood_calendar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _moodService = MoodService();
  final user = FirebaseAuth.instance.currentUser!;
  Map<String, String> moodsByDay = {};
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  final List<Map<String, String>> moods = const [
    {'emoji': '😊', 'label': 'Feliz'},
    {'emoji': '😔', 'label': 'Triste'},
    {'emoji': '😴', 'label': 'Cansado'},
    {'emoji': '😡', 'label': 'Enojado'},
  ];

  @override
  void initState() {
    super.initState();

    // 🔹 Solo ejecutar UNA VEZ para mover los datos antiguos:
    //migrateOldMoods();

    _listenMoods();
  }

  void _listenMoods() {
    _moodService.listenUserMoods().listen((list) {
      final map = <String, String>{};
      for (var mood in list) {
        final key = DateFormat('yyyy-MM-dd').format(mood.date);
        map[key] = mood.emoji;
      }
      setState(() => moodsByDay = map);
    });
  }

  Future<void> _selectMood(String emoji, String label) async {
    final today = DateTime.now();
    final sel = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
    );

    if (sel.isAfter(today)) {
      _showError('No puedes registrar un estado de ánimo en un día futuro.');
      return;
    }

    final diff = today.difference(sel).inDays;
    if (diff > 3) {
      _showError('Solo puedes modificar los estados de los últimos 3 días.');
      return;
    }

    await _moodService.saveMood(emoji, label, sel);
    setState(() => moodsByDay[DateFormat('yyyy-MM-dd').format(sel)] = emoji);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  /// 🔹 Diálogo de confirmación antes de cerrar sesión
  Future<void> _confirmLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Estado de Ánimo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.checklist),
            tooltip: 'Hábitos',
            onPressed: () {
              Navigator.pushNamed(context, '/habits');
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: _confirmLogout,
          ),
        ],
      ),
      body: Column(
        children: [
          MoodCalendar(
            moodsByDay: moodsByDay,
            focusedDay: _focusedDay,
            selectedDay: _selectedDay,
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            children: moods.map((m) {
              return ElevatedButton(
                onPressed: () => _selectMood(m['emoji']!, m['label']!),
                child: Text('${m['emoji']} ${m['label']}'),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

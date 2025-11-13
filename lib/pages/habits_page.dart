import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/habit_service.dart';
import '../models/habit.dart';

class HabitsPage extends StatefulWidget {
  const HabitsPage({super.key});

  @override
  State<HabitsPage> createState() => _HabitsPageState();
}

class _HabitsPageState extends State<HabitsPage> {
  final _habitService = HabitService();
  final _controller = TextEditingController();
  List<Habit> _habits = [];
  final DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _listenHabits();
  }

  void _listenHabits() {
    _habitService.listenUserHabits().listen((list) {
      setState(() => _habits = list);
    });
  }

  Future<void> _addHabit() async {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    await _habitService.addHabit(name);
    _controller.clear();
  }

  Future<void> _toggleHabit(Habit habit) async {
    await _habitService.toggleHabitDone(habit.name, _selectedDay);
  }

  bool _isHabitDoneToday(Habit habit) {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDay);
    return habit.doneDates.contains(dateStr);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Hábitos')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Nuevo hábito',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addHabit,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _habits.length,
                itemBuilder: (context, index) {
                  final habit = _habits[index];
                  final done = _isHabitDoneToday(habit);
                  return Card(
                    child: ListTile(
                      title: Text(habit.name),
                      trailing: IconButton(
                        icon: Icon(
                          done ? Icons.check_circle : Icons.radio_button_unchecked,
                          color: done ? Colors.green : Colors.grey,
                        ),
                        onPressed: () => _toggleHabit(habit),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => HabitDetailPage(habit: habit),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 🔹 Pantalla detalle del hábito
class HabitDetailPage extends StatelessWidget {
  final Habit habit;
  const HabitDetailPage({super.key, required this.habit});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final currentMonth = DateFormat('yyyy-MM').format(now);
    final doneThisMonth = habit.doneDates
        .where((d) => d.startsWith(currentMonth))
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(habit.name)),
      body: Center(
        child: Text(
          'Has completado este hábito ${doneThisMonth.length} días este mes.',
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}

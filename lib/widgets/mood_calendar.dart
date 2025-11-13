import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class MoodCalendar extends StatelessWidget {
  final Map<String, String> moodsByDay;
  final DateTime focusedDay;
  final DateTime selectedDay;
  final Function(DateTime, DateTime) onDaySelected;

  const MoodCalendar({
    super.key,
    required this.moodsByDay,
    required this.focusedDay,
    required this.selectedDay,
    required this.onDaySelected,
  });

  String _keyOf(DateTime d) => DateFormat('yyyy-MM-dd').format(DateTime(d.year, d.month, d.day));

  @override
  Widget build(BuildContext context) {
    return TableCalendar(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2035, 12, 31),
      focusedDay: focusedDay,
      selectedDayPredicate: (d) => isSameDay(selectedDay, d),
      onDaySelected: onDaySelected,
      calendarBuilders: CalendarBuilders(
        defaultBuilder: (context, day, _) {
          final emoji = moodsByDay[_keyOf(day)];
          return Center(
            child: Text(
              emoji ?? DateFormat('d').format(day),
              style: const TextStyle(fontSize: 18),
            ),
          );
        },
        todayBuilder: (context, day, _) {
          final emoji = moodsByDay[_keyOf(day)];
          return Container(
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                emoji ?? DateFormat('d').format(day),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          );
        },
      ),
    );
  }
}

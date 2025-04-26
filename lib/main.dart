import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appDocumentDir = await path_provider.getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDocumentDir.path);
  await Hive.openBox('streakBox');
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Streak Calendar',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: StreakCalendarPage(),
    );
  }
}

class StreakCalendarPage extends StatefulWidget {
  @override
  _StreakCalendarPageState createState() => _StreakCalendarPageState();
}

class _StreakCalendarPageState extends State<StreakCalendarPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  late Box _streakBox;
  final DateTime _currentDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectedDay = _currentDate;
    _streakBox = Hive.box('streakBox');
  }

  Set<DateTime> get _completedDays {
    final savedDates =
        _streakBox.get('completedDays', defaultValue: <String>[]);
    return (savedDates as List)
        .map((dateStr) => DateTime.parse(dateStr as String))
        .toSet();
  }

  Future<void> _markDayAsDone(DateTime day) async {
    final currentCompleted = _completedDays.toSet();
    currentCompleted.add(day);
    await _streakBox.put(
      'completedDays',
      currentCompleted.map((date) => date.toIso8601String()).toList(),
    );
    setState(() {});
  }

  bool _isToday(DateTime day) {
    return isSameDay(day, _currentDate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade200, Colors.purple.shade200],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(height: 10),
              Text(
                '🔥 My Streak 🔥',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                        blurRadius: 5,
                        color: Colors.black26,
                        offset: Offset(2, 2))
                  ],
                ),
              ),
              SizedBox(height: 20),
              TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDay, day);
                },
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Colors.purple,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, date, _) {
                    if (_completedDays.contains(date)) {
                      return Center(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.greenAccent,
                            shape: BoxShape.circle,
                          ),
                          width: 35,
                          height: 35,
                          alignment: Alignment.center,
                          child: Text(
                            '${date.day}',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    }
                    return null;
                  },
                  markerBuilder: (context, date, events) => null,
                ),
              ),
              SizedBox(height: 20),
              if (_isToday(_selectedDay!) &&
                  !_completedDays.contains(_selectedDay))
                ElevatedButton(
                  onPressed: () => _markDayAsDone(_selectedDay!),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: StadiumBorder(),
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: Text('Mark Today as Done! 🚀',
                      style: TextStyle(fontSize: 18)),
                )
              else if (_isToday(_selectedDay!) &&
                  _completedDays.contains(_selectedDay))
                Text(
                  'You already crushed today! 🎯',
                  style: TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                )
              else
                Text(
                  'Only today can be marked ✅',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              SizedBox(height: 30),
              AnimatedContainer(
                duration: Duration(milliseconds: 500),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(2, 4))
                  ],
                ),
                child: Text(
                  '🔥 Current Streak: ${_calculateCurrentStreak()} days 🔥',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _calculateCurrentStreak() {
    if (_completedDays.isEmpty) return 0;

    final sortedDays = _completedDays.toList()..sort((a, b) => b.compareTo(a));
    int streak = 0;
    DateTime currentDate = _currentDate;

    if (isSameDay(sortedDays[0], currentDate)) {
      streak = 1;
      currentDate = currentDate.subtract(Duration(days: 1));
    }

    for (final day in sortedDays) {
      if (isSameDay(day, currentDate)) {
        streak++;
        currentDate = currentDate.subtract(Duration(days: 1));
      } else if (day.isBefore(currentDate)) {
        break;
      }
    }

    return streak;
  }
}

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import '../models/workout_log.dart';
import '../providers/workout_provider.dart';
import 'workout_details_screen.dart';
import 'settings/settings_screen.dart';

class LogScreen extends StatefulWidget {
  const LogScreen({super.key});

  @override
  _LogScreenState createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    // Удаляем загрузку данных опроса
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   context.read<SurveyProvider>().loadSurveyData();
    // });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Training Log'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<WorkoutProvider>(
        builder: (context, workoutProvider, child) {
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'WORKOUTS',
                                  style: TextStyle(
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  workoutProvider.workoutLogs.length.toString(),
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'STREAK',
                                  style: TextStyle(
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  _calculateStreak(workoutProvider).toString(),
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      TableCalendar(
                        firstDay: DateTime.utc(2020, 1, 1),
                        lastDay: DateTime.utc(2030, 12, 31),
                        focusedDay: _focusedDay,
                        calendarFormat: _calendarFormat,
                        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
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
                          selectedDecoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            shape: BoxShape.circle,
                          ),
                          todayDecoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                        ),
                        calendarBuilders: CalendarBuilders(
                          markerBuilder: (context, date, events) {
                            final workouts = workoutProvider.getWorkoutsForDate(date);
                            final hasCompleted = workouts.any((w) => workoutProvider.isWorkoutCompleted(date, w));
                            final hasScheduled = workouts.isNotEmpty;

                            if (!hasScheduled) return null;

                            return Positioned(
                              bottom: 1,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: hasCompleted ? Colors.green : Colors.blue,
                                ),
                              ),
                            );
                          },
                        ),
                        eventLoader: (day) => workoutProvider.getWorkoutsForDate(day),
                      ),
                      if (_selectedDay != null) ...[
                        _buildWorkoutList(workoutProvider),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWorkoutList(WorkoutProvider workoutProvider) {
    final workouts = workoutProvider.getWorkoutsForDate(_selectedDay!);

    if (workouts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fitness_center, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No workouts scheduled',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Add workouts from the Workouts tab',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: workouts.length,
      itemBuilder: (context, index) {
        final workout = workouts[index];
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            title: Text(workout.name),
            subtitle: Text('${workout.exercises.length} exercises'),
            trailing: IconButton(
              icon: Icon(Icons.play_circle_fill),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WorkoutDetailsScreen(workout: workout),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  int _calculateStreak(WorkoutProvider workoutProvider) {
    int streak = 0;
    DateTime currentDate = DateTime.now();

    while (true) {
      final workouts = workoutProvider.getWorkoutsForDate(currentDate);
      final hasCompleted = workouts.any((w) => workoutProvider.isWorkoutCompleted(currentDate, w));

      if (!hasCompleted) break;

      streak++;
      currentDate = currentDate.subtract(Duration(days: 1));
    }

    return streak;
  }
} 
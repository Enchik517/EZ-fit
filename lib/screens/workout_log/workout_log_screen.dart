import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/workout_provider.dart';
import '../../models/workout.dart';
import '../workout_details_screen.dart';

class WorkoutLogScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Upcoming Workouts'),
      ),
      body: Consumer<WorkoutProvider>(
        builder: (context, workoutProvider, child) {
          final upcomingWorkouts = workoutProvider.getUpcomingWorkouts();

          if (upcomingWorkouts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.fitness_center, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No upcoming workouts',
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
            padding: EdgeInsets.all(16),
            itemCount: upcomingWorkouts.length,
            itemBuilder: (context, index) {
              final workout = upcomingWorkouts[index];
              return Card(
                child: ListTile(
                  title: Text(workout.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${workout.exercises.length} exercises • ${workout.totalDuration.inMinutes} min'),
                      Text(workout.difficulty),
                      Wrap(
                        spacing: 4,
                        children: workout.targetMuscles.map((muscle) => 
                          Chip(
                            label: Text(muscle),
                            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          )
                        ).toList(),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.play_circle_fill),
                    color: Theme.of(context).primaryColor,
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
        },
      ),
    );
  }
} 
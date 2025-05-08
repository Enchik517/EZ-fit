import 'package:flutter/material.dart';
import '../models/ai_workout_plan.dart';
import '../providers/workout_provider.dart';
import 'package:provider/provider.dart';

class AIWorkoutPlanWidget extends StatelessWidget {
  final AIWorkoutPlan plan;

  const AIWorkoutPlanWidget({
    Key? key,
    required this.plan,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(plan.name),
            subtitle: Text(plan.description),
          ),
          Divider(),
          ...plan.days.map((day) => _buildDayCard(context, day)).toList(),
          if (plan.notes != null)
            Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                'Notes:\n${plan.notes}',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
          ButtonBar(
            children: [
              TextButton(
                onPressed: () => _addToSchedule(context),
                child: Text('Add to Schedule'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDayCard(BuildContext context, AIWorkoutDay day) {
    return ExpansionTile(
      title: Text(day.name),
      children: day.exercises.map((exercise) => ListTile(
        title: Text(exercise.name),
        subtitle: Text('${exercise.sets} sets x ${exercise.reps} reps'),
        trailing: exercise.notes != null ? 
          Tooltip(
            message: exercise.notes!,
            child: Icon(Icons.info_outline),
          ) : null,
      )).toList(),
    );
  }

  void _addToSchedule(BuildContext context) {
    // TODO: Implement adding to schedule
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Plan added to schedule')),
    );
  }
} 
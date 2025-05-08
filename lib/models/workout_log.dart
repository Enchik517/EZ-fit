import 'package:flutter/material.dart';
import 'workout.dart';
import 'exercise.dart';
import 'package:uuid/uuid.dart';

class WorkoutLog {
  final String id;
  final String workoutName;
  final DateTime date;
  final Duration duration;
  final List<ExerciseLog> exercises;
  final String? notes;
  final bool isCompleted;
  bool isFavorite;
  DateTime? endTime;

  WorkoutLog({
    String? id,
    required this.workoutName,
    required this.date,
    required this.duration,
    required this.exercises,
    this.notes,
    this.isCompleted = false,
    this.isFavorite = false,
    this.endTime,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'workout_name': workoutName,
      'workout_date': date.toIso8601String(),
      'duration': duration.inMinutes,
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'notes': notes,
      'is_completed': isCompleted,
      'is_favorite': isFavorite,
    };
  }

  factory WorkoutLog.fromJson(Map<String, dynamic> json) {
    return WorkoutLog(
      id: json['id']?.toString() ?? '',
      workoutName: json['workout_name']?.toString() ?? 'Unnamed Workout',
      date: DateTime.parse(json['workout_date'] ?? DateTime.now().toIso8601String()),
      duration: Duration(minutes: int.tryParse(json['duration']?.toString() ?? '0') ?? 0),
      exercises: (json['exercises'] as List? ?? []).map((e) => ExerciseLog.fromJson(e)).toList(),
      notes: json['notes']?.toString(),
      isCompleted: json['is_completed'] as bool? ?? false,
      isFavorite: json['is_favorite'] as bool? ?? false,
    );
  }

  factory WorkoutLog.fromWorkout(Workout workout) {
    return WorkoutLog(
      workoutName: workout.name,
      date: DateTime.now(),
      duration: Duration(minutes: workout.duration),
      exercises: [],
      isCompleted: false,
      isFavorite: false,
    );
  }
}

class ExerciseLog {
  final Exercise exercise;
  final List<SetLog> sets;
  bool get isCompleted {
    try {
      int targetSets = int.parse(exercise.sets);
      return sets.length >= targetSets;
    } catch (e) {
      final match = RegExp(r'\d+').firstMatch(exercise.sets);
      int targetSets = match != null ? int.tryParse(match.group(0)!) ?? 3 : 3;
      return sets.length >= targetSets;
    }
  }

  ExerciseLog({
    required this.exercise,
    required this.sets,
  });

  Map<String, dynamic> toJson() {
    return {
      'exercise': exercise.toJson(),
      'sets': sets.map((s) => s.toJson()).toList(),
    };
  }

  factory ExerciseLog.fromJson(Map<String, dynamic> json) {
    return ExerciseLog(
      exercise: Exercise.fromJson(json['exercise']),
      sets: (json['sets'] as List)
          .map((s) => SetLog.fromJson(s))
          .toList(),
    );
  }

  factory ExerciseLog.fromExercise(Exercise e) {
    return ExerciseLog(
      exercise: e,
      sets: List.generate(
        int.parse(e.sets),
        (index) => SetLog(
          reps: int.parse(e.reps.replaceAll(RegExp(r'[^0-9]'), '')),
          weight: 0,
        ),
      ),
    );
  }
}

class SetLog {
  final int reps;
  final double? weight;
  final Duration? duration;
  final String? notes;

  SetLog({
    required this.reps,
    this.weight,
    this.duration,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'reps': reps,
      'weight': weight,
      'duration': duration?.inSeconds,
      'notes': notes,
    };
  }

  factory SetLog.fromJson(Map<String, dynamic> json) {
    return SetLog(
      reps: json['reps'] as int,
      weight: json['weight'] as double?,
      duration: json['duration'] != null 
          ? Duration(seconds: json['duration'] as int)
          : null,
      notes: json['notes'] as String?,
    );
  }
} 
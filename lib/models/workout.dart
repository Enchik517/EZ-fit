import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'exercise.dart';

class Workout {
  final String id;
  final String name;
  final String description;
  final List<Exercise> exercises;
  final int duration; // в минутах
  final int calories;
  final String? imageUrl;
  final String? category;
  final DateTime? createdAt;
  final String difficulty;
  final List<String> equipment;
  final List<String> targetMuscles;
  final String focus;
  final String warmUp;
  final String coolDown;
  final DateTime? scheduledDate;
  final Duration totalDuration;
  final Duration exerciseTime;
  final Duration restBetweenSets;
  final Duration restBetweenExercises;
  final String? instructions; // Подробные инструкции к тренировке
  final List<String>? tips; // Советы по выполнению
  final bool isAIGenerated;
  final DateTime? schedule;
  final bool isFavorite;

  Workout({
    required this.id,
    required this.name,
    required this.description,
    required this.exercises,
    required this.duration,
    this.calories = 0,
    this.imageUrl,
    this.category,
    this.createdAt,
    required this.difficulty,
    required this.equipment,
    required this.targetMuscles,
    required this.focus,
    this.warmUp = '',
    this.coolDown = '',
    this.scheduledDate,
    this.totalDuration = const Duration(minutes: 60),
    this.exerciseTime = const Duration(seconds: 45),
    this.restBetweenSets = const Duration(seconds: 30),
    this.restBetweenExercises = const Duration(minutes: 1),
    this.instructions,
    this.tips,
    this.isAIGenerated = false,
    this.schedule,
    this.isFavorite = false,
  });

  Map<String, dynamic> toJson() {
    if (kDebugMode) {
      debugPrint('📦 Workout.toJson для: $name (id: $id)');
    }

    // Проверяем, что equipment и targetMuscles всегда хранятся как список строк
    List<String> safeEquipment = [];
    if (equipment is List<String>) {
      safeEquipment = equipment;
    } else if (equipment is List) {
      safeEquipment = equipment.map((e) => e.toString()).toList();
    }

    List<String> safeTargetMuscles = [];
    if (targetMuscles is List<String>) {
      safeTargetMuscles = targetMuscles;
    } else if (targetMuscles is List) {
      safeTargetMuscles = targetMuscles.map((e) => e.toString()).toList();
    }

    final result = {
      'id': id,
      'name': name,
      'description': description,
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'duration': duration,
      'calories': calories,
      'image_url': imageUrl,
      'category': category,
      'created_at': createdAt?.toIso8601String(),
      'difficulty': difficulty,
      'equipment': safeEquipment,
      'targetMuscles': safeTargetMuscles,
      'focus': focus,
      'warmUp': warmUp,
      'coolDown': coolDown,
      'scheduledDate': scheduledDate?.toIso8601String(),
      'exerciseTime': exerciseTime.inSeconds,
      'restBetweenSets': restBetweenSets.inSeconds,
      'restBetweenExercises': restBetweenExercises.inMinutes,
      'instructions': instructions,
      'tips': tips,
      'isAIGenerated': isAIGenerated,
      'schedule': schedule?.toIso8601String(),
      'is_favorite': isFavorite,
    };

    if (kDebugMode) {
      debugPrint('📦 Workout.toJson результат имеет ${result.length} полей');
    }

    return result;
  }

  factory Workout.fromJson(Map<String, dynamic> json) {
    return Workout(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      exercises: (json['exercises'] as List<dynamic>?)
              ?.map((e) => Exercise.basic(
                  name: e['name'],
                  targetMuscleGroup: e['targetMuscleGroup'],
                  equipment: e['equipment'],
                  sets: e['sets'],
                  reps: e['reps'],
                  difficulty: e['difficulty'] ?? 'Beginner'))
              .toList() ??
          [],
      duration: json['duration'] as int? ?? 30,
      calories: json['calories'] as int? ?? 0,
      imageUrl: json['image_url'] as String?,
      category: json['category'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      difficulty: json['difficulty'] as String? ?? 'beginner',
      equipment: (json['equipment'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      targetMuscles: (json['target_muscles'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      focus: json['focus'] as String? ?? 'general',
      warmUp: json['warm_up'] as String? ?? '',
      coolDown: json['cool_down'] as String? ?? '',
      scheduledDate: json['scheduled_date'] != null
          ? DateTime.parse(json['scheduled_date'])
          : null,
      totalDuration: Duration(minutes: json['total_duration'] as int? ?? 60),
      exerciseTime: Duration(seconds: json['exercise_time'] as int? ?? 45),
      restBetweenSets:
          Duration(seconds: json['rest_between_sets'] as int? ?? 30),
      restBetweenExercises:
          Duration(minutes: json['rest_between_exercises'] as int? ?? 1),
      instructions: json['instructions'] as String?,
      tips: json['tips'] != null ? List<String>.from(json['tips']) : null,
      isAIGenerated: json['is_ai_generated'] as bool? ?? false,
      schedule:
          json['schedule'] != null ? DateTime.parse(json['schedule']) : null,
      isFavorite: json['is_favorite'] as bool? ?? false,
    );
  }

  Workout copyWith({
    String? id,
    String? name,
    String? description,
    List<Exercise>? exercises,
    int? duration,
    int? calories,
    String? imageUrl,
    String? category,
    DateTime? createdAt,
    String? difficulty,
    List<String>? equipment,
    List<String>? targetMuscles,
    String? focus,
    String? warmUp,
    String? coolDown,
    DateTime? scheduledDate,
    Duration? totalDuration,
    Duration? exerciseTime,
    Duration? restBetweenSets,
    Duration? restBetweenExercises,
    String? instructions,
    List<String>? tips,
    bool? isAIGenerated,
    DateTime? schedule,
    bool? isFavorite,
  }) {
    return Workout(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      exercises: exercises ?? this.exercises,
      duration: duration ?? this.duration,
      calories: calories ?? this.calories,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      difficulty: difficulty ?? this.difficulty,
      equipment: equipment ?? this.equipment,
      targetMuscles: targetMuscles ?? this.targetMuscles,
      focus: focus ?? this.focus,
      warmUp: warmUp ?? this.warmUp,
      coolDown: coolDown ?? this.coolDown,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      totalDuration: totalDuration ?? this.totalDuration,
      exerciseTime: exerciseTime ?? this.exerciseTime,
      restBetweenSets: restBetweenSets ?? this.restBetweenSets,
      restBetweenExercises: restBetweenExercises ?? this.restBetweenExercises,
      instructions: instructions ?? this.instructions,
      tips: tips ?? this.tips,
      isAIGenerated: isAIGenerated ?? this.isAIGenerated,
      schedule: schedule ?? this.schedule,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

extension WorkoutExtensions on Workout {
  /// Создает копию тренировки с флагом isFavorite=true
  Workout markAsFavorite() {
    return copyWith(isFavorite: true);
  }

  /// Создает копию тренировки с флагом isFavorite=false
  Workout removeFromFavorites() {
    return copyWith(isFavorite: false);
  }

  /// Создает копию тренировки с инвертированным флагом isFavorite
  Workout toggleFavoriteStatus() {
    return copyWith(isFavorite: !isFavorite);
  }

  /// Проверяет, является ли тренировка действительной (имеет все необходимые поля)
  bool get isValid {
    return id.isNotEmpty && name.isNotEmpty && exercises.isNotEmpty;
  }

  /// Возвращает строковое представление тренировки для отладки
  String get debugString {
    return 'Workout{id: $id, name: $name, exercises: ${exercises.length}, isFavorite: $isFavorite}';
  }
}

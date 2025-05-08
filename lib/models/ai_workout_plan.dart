class AIWorkoutPlan {
  final String name;
  final String description;
  final String difficulty;
  final String category;
  final List<AIWorkoutDay> days;
  final Duration exerciseTime;
  final Duration restBetweenSets;
  final Duration restBetweenExercises;
  final Duration totalDuration;
  final String instructions;
  final List<String> tips;
  final String? notes;

  AIWorkoutPlan({
    required this.name,
    required this.description,
    required this.difficulty,
    required this.category,
    required this.days,
    required this.exerciseTime,
    required this.restBetweenSets,
    required this.restBetweenExercises,
    required this.totalDuration,
    required this.instructions,
    required this.tips,
    this.notes,
  });

  factory AIWorkoutPlan.fromJson(Map<String, dynamic> json) {
    return AIWorkoutPlan(
      name: json['name'] as String,
      description: json['description'] as String,
      difficulty: json['difficulty'] as String,
      category: json['category'] as String,
      days: (json['days'] as List).map((e) => AIWorkoutDay.fromJson(e)).toList(),
      exerciseTime: Duration(seconds: json['exerciseTime'] as int),
      restBetweenSets: Duration(seconds: json['restBetweenSets'] as int),
      restBetweenExercises: Duration(seconds: json['restBetweenExercises'] as int),
      totalDuration: Duration(minutes: json['totalDuration'] as int),
      instructions: json['instructions'] as String,
      tips: (json['tips'] as List).map((e) => e as String).toList(),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'difficulty': difficulty,
      'category': category,
      'days': days.map((e) => e.toJson()).toList(),
      'exerciseTime': exerciseTime.inSeconds,
      'restBetweenSets': restBetweenSets.inSeconds,
      'restBetweenExercises': restBetweenExercises.inSeconds,
      'totalDuration': totalDuration.inMinutes,
      'instructions': instructions,
      'tips': tips,
      'notes': notes,
    };
  }
}

class AIWorkoutDay {
  final String name;
  final List<AIExercise> exercises;

  AIWorkoutDay({
    required this.name,
    required this.exercises,
  });

  factory AIWorkoutDay.fromJson(Map<String, dynamic> json) {
    return AIWorkoutDay(
      name: json['name'] as String,
      exercises: (json['exercises'] as List).map((e) => AIExercise.fromJson(e)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'exercises': exercises.map((e) => e.toJson()).toList(),
    };
  }
}

class AIExercise {
  final String name;
  final String sets;
  final String reps;
  final String instructions;
  final List<String> commonMistakes;
  final List<String> modifications;
  final String? notes;

  AIExercise({
    required this.name,
    required this.sets,
    required this.reps,
    required this.instructions,
    required this.commonMistakes,
    required this.modifications,
    this.notes,
  });

  factory AIExercise.fromJson(Map<String, dynamic> json) {
    return AIExercise(
      name: json['name'] as String,
      sets: json['sets'] as String,
      reps: json['reps'] as String,
      instructions: json['instructions'] as String,
      commonMistakes: (json['commonMistakes'] as List).map((e) => e as String).toList(),
      modifications: (json['modifications'] as List).map((e) => e as String).toList(),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'sets': sets,
      'reps': reps,
      'instructions': instructions,
      'commonMistakes': commonMistakes,
      'modifications': modifications,
      'notes': notes,
    };
  }
} 
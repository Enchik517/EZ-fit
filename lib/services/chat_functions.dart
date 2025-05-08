import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/workout.dart';
import '../models/exercise.dart';
import '../services/workout_service.dart';
import '../services/survey_service.dart';
import 'package:uuid/uuid.dart';

class ChatFunctions {
  static final SurveyService _surveyService = SurveyService();
  static final _uuid = Uuid();

  static Map<String, Function> get functions => {
        'create_workout': createWorkout,
        'get_user_profile': getUserProfile,
        'modify_workout': modifyWorkoutFromJson,
        'search_exercises': searchExercises,
      };

  static Future<Map<String, dynamic>> createWorkout({
    required String name,
    required String focus,
    required String difficulty,
    required int duration,
    List<String>? equipment,
  }) async {
    final workouts = WorkoutService.filterWorkouts(
      difficulty: difficulty,
      equipment: equipment,
      muscleGroup: focus,
    );

    // Получаем упражнения из первой тренировки или создаем базовые
    final exercises = workouts.isNotEmpty
        ? workouts.first.exercises
        : [
            Exercise.basic(
                name: 'Basic $focus Exercise',
                targetMuscleGroup: focus,
                equipment: equipment?.first ?? 'none',
                sets: '3',
                reps: '10',
                difficulty: difficulty)
          ];

    final workout = Workout(
      id: _uuid.v4(),
      name: name,
      description: 'Custom workout for $focus',
      exercises: exercises.take(5).toList(),
      duration: duration,
      difficulty: difficulty,
      equipment: equipment ?? ['none'],
      targetMuscles: [focus],
      focus: focus,
      isAIGenerated: true,
    );

    return workout.toJson();
  }

  static Future<Map<String, dynamic>> getUserProfile() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return {};

    try {
      // Получаем полный профиль пользователя из таблицы user_profiles
      final response = await Supabase.instance.client
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .single();

      if (response != null) {
        // Форматируем данные для отображения в чате
        final formattedProfile = {
          'height': response['height'] != null
              ? '${response['height']} cm'
              : 'Not set',
          'weight': response['weight'] != null
              ? '${response['weight']} kg'
              : 'Not set',
          'age': response['birth_date'] != null
              ? DateTime.now()
                      .difference(DateTime.parse(response['birth_date']))
                      .inDays ~/
                  365
              : 'Not set',
          'gender': response['gender'] ?? 'Not set',
          'fitness_level': response['fitness_level'] ?? 'Not set',
          'goals': response['goals'] ?? [],
          'weekly_workouts': response['weekly_workouts'] ?? 'Not set',
          'workout_duration': response['workout_duration'] ?? 'Not set',
          'equipment': response['equipment'] ?? [],
          'injuries': response['injuries'] ?? [],
        };

        return formattedProfile;
      }
    } catch (e) {
      print('Ошибка при получении профиля: $e');
    }

    // Если не удалось получить профиль из user_profiles, пробуем survey_data
    final surveyData = await _surveyService.getSurveyData(userId);
    return (surveyData?['survey_data'] as Map<String, dynamic>?) ?? {};
  }

  static Future<List<Map<String, dynamic>>> searchExercises({
    String? muscleGroup,
    String? equipment,
    String? difficulty,
  }) async {
    final workouts = WorkoutService.filterWorkouts(
      difficulty: difficulty,
      equipment: equipment != null ? [equipment] : null,
      muscleGroup: muscleGroup,
    );

    // Собираем все уникальные упражнения из тренировок
    final exercises = workouts.expand((w) => w.exercises).toSet().toList();

    return exercises.map((e) => e.toJson()).toList();
  }

  static Future<Map<String, dynamic>> modifyWorkoutFromJson({
    required Map<String, dynamic> workout,
    String? newDifficulty,
    List<String>? addExercises,
    List<String>? removeExercises,
  }) async {
    final originalWorkout = Workout.fromJson(workout);
    var exercises = [...originalWorkout.exercises];

    if (removeExercises != null) {
      exercises.removeWhere((e) => removeExercises.contains(e.name));
    }

    if (addExercises != null) {
      // Получаем все упражнения из существующих тренировок
      final allWorkouts = WorkoutService.filterWorkouts(
        difficulty: newDifficulty ?? originalWorkout.difficulty,
      );

      final allExercises = allWorkouts
          .expand((w) => w.exercises)
          .where((e) => addExercises.contains(e.name))
          .toList();

      exercises.addAll(allExercises);
    }

    return Workout(
      id: originalWorkout.id,
      name: originalWorkout.name,
      description: originalWorkout.description,
      exercises: exercises,
      duration: originalWorkout.duration,
      difficulty: newDifficulty ?? originalWorkout.difficulty,
      equipment: originalWorkout.equipment,
      targetMuscles: originalWorkout.targetMuscles,
      focus: originalWorkout.focus,
      isAIGenerated: true,
    ).toJson();
  }

  static Workout createWorkoutFromUserPreferences({
    required String name,
    required String description,
    required List<Exercise> exercises,
    required String difficulty,
    required List<String> equipment,
    required List<String> targetMuscles,
    required String focus,
    int duration = 45,
  }) {
    return Workout(
      id: _uuid.v4(),
      name: name,
      description: description,
      exercises: exercises,
      duration: duration,
      difficulty: difficulty,
      equipment: equipment,
      targetMuscles: targetMuscles,
      focus: focus,
    );
  }

  static Workout generateCustomWorkout({
    required String name,
    required String description,
    required List<Exercise> exercises,
    required String difficulty,
    required List<String> equipment,
    required List<String> targetMuscles,
    required String focus,
    int duration = 45,
  }) {
    return Workout(
      id: _uuid.v4(),
      name: name,
      description: description,
      exercises: exercises,
      duration: duration,
      difficulty: difficulty,
      equipment: equipment,
      targetMuscles: targetMuscles,
      focus: focus,
    );
  }
}

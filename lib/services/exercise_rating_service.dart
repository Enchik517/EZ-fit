import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/exercise.dart';
import '../models/user_profile.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart';

/// Сервис для управления рейтингами упражнений
class ExerciseRatingService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Получить список упражнений с их текущими рейтингами из базы данных
  Future<List<Exercise>> getExercisesWithRatings() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Получаем пользовательские предпочтения и рейтинги для упражнений
      final ratingsData = await _supabase
          .from('exercise_ratings')
          .select('*')
          .eq('user_id', userId)
          .catchError((e) {
        debugPrint('Error getting ratings: $e');
        // В случае ошибки, вернем пустой список
        return [];
      });

      // Создаем Map для быстрого доступа к рейтингам упражнений
      final Map<String, Map<String, dynamic>> ratingsMap = {};
      for (final rating in ratingsData) {
        ratingsMap[rating['exercise_id']] = rating;
      }

      // Получаем данные об использовании упражнений (история)
      final usageData = await _supabase
          .from('exercise_history')
          .select('exercise_id, created_at')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .catchError((e) {
        debugPrint('Error getting exercise history: $e');
        // В случае ошибки, вернем пустой список
        return [];
      });

      // Создаем Map с данными о последнем использовании и количестве использований
      final Map<String, DateTime> lastUsedMap = {};
      final Map<String, int> usageCountMap = {};

      for (final usage in usageData) {
        final exerciseId = usage['exercise_id'];
        final createdAt = DateTime.parse(usage['created_at']);

        // Обновляем дату последнего использования, если она еще не установлена или новее
        if (!lastUsedMap.containsKey(exerciseId) ||
            createdAt.isAfter(lastUsedMap[exerciseId]!)) {
          lastUsedMap[exerciseId] = createdAt;
        }

        // Увеличиваем счетчик использований
        usageCountMap[exerciseId] = (usageCountMap[exerciseId] ?? 0) + 1;
      }

      // Загружаем локальный список упражнений из JSON-файла
      final String jsonString =
          await rootBundle.loadString('assets/exercise.json');
      final List<dynamic> exercisesJson = json.decode(jsonString);

      // Преобразуем данные в объекты Exercise
      final List<Exercise> exercises = [];
      for (final exerciseData in exercisesJson) {
        final String exerciseName = exerciseData['name'];
        final String exerciseId =
            exerciseName.replaceAll(' ', '_').toLowerCase();

        // Получаем данные о рейтинге для этого упражнения
        final Map<String, dynamic>? ratingData = ratingsMap[exerciseId];

        final exercise = Exercise(
          id: exerciseId,
          name: exerciseName,
          description: exerciseData['description'],
          muscleGroup: exerciseData['muscleGroup'],
          equipment: exerciseData['equipment'],
          difficultyLevel: exerciseData['difficultyLevel'],
          targetMuscleGroup: exerciseData['muscleGroup'],
          baseRating: ratingData?['base_rating'] ?? 50.0,
          currentRating: ratingData?['current_rating'] ?? 50.0,
          lastUsed: lastUsedMap[exerciseId],
          usageCount: usageCountMap[exerciseId] ?? 0,
          isFavorite: ratingData?['is_favorite'] ?? false,
          userPreference: ratingData?['user_preference'] ?? 0,
        );

        exercises.add(exercise);
      }

      return exercises;
    } catch (e) {
      debugPrint('Error getting exercises with ratings: $e');
      // В случае ошибки, возвращаем пустой список вместо повторного выброса исключения
      // Это позволит приложению продолжать работать даже при проблемах

      // Если не можем получить данные из БД, загружаем локальный JSON
      try {
        final String jsonString =
            await rootBundle.loadString('assets/exercise.json');
        final List<dynamic> exercisesJson = json.decode(jsonString);

        return exercisesJson.map((data) {
          final String name = data['name'];
          final String id = name.replaceAll(' ', '_').toLowerCase();

          return Exercise(
            id: id,
            name: name,
            description: data['description'],
            muscleGroup: data['muscleGroup'],
            equipment: data['equipment'],
            difficultyLevel: data['difficultyLevel'],
            targetMuscleGroup: data['muscleGroup'],
          );
        }).toList();
      } catch (jsonError) {
        debugPrint('Error loading local exercises: $jsonError');
        return []; // Если все совсем плохо, вернем пустой список
      }
    }
  }

  /// Обновить рейтинг упражнения в базе данных
  Future<void> updateExerciseRating(Exercise exercise) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Проверяем, существует ли уже запись рейтинга для этого упражнения
      final existingRating = await _supabase
          .from('exercise_ratings')
          .select()
          .eq('user_id', userId)
          .eq('exercise_id', exercise.id)
          .maybeSingle()
          .catchError((e) {
        if (kDebugMode) debugPrint('Error checking existing rating: $e');
        return null;
      });

      final currentRating = exercise.calculateCurrentRating();

      // Логирование изменения рейтинга
      if (kDebugMode) {
        debugPrint('=== RATING UPDATE ===');
        debugPrint('Exercise: ${exercise.name} (${exercise.id})');
        debugPrint('Base rating: ${exercise.baseRating}');
        debugPrint('Current rating: $currentRating');
        debugPrint('User preference: ${exercise.userPreference}');
        debugPrint('Is favorite: ${exercise.isFavorite}');
        debugPrint('Usage count: ${exercise.usageCount}');
        if (exercise.lastUsed != null) {
          debugPrint('Last used: ${exercise.lastUsed!.toIso8601String()}');
        }
      }

      final dataToUpsert = {
        'user_id': userId,
        'exercise_id': exercise.id,
        'base_rating': exercise.baseRating,
        'current_rating': currentRating,
        'is_favorite': exercise.isFavorite,
        'user_preference': exercise.userPreference,
        'last_updated': DateTime.now().toIso8601String(),
      };

      if (existingRating != null) {
        // Обновляем существующую запись
        if (kDebugMode) debugPrint('Updating existing rating record');
        await _supabase
            .from('exercise_ratings')
            .update(dataToUpsert)
            .eq('user_id', userId)
            .eq('exercise_id', exercise.id)
            .catchError((e) {
          if (kDebugMode) debugPrint('Error updating rating: $e');
        });
      } else {
        // Создаем новую запись
        if (kDebugMode) debugPrint('Creating new rating record');
        await _supabase
            .from('exercise_ratings')
            .insert(dataToUpsert)
            .catchError((e) {
          if (kDebugMode) debugPrint('Error inserting rating: $e');
        });
      }

      if (kDebugMode) {
        debugPrint('Rating updated successfully');
        debugPrint('===================');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error updating exercise rating: $e');
      // Логируем ошибку, но не пробрасываем ее выше
      // чтобы приложение могло продолжать работать
    }
  }

  /// Отметить упражнение как использованное
  Future<Exercise> markExerciseAsUsed(Exercise exercise) async {
    debugPrint('Marking exercise as used: ${exercise.name} (${exercise.id})');
    final updatedExercise = exercise.markAsUsed();
    debugPrint('New rating after usage: ${updatedExercise.currentRating}');

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Добавляем запись в историю использований
      await _supabase.from('exercise_history').insert({
        'user_id': userId,
        'exercise_id': exercise.id,
        'created_at': DateTime.now().toIso8601String(),
      }).catchError((e) {
        debugPrint('Error recording exercise history: $e');
      });

      await updateExerciseRating(updatedExercise);
    } catch (e) {
      debugPrint('Error marking exercise as used: $e');
      // Пропускаем ошибку, чтобы приложение продолжало работать
    }

    return updatedExercise;
  }

  /// Обновить предпочтение пользователя для упражнения
  Future<Exercise> updateUserPreference(
      Exercise exercise, int preference) async {
    debugPrint(
        'Updating user preference for exercise: ${exercise.name} (${exercise.id}) to $preference');
    final updatedExercise = exercise.updateUserPreference(preference);
    debugPrint(
        'New rating after preference update: ${updatedExercise.calculateCurrentRating()}');

    try {
      await updateExerciseRating(updatedExercise);
    } catch (e) {
      debugPrint('Error updating user preference: $e');
    }

    return updatedExercise;
  }

  /// Переключить статус избранного для упражнения
  Future<Exercise> toggleFavorite(Exercise exercise) async {
    final updatedExercise = exercise.toggleFavorite();

    try {
      await updateExerciseRating(updatedExercise);
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
    }

    return updatedExercise;
  }

  /// Еженедельный сброс рейтингов (вызывается периодически)
  Future<void> weeklyRatingReset() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Получаем все рейтинги для пользователя
      final ratings = await _supabase
          .from('exercise_ratings')
          .select()
          .eq('user_id', userId)
          .catchError((e) {
        debugPrint('Error getting ratings for reset: $e');
        return [];
      });

      // Обрабатываем каждый рейтинг
      for (final rating in ratings) {
        final exerciseId = rating['exercise_id'];

        // Частично сбрасываем временный негативный рейтинг за использование
        double baseRating = rating['base_rating'] ?? 50.0;

        // Сохраняем влияние пользовательских предпочтений (like/dislike)
        int userPreference = rating['user_preference'] ?? 0;
        double newRating = baseRating + (userPreference * 15.0);

        // Сохраняем влияние статуса избранного
        bool isFavorite = rating['is_favorite'] ?? false;
        if (isFavorite) {
          newRating += 20.0;
        }

        // Обновляем рейтинг в базе данных
        await _supabase
            .from('exercise_ratings')
            .update({
              'current_rating': newRating.clamp(1.0, 100.0),
              'last_updated': DateTime.now().toIso8601String(),
            })
            .eq('user_id', userId)
            .eq('exercise_id', exerciseId)
            .catchError((e) {
              debugPrint('Error updating rating during reset: $e');
            });
      }
    } catch (e) {
      debugPrint('Error resetting weekly ratings: $e');
    }
  }

  /// Получить отсортированный по рейтингу список упражнений, соответствующих фильтрам
  Future<List<Exercise>> getFilteredAndRankedExercises({
    String? muscleGroup,
    String? equipment,
    String? difficulty,
    int maxExercises = 8,
  }) async {
    try {
      // Получаем все упражнения с рейтингами
      final allExercises = await getExercisesWithRatings();

      // Применяем фильтры
      List<Exercise> filteredExercises = allExercises.where((exercise) {
        bool matchesMuscleGroup = muscleGroup == null ||
            exercise.muscleGroup
                .toLowerCase()
                .contains(muscleGroup.toLowerCase());

        bool matchesEquipment = equipment == null ||
            exercise.equipment.toLowerCase().contains(equipment.toLowerCase());

        bool matchesDifficulty = difficulty == null ||
            exercise.difficultyLevel.toLowerCase() == difficulty.toLowerCase();

        return matchesMuscleGroup && matchesEquipment && matchesDifficulty;
      }).toList();

      // Сортируем по текущему рейтингу (от высокого к низкому)
      filteredExercises.sort((a, b) =>
          b.calculateCurrentRating().compareTo(a.calculateCurrentRating()));

      // Возвращаем ограниченное количество упражнений
      return filteredExercises.take(maxExercises).toList();
    } catch (e) {
      debugPrint('Error getting filtered and ranked exercises: $e');
      return []; // Возвращаем пустой список вместо выброса исключения
    }
  }

  /// Получить персонализированные упражнения на основе рейтингов и профиля пользователя
  Future<List<Exercise>> getPersonalizedExercises({
    String? muscleGroup,
    String? equipment,
    String? difficulty,
    UserProfile? userProfile,
    int maxExercises = 8,
  }) async {
    try {
      final allExercises = await getExercisesWithRatings();

      // Базовая фильтрация как и раньше
      List<Exercise> filteredExercises = allExercises.where((exercise) {
        bool matchesMuscleGroup = muscleGroup == null ||
            exercise.muscleGroup
                .toLowerCase()
                .contains(muscleGroup.toLowerCase());

        bool matchesEquipment = equipment == null ||
            exercise.equipment.toLowerCase().contains(equipment.toLowerCase());

        bool matchesDifficulty = difficulty == null ||
            exercise.difficultyLevel.toLowerCase() == difficulty.toLowerCase();

        // Доп. проверка на соответствие уровню пользователя
        bool matchesUserLevel = true;
        if (userProfile != null) {
          // Новичкам не рекомендуем сложные упражнения
          if (userProfile.fitnessLevel?.toLowerCase() == 'beginner' &&
              exercise.difficultyLevel.toLowerCase() == 'advanced') {
            matchesUserLevel = false;
          }

          // Проверяем наличие травм и противопоказаний
          if (userProfile.injuries != null &&
              userProfile.injuries!.isNotEmpty) {
            for (var injury in userProfile.injuries!) {
              if (_isContraindicated(exercise, injury)) {
                matchesUserLevel = false;
                break;
              }
            }
          }
        }

        return matchesMuscleGroup &&
            matchesEquipment &&
            matchesDifficulty &&
            matchesUserLevel;
      }).toList();

      // Персонализированное ранжирование с учетом дополнительных факторов
      filteredExercises.sort((a, b) {
        double aScore = a.calculateCurrentRating();
        double bScore = b.calculateCurrentRating();

        // Применяем дополнительные персонализированные коэффициенты
        if (userProfile != null) {
          // 1. Предпочтение упражнений с оборудованием пользователя
          if (userProfile.equipment.contains(a.equipment)) {
            aScore += 5.0;
          }
          if (userProfile.equipment.contains(b.equipment)) {
            bScore += 5.0;
          }

          // 2. Учитываем фокусные группы мышц из целей пользователя
          if (userProfile.goals.any((goal) =>
              a.targetMuscleGroup.toLowerCase().contains(goal.toLowerCase()))) {
            aScore += 8.0;
          }
          if (userProfile.goals.any((goal) =>
              b.targetMuscleGroup.toLowerCase().contains(goal.toLowerCase()))) {
            bScore += 8.0;
          }
        }

        return bScore.compareTo(aScore);
      });

      return filteredExercises.take(maxExercises).toList();
    } catch (e) {
      debugPrint('Error getting personalized exercises: $e');
      return []; // Возвращаем пустой список вместо выброса исключения
    }
  }

  /// Проверяет, противопоказано ли упражнение при конкретной травме
  bool _isContraindicated(Exercise exercise, String injury) {
    // Простая логика определения противопоказаний на основе групп мышц и травм

    if (injury.toLowerCase().contains('knee') ||
        injury.toLowerCase().contains('колен')) {
      // Противопоказания для проблем с коленями
      return exercise.muscleGroup.toLowerCase() == 'legs' &&
          (exercise.name.toLowerCase().contains('squat') ||
              exercise.name.toLowerCase().contains('lunge'));
    }

    if (injury.toLowerCase().contains('back') ||
        injury.toLowerCase().contains('спин')) {
      // Противопоказания для проблем со спиной
      return exercise.muscleGroup.toLowerCase() == 'back' ||
          exercise.name.toLowerCase().contains('deadlift') ||
          exercise.name.toLowerCase().contains('мертвая тяга');
    }

    if (injury.toLowerCase().contains('shoulder') ||
        injury.toLowerCase().contains('плеч')) {
      // Противопоказания для проблем с плечами
      return exercise.muscleGroup.toLowerCase() == 'shoulders' ||
          exercise.name.toLowerCase().contains('overhead') ||
          exercise.name.toLowerCase().contains('press');
    }

    return false;
  }
}

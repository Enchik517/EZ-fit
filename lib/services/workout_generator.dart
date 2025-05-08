import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/workout.dart';
import '../models/exercise.dart';
import '../models/user_profile.dart';
import 'exercise_rating_service.dart';

/// Класс для генерации персонализированных тренировок на основе рейтингов упражнений
class WorkoutGenerator {
  final ExerciseRatingService _ratingService = ExerciseRatingService();
  final _uuid = Uuid();

  /// Создать персонализированную тренировку на основе рейтингов упражнений
  Future<Workout> generatePersonalizedWorkout({
    required UserProfile userProfile,
    required String focusArea,
    required String difficulty,
    int exerciseCount = 5,
    int duration = 45,
  }) async {
    debugPrint(
        'Generating personalized workout for ${userProfile.name}, focus: $focusArea');

    // Получаем информацию о тренировочной истории пользователя
    final workoutHistory = await _getRecentWorkoutHistory(userProfile.id);
    final recentlyUsedExercises = _extractRecentExercises(workoutHistory);

    // Получаем персонализированные упражнения для основной группы мышц
    // с учетом их рейтингов и тренировочной истории
    final mainExercises = await _ratingService.getPersonalizedExercises(
      muscleGroup: focusArea,
      difficulty: difficulty,
      userProfile: userProfile,
      maxExercises: exerciseCount + 3, // Запрашиваем с запасом для фильтрации
    );

    // Фильтруем упражнения, которые использовались недавно (разнообразие)
    final filteredMainExercises = _filterRecentlyUsedExercises(
      mainExercises,
      recentlyUsedExercises,
      maxRecent: 2, // Оставляем максимум 2 недавно использованных упражнения
    );

    // Берем нужное количество упражнений с наивысшим рейтингом
    final finalMainExercises =
        filteredMainExercises.take(exerciseCount).toList();

    // Добавляем дополнительные упражнения для комплексной тренировки
    final supplementaryMuscleGroups = _getSupplementaryMuscleGroups(focusArea);
    List<Exercise> supplementaryExercises = [];

    for (var muscleGroup in supplementaryMuscleGroups) {
      final exercises = await _ratingService.getPersonalizedExercises(
        muscleGroup: muscleGroup,
        difficulty: difficulty,
        userProfile: userProfile,
        maxExercises: 3, // Запрашиваем больше для лучшего выбора
      );

      // Фильтруем недавно использованные
      final filteredExercises = _filterRecentlyUsedExercises(
        exercises,
        recentlyUsedExercises,
        maxRecent:
            1, // Для дополнительных групп мышц строже ограничиваем повторы
      );

      supplementaryExercises.addAll(filteredExercises);
    }

    // Объединяем основные и дополнительные упражнения
    final allExercises = [...finalMainExercises];

    // Добавляем несколько дополнительных, чтобы разнообразить тренировку,
    // учитывая их рейтинги и совместимость
    if (supplementaryExercises.isNotEmpty) {
      // Сортируем дополнительные упражнения по рейтингу
      supplementaryExercises.sort((a, b) =>
          b.calculateCurrentRating().compareTo(a.calculateCurrentRating()));

      // Выбираем упражнения, которые хорошо сочетаются с основными
      final compatibleExercises = _selectCompatibleExercises(
          supplementaryExercises, finalMainExercises, userProfile);

      // Добавляем топ-2 совместимых упражнения
      allExercises.addAll(compatibleExercises.take(
          compatibleExercises.length < 2 ? compatibleExercises.length : 2));
    }

    // Оптимизируем порядок упражнений
    final optimizedExercises = _optimizeExerciseOrder(allExercises, focusArea);

    // Обновляем рейтинги и даты последнего использования
    await _updateExerciseUsage(optimizedExercises);

    // Создаем персонализированную тренировку
    return Workout(
      id: _uuid.v4(),
      name: '${userProfile.name}\'s ${_getFocusAreaName(focusArea)} Workout',
      description:
          'Персонализированная тренировка на ${_getFocusAreaName(focusArea)} с высокорейтинговыми упражнениями',
      exercises: optimizedExercises,
      duration: duration,
      difficulty: difficulty,
      equipment: _getUniqueEquipment(optimizedExercises),
      targetMuscles: _getUniqueMuscleGroups(optimizedExercises),
      focus: focusArea,
      isAIGenerated: true,
      createdAt: DateTime.now(),
    );
  }

  /// Получает недавнюю историю тренировок пользователя
  Future<List<Workout>> _getRecentWorkoutHistory(String userId) async {
    // Здесь должна быть логика получения истории тренировок из провайдера или сервиса
    // TODO: Реализовать получение истории тренировок из БД или провайдера
    return []; // Временно возвращаем пустой список
  }

  /// Извлекает недавно использованные упражнения из истории тренировок
  List<Exercise> _extractRecentExercises(List<Workout> workoutHistory) {
    final recentExercises = <Exercise>[];

    // Извлекаем упражнения из недавних тренировок
    for (var workout in workoutHistory) {
      recentExercises.addAll(workout.exercises);
    }

    return recentExercises;
  }

  /// Фильтрует недавно использованные упражнения, оставляя только необходимый минимум
  List<Exercise> _filterRecentlyUsedExercises(
      List<Exercise> exercises, List<Exercise> recentlyUsed,
      {int maxRecent = 1}) {
    // Если нет истории, возвращаем все упражнения
    if (recentlyUsed.isEmpty) return exercises;

    // Разделяем упражнения на недавно использованные и неиспользованные
    final recentIds = recentlyUsed.map((e) => e.id).toSet();
    final recent = <Exercise>[];
    final notRecent = <Exercise>[];

    for (var exercise in exercises) {
      if (recentIds.contains(exercise.id)) {
        recent.add(exercise);
      } else {
        notRecent.add(exercise);
      }
    }

    // Сортируем недавно использованные по рейтингу и берем только лучшие
    recent.sort((a, b) =>
        b.calculateCurrentRating().compareTo(a.calculateCurrentRating()));
    final selectedRecent = recent.take(maxRecent).toList();

    // Объединяем неиспользованные и выбранные недавние
    return [...notRecent, ...selectedRecent];
  }

  /// Выбирает упражнения, которые хорошо сочетаются с основными
  List<Exercise> _selectCompatibleExercises(List<Exercise> candidates,
      List<Exercise> mainExercises, UserProfile userProfile) {
    // Определяем оборудование, которое уже используется в основных упражнениях
    final mainEquipment = mainExercises.map((e) => e.equipment).toSet();

    // Приоритизируем упражнения, которые используют то же оборудование
    // и имеют высокий рейтинг
    candidates.sort((a, b) {
      int aEquipScore = mainEquipment.contains(a.equipment) ? 1 : 0;
      int bEquipScore = mainEquipment.contains(b.equipment) ? 1 : 0;

      if (aEquipScore != bEquipScore) {
        return bEquipScore -
            aEquipScore; // Сначала по совместимости оборудования
      }

      // Затем по рейтингу
      return b.calculateCurrentRating().compareTo(a.calculateCurrentRating());
    });

    return candidates;
  }

  /// Оптимизирует порядок упражнений для лучшей тренировки
  List<Exercise> _optimizeExerciseOrder(
      List<Exercise> exercises, String focusArea) {
    // Создаем копию списка, чтобы не изменять оригинал
    final result = List<Exercise>.from(exercises);

    // Сортируем упражнения: сначала основные для целевой группы мышц,
    // затем дополнительные
    result.sort((a, b) {
      // Проверяем, является ли упражнение основным для целевой группы
      bool aIsMain =
          a.muscleGroup.toLowerCase().contains(focusArea.toLowerCase());
      bool bIsMain =
          b.muscleGroup.toLowerCase().contains(focusArea.toLowerCase());

      if (aIsMain != bIsMain) {
        return aIsMain ? -1 : 1; // Основные упражнения в начале
      }

      // Для сложных упражнений - сначала те, что требуют больше энергии
      if (a.difficultyLevel != b.difficultyLevel) {
        final difficultyOrder = {
          'advanced': 0,
          'intermediate': 1,
          'beginner': 2
        };

        return (difficultyOrder[a.difficultyLevel.toLowerCase()] ?? 1)
            .compareTo(difficultyOrder[b.difficultyLevel.toLowerCase()] ?? 1);
      }

      return 0;
    });

    return result;
  }

  /// Обновляет информацию об использовании упражнений
  Future<void> _updateExerciseUsage(List<Exercise> exercises) async {
    // В реальном приложении здесь должно быть обновление в базе данных
    // или через ExerciseRatingService

    for (var exercise in exercises) {
      // Отмечаем упражнение как использованное
      await _ratingService.markExerciseAsUsed(exercise);
    }
  }

  /// Получить название основной группы мышц в более читаемом формате
  String _getFocusAreaName(String focusArea) {
    switch (focusArea.toLowerCase()) {
      case 'chest':
        return 'грудные мышцы';
      case 'back':
        return 'спину';
      case 'legs':
        return 'ноги';
      case 'shoulders':
        return 'плечи';
      case 'arms':
        return 'руки';
      case 'core':
        return 'кор';
      case 'fullbody':
      case 'full_body':
      case 'full body':
        return 'всё тело';
      default:
        return focusArea;
    }
  }

  /// Определить дополнительные группы мышц для комплексной тренировки
  List<String> _getSupplementaryMuscleGroups(String mainMuscleGroup) {
    // Логика определения дополнительных групп мышц
    switch (mainMuscleGroup.toLowerCase()) {
      case 'chest':
        return ['triceps', 'shoulders'];
      case 'back':
        return ['biceps', 'shoulders'];
      case 'legs':
        return ['core', 'glutes'];
      case 'shoulders':
        return ['triceps', 'upper_back'];
      case 'arms':
        return ['chest', 'back'];
      case 'core':
        return ['lower_back', 'abs'];
      default:
        return ['core'];
    }
  }

  /// Получить уникальное оборудование для тренировки
  List<String> _getUniqueEquipment(List<Exercise> exercises) {
    return exercises.map((e) => e.equipment).toSet().toList();
  }

  /// Получить уникальные группы мышц для тренировки
  List<String> _getUniqueMuscleGroups(List<Exercise> exercises) {
    return exercises.map((e) => e.targetMuscleGroup).toSet().toList();
  }
}

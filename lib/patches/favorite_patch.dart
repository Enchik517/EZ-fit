import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/workout.dart';
import '../models/exercise.dart';
import '../providers/workout_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

/// Класс для работы с избранными тренировками (не путать с избранными упражнениями!)
/// Избранные тренировки и избранные упражнения - это две отдельные функции
/// Тренировки добавляются в избранное целиком и сохраняются в таблице favorite_workouts
/// Упражнения имеют свой собственный статус isFavorite и сохраняются отдельно
class FavoritePatch {
  /// Универсальный метод для добавления тренировки в избранное
  /// Использует наиболее надежный подход с обработкой ошибок
  static Future<bool> addToFavorites(
      BuildContext context, Workout workout) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final workoutProvider =
        Provider.of<WorkoutProvider>(context, listen: false);

    if (kDebugMode)
      debugPrint('📌 Добавление тренировки в избранное: ${workout.name}');

    // Показываем индикатор прогресса
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 2,
            ),
            const SizedBox(width: 16),
            Text('Добавление "${workout.name}" в избранное...'),
          ],
        ),
        duration: const Duration(seconds: 1),
      ),
    );

    try {
      // Получаем ID пользователя
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Пользователь не авторизован');
      }

      if (kDebugMode) debugPrint('👤 Пользователь: $userId');

      // Создаем копию тренировки с флагом isFavorite = true
      final favoriteWorkout = workout.copyWith(isFavorite: true);

      // Проверяем, есть ли уже эта тренировка в избранном
      final existing = await Supabase.instance.client
          .from('favorite_workouts')
          .select()
          .eq('user_id', userId)
          .eq('workout_id', workout.id)
          .maybeSingle();

      if (existing != null) {
        if (kDebugMode) debugPrint('⚠️ Тренировка уже в избранном');
        // Уже в избранном, обновляем данные
        await Supabase.instance.client.from('favorite_workouts').update({
          'workout_data': favoriteWorkout.toJson(),
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', existing['id']);

        if (kDebugMode) debugPrint('✅ Данные в избранном обновлены');
      } else {
        // Добавляем в избранное
        await Supabase.instance.client.from('favorite_workouts').insert({
          'user_id': userId,
          'workout_id': workout.id,
          'workout_name': workout.name,
          'workout_data': favoriteWorkout.toJson(),
          'created_at': DateTime.now().toIso8601String(),
        });

        if (kDebugMode) debugPrint('✅ Тренировка добавлена в избранное');
      }

      // Также добавляем или обновляем запись в таблице workouts
      try {
        // Проверяем существует ли запись в workouts
        final workoutRecord = await Supabase.instance.client
            .from('workouts')
            .select()
            .eq('id', workout.id)
            .maybeSingle();

        if (workoutRecord != null) {
          // Обновляем статус в workouts
          await Supabase.instance.client
              .from('workouts')
              .update({'is_favorite': true}).eq('id', workout.id);

          if (kDebugMode) debugPrint('✅ Обновлен статус в таблице workouts');
        } else {
          // Создаем новую запись в workouts
          await Supabase.instance.client.from('workouts').insert({
            'id': workout.id,
            'user_id': userId,
            'name': workout.name,
            'description': workout.description,
            'difficulty': workout.difficulty,
            'equipment': workout.equipment,
            'target_muscles': workout.targetMuscles,
            'focus': workout.focus,
            'duration': workout.duration,
            'is_favorite': true,
            'created_at': DateTime.now().toIso8601String()
          });

          if (kDebugMode) debugPrint('✅ Создана запись в таблице workouts');
        }
      } catch (e) {
        if (kDebugMode) debugPrint('⚠️ Ошибка обновления таблицы workouts: $e');
        // Не критично, продолжаем
      }

      // Принудительно обновляем локальное состояние провайдера
      await workoutProvider.loadWorkouts();

      // Очень важно - принудительно обновляем список избранных тренировок
      final favorites = workoutProvider.getFavoriteWorkouts();
      if (kDebugMode)
        debugPrint(
            '📊 Количество избранных тренировок после обновления: ${favorites.length}');

      // Для отладки выводим все избранные тренировки
      if (kDebugMode) {
        for (var i = 0; i < favorites.length; i++) {
          debugPrint(
              '📌 Favorite #${i + 1}: ${favorites[i].name} (ID: ${favorites[i].id})');
        }
      }

      // Показываем уведомление об успехе
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('${workout.name} добавлена в избранное'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Ошибка добавления в избранное: $e');

      // Показываем ошибку
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Ошибка: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );

      return false;
    }
  }

  /// Универсальный метод для удаления тренировки из избранного
  static Future<bool> removeFromFavorites(
      BuildContext context, Workout workout) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final workoutProvider =
        Provider.of<WorkoutProvider>(context, listen: false);

    if (kDebugMode)
      debugPrint('🗑️ Удаление тренировки из избранного: ${workout.name}');

    // Показываем индикатор прогресса
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 2,
            ),
            const SizedBox(width: 16),
            Text('Удаление "${workout.name}" из избранного...'),
          ],
        ),
        duration: const Duration(seconds: 1),
      ),
    );

    try {
      // Получаем ID пользователя
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Пользователь не авторизован');
      }

      // Создаем копию тренировки с флагом isFavorite = false
      final notFavoriteWorkout = workout.copyWith(isFavorite: false);

      // Удаляем из избранного
      await Supabase.instance.client
          .from('favorite_workouts')
          .delete()
          .eq('user_id', userId)
          .eq('workout_id', workout.id);

      if (kDebugMode) debugPrint('✅ Тренировка удалена из избранного');

      // Также обновляем запись в таблице workouts
      try {
        await Supabase.instance.client
            .from('workouts')
            .update({'is_favorite': false})
            .eq('id', workout.id)
            .eq('user_id', userId);

        if (kDebugMode) debugPrint('✅ Обновлен статус в таблице workouts');
      } catch (e) {
        if (kDebugMode) debugPrint('⚠️ Ошибка обновления таблицы workouts: $e');
        // Не критично, продолжаем
      }

      // Принудительно обновляем локальное состояние провайдера
      await workoutProvider.loadWorkouts();

      // Очень важно - принудительно обновляем список избранных тренировок
      final favorites = workoutProvider.getFavoriteWorkouts();
      if (kDebugMode)
        debugPrint(
            '📊 Количество избранных тренировок после удаления: ${favorites.length}');

      // Показываем уведомление об успехе
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('${workout.name} удалена из избранного'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Ошибка удаления из избранного: $e');

      // Показываем ошибку
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Ошибка: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );

      return false;
    }
  }

  /// Переключение статуса избранного (универсальный метод)
  static Future<bool> toggleFavorite(
      BuildContext context, Workout workout) async {
    // Создаем копию с противоположным статусом для немедленного UI-обновления
    final isCurrentlyFavorite = workout.isFavorite;
    final localWorkoutProvider =
        Provider.of<WorkoutProvider>(context, listen: false);

    try {
      // 1. Немедленное обновление локального состояния для быстрой обратной связи
      final Workout localUpdatedWorkout = workout.toggleFavoriteStatus();

      // Принудительное обновление UI
      if (isCurrentlyFavorite) {
        if (kDebugMode) debugPrint('🔄 Локально удаляем из избранного...');
        // Удаляем из списка _customWorkouts немедленно
        localWorkoutProvider.notifyListeners();
      } else {
        if (kDebugMode) debugPrint('🔄 Локально добавляем в избранное...');
        // Локально добавляем в список _customWorkouts
        localWorkoutProvider.notifyListeners();
      }

      // 2. Выполняем фактическое обновление в базе данных
      if (isCurrentlyFavorite) {
        await removeFromFavorites(context, workout);
      } else {
        await addToFavorites(context, workout);
      }

      // 3. Принудительно перезагружаем данные с сервера, чтобы убедиться, что все синхронизировано
      if (kDebugMode) debugPrint('🔄 Синхронизация с сервером...');
      await localWorkoutProvider.loadWorkouts();

      // 4. Обновляем UI после получения данных с сервера
      localWorkoutProvider.notifyListeners();

      if (kDebugMode) {
        final updatedFavorites = localWorkoutProvider.getFavoriteWorkouts();
        debugPrint(
            '📊 Избранных тренировок после обновления: ${updatedFavorites.length}');
      }

      return true;
    } catch (e) {
      if (kDebugMode)
        debugPrint('❌ Ошибка переключения статуса избранного: $e');

      // В случае ошибки уведомляем пользователя
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Произошла ошибка: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );

      return false;
    }
  }

  /// Проверяет действительный статус избранного напрямую через Supabase
  /// Возвращает true, если тренировка находится в избранном
  static Future<bool> verifyFavoriteStatus(String workoutId) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        if (kDebugMode) debugPrint('❌ Нет доступного ID пользователя');
        return false;
      }

      if (kDebugMode)
        debugPrint(
            '🔍 Проверка статуса избранного для тренировки с ID: $workoutId');

      // Проверяем наличие в таблице favorite_workouts
      final existing = await Supabase.instance.client
          .from('favorite_workouts')
          .select('id')
          .eq('user_id', userId)
          .eq('workout_id', workoutId)
          .maybeSingle();

      final isFavorite = existing != null;

      if (kDebugMode) {
        if (isFavorite) {
          debugPrint('✅ Тренировка находится в избранном');
        } else {
          debugPrint('ℹ️ Тренировка не найдена в избранном');
        }
      }

      return isFavorite;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Ошибка проверки статуса избранного: $e');
      return false;
    }
  }

  /// Синхронизирует статус избранного между локальным списком и базой данных
  static Future<void> syncFavorites(BuildContext context) async {
    try {
      final workoutProvider =
          Provider.of<WorkoutProvider>(context, listen: false);

      if (kDebugMode) debugPrint('🔄 Синхронизация статуса избранного');

      // Перезагружаем список тренировок
      await workoutProvider.loadWorkouts();

      // Получаем обновленный список избранных тренировок
      final favorites = workoutProvider.getFavoriteWorkouts();

      if (kDebugMode)
        debugPrint('📊 Количество избранных тренировок: ${favorites.length}');

      // Обновляем UI
      workoutProvider.notifyListeners();
    } catch (e) {
      if (kDebugMode)
        debugPrint('❌ Ошибка синхронизации статуса избранного: $e');
    }
  }

  /// Принудительно исправляет проблемы с избранным
  static Future<void> fixFavorites(BuildContext context) async {
    try {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final workoutProvider =
          Provider.of<WorkoutProvider>(context, listen: false);

      // Показываем индикатор процесса
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 2,
              ),
              const SizedBox(width: 16),
              Text('Исправление списка избранного...'),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      if (kDebugMode) debugPrint('🛠️ Запуск исправления избранных тренировок');

      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Пользователь не авторизован');
      }

      // 1. Очищаем данные в таблице любимых тренировок для текущего пользователя
      await Supabase.instance.client
          .from('favorite_workouts')
          .delete()
          .eq('user_id', userId);

      if (kDebugMode) debugPrint('✅ Таблица favorite_workouts очищена');

      // 2. Получаем все тренировки с пометкой "избранное"
      final favoriteWorkoutsFromProvider =
          workoutProvider.workouts.where((w) => w.isFavorite).toList();

      if (kDebugMode)
        debugPrint(
            '📊 Найдено ${favoriteWorkoutsFromProvider.length} избранных тренировок в провайдере');

      // 3. Добавляем их заново в таблицу favorite_workouts
      for (final workout in favoriteWorkoutsFromProvider) {
        try {
          await Supabase.instance.client.from('favorite_workouts').insert({
            'user_id': userId,
            'workout_id': workout.id,
            'workout_name': workout.name,
            'workout_data': workout.copyWith(isFavorite: true).toJson(),
            'created_at': DateTime.now().toIso8601String(),
          });

          if (kDebugMode)
            debugPrint(
                '✅ Добавлена тренировка ${workout.name} (ID: ${workout.id})');
        } catch (e) {
          if (kDebugMode)
            debugPrint('❌ Ошибка добавления тренировки ${workout.name}: $e');
        }
      }

      // 4. Принудительное обновление данных
      await workoutProvider.loadWorkouts();

      if (kDebugMode)
        debugPrint(
            '🔄 Данные обновлены. Избранных: ${workoutProvider.getFavoriteWorkouts().length}');

      // Показываем уведомление об успехе
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Избранное успешно исправлено'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Ошибка исправления избранного: $e');

      // Показываем уведомление об ошибке
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Обнаруживает и добавляет скрытые избранные тренировки из базы данных
  static Future<void> discoverHiddenFavorites(BuildContext context) async {
    try {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final workoutProvider =
          Provider.of<WorkoutProvider>(context, listen: false);

      // Показываем индикатор процесса
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 2,
              ),
              const SizedBox(width: 16),
              Text('Обнаружение скрытых тренировок...'),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      if (kDebugMode) debugPrint('🔍 Поиск скрытых избранных тренировок');

      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Пользователь не авторизован');
      }

      // 1. Получаем все тренировки из favorite_workouts
      final favoritesInDB = await Supabase.instance.client
          .from('favorite_workouts')
          .select('workout_id, workout_name, workout_data')
          .eq('user_id', userId);

      if (kDebugMode)
        debugPrint(
            '📊 Найдено ${favoritesInDB.length} тренировок в БД favorite_workouts');

      if (favoritesInDB.isEmpty) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Нет записей о избранных тренировках в БД'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }

      // 2. Получаем текущие избранные тренировки из провайдера
      final currentFavorites = workoutProvider.getFavoriteWorkouts();
      final currentFavoriteIds = currentFavorites.map((w) => w.id).toSet();

      if (kDebugMode)
        debugPrint(
            '📊 Текущих избранных тренировок в провайдере: ${currentFavorites.length}');

      // 3. Находим ID тренировок, которые есть в БД, но нет в провайдере
      final missingFavoriteItems = favoritesInDB
          .where((item) => !currentFavoriteIds.contains(item['workout_id']))
          .toList();

      if (kDebugMode)
        debugPrint(
            '🔍 Найдено ${missingFavoriteItems.length} скрытых тренировок');

      if (missingFavoriteItems.isEmpty) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Скрытых тренировок не обнаружено'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }

      // 4. Добавляем скрытые тренировки в рабочие списки провайдера
      for (final item in missingFavoriteItems) {
        try {
          final workoutData = item['workout_data'] as Map<String, dynamic>;
          final workout = Workout.fromJson(workoutData);

          if (kDebugMode)
            debugPrint(
                '✅ Добавляем тренировку ${workout.name} (ID: ${workout.id})');

          // Также добавляем в таблицу workouts
          await Supabase.instance.client.from('workouts').upsert({
            'id': workout.id,
            'user_id': userId,
            'name': workout.name,
            'description': workout.description,
            'difficulty': workout.difficulty,
            'equipment': workout.equipment,
            'target_muscles': workout.targetMuscles,
            'focus': workout.focus,
            'duration': workout.duration,
            'is_favorite': true,
            'created_at': DateTime.now().toIso8601String()
          });
        } catch (e) {
          if (kDebugMode) debugPrint('❌ Ошибка добавления тренировки: $e');
        }
      }

      // 5. Принудительное обновление данных
      await workoutProvider.loadWorkouts();

      // Показываем уведомление об успехе
      final currentCount = workoutProvider.getFavoriteWorkouts().length;
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
              'Обнаружено ${missingFavoriteItems.length} тренировок. Теперь в избранном: $currentCount'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Ошибка обнаружения скрытых тренировок: $e');

      // Показываем уведомление об ошибке
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Создает тестовую тренировку, если список избранного пуст
  static Future<void> createTestWorkout(BuildContext context) async {
    try {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final workoutProvider =
          Provider.of<WorkoutProvider>(context, listen: false);

      if (kDebugMode) debugPrint('🧪 Создание тестовой тренировки');

      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Пользователь не авторизован');
      }

      if (kDebugMode) debugPrint('👤 Пользователь ID: $userId');

      // Проверяем существующие тренировки
      final existingCount = await Supabase.instance.client
          .from('workouts')
          .select('count')
          .eq('user_id', userId)
          .single();

      final count = existingCount['count'] as int? ?? 0;
      if (kDebugMode) debugPrint('📊 Существующих тренировок: $count');

      // Генерируем уникальный ID для тренировки
      final workoutId = '${DateTime.now().millisecondsSinceEpoch}-test';
      if (kDebugMode) debugPrint('🆔 ID новой тренировки: $workoutId');

      // Создаем простую тренировку для теста
      final testWorkout = Workout(
        id: workoutId,
        name: 'Тестовая тренировка',
        description: 'Тренировка для проверки работы избранного',
        exercises: [
          Exercise.basic(
            name: 'Отжимания',
            targetMuscleGroup: 'Грудь',
            equipment: 'Без оборудования',
            sets: '3',
            reps: '10',
            difficulty: 'Средний',
          ),
          Exercise.basic(
            name: 'Приседания',
            targetMuscleGroup: 'Ноги',
            equipment: 'Без оборудования',
            sets: '3',
            reps: '15',
            difficulty: 'Средний',
          ),
        ],
        duration: 20,
        difficulty: 'Средний',
        equipment: ['Без оборудования'],
        targetMuscles: ['Грудь', 'Ноги'],
        focus: 'Общее',
        isFavorite: true,
      );

      // Подготавливаем данные для workouts
      final workoutData = {
        'id': workoutId,
        'user_id': userId,
        'name': testWorkout.name,
        'description': testWorkout.description,
        'difficulty': testWorkout.difficulty,
        'equipment': testWorkout.equipment,
        'target_muscles': testWorkout.targetMuscles,
        'focus': testWorkout.focus,
        'duration': testWorkout.duration,
        'is_favorite': true,
        'exercises': testWorkout.exercises
            .map((e) => {
                  'name': e.name,
                  'targetMuscleGroup': e.targetMuscleGroup,
                  'equipment': e.equipment,
                  'sets': e.sets,
                  'reps': e.reps,
                  'difficulty': e.difficulty,
                })
            .toList(),
        'created_at': DateTime.now().toIso8601String()
      };

      // Подготавливаем данные для favorite_workouts
      final favoriteData = {
        'user_id': userId,
        'workout_id': workoutId,
        'workout_name': testWorkout.name,
        'workout_data': testWorkout.toJson(),
        'created_at': DateTime.now().toIso8601String(),
      };

      // Очищаем старые тестовые тренировки, если они есть
      if (kDebugMode) debugPrint('🧹 Удаление старых тестовых тренировок...');

      await Supabase.instance.client
          .from('favorite_workouts')
          .delete()
          .eq('user_id', userId)
          .like('workout_id', '%-test');

      await Supabase.instance.client
          .from('workouts')
          .delete()
          .eq('user_id', userId)
          .like('id', '%-test');

      if (kDebugMode) debugPrint('✅ Старые тестовые тренировки удалены');

      // Добавляем данные в БД
      if (kDebugMode) debugPrint('📝 Создание записи в workouts...');
      final workoutsResponse = await Supabase.instance.client
          .from('workouts')
          .insert(workoutData)
          .select();

      if (kDebugMode) debugPrint('📝 Ответ workouts: $workoutsResponse');

      if (kDebugMode) debugPrint('📝 Создание записи в favorite_workouts...');
      final favoritesResponse = await Supabase.instance.client
          .from('favorite_workouts')
          .insert(favoriteData)
          .select();

      if (kDebugMode)
        debugPrint('📝 Ответ favorite_workouts: $favoritesResponse');

      if (kDebugMode) debugPrint('✅ Тестовая тренировка создана успешно');

      // Принудительно обновляем данные
      await workoutProvider.loadWorkouts();
      workoutProvider.notifyListeners();

      // Делаем дополнительную проверку
      final checkFavorites = await Supabase.instance.client
          .from('favorite_workouts')
          .select('count')
          .eq('user_id', userId)
          .single();

      final favoritesCount = checkFavorites['count'] as int? ?? 0;
      if (kDebugMode)
        debugPrint(
            '📊 Проверка: избранных тренировок после создания: $favoritesCount');

      // Показываем уведомление только если есть UI
      if (context.mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Тестовая тренировка создана ($favoritesCount)'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Ошибка создания тестовой тренировки: $e');

      // Показываем ошибку только если есть UI
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}

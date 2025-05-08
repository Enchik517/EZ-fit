import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../providers/workout_provider.dart';
import '../models/workout.dart';

/// This extension adds debug logging and improved error handling to the WorkoutProvider
extension WorkoutProviderPatch on WorkoutProvider {
  /// Patched method to save workout to history with extra logging and error handling
  Future<bool> saveWorkoutToHistoryWithLogging(Workout workout) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        if (kDebugMode)
          debugPrint('No user ID available for saving workout to history');
        return false;
      }

      // Log the attempt
      if (kDebugMode)
        debugPrint('Attempting to save workout to history: ${workout.name}');

      // Check if workout already exists in history
      final existing = await Supabase.instance.client
          .from('workout_history')
          .select()
          .eq('user_id', userId)
          .eq('workout_id', workout.id)
          .maybeSingle();

      if (existing != null) {
        if (kDebugMode)
          debugPrint('Workout already exists in history: ${workout.id}');
        return true;
      }

      // Format the data for insert
      final data = {
        'user_id': userId,
        'workout_id': workout.id,
        'workout_name': workout.name,
        'created_at': DateTime.now().toIso8601String(),
      };

      // Insert into history
      await Supabase.instance.client.from('workout_history').insert(data);

      if (kDebugMode)
        debugPrint('Workout saved to history successfully: ${workout.name}');
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('Error saving workout to history: $e');
      return false;
    }
  }

  /// Patched method to toggle favorite status with extra logging and error handling
  Future<bool> toggleFavoriteWithLogging(Workout workout) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        if (kDebugMode)
          debugPrint('❌ No user ID available for toggling favorite');
        return false;
      }

      if (kDebugMode)
        debugPrint(
            '🔄 toggleFavoriteWithLogging для тренировки: ${workout.name}, ID: ${workout.id}');

      // Проверяем, существует ли тренировка в избранном
      try {
        // Check current favorite status
        final existing = await Supabase.instance.client
            .from('favorite_workouts')
            .select()
            .eq('user_id', userId)
            .eq('workout_id', workout.id)
            .maybeSingle();

        // Log the attempt
        if (kDebugMode)
          debugPrint(
              '🔍 Current favorite status for workout: ${workout.name}, status: ${existing != null ? 'favorite' : 'not favorite'}');

        if (existing != null) {
          // Уже в избранном, удаляем
          if (kDebugMode) debugPrint('🗑️ Removing from favorites...');

          await Supabase.instance.client
              .from('favorite_workouts')
              .delete()
              .eq('id', existing['id']);

          // Также обновляем статус в таблице workouts, если она существует
          try {
            final workoutExists = await Supabase.instance.client
                .from('workouts')
                .select('id')
                .eq('id', workout.id)
                .maybeSingle();

            if (workoutExists != null) {
              await Supabase.instance.client
                  .from('workouts')
                  .update({'is_favorite': false}).eq('id', workout.id);
              if (kDebugMode)
                debugPrint('✅ Updated workout status in workouts table');
            }
          } catch (e) {
            if (kDebugMode) debugPrint('⚠️ Error updating workouts table: $e');
            // Не критично, продолжаем
          }

          if (kDebugMode)
            debugPrint('✅ Workout removed from favorites: ${workout.name}');

          // Принудительное обновление списка избранного в провайдере
          await loadWorkouts();

          return false; // Больше не в избранном
        } else {
          // Не в избранном, добавляем
          if (kDebugMode) debugPrint('➕ Adding to favorites...');

          // Создаем полную копию тренировки со всеми данными
          final workoutData = workout.copyWith(isFavorite: true).toJson();

          // Добавляем в избранное
          await Supabase.instance.client.from('favorite_workouts').insert({
            'user_id': userId,
            'workout_id': workout.id,
            'workout_name': workout.name,
            'workout_data': workoutData,
            'created_at': DateTime.now().toIso8601String(),
          });

          // Также обновляем статус в таблице workouts, если она существует
          try {
            final workoutExists = await Supabase.instance.client
                .from('workouts')
                .select('id')
                .eq('id', workout.id)
                .maybeSingle();

            if (workoutExists != null) {
              await Supabase.instance.client
                  .from('workouts')
                  .update({'is_favorite': true}).eq('id', workout.id);
              if (kDebugMode)
                debugPrint('✅ Updated workout status in workouts table');
            } else {
              // Если тренировки нет в таблице workouts, добавляем её
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
              if (kDebugMode) debugPrint('✅ Added workout to workouts table');
            }
          } catch (e) {
            if (kDebugMode) debugPrint('⚠️ Error updating workouts table: $e');
            // Не критично, продолжаем
          }

          if (kDebugMode)
            debugPrint('✅ Workout added to favorites: ${workout.name}');

          // Принудительное обновление списка избранного в провайдере
          await loadWorkouts();

          return true; // Теперь в избранном
        }
      } catch (e) {
        if (kDebugMode)
          debugPrint('❌ Error checking favorite status in database: $e');

        // Если возникла ошибка при проверке, пробуем принудительно добавить
        if (kDebugMode)
          debugPrint('🔄 Attempting to force add to favorites...');

        try {
          // Проверяем, есть ли уже в избранном (исключаем дубликаты)
          final existing = await Supabase.instance.client
              .from('favorite_workouts')
              .select('id')
              .eq('workout_id', workout.id)
              .eq('user_id', userId);

          if (existing != null && (existing as List).isNotEmpty) {
            if (kDebugMode)
              debugPrint('⚠️ Workout already in favorites, skipping');
            return true;
          }

          // Создаем полную копию тренировки со всеми данными
          final workoutData = workout.copyWith(isFavorite: true).toJson();

          // Добавляем в избранное
          await Supabase.instance.client.from('favorite_workouts').insert({
            'user_id': userId,
            'workout_id': workout.id,
            'workout_name': workout.name,
            'workout_data': workoutData,
            'created_at': DateTime.now().toIso8601String(),
          });

          if (kDebugMode)
            debugPrint('✅ Workout force-added to favorites: ${workout.name}');

          // Принудительное обновление списка избранного в провайдере
          await loadWorkouts();

          return true;
        } catch (forceError) {
          if (kDebugMode)
            debugPrint('❌ Error force-adding to favorites: $forceError');
          return false;
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error toggling favorite status: $e');
      return false;
    }
  }

  /// Verify that workout data is stored correctly
  Future<Map<String, dynamic>> verifyWorkoutData() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        return {'success': false, 'error': 'No user ID available'};
      }

      // Check workout history
      final historyResponse = await Supabase.instance.client
          .from('workout_history')
          .select('count')
          .eq('user_id', userId)
          .single();

      final historyCount = historyResponse['count'] as int? ?? 0;

      // Check favorites
      final favoritesResponse = await Supabase.instance.client
          .from('favorite_workouts')
          .select('count')
          .eq('user_id', userId)
          .single();

      final favoritesCount = favoritesResponse['count'] as int? ?? 0;

      // Log the counts
      debugPrint('History: $historyCount, Favorites: $favoritesCount');

      return {
        'success': true,
        'history_count': historyCount,
        'favorites_count': favoritesCount,
      };
    } catch (e) {
      debugPrint('Failed to verify workout data: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Forward to WorkoutProvider.loadWorkouts
  Future<void> reloadWorkouts() async {
    try {
      if (kDebugMode)
        debugPrint('🔄 Принудительное обновление списка тренировок');
      await loadWorkouts();
      if (kDebugMode) debugPrint('✅ Список тренировок обновлен');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Ошибка обновления списка тренировок: $e');
    }
  }
}

/// Widget to add to the app that provides a debugging overlay
class WorkoutDebugOverlay extends StatelessWidget {
  final Widget child;

  const WorkoutDebugOverlay({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            heroTag: 'workout_debug',
            mini: true,
            backgroundColor: Colors.black45,
            child: const Icon(Icons.bug_report, color: Colors.white),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => WorkoutDiagnosticsScreen(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Diagnostics screen (imported from the main file)
class WorkoutDiagnosticsScreen extends StatelessWidget {
  const WorkoutDiagnosticsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Diagnostics'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/workout-diagnostics');
          },
          child: const Text('Open Full Diagnostics'),
        ),
      ),
    );
  }
}

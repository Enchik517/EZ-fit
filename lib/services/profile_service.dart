import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';
import 'dart:convert';

class ProfileService {
  final _supabase = Supabase.instance.client;

  Future<bool> hasCompletedSurvey() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final response = await _supabase
          .from('user_profiles')
          .select('has_completed_survey')
          .eq('id', userId)
          .maybeSingle();

      return response != null && response['has_completed_survey'] == true;
    } catch (e) {
      debugPrint('Ошибка при проверке наличия опроса: $e');
      return false;
    }
  }

  Future<UserProfile?> getProfile({required String userId}) async {
    try {
      final response = await _supabase
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) {
        debugPrint('Профиль не найден для пользователя: $userId');
        return null;
      }

      return UserProfile.fromJson(response);
    } catch (e) {
      debugPrint('Ошибка при получении профиля: $e');
      return null;
    }
  }

  Future<void> createProfile(UserProfile profile) async {
    try {
      await _supabase.from('user_profiles').insert(profile.toJson());
    } catch (e) {
      debugPrint('Ошибка при создании профиля: $e');
      rethrow;
    }
  }

  Future<void> updateProfile(UserProfile profile) async {
    try {
      await _supabase
          .from('user_profiles')
          .update(profile.toJson())
          .eq('id', profile.id);
    } catch (e) {
      debugPrint('Ошибка при обновлении профиля: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateProfileWithAI(
      UserProfile profile, String updateRequest) async {
    try {
      final response = await _supabase.functions.invoke(
        'chat',
        body: {
          'action': 'profile_update',
          'profile': profile.toJson(),
          'message': updateRequest,
        },
      );

      if (response.status != 200) {
        throw Exception('Failed to get AI recommendations');
      }

      final aiResponse = jsonDecode(response.data['message']);
      return aiResponse;
    } catch (e) {
      debugPrint('Ошибка при обновлении профиля с AI: $e');
      return {'error': 'Не удалось получить рекомендации'};
    }
  }

  Future<Map<String, dynamic>> adaptWorkoutWithAI(
      UserProfile profile, Map<String, dynamic> workout) async {
    try {
      final response = await _supabase.functions.invoke(
        'chat',
        body: {
          'action': 'adapt_workout',
          'profile': profile.toJson(),
          'workout': workout,
        },
      );

      if (response.status != 200) {
        throw Exception('Failed to adapt workout');
      }

      final aiResponse = jsonDecode(response.data['message']);
      return aiResponse['adaptedWorkout'];
    } catch (e) {
      debugPrint('Ошибка при адаптации тренировки с AI: $e');
      return {'error': 'Не удалось адаптировать тренировку'};
    }
  }

  Future<Map<String, dynamic>> updateProfileWithRecommendations(
    UserProfile profile,
    String updateRequest,
  ) async {
    try {
      // Get AI recommendations
      final aiRecommendations =
          await updateProfileWithAI(profile, updateRequest);

      // Update profile with safety considerations
      final injuries = profile.injuries ?? [];
      if (aiRecommendations['recommendations']['exercisesToAvoid'] != null) {
        injuries.addAll(List<String>.from(
            aiRecommendations['recommendations']['exercisesToAvoid']));
      }

      // Create updated profile
      final updatedProfile = profile.copyWith(
        injuries: injuries,
      );

      // Save to database
      await updateProfile(updatedProfile);

      // Return recommendations for UI display
      return aiRecommendations;
    } catch (e) {
      debugPrint('Ошибка при обновлении профиля с рекомендациями: $e');
      return {'error': 'Не удалось обновить профиль с рекомендациями'};
    }
  }

  Future<void> updateWorkoutStats({
    required String userId,
    required int addSets,
    required double addHours,
  }) async {
    try {
      final now = DateTime.now();
      final profile = await getProfile(userId: userId);

      if (profile == null) return;

      // Проверяем streak
      int newStreak = profile.workoutStreak;
      if (profile.lastWorkoutDate != null) {
        final difference = now.difference(profile.lastWorkoutDate!).inDays;
        if (difference <= 1) {
          // Если тренировка была вчера или сегодня, увеличиваем streak
          newStreak++;
        } else {
          // Если был пропуск, начинаем streak заново
          newStreak = 1;
        }
      } else {
        // Первая тренировка
        newStreak = 1;
      }

      await _supabase.from('user_profiles').update({
        'total_workouts': profile.totalWorkouts + 1,
        'total_sets': profile.totalSets + addSets,
        'total_hours': profile.totalHours + addHours,
        'workout_streak': newStreak,
        'last_workout_date': now.toIso8601String(),
      }).eq('id', userId);
    } catch (e) {
      //      rethrow;
    }
  }
}

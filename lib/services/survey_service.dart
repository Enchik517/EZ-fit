import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/survey_state.dart';

class SurveyData {
  final List<String>? selectedGoals;
  final int? weeklyWorkouts;
  final int? workoutDuration;
  final String? fitnessLevel;
  final List<String>? injuries;
  final int? age;
  final String? gender;
  final List<String>? selectedEquipment;

  SurveyData({
    this.selectedGoals,
    this.weeklyWorkouts,
    this.workoutDuration,
    this.fitnessLevel,
    this.injuries,
    this.age,
    this.gender,
    this.selectedEquipment,
  });

  factory SurveyData.fromJson(Map<String, dynamic> json) {
    return SurveyData(
      selectedGoals: json['selected_goals']?.cast<String>(),
      weeklyWorkouts: json['weekly_workouts'] is String
          ? int.tryParse(json['weekly_workouts'])
          : json['weekly_workouts'],
      workoutDuration: json['workout_duration'] is String
          ? int.tryParse(json['workout_duration'])
          : json['workout_duration'],
      fitnessLevel: json['fitness_level'],
      injuries: json['injuries']?.cast<String>(),
      age: json['age'] is String ? int.tryParse(json['age']) : json['age'],
      gender: json['gender'],
      selectedEquipment: json['selected_equipment']?.cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'selected_goals': selectedGoals,
      'weekly_workouts': weeklyWorkouts,
      'workout_duration': workoutDuration,
      'fitness_level': fitnessLevel,
      'injuries': injuries,
      'age': age,
      'gender': gender,
      'selected_equipment': selectedEquipment,
    };
  }
}

class SurveyService {
  final supabase = Supabase.instance.client;

  Future<bool> checkSurveyCompletion(String? userId) async {
    if (userId == null) return false;

    try {
      final response = await supabase
          .from('user_surveys')
          .select()
          .eq('user_id', userId)
          .single();
      return response != null;
    } catch (e) {
      return false;
    }
  }

  Future<void> saveSurvey(String userId, SurveyState survey) async {
    await supabase.from('user_surveys').upsert({
      'user_id': userId,
      'survey_data': survey.toJson(),
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id');
  }

  Future<Map<String, dynamic>?> getSurveyData(String userId) async {
    final response = await supabase
        .from('user_surveys')
        .select()
        .eq('user_id', userId)
        .single();
    return response;
  }

  Future<void> updateSurveyData(
      String userId, Map<String, dynamic> data) async {
    try {
      final currentData = await getSurveyData(userId);
      final updatedData = currentData ?? {};
      updatedData.addAll(data);

      await supabase
          .from('user_surveys')
          .update({'survey_data': updatedData}).eq('user_id', userId);
    } catch (e) {
      print('Error updating survey data: $e');
    }
  }

  Future<void> saveSurveyData({
    required String userId,
    required Map<String, dynamic> data,
    required List<String> selectedGoals,
    required int? weeklyWorkouts,
  }) async {
    await supabase.from('user_surveys').upsert({
      'user_id': userId,
      'survey_data': data,
      'selected_goals': selectedGoals,
      'weekly_workouts': weeklyWorkouts,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
}

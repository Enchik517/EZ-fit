import 'package:flutter/foundation.dart';
import '../models/survey_state.dart';
import '../services/survey_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

class SurveyData {
  String? sex;
  DateTime? birthDate;
  double? heightCm;
  double? weightKg;
  String? bodyFatRange;
  String? workoutFrequency;
  String? mainGoal;
  double? targetWeightKg;
  String? targetWeightRate;
  String? targetBodyFat;
  Set<String> injuries;
  String? injuryNotes;
  Set<String> focusAreas;

  SurveyData({
    this.sex,
    this.birthDate,
    this.heightCm,
    this.weightKg,
    this.bodyFatRange,
    this.workoutFrequency,
    this.mainGoal,
    this.targetWeightKg,
    this.targetWeightRate,
    this.targetBodyFat,
    this.injuries = const {},
    this.injuryNotes,
    this.focusAreas = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'sex': sex,
      'birthDate': birthDate?.toIso8601String(),
      'heightCm': heightCm,
      'weightKg': weightKg,
      'bodyFatRange': bodyFatRange,
      'workoutFrequency': workoutFrequency,
      'mainGoal': mainGoal,
      'targetWeightKg': targetWeightKg,
      'targetWeightRate': targetWeightRate,
      'targetBodyFat': targetBodyFat,
      'injuries': injuries.toList(),
      'injuryNotes': injuryNotes,
      'focusAreas': focusAreas.toList(),
    };
  }

  factory SurveyData.fromJson(Map<String, dynamic> json) {
    return SurveyData(
      sex: json['sex'],
      birthDate:
          json['birthDate'] != null ? DateTime.parse(json['birthDate']) : null,
      heightCm: json['heightCm'],
      weightKg: json['weightKg'],
      bodyFatRange: json['bodyFatRange'],
      workoutFrequency: json['workoutFrequency'],
      mainGoal: json['mainGoal'],
      targetWeightKg: json['targetWeightKg'],
      targetWeightRate: json['targetWeightRate'],
      targetBodyFat: json['targetBodyFat'],
      injuries: Set<String>.from(json['injuries'] ?? []),
      injuryNotes: json['injuryNotes'],
      focusAreas: Set<String>.from(json['focusAreas'] ?? []),
    );
  }
}

class SurveyProvider extends ChangeNotifier {
  final SurveyService? _surveyService;
  SurveyState _state = SurveyState();
  bool _isLoading = false;
  SurveyData _data = SurveyData();

  SurveyProvider([this._surveyService]);

  SurveyState get state => _state;
  bool get isLoading => _isLoading;
  SurveyData get data => _data;

  bool get isDevAccount {
    final email = Supabase.instance.client.auth.currentUser?.email;
    return email == 'test@dev.com';
  }

  void updateState(SurveyState newState) {
    _state = newState;
    notifyListeners();
  }

  Future<void> loadSurveyData(String userId) async {
    if (_surveyService == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final Map<String, dynamic>? surveyData =
          await _surveyService!.getSurveyData(userId);
      if (surveyData != null) {
        // Получаем данные из survey_data или используем пустой объект
        final surveyDataObj =
            surveyData['survey_data'] as Map<String, dynamic>? ?? {};

        _state = SurveyState(
          age: surveyDataObj['age'] as int?,
          gender: surveyDataObj['gender'] as String?,
          fitnessLevel: surveyDataObj['fitness_level'] as String?,
          selectedGoals:
              List<String>.from(surveyDataObj['selected_goals'] ?? []),
          selectedEquipment:
              List<String>.from(surveyDataObj['selected_equipment'] ?? []),
          weeklyWorkouts: surveyDataObj['weekly_workouts'] as int?,
          workoutDuration: surveyDataObj['workout_duration'] as int?,
          injuries: List<String>.from(surveyDataObj['injuries'] ?? []),
        );

        // Загружаем данные в _data если они есть
        if (surveyDataObj.isNotEmpty) {
          _data = SurveyData.fromJson(surveyDataObj);
        }
      }
    } catch (e) {
      //    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateAge(int? age) {
    _state.age = age;
    notifyListeners();
  }

  void updateGender(String gender) {
    _state.gender = gender;
    notifyListeners();
  }

  void updateFitnessLevel(String level) {
    _state.fitnessLevel = level;
    notifyListeners();
  }

  void toggleGoal(String goal) {
    _state.selectedGoals ??= [];
    if (_state.selectedGoals!.contains(goal)) {
      _state.selectedGoals!.remove(goal);
    } else {
      _state.selectedGoals!.add(goal);
    }
    notifyListeners();
  }

  void toggleEquipment(String equipment) {
    _state.selectedEquipment ??= [];
    if (equipment == 'None') {
      _state.selectedEquipment!.clear();
      _state.selectedEquipment!.add(equipment);
    } else {
      _state.selectedEquipment!.remove('None');
      if (_state.selectedEquipment!.contains(equipment)) {
        _state.selectedEquipment!.remove(equipment);
      } else {
        _state.selectedEquipment!.add(equipment);
      }
    }
    notifyListeners();
  }

  void updateWeeklyWorkouts(int count) {
    _state.weeklyWorkouts = count;
    notifyListeners();
  }

  void updateWorkoutDuration(int duration) {
    _state.workoutDuration = duration;
    notifyListeners();
  }

  void updatePreferredTime(String time) {
    _state.preferredTime = time;
    notifyListeners();
  }

  void updateGymAccess(bool hasAccess) {
    _state.hasGymAccess = hasAccess;
    notifyListeners();
  }

  void clearGoals() {
    _state.selectedGoals ??= [];
    _state.selectedGoals!.clear();
    notifyListeners();
  }

  void clearEquipment() {
    _state.selectedEquipment ??= [];
    _state.selectedEquipment!.clear();
    notifyListeners();
  }

  bool get canProceed => _state.isComplete;

  void setInjuries(List<String> injuries) {
    _state.injuries = injuries;
    notifyListeners();
  }

  void clearSurvey() {
    _state = SurveyState(
      selectedGoals: [],
      selectedEquipment: [],
      injuries: [],
    );
    notifyListeners();
  }

  // Новые методы для работы с SurveyData
  void updateSex(String sex) {
    _data.sex = sex;
    notifyListeners();
  }

  void updateBirthDate(DateTime date) {
    _data.birthDate = date;
    notifyListeners();
  }

  void updateHeightCm(double heightCm) {
    _data.heightCm = heightCm;
    notifyListeners();
  }

  void updateWeightKg(double weightKg) {
    _data.weightKg = weightKg;
    notifyListeners();
  }

  void updateBodyFatRange(String range) {
    _data.bodyFatRange = range;
    notifyListeners();
  }

  void updateWorkoutFrequency(String frequency) {
    _data.workoutFrequency = frequency;
    notifyListeners();
  }

  void updateMainGoal(String goal) {
    _data.mainGoal = goal;
    notifyListeners();
  }

  void updateTargetWeight(double weightKg) {
    _data.targetWeightKg = weightKg;
    notifyListeners();
  }

  void updateTargetWeightRate(String rate) {
    _data.targetWeightRate = rate;
    notifyListeners();
  }

  void updateTargetBodyFat(String bodyFat) {
    _data.targetBodyFat = bodyFat;
    notifyListeners();
  }

  void toggleInjury(String injury) {
    if (_data.injuries.contains(injury)) {
      _data.injuries.remove(injury);
    } else {
      _data.injuries.add(injury);
    }
    notifyListeners();
  }

  void updateInjuryNotes(String notes) {
    _data.injuryNotes = notes;
    notifyListeners();
  }

  void toggleFocusArea(String area) {
    if (_data.focusAreas.contains(area)) {
      _data.focusAreas.remove(area);
    } else if (_data.focusAreas.length < 3) {
      _data.focusAreas.add(area);
    }
    notifyListeners();
  }

  Future<void> saveSurveyData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;

      if (_surveyService == null || userId == null) {
        // Сохраняем локально или в SharedPreferences если нужно
        //        return;
      }

      await _surveyService!.saveSurveyData(
        userId: userId!,
        data: _data.toJson(),
        selectedGoals: _state.selectedGoals ?? [],
        weeklyWorkouts: _state.weeklyWorkouts ?? 0,
      );

      clearSurvey();
    } catch (e) {
      //      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

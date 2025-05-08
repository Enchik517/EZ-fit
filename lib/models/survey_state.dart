class SurveyState {
  int? age;
  String? gender;
  double? weight;
  double? height;
  String? fitnessLevel;
  List<String>? selectedGoals;
  List<String>? selectedEquipment;
  int? weeklyWorkouts;
  int? workoutDuration;
  List<String>? injuries;
  String? preferredTime;
  bool? hasGymAccess;

  SurveyState({
    this.age,
    this.gender,
    this.weight,
    this.height,
    this.fitnessLevel,
    this.selectedGoals,
    this.selectedEquipment,
    this.weeklyWorkouts,
    this.workoutDuration,
    this.injuries,
    this.preferredTime,
    this.hasGymAccess,
  });

  factory SurveyState.fromJson(Map<String, dynamic> json) {
    return SurveyState(
      age: json['age'] as int?,
      gender: json['gender'] as String?,
      weight: (json['weight'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
      fitnessLevel: json['fitnessLevel'] as String?,
      selectedGoals: (json['selectedGoals'] as List<dynamic>?)?.map((e) => e as String).toList(),
      selectedEquipment: (json['selectedEquipment'] as List<dynamic>?)?.map((e) => e as String).toList(),
      weeklyWorkouts: json['weeklyWorkouts'] as int?,
      workoutDuration: json['workoutDuration'] as int?,
      injuries: (json['injuries'] as List<dynamic>?)?.map((e) => e as String).toList(),
      preferredTime: json['preferredTime'] as String?,
      hasGymAccess: json['hasGymAccess'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'age': age,
      'gender': gender,
      'weight': weight,
      'height': height,
      'fitnessLevel': fitnessLevel,
      'selectedGoals': selectedGoals,
      'selectedEquipment': selectedEquipment,
      'weeklyWorkouts': weeklyWorkouts,
      'workoutDuration': workoutDuration,
      'injuries': injuries,
      'preferredTime': preferredTime,
      'hasGymAccess': hasGymAccess,
    };
  }

  bool get isComplete {
    return age != null &&
        gender != null &&
        weight != null &&
        height != null &&
        fitnessLevel != null &&
        selectedGoals?.isNotEmpty == true &&
        selectedEquipment?.isNotEmpty == true &&
        weeklyWorkouts != null &&
        workoutDuration != null &&
        preferredTime != null &&
        hasGymAccess != null;
  }
} 
class UserSurvey {
  final int age;
  final String gender;
  final double weight;
  final double height;
  final String fitnessLevel; // beginner, intermediate, advanced
  final List<String> fitnessGoals;
  final List<String> availableEquipment;
  final int weeklyWorkouts;
  final int workoutDuration;
  final List<String> injuries;
  final String preferredTime;
  final bool hasGymAccess;

  UserSurvey({
    this.age = 0,
    this.gender = '',
    this.weight = 0,
    this.height = 0,
    this.fitnessLevel = 'beginner',
    this.fitnessGoals = const [],
    this.availableEquipment = const [],
    this.weeklyWorkouts = 3,
    this.workoutDuration = 45,
    this.injuries = const [],
    this.preferredTime = 'morning',
    this.hasGymAccess = false,
  });

  Map<String, dynamic> toJson() => {
    'age': age,
    'gender': gender,
    'weight': weight,
    'height': height,
    'fitnessLevel': fitnessLevel,
    'fitnessGoals': fitnessGoals,
    'availableEquipment': availableEquipment,
    'weeklyWorkouts': weeklyWorkouts,
    'workoutDuration': workoutDuration,
    'injuries': injuries,
    'preferredTime': preferredTime,
    'hasGymAccess': hasGymAccess,
  };
} 
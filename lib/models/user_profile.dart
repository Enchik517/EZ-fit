class UserProfile {
  final String id;
  final String? username;
  final String? email;
  final String? name;
  final String? fullName;
  final DateTime birthDate;
  final double? weight;
  final double? height;
  final String? gender;
  final String? fitnessLevel;
  final List<String> goals;
  final List<String> preferredWorkoutTypes;
  final List<String> equipment;
  final List<String>? injuries;
  final int workoutDaysPerWeek;
  final String weeklyWorkouts;
  final String workoutDuration;
  final int workoutStreak;
  final int streakCount;
  final int totalWorkouts;
  final int totalSets;
  final double totalHours;
  final DateTime? lastWorkoutDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool hasCompletedSurvey;
  final bool syncWithHealth;
  final String? notes;
  final String? avatarUrl;
  final String? themePreference;
  final String? languagePreference;
  final String? subscriptionType;
  final DateTime? subscriptionExpireDate;
  final int totalWorkoutsCompleted;
  final int totalWorkoutDuration;
  final DateTime? lastActive;

  UserProfile({
    required this.id,
    this.username,
    this.email,
    this.name,
    this.fullName,
    required this.birthDate,
    this.weight,
    this.height,
    this.gender,
    this.fitnessLevel,
    List<String>? goals,
    List<String>? preferredWorkoutTypes,
    List<String>? equipment,
    this.injuries,
    this.workoutDaysPerWeek = 3,
    this.weeklyWorkouts = '',
    this.workoutDuration = '',
    this.workoutStreak = 0,
    this.streakCount = 0,
    this.totalWorkouts = 0,
    this.totalSets = 0,
    this.totalHours = 0,
    this.lastWorkoutDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.hasCompletedSurvey = false,
    this.syncWithHealth = false,
    this.notes,
    this.avatarUrl,
    this.themePreference = 'system',
    this.languagePreference = 'en',
    this.subscriptionType = 'free',
    this.subscriptionExpireDate,
    this.totalWorkoutsCompleted = 0,
    this.totalWorkoutDuration = 0,
    this.lastActive,
  })  : this.goals = goals ?? [],
        this.preferredWorkoutTypes = preferredWorkoutTypes ?? [],
        this.equipment = equipment ?? [],
        this.createdAt = createdAt ?? DateTime.now(),
        this.updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'full_name': fullName ?? name,
      'birth_date': birthDate.toIso8601String(),
      'weight': weight,
      'height': height,
      'gender': gender,
      'fitness_level': fitnessLevel,
      'goals': goals,
      'equipment': equipment,
      'injuries': injuries,
      'workout_days_per_week': workoutDaysPerWeek,
      'weekly_workouts': weeklyWorkouts,
      'workout_duration': workoutDuration,
      'workout_streak': workoutStreak,
      'streak_count': streakCount,
      'total_workouts': totalWorkouts,
      'total_sets': totalSets,
      'total_hours': totalHours,
      'last_workout_date': lastWorkoutDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'has_completed_survey': hasCompletedSurvey,
      'sync_with_health': syncWithHealth,
      'notes': notes,
      'avatar_url': avatarUrl,
      'theme_preference': themePreference,
      'language_preference': languagePreference,
      'subscription_type': subscriptionType,
      'subscription_expire_date': subscriptionExpireDate?.toIso8601String(),
      'total_workouts_completed': totalWorkoutsCompleted,
      'total_workout_duration': totalWorkoutDuration,
      'last_active': lastActive?.toIso8601String(),
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    try {
      // Специальная обработка поля has_completed_survey
      dynamic hasCompletedSurveyValue = json['has_completed_survey'];
      bool hasCompletedSurvey = false;

      // Обрабатываем все возможные типы данных
      if (hasCompletedSurveyValue is bool) {
        hasCompletedSurvey = hasCompletedSurveyValue;
      } else if (hasCompletedSurveyValue is String) {
        hasCompletedSurvey = hasCompletedSurveyValue.toLowerCase() == 'true';
      } else if (hasCompletedSurveyValue is int) {
        hasCompletedSurvey = hasCompletedSurveyValue > 0;
      } else if (hasCompletedSurveyValue == null) {
        // Если значение отсутствует, считаем что опрос не пройден
        hasCompletedSurvey = false;
      }

      // debugPrint('Значение has_completed_survey из JSON: $hasCompletedSurveyValue, преобразовано в: $hasCompletedSurvey');

      return UserProfile(
        id: json['id'],
        username: json['username'],
        email: json['email'],
        name: json['name'],
        fullName: json['full_name'],
        birthDate: json['birth_date'] != null
            ? DateTime.parse(json['birth_date'])
            : DateTime.now().subtract(const Duration(days: 365 * 25)),
        gender: json['gender'],
        height: json['height'] != null
            ? double.tryParse(json['height'].toString())
            : null,
        weight: json['weight'] != null
            ? double.tryParse(json['weight'].toString())
            : null,
        fitnessLevel: json['fitness_level'],
        goals: json['goals'] != null
            ? List<String>.from(json['goals'] as List)
            : [],
        preferredWorkoutTypes: json['preferred_workout_types'] != null
            ? List<String>.from(json['preferred_workout_types'] as List)
            : [],
        equipment: json['equipment'] != null
            ? List<String>.from(json['equipment'] as List)
            : [],
        injuries: json['injuries'] != null
            ? List<String>.from(json['injuries'] as List)
            : null,
        workoutDaysPerWeek: json['workout_days_per_week'] != null
            ? int.tryParse(json['workout_days_per_week'].toString()) ?? 3
            : 3,
        weeklyWorkouts: json['weekly_workouts'] ?? '',
        workoutDuration: json['workout_duration'] ?? '',
        workoutStreak: json['workout_streak'] != null
            ? int.tryParse(json['workout_streak'].toString()) ?? 0
            : 0,
        streakCount: json['streak_count'] != null
            ? int.tryParse(json['streak_count'].toString()) ?? 0
            : 0,
        totalWorkouts: json['total_workouts'] != null
            ? int.tryParse(json['total_workouts'].toString()) ?? 0
            : 0,
        totalSets: json['total_sets'] != null
            ? int.tryParse(json['total_sets'].toString()) ?? 0
            : 0,
        totalHours: json['total_hours'] != null
            ? double.tryParse(json['total_hours'].toString()) ?? 0
            : 0,
        lastWorkoutDate: json['last_workout_date'] != null
            ? DateTime.tryParse(json['last_workout_date'].toString())
            : null,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
            : DateTime.now(),
        updatedAt: json['updated_at'] != null
            ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
            : DateTime.now(),
        hasCompletedSurvey: hasCompletedSurvey,
        syncWithHealth: json['sync_with_health'] is bool
            ? json['sync_with_health']
            : json['sync_with_health'] == 'true' ||
                json['sync_with_health'] == '1',
        notes: json['notes'],
        avatarUrl: json['avatar_url'],
        themePreference: json['theme_preference'] ?? 'system',
        languagePreference: json['language_preference'] ?? 'en',
        subscriptionType: json['subscription_type'] ?? 'free',
        subscriptionExpireDate: json['subscription_expire_date'] != null
            ? DateTime.tryParse(json['subscription_expire_date'].toString())
            : null,
        totalWorkoutsCompleted: json['total_workouts_completed'] != null
            ? int.tryParse(json['total_workouts_completed'].toString()) ?? 0
            : 0,
        totalWorkoutDuration: json['total_workout_duration'] != null
            ? int.tryParse(json['total_workout_duration'].toString()) ?? 0
            : 0,
        lastActive: json['last_active'] != null
            ? DateTime.tryParse(json['last_active'].toString())
            : null,
      );
    } catch (e) {
      // Возвращаем профиль по умолчанию при ошибке
      return UserProfile(
        id: json['id'] ?? '',
        birthDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
        hasCompletedSurvey: json['has_completed_survey'] == true,
      );
    }
  }

  UserProfile copyWith({
    String? id,
    String? username,
    String? email,
    String? name,
    String? fullName,
    DateTime? birthDate,
    double? weight,
    double? height,
    String? gender,
    String? fitnessLevel,
    List<String>? goals,
    List<String>? preferredWorkoutTypes,
    List<String>? equipment,
    List<String>? injuries,
    int? workoutDaysPerWeek,
    String? weeklyWorkouts,
    String? workoutDuration,
    int? workoutStreak,
    int? streakCount,
    int? totalWorkouts,
    int? totalSets,
    double? totalHours,
    DateTime? lastWorkoutDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? hasCompletedSurvey,
    bool? syncWithHealth,
    String? notes,
    String? avatarUrl,
    String? themePreference,
    String? languagePreference,
    String? subscriptionType,
    DateTime? subscriptionExpireDate,
    int? totalWorkoutsCompleted,
    int? totalWorkoutDuration,
    DateTime? lastActive,
  }) {
    return UserProfile(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      name: name ?? this.name,
      fullName: fullName ?? this.fullName,
      birthDate: birthDate ?? this.birthDate,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      gender: gender ?? this.gender,
      fitnessLevel: fitnessLevel ?? this.fitnessLevel,
      goals: goals ?? this.goals,
      preferredWorkoutTypes:
          preferredWorkoutTypes ?? this.preferredWorkoutTypes,
      equipment: equipment ?? this.equipment,
      injuries: injuries ?? this.injuries,
      workoutDaysPerWeek: workoutDaysPerWeek ?? this.workoutDaysPerWeek,
      weeklyWorkouts: weeklyWorkouts ?? this.weeklyWorkouts,
      workoutDuration: workoutDuration ?? this.workoutDuration,
      workoutStreak: workoutStreak ?? this.workoutStreak,
      streakCount: streakCount ?? this.streakCount,
      totalWorkouts: totalWorkouts ?? this.totalWorkouts,
      totalSets: totalSets ?? this.totalSets,
      totalHours: totalHours ?? this.totalHours,
      lastWorkoutDate: lastWorkoutDate ?? this.lastWorkoutDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      hasCompletedSurvey: hasCompletedSurvey ?? this.hasCompletedSurvey,
      syncWithHealth: syncWithHealth ?? this.syncWithHealth,
      notes: notes ?? this.notes,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      themePreference: themePreference ?? this.themePreference,
      languagePreference: languagePreference ?? this.languagePreference,
      subscriptionType: subscriptionType ?? this.subscriptionType,
      subscriptionExpireDate:
          subscriptionExpireDate ?? this.subscriptionExpireDate,
      totalWorkoutsCompleted:
          totalWorkoutsCompleted ?? this.totalWorkoutsCompleted,
      totalWorkoutDuration: totalWorkoutDuration ?? this.totalWorkoutDuration,
      lastActive: lastActive ?? this.lastActive,
    );
  }
}

class TimeAvailability {
  final int daysPerWeek;
  final int minutesPerSession;

  TimeAvailability({
    required this.daysPerWeek,
    required this.minutesPerSession,
  });
}

enum GoalType {
  weightLoss,
  weightGain,
  muscleMass,
  strength,
  endurance,
  flexibility,
  generalFitness
}

enum ActivityLevel {
  sedentary,
  lightlyActive,
  moderatelyActive,
  veryActive,
  extraActive
}

enum FitnessLevel { beginner, intermediate, advanced }

enum MuscleGroup {
  chest,
  back,
  shoulders,
  biceps,
  triceps,
  legs,
  core,
  fullBody
}

enum Equipment {
  none,
  dumbbells,
  barbell,
  resistanceBands,
  pullupBar,
  bench,
  cables,
  machines,
  yoga,
  cardioEquipment
}

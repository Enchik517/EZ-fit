import 'package:flutter/material.dart';
import '../models/workout.dart';
import '../models/workout_log.dart';
import '../models/user_profile.dart';
import '../models/body_measurement.dart';
import '../services/workout_service.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_provider.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../models/exercise.dart';
import '../services/exercise_rating_service.dart';
import '../services/workout_generator.dart';
import 'package:provider/provider.dart';
import '../main.dart';

class WorkoutProvider with ChangeNotifier {
  final List<Workout> _presetWorkouts = WorkoutService.workouts;
  List<Workout> _customWorkouts = [];
  List<WorkoutLog> _workoutLogs = [];
  final Map<DateTime, List<Workout>> _scheduledWorkouts = {};
  Map<String, Set<String>> _completedWorkouts = {};
  List<BodyMeasurement> _bodyMeasurements = [];
  UserProfile? _userProfile;

  String _selectedCategory = 'All';
  String _selectedAICategory = 'All';

  final _supabase = Supabase.instance.client;
  List<Workout> _workouts = [];
  List<Workout> _workoutHistory = [];
  bool _isLoading = false;

  DateTime? _lastRandomWorkoutsUpdate;
  List<Workout>? _cachedRandomWorkouts;

  String _selectedDuration = 'All';
  String _selectedMuscles = 'All';
  String _selectedEquipment = 'All';
  String _selectedDifficulty = 'All';
  String _selectedFocus = 'All';

  int _totalWorkouts = 0;
  int _totalSets = 0;
  double _totalHours = 0.0;
  int _workoutStreak = 0;
  DateTime? _lastWorkoutDate;

  final ExerciseRatingService _exerciseRatingService = ExerciseRatingService();
  final WorkoutGenerator _workoutGenerator = WorkoutGenerator();

  // Параметры для хранения фильтров HomeScreen, чтобы они сохранялись между переключениями экранов
  String _homeDurationFilter = '45 min';
  Set<String> _homeMusclesFilters = {'All'};
  Set<String> _homeEquipmentFilters = {'All'};
  Set<String> _homeDifficultyFilters = {'All'};

  // Геттеры для HomeScreen фильтров
  String get homeDurationFilter => _homeDurationFilter;
  Set<String> get homeMusclesFilters => _homeMusclesFilters;
  Set<String> get homeEquipmentFilters => _homeEquipmentFilters;
  Set<String> get homeDifficultyFilters => _homeDifficultyFilters;

  // Методы для установки фильтров HomeScreen
  void setHomeDurationFilter(String duration) {
    _homeDurationFilter = duration;
    notifyListeners();
  }

  void setHomeMusclesFilters(Set<String> muscles) {
    _homeMusclesFilters = muscles;
    notifyListeners();
  }

  void setHomeEquipmentFilters(Set<String> equipment) {
    _homeEquipmentFilters = equipment;
    notifyListeners();
  }

  void setHomeDifficultyFilters(Set<String> difficulty) {
    _homeDifficultyFilters = difficulty;
    notifyListeners();
  }

  WorkoutProvider() {
    // Загружаем данные при создании провайдера
    _initializeData();
  }

  // Инициализация данных
  Future<void> _initializeData() async {
    try {
      // Проверяем, есть ли активный пользователь
      final userId = _supabase.auth.currentUser?.id;
      if (userId != null) {
        await loadWorkouts();
        await loadWorkoutLogs();
        await loadStatistics();
      }
    } catch (e) {
      debugPrint('Ошибка инициализации данных: $e');
    }
  }

  // Геттеры
  List<Workout> get presetWorkouts => _presetWorkouts;
  List<Workout> get customWorkouts => _customWorkouts;
  List<WorkoutLog> get workoutLogs => _workoutLogs;
  UserProfile? get userProfile => _userProfile;
  Map<DateTime, List<Workout>> get scheduledWorkouts => _scheduledWorkouts;

  List<BodyMeasurement> get bodyMeasurements => _bodyMeasurements;

  String get selectedCategory => _selectedCategory;
  String get selectedAICategory => _selectedAICategory;

  bool get isLoading => _isLoading;
  List<Workout> get workouts => _workouts;
  List<Workout> get workoutHistory => _workoutHistory;

  int get totalWorkouts => _totalWorkouts;
  int get totalSets => _totalSets;
  double get totalHours => _totalHours;
  int get workoutStreak => _workoutStreak;
  DateTime? get lastWorkoutDate => _lastWorkoutDate;

  // Метод для добавления тренировки из Goals
  void addCustomWorkout(Workout workout) {
    _customWorkouts.add(workout);
    notifyListeners();
  }

  // Filter methods
  List<Workout> getWorkoutsByDifficulty(String difficulty) {
    return WorkoutService.getWorkoutsByDifficulty(difficulty);
  }

  List<Workout> getWorkoutsByEquipment(String equipment) {
    return WorkoutService.getWorkoutsByEquipment(equipment);
  }

  List<Workout> getWorkoutsByMuscleGroup(String muscleGroup) {
    return WorkoutService.getWorkoutsByMuscleGroup(muscleGroup);
  }

  List<Workout> getWorkoutsByGender(String gender) {
    return WorkoutService.getWorkoutsByGender(gender);
  }

  void generateWorkoutPlan(UserProfile profile) {
    _userProfile = profile;

    // Используем новый подход с учетом рейтингов для пользователя
    _schedulePersonalizedWorkoutPlan(profile);
    notifyListeners();
  }

  Future<void> _schedulePersonalizedWorkoutPlan(UserProfile profile) async {
    try {
      _scheduledWorkouts.clear();
      final workoutsPerWeek = profile.workoutDaysPerWeek;

      // Создаем список фокусных областей для тренировок
      final focusAreas = _getBalancedFocusAreas(workoutsPerWeek);

      // Определяем сложность на основе уровня подготовки
      final difficulty = profile.fitnessLevel?.toLowerCase() ?? 'beginner';

      // Создаем тренировки на неделю вперед
      DateTime currentDate = DateTime.now();
      int day = 0;

      for (int i = 0; i < workoutsPerWeek; i++) {
        // Определяем дату (пропускаем выходные, если пользователь не хочет тренироваться в выходные)
        while (true) {
          day++;
          final workoutDate = currentDate.add(Duration(days: day));
          final weekday = workoutDate.weekday;

          // Если рабочий день (понедельник-пятница) или пользователь тренируется и в выходные
          if (weekday <= 5 || workoutsPerWeek > 5) {
            // Создаем персонализированную тренировку
            final workout = await createPersonalizedWorkout(
              focusArea: focusAreas[i],
              difficulty: difficulty,
            );

            if (workout != null) {
              // Планируем тренировку на этот день
              final dateKey = DateTime(
                  workoutDate.year, workoutDate.month, workoutDate.day);

              if (_scheduledWorkouts.containsKey(dateKey)) {
                _scheduledWorkouts[dateKey]!.add(workout);
              } else {
                _scheduledWorkouts[dateKey] = [workout];
              }
            }

            break; // Переходим к следующей тренировке
          }
        }
      }
    } catch (e) {
      debugPrint('Error scheduling personalized workouts: $e');
    }
  }

  // Вспомогательный метод для определения сбалансированных фокусных областей
  List<String> _getBalancedFocusAreas(int workoutsPerWeek) {
    // Основные группы мышц
    final List<String> allFocusAreas = [
      'chest',
      'back',
      'legs',
      'shoulders',
      'arms',
      'core'
    ];

    // Полные тренировки
    final List<String> fullBodyWorkouts = ['full body'];

    List<String> result = [];

    // Для тренировок 1-2 раза в неделю - полные тренировки
    if (workoutsPerWeek <= 2) {
      return List.filled(workoutsPerWeek, 'full body');
    }

    // Для 3-4 тренировок - комбинация основных групп
    if (workoutsPerWeek <= 4) {
      allFocusAreas.shuffle();
      result = allFocusAreas.take(workoutsPerWeek - 1).toList();
      result.add('full body'); // Добавляем одну полную тренировку
      return result;
    }

    // Для 5+ тренировок - все основные группы + остальное full body
    result = List.from(allFocusAreas);
    if (workoutsPerWeek > allFocusAreas.length) {
      result.addAll(
          List.filled(workoutsPerWeek - allFocusAreas.length, 'full body'));
    }

    return result;
  }

  List<Workout> getWorkoutsForDate(DateTime date) {
    final dateKey = DateTime(date.year, date.month, date.day);
    return _scheduledWorkouts[dateKey] ?? [];
  }

  bool hasWorkoutOnDate(DateTime date) {
    DateTime dateKey = DateTime(date.year, date.month, date.day);
    return _scheduledWorkouts.containsKey(dateKey);
  }

  Future<void> logWorkout(WorkoutLog log, {AuthProvider? authProvider}) async {
    try {
      _isLoading = true;
      notifyListeners();

      final data = log.toJson();
      await _supabase.from('workout_logs').insert(data);

      // Обновляем стрик после успешного логирования тренировки
      if (authProvider != null) {
        await updateWorkoutStreak(authProvider);
      }

      await loadWorkouts();
    } catch (e) {
      debugPrint('Error logging workout: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addWorkoutLog(WorkoutLog log) async {
    try {
      if (kDebugMode) debugPrint('Adding workout log...');
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        if (kDebugMode) debugPrint('No user logged in');
        return;
      }

      // Подготавливаем данные для сохранения
      final workoutLogData = {
        'user_id': userId,
        'workout_name': log.workoutName,
        'workout_date': log.date.toUtc().toIso8601String(),
        'duration': log.duration.inMinutes,
        'exercises': log.exercises
            .map((e) => {
                  'exercise': e.exercise.toJson(),
                  'sets': e.sets
                      .map((s) => {
                            'reps': s.reps,
                            'weight': s.weight,
                            'duration': s.duration?.inSeconds,
                            'notes': s.notes,
                          })
                      .toList(),
                })
            .toList(),
        'notes': log.notes,
      };

      if (kDebugMode) debugPrint('Saving workout log to Supabase...');

      // Сохраняем в Supabase и получаем сохраненную запись
      final response = await _supabase
          .from('workout_logs')
          .insert(workoutLogData)
          .select()
          .single();

      if (kDebugMode) debugPrint('Workout log saved successfully');

      // Создаем новый лог с ID из базы
      final savedLog = WorkoutLog(
        id: response['id'],
        workoutName: log.workoutName,
        date: log.date,
        duration: log.duration,
        exercises: log.exercises,
        notes: log.notes,
      );

      // Добавляем в локальный список
      _workoutLogs.insert(0, savedLog);

      if (kDebugMode) debugPrint('Local workout logs updated');

      // Обновляем статистику
      await loadStatistics();

      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('Error saving workout log: $e');
      rethrow;
    }
  }

  Future<void> loadWorkouts() async {
    _isLoading = true;
    notifyListeners();

    try {
      final userId = await _getCurrentUserId();
      if (userId == null) {
        if (kDebugMode) debugPrint('No user logged in for loadWorkouts');
        _isLoading = false;
        notifyListeners();
        return;
      }

      if (kDebugMode) debugPrint('Loading workouts for user: $userId');

      // Load workout logs
      await loadWorkoutLogs();

      // Сбрасываем списки перед загрузкой новых данных
      _customWorkouts = [];
      _workouts = [];

      // Используем пагинацию для загрузки избранных тренировок
      if (kDebugMode) debugPrint('Loading favorite workouts...');
      int favPage = 0;
      const pageSize = 50; // Разумный размер страницы
      bool hasMoreFavs = true;

      while (hasMoreFavs) {
        // Load favorite workouts first
        final favoriteResponse = await _supabase
            .from('favorite_workouts')
            .select()
            .eq('user_id', userId)
            .range(favPage * pageSize, (favPage + 1) * pageSize - 1);

        if (kDebugMode)
          debugPrint(
              'Loaded ${favoriteResponse?.length} favorite workouts for page ${favPage + 1}');

        if (favoriteResponse == null || favoriteResponse.isEmpty) {
          hasMoreFavs = false;
          continue;
        }

        for (final favorite in favoriteResponse) {
          final workoutData = favorite['workout_data'] as Map<String, dynamic>;
          workoutData['is_favorite'] =
              true; // Убедимся что статус избранного установлен
          final workout = Workout.fromJson(workoutData);
          _customWorkouts.add(workout);
        }

        // Если получено меньше записей, чем размер страницы, значит больше данных нет
        if (favoriteResponse.length < pageSize) {
          hasMoreFavs = false;
        } else {
          favPage++;
        }
      }

      // Используем пагинацию для загрузки обычных тренировок
      if (kDebugMode) debugPrint('Loading regular workouts...');
      int workoutPage = 0;
      bool hasMoreWorkouts = true;

      while (hasMoreWorkouts) {
        // Load regular workouts
        final response = await _supabase
            .from('workouts')
            .select()
            .eq('user_id', userId)
            .range(workoutPage * pageSize, (workoutPage + 1) * pageSize - 1);

        if (kDebugMode)
          debugPrint(
              'Loaded ${response?.length} regular workouts for page ${workoutPage + 1}');

        if (response == null || response.isEmpty) {
          hasMoreWorkouts = false;
          continue;
        }

        final workoutsPage = (response as List)
            .map((workout) {
              try {
                final workoutData = Map<String, dynamic>.from(workout);

                // Handle null values for all fields
                workoutData['name'] = workout['name'] ?? '';
                workoutData['description'] = workout['description'] ?? '';
                workoutData['difficulty'] = workout['difficulty'] ?? 'beginner';
                workoutData['focus'] = workout['focus'] ?? '';
                workoutData['duration'] = workout['duration'] ?? 0;

                // Безопасно преобразуем списки или устанавливаем пустые списки
                workoutData['equipment'] = (workout['equipment'] is List)
                    ? (workout['equipment'] as List)
                        .map((e) => e?.toString() ?? '')
                        .where((e) => e.isNotEmpty)
                        .toList()
                    : [];

                workoutData['target_muscles'] =
                    (workout['target_muscles'] is List)
                        ? (workout['target_muscles'] as List)
                            .map((e) => e?.toString() ?? '')
                            .where((e) => e.isNotEmpty)
                            .toList()
                        : [];

                // Безопасно обрабатываем список упражнений
                workoutData['exercises'] = (workout['exercises'] is List)
                    ? (workout['exercises'] as List)
                        .map((e) {
                          if (e == null) return null;
                          try {
                            final exercise = Map<String, dynamic>.from(e);
                            exercise['name'] = e['name'] ?? '';
                            exercise['sets'] = e['sets'] ?? 0;
                            exercise['reps'] = e['reps'] ?? 0;
                            exercise['weight'] = e['weight'] ?? 0;
                            exercise['duration'] = e['duration'] ?? 0;
                            exercise['rest'] = e['rest'] ?? 0;
                            exercise['notes'] = e['notes'] ?? '';
                            exercise['equipment'] = e['equipment'] ?? '';
                            exercise['videoUrl'] = e['videoUrl'] ?? '';
                            return exercise;
                          } catch (e) {
                            if (kDebugMode)
                              debugPrint('Error parsing exercise: $e');
                            return null;
                          }
                        })
                        .where((e) => e != null)
                        .toList()
                    : [];

                workoutData['created_at'] =
                    workout['created_at'] ?? DateTime.now().toIso8601String();
                workoutData['updated_at'] =
                    workout['updated_at'] ?? DateTime.now().toIso8601String();
                workoutData['is_favorite'] = workout['is_favorite'] ?? false;
                workoutData['calories_burned'] =
                    workout['calories_burned'] ?? 0;
                workoutData['user_id'] = workout['user_id'] ?? '';

                return Workout.fromJson(workoutData);
              } catch (e) {
                if (kDebugMode) debugPrint('Error parsing workout: $e');
                return null;
              }
            })
            .where((workout) => workout != null)
            .cast<Workout>()
            .toList();

        _workouts.addAll(workoutsPage);

        // Если получено меньше записей, чем размер страницы, значит больше данных нет
        if (workoutsPage.length < pageSize) {
          hasMoreWorkouts = false;
        } else {
          workoutPage++;
        }
      }

      // Add favorite workouts to main workouts list if they're not there
      for (var favorite in _customWorkouts) {
        if (!_workouts.any((w) => w.id == favorite.id)) {
          _workouts.add(favorite);
        }
      }

      if (kDebugMode)
        debugPrint(
            'Successfully loaded ${_workouts.length} workouts in total (including ${_customWorkouts.length} favorites)');
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading workouts: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> _getCurrentUserId() async {
    final userId = _supabase.auth.currentUser?.id;

    if (userId != null) {
      return userId;
    }

    try {
      // Если currentUser null, пробуем получить из сессии
      final session = _supabase.auth.currentSession;
      return session?.user.id;
    } catch (e) {
      if (kDebugMode) debugPrint('Error getting user session: $e');
      return null;
    }
  }

  Future<void> loadWorkoutLogs() async {
    try {
      if (kDebugMode) debugPrint('Loading workout logs...');
      final userId = await _getCurrentUserId();
      if (userId == null) {
        if (kDebugMode) debugPrint('No user logged in');
        return;
      }

      if (kDebugMode) debugPrint('Loading workout logs for user: $userId');

      _workoutLogs = [];
      // Используем пагинацию для загрузки данных
      int page = 0;
      const pageSize = 100; // Устанавливаем размер страницы
      bool hasMoreData = true;

      while (hasMoreData) {
        if (kDebugMode)
          debugPrint(
              'Loading workout logs page ${page + 1} with pageSize $pageSize');

        final response = await _supabase
            .from('workout_logs')
            .select()
            .eq('user_id', userId)
            .order('workout_date', ascending: false)
            .range(page * pageSize, (page + 1) * pageSize - 1);

        if (kDebugMode)
          debugPrint(
              'Received response from Supabase: ${response?.length} logs for page ${page + 1}');

        if (response == null || response.isEmpty) {
          hasMoreData = false;
          continue;
        }

        final logs = (response as List)
            .map((log) {
              try {
                if (log == null) return null;

                // Убедимся, что у нас есть обязательные поля
                if (log['workout_date'] == null) {
                  if (kDebugMode)
                    debugPrint('Missing workout_date in log: ${log['id']}');
                  return null;
                }

                return WorkoutLog(
                  id: log['id']?.toString() ?? '',
                  workoutName:
                      log['workout_name']?.toString() ?? 'Unnamed Workout',
                  date: DateTime.parse(log['workout_date']),
                  duration: Duration(
                      minutes:
                          int.tryParse(log['duration']?.toString() ?? '0') ??
                              0),
                  exercises: (log['exercises'] is List
                          ? log['exercises'] as List
                          : [])
                      .map((e) {
                        if (e == null) return null;
                        try {
                          return ExerciseLog(
                            exercise: Exercise.fromJson(
                                Map<String, dynamic>.from(e['exercise'] ?? {})),
                            sets: (e['sets'] is List ? e['sets'] as List : [])
                                .map((s) {
                                  if (s == null) return null;
                                  try {
                                    return SetLog(
                                      reps: int.tryParse(
                                              s['reps']?.toString() ?? '0') ??
                                          0,
                                      weight: double.tryParse(
                                              s['weight']?.toString() ?? '0') ??
                                          0.0,
                                      duration: s['duration'] != null
                                          ? Duration(
                                              seconds: int.tryParse(
                                                      s['duration']
                                                          .toString()) ??
                                                  0)
                                          : null,
                                      notes: s['notes']?.toString(),
                                    );
                                  } catch (e) {
                                    if (kDebugMode)
                                      debugPrint('Error parsing set: $e');
                                    return null;
                                  }
                                })
                                .where((s) => s != null)
                                .cast<SetLog>()
                                .toList(),
                          );
                        } catch (e) {
                          if (kDebugMode)
                            debugPrint('Error parsing exercise log: $e');
                          return null;
                        }
                      })
                      .where((e) => e != null)
                      .cast<ExerciseLog>()
                      .toList(),
                  notes: log['notes']?.toString(),
                );
              } catch (e, stackTrace) {
                if (kDebugMode)
                  debugPrint('Error parsing individual workout log: $e');
                if (kDebugMode) debugPrint('Stack trace: $stackTrace');
                if (kDebugMode) debugPrint('Problematic log data: $log');
                return null;
              }
            })
            .where((log) => log != null)
            .cast<WorkoutLog>()
            .toList();

        _workoutLogs.addAll(logs);

        // Если получено меньше записей, чем размер страницы, значит больше данных нет
        if (logs.length < pageSize) {
          hasMoreData = false;
        } else {
          page++;
        }
      }

      if (kDebugMode)
        debugPrint(
            'Successfully loaded ${_workoutLogs.length} workout logs in total');
      notifyListeners();
    } catch (e, stackTrace) {
      if (kDebugMode) debugPrint('Error loading workout logs: $e');
      if (kDebugMode) debugPrint('Stack trace: $stackTrace');
      _workoutLogs = [];
      notifyListeners();
    }
  }

  Future<void> _saveWorkoutLogs() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase.from('workout_logs').upsert(
            _workoutLogs
                .map((log) => {
                      'user_id': userId,
                      ...log.toJson(),
                    })
                .toList(),
          );
    } catch (e) {
      if (kDebugMode) debugPrint('Error saving workout logs: $e');
      rethrow;
    }
  }

  List<WorkoutLog> getLogsForDate(DateTime date) {
    return _workoutLogs.where((log) {
      return log.date.year == date.year &&
          log.date.month == date.month &&
          log.date.day == date.day;
    }).toList();
  }

  bool isWorkoutCompleted(DateTime date, Workout workout) {
    String dateKey = _getDateKey(date);
    return _completedWorkouts[dateKey]?.contains(workout.name) ?? false;
  }

  String _getDateKey(DateTime date) {
    return "${date.year}-${date.month}-${date.day}";
  }

  // Body measurement methods
  void addBodyMeasurement(BodyMeasurement measurement) {
    _bodyMeasurements.add(measurement);
    _bodyMeasurements
        .sort((a, b) => b.date.compareTo(a.date)); // Sort by date descending
    notifyListeners();
  }

  List<BodyMeasurement> getMeasurementsForRange(DateTime start, DateTime end) {
    return _bodyMeasurements.where((m) {
      return m.date.isAfter(start.subtract(Duration(days: 1))) &&
          m.date.isBefore(end.add(Duration(days: 1)));
    }).toList();
  }

  BodyMeasurement? getLatestMeasurement() {
    return _bodyMeasurements.isNotEmpty ? _bodyMeasurements.first : null;
  }

  Map<String, List<double>> getMeasurementHistory(String measurementName,
      {int days = 30}) {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days));

    final measurements = _bodyMeasurements
        .where((m) => m.date.isAfter(startDate))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return {
      'dates': measurements
          .map((m) => m.date.millisecondsSinceEpoch.toDouble())
          .toList(),
      'values': measurements.map((m) {
        if (measurementName == 'Weight') {
          return m.weight;
        } else {
          return m.measurements[measurementName] ?? 0.0;
        }
      }).toList(),
    };
  }

  List<Workout> getUpcomingWorkouts() {
    final now = DateTime.now();
    final endOfWeek = now.add(Duration(days: 7 - now.weekday));

    return _customWorkouts.where((workout) {
      final workoutDate = workout.scheduledDate;
      return workoutDate != null &&
          workoutDate.isAfter(now) &&
          workoutDate.isBefore(endOfWeek) &&
          !isWorkoutCompleted(workoutDate, workout);
    }).toList()
      ..sort((a, b) => a.scheduledDate!.compareTo(b.scheduledDate!));
  }

  void scheduleWorkout(Workout workout, DateTime date) {
    final dateKey = DateTime(date.year, date.month, date.day);

    if (_scheduledWorkouts.containsKey(dateKey)) {
      if (!_scheduledWorkouts[dateKey]!.contains(workout)) {
        _scheduledWorkouts[dateKey]!.add(workout);
      }
    } else {
      _scheduledWorkouts[dateKey] = [workout];
    }

    notifyListeners();
  }

  // Добавляем метод для добавления новой тренировки
  void addWorkout(Workout workout) {
    _customWorkouts.add(workout);
    notifyListeners();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setAICategory(String category) {
    _selectedAICategory = category;
    notifyListeners();
  }

  List<Workout> getFilteredWorkouts([String? category]) {
    if (category == null) return _workouts;

    // Создаем списки упражнений для каждой категории
    final Map<String, List<String>> categoryExercises = {
      'Express Workouts': [
        'Push-Up',
        'Bodyweight Squat',
        'Forward Lunge',
        'Reverse Lunge',
        'High Plank',
        'Low Plank',
        'Glute Bridge',
        'Superman',
        'Inchworm',
        'Mountain Climber'
      ],
      'HIIT': [
        'Jump Squat',
        'Plank Jacks',
        'Mountain Climber',
        'Burpee',
        'Jumping Lunge'
      ],
      'Home Workouts': [
        'Push-Up',
        'Knee Push-Up',
        'Incline Push-Up',
        'Wide Grip Push-Up',
        'Spiderman Push-Up',
        'Hindu Push-Up',
        'Bodyweight Squat',
        'Sumo Squat',
        'Narrow Squat',
        'Jump Squat',
        'Split Squat',
        'Bulgarian Split Squat',
        'Pistol Squat',
        'Wall Sit',
        'Air Squat',
        'Duck Walk',
        'Forward Lunge',
        'Reverse Lunge',
        'Walking Lunge',
        'Curtsy Lunge',
        'Side Lunge',
        'Jumping Lunge',
        'Clock Lunge',
        'Overhead Lunge',
        'Lunge with Twist',
        'Elevated Lunge',
        'High Plank',
        'Low Plank',
        'Side Plank',
        'Plank with Shoulder Taps',
        'Plank Jacks',
        'Plank Up-Downs',
        'Reverse Plank',
        'Single-Leg Plank',
        'Bird Dog Plank',
        'Spider Plank',
        'Burpee',
        'Mountain Climber',
        'Donkey Kick',
        'Glute Bridge',
        'Superman',
        'Bear Crawl',
        'Crab Walk',
        'Inchworm',
        'Hip Thrust',
        'V-Up'
      ],
      'Glutes': [
        'Sumo Squat',
        'Split Squat',
        'Bulgarian Split Squat',
        'Curtsy Lunge',
        'Side Lunge',
        'Donkey Kick',
        'Glute Bridge',
        'Superman',
        'Hip Thrust',
        'Barbell Deadlift',
        'Barbell Romanian Deadlift',
        'Barbell Hip Thrust'
      ],
      'Strength': [
        'Decline Push-Up',
        'Close Grip Push-Up',
        'Diamond Push-Up',
        'Pike Push-Up',
        'Pistol Squat',
        'Barbell Back Squat',
        'Barbell Front Squat',
        'Barbell Deadlift',
        'Barbell Romanian Deadlift',
        'Barbell Lunge',
        'Barbell Bench Press',
        'Barbell Incline Bench Press',
        'Barbell Decline Bench Press',
        'Barbell Overhead Press',
        'Barbell Bent-Over Row',
        'Barbell Clean',
        'Barbell Snatch',
        'Barbell Hip Thrust',
        'Barbell Shrug'
      ],
      'Full Body': [
        'Burpee',
        'Bear Crawl',
        'Crab Walk',
        'Inchworm',
        'Barbell Clean',
        'Barbell Snatch'
      ],
    };

    // Получаем список упражнений для выбранной категории
    final exerciseNames = categoryExercises[category] ?? [];

    // Создаем список упражнений из JSON данных
    List<Exercise> exercises = [];
    for (var name in exerciseNames) {
      try {
        // Ищем упражнение в нашем JSON файле
        final exerciseData = WorkoutService.exercises.firstWhere(
          (e) => e['name'] == name,
          orElse: () => {},
        );

        if (exerciseData.isNotEmpty) {
          exercises.add(Exercise(
            name: exerciseData['name'],
            description: exerciseData['description'],
            muscleGroup: exerciseData['muscleGroup'],
            equipment: exerciseData['equipment'],
            difficultyLevel: exerciseData['difficultyLevel'],
            superSetId: exerciseData['superSetId'],
            targetMuscleGroup: exerciseData['muscleGroup'],
            sets: '3', // Дефолтные значения
            reps: '12',
            weight: 0.0,
            videoUrl: exerciseData['videoUrl'],
            exerciseTime: Duration(seconds: 45),
            restTime: Duration(seconds: 30),
            notes: '',
          ));
        }
      } catch (e) {
        if (kDebugMode) debugPrint('Error creating exercise $name: $e');
      }
    }

    // Если нашли упражнения, создаем из них тренировку
    if (exercises.isNotEmpty) {
      final workout = Workout(
        id: const Uuid().v4(),
        name: '$category Workout',
        description: 'Workout from $category collection',
        exercises: exercises,
        duration: exercises.length * 5,
        difficulty: 'Intermediate',
        equipment: exercises.map((e) => e.equipment).toSet().toList(),
        targetMuscles:
            exercises.map((e) => e.targetMuscleGroup).toSet().toList(),
        focus: category,
      );

      return [workout];
    }

    return [];
  }

  List<Workout> getFilteredCustomWorkouts() {
    if (_selectedAICategory == 'All') {
      return _customWorkouts;
    }
    return _customWorkouts
        .where((workout) =>
            workout.focus == _selectedAICategory ||
            workout.description
                .toLowerCase()
                .contains(_selectedAICategory.toLowerCase()))
        .toList();
  }

  Future<void> saveWorkout(Workout workout) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Prepare workout data for database
      final workoutData = {
        'user_id': userId,
        'name': workout.name,
        'description': workout.description,
        'exercises': workout.exercises
            .map((e) => {
                  'name': e.name,
                  'description': e.description,
                  'equipment': e.equipment,
                  'sets': e.sets,
                  'reps': e.reps,
                  'target_muscle_group': e.targetMuscleGroup,
                  'difficulty': e.difficulty,
                  'super_set_id': e.superSetId,
                  'video_url': e.videoUrl,
                })
            .toList(),
        'difficulty': workout.difficulty,
        'equipment': workout.equipment.toList(),
        'target_muscles': workout.targetMuscles.toList(),
        'focus': workout.focus,
        'duration': workout.duration,
        'created_at': DateTime.now().toIso8601String(),
        'is_favorite': true,
      };

      // Save to database
      await _supabase.from('workouts').insert(workoutData);

      // Update local state
      _workouts.add(workout);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('Error saving workout: $e');
      rethrow;
    }
  }

  Future<void> removeFromFavorites(String workoutId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Remove from database
      await _supabase
          .from('workouts')
          .delete()
          .eq('user_id', userId)
          .eq('id', workoutId);

      // Update local state
      _workouts.removeWhere((w) => w.id == workoutId);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('Error removing workout from favorites: $e');
      rethrow;
    }
  }

  Future<void> loadWorkoutHistory() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await _supabase
          .from('workout_history')
          .select('*, workout:workouts(*)')
          .eq('user_id', userId)
          .order('completed_at', ascending: false)
          .limit(10);

      _workoutHistory = response
          .map<Workout>((json) => Workout.fromJson(json['workout']))
          .toList();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading workout history: $e');
    }
  }

  Workout? getNextWorkout() {
    if (_workouts.isEmpty) return null;
    // В будущем здесь может быть более сложная логика выбора следующей тренировки
    return _workouts.first;
  }

  List<Workout> getRecentWorkouts() {
    return _workoutHistory.take(5).toList();
  }

  Map<String, num> getWorkoutStats() {
    final completedWorkouts = _workoutHistory.length;
    final totalExercises = _workoutHistory.fold<int>(
      0,
      (sum, workout) => sum + workout.exercises.length,
    );
    final totalMinutes = _workoutHistory.fold<int>(
      0,
      (sum, workout) => sum + workout.duration,
    );

    return {
      'workouts': completedWorkouts,
      'exercises': totalExercises,
      'hours': totalMinutes / 60,
    };
  }

  Future<void> completeWorkout(Workout workout) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase.from('workout_history').insert({
        'user_id': userId,
        'workout_id': workout.id,
        'completed_at': DateTime.now().toIso8601String(),
      });

      await loadWorkoutHistory();
    } catch (e) {
      if (kDebugMode) debugPrint('Error completing workout: $e');
    }
  }

  Future<void> updateWorkoutStreak(AuthProvider authProvider) async {
    if (authProvider.userProfile == null) return;

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Загружаем все логи тренировок
      final logs = await _supabase
          .from('workout_logs')
          .select('workout_date')
          .eq('user_id', userId)
          .order('workout_date', ascending: false);

      if (logs == null || logs.isEmpty) {
        // Это первая тренировка
        final updatedProfile = authProvider.userProfile!.copyWith(
          workoutStreak: 1,
          lastWorkoutDate: DateTime.now(),
        );
        await authProvider.updateUserProfile(updatedProfile);
        _workoutStreak = 1;
        notifyListeners();
        return;
      }

      // Получаем отсортированные даты тренировок (только дата, без времени)
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final sortedDates = logs
          .map((log) => DateTime.parse(log['workout_date']))
          .map((date) => DateTime(date.year, date.month, date.day))
          .toList()
        ..sort((a, b) => b.compareTo(a));

      // Создаем множество уникальных дат тренировок
      final Set<String> uniqueDates = sortedDates
          .map((date) =>
              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}')
          .toSet();

      // Добавляем сегодняшнюю дату (текущая тренировка)
      final todayFormatted =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      uniqueDates.add(todayFormatted);

      // Начинаем расчет стрика с сегодняшнего дня
      int streak = 1;

      // Проверяем предыдущие дни
      var checkDate = today.subtract(Duration(days: 1));

      while (true) {
        final checkDateFormatted =
            '${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}';

        if (uniqueDates.contains(checkDateFormatted)) {
          streak++;
          checkDate = checkDate.subtract(Duration(days: 1));
        } else {
          break;
        }
      }

      if (kDebugMode) debugPrint('Updated workout streak: $streak');

      final updatedProfile = authProvider.userProfile!.copyWith(
        workoutStreak: streak,
        lastWorkoutDate: now,
      );

      await authProvider.updateUserProfile(updatedProfile);

      // Обновляем локальную переменную
      _workoutStreak = streak;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('Error updating workout streak: $e');
    }
  }

  // Получаем тренировку на сегодня
  Workout? getTodayWorkout() {
    if (_workouts.isEmpty) return null;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    try {
      return _workouts.firstWhere(
        (workout) {
          if (workout.schedule == null) return false;
          final scheduleDate = DateTime(
            workout.schedule!.year,
            workout.schedule!.month,
            workout.schedule!.day,
          );
          return scheduleDate == today;
        },
        orElse: () => _workouts.first,
      );
    } catch (e) {
      return null;
    }
  }

  // Удаляем тренировку из случайных
  void removeFromRandomWorkouts(Workout workout) {
    if (_cachedRandomWorkouts != null) {
      _cachedRandomWorkouts!.remove(workout);
      notifyListeners();
    }
  }

  // Заменяем тренировку на другую случайную
  Future<void> replaceRandomWorkout(Workout workout) async {
    if (_cachedRandomWorkouts == null || _workouts.isEmpty) return;

    final todayWorkout = getTodayWorkout();
    final availableWorkouts = _workouts
        .where((w) =>
            (todayWorkout == null || w != todayWorkout) &&
            !_cachedRandomWorkouts!.contains(w))
        .toList();

    if (availableWorkouts.isEmpty) return;

    availableWorkouts.shuffle();
    final index = _cachedRandomWorkouts!.indexOf(workout);
    if (index != -1) {
      _cachedRandomWorkouts![index] = availableWorkouts.first;
      notifyListeners();
    }
  }

  // Получаем случайные тренировки
  List<Workout> getRandomWorkouts() {
    if (_workouts.isEmpty) return [];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Update cache only once per day or if cache is empty
    if (_lastRandomWorkoutsUpdate != today ||
        _cachedRandomWorkouts == null ||
        _cachedRandomWorkouts!.isEmpty) {
      final todayWorkout = getTodayWorkout();
      final availableWorkouts = _workouts
          .where((w) => todayWorkout == null || w != todayWorkout)
          .toList();

      if (availableWorkouts.isEmpty) return [];

      availableWorkouts.shuffle();
      _cachedRandomWorkouts = availableWorkouts.take(3).toList();
      _lastRandomWorkoutsUpdate = today;
    }

    return _cachedRandomWorkouts ?? [];
  }

  Future<bool> isWorkoutCompletedForDate(
      String workoutName, String date) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final response = await _supabase
          .from('completed_workouts')
          .select()
          .eq('user_id', userId)
          .eq('date', date)
          .eq('workout_name', workoutName);

      return (response as List).isNotEmpty;
    } catch (e) {
      if (kDebugMode) debugPrint('Error checking workout completion: $e');
      return false;
    }
  }

  List<Workout> getFavoriteWorkouts() {
    try {
      if (kDebugMode) debugPrint('🔍 Запрос на получение избранных тренировок');
      if (kDebugMode)
        debugPrint('📊 В _workouts: ${_workouts.length} тренировок');
      if (kDebugMode)
        debugPrint(
            '📊 В _customWorkouts: ${_customWorkouts.length} тренировок');

      // Объединяем тренировки с флагом isFavorite из основного списка и все тренировки из _customWorkouts
      final List<Workout> result = [];
      final Set<String> addedIds = {}; // Для отслеживания уже добавленных ID

      // Сначала добавляем все тренировки из _customWorkouts
      if (kDebugMode) debugPrint('📊 Добавление тренировок из _customWorkouts');
      for (final customWorkout in _customWorkouts) {
        result.add(customWorkout);
        addedIds.add(customWorkout.id);
        if (kDebugMode)
          debugPrint(
              '📌 Добавлена из _customWorkouts: ${customWorkout.name} (ID: ${customWorkout.id})');
      }

      // Затем добавляем тренировки с isFavorite=true из _workouts, если их ID еще не добавлены
      if (kDebugMode)
        debugPrint('📊 Добавление тренировок с isFavorite=true из _workouts');
      final favoritesFromMain =
          _workouts.where((workout) => workout.isFavorite).toList();

      if (kDebugMode)
        debugPrint(
            '📊 Found ${favoritesFromMain.length} favorites in main workouts list');

      // Выводим все тренировки из основного списка помеченные как избранное
      if (kDebugMode && favoritesFromMain.isNotEmpty) {
        debugPrint('🔍 Favorites from main list:');
        for (var i = 0; i < favoritesFromMain.length; i++) {
          debugPrint(
              '📌 #${i + 1}: ${favoritesFromMain[i].name} (ID: ${favoritesFromMain[i].id})');
        }
      }

      for (final mainWorkout in favoritesFromMain) {
        if (!addedIds.contains(mainWorkout.id)) {
          result.add(mainWorkout);
          addedIds.add(mainWorkout.id);
          if (kDebugMode)
            debugPrint(
                '📌 Добавлена из _workouts: ${mainWorkout.name} (ID: ${mainWorkout.id})');
        } else {
          if (kDebugMode)
            debugPrint(
                '⚠️ Пропущена тренировка из _workouts (уже в списке): ${mainWorkout.name} (ID: ${mainWorkout.id})');
        }
      }

      if (kDebugMode)
        debugPrint('📊 Total favorites after merging: ${result.length}');

      // Сортируем результат, чтобы сначала шли тренировки с isFavorite=true
      result.sort((a, b) {
        if (a.isFavorite == b.isFavorite) {
          // Если оба имеют одинаковый статус избранного, сортируем по названию
          return a.name.compareTo(b.name);
        }
        // Если статусы различаются, сначала отображаем избранные
        return a.isFavorite ? -1 : 1;
      });

      // Для отладки выводим все избранные тренировки после сортировки
      if (kDebugMode && result.isNotEmpty) {
        debugPrint('📋 Final sorted favorites list:');
        for (var i = 0; i < result.length; i++) {
          debugPrint(
              '📌 Favorite #${i + 1}: ${result[i].name} (ID: ${result[i].id}, isFavorite: ${result[i].isFavorite})');
        }
      } else if (kDebugMode && result.isEmpty) {
        debugPrint('⚠️ No favorites found!');
      }

      return result;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error getting favorite workouts: $e');
      return [];
    }
  }

  Future<void> toggleFavorite(String workoutId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        if (kDebugMode)
          debugPrint('❌ Cannot toggle favorite: User is not logged in');
        return;
      }

      // Проверяем формат ID
      RegExp uuidRegExp = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
        caseSensitive: false,
      );

      if (!uuidRegExp.hasMatch(workoutId)) {
        if (kDebugMode)
          debugPrint(
              '❌ Cannot toggle favorite: Invalid workout ID format: $workoutId');
        throw FormatException('Invalid workout ID format');
      }

      if (kDebugMode)
        debugPrint(
            '🔍 Searching for workout with ID: $workoutId in ${_workouts.length} workouts');

      // Find the workout in the list
      final workoutIndex = _workouts.indexWhere((w) => w.id == workoutId);
      bool isNewFavorite = true;
      Workout? workout;

      if (workoutIndex != -1) {
        // Workout found in _workouts list
        workout = _workouts[workoutIndex];
        isNewFavorite = !workout.isFavorite;

        if (kDebugMode)
          debugPrint(
              '🔄 Toggling favorite for workout: ${workout.name} (ID: $workoutId)');
        if (kDebugMode)
          debugPrint('⬅️ Old favorite status: ${workout.isFavorite}');
        if (kDebugMode) debugPrint('➡️ New favorite status: $isNewFavorite');
      } else {
        // Workout not found in _workouts list
        // Check if it exists in favorite_workouts table
        if (kDebugMode)
          debugPrint(
              '⚠️ Workout not found in _workouts list. Checking in favorite_workouts...');

        try {
          final favoriteResponse = await _supabase
              .from('favorite_workouts')
              .select()
              .eq('user_id', userId)
              .eq('workout_id', workoutId)
              .maybeSingle();

          if (favoriteResponse != null) {
            // Workout exists in favorites, we should remove it
            isNewFavorite = false;
            if (kDebugMode)
              debugPrint('🔄 Workout exists in favorites, removing it');
          } else {
            // Workout doesn't exist in favorites, try to find it in workouts table
            final workoutResponse = await _supabase
                .from('workouts')
                .select()
                .eq('id', workoutId)
                .maybeSingle();

            if (workoutResponse == null) {
              if (kDebugMode)
                debugPrint(
                    '❌ Workout not found anywhere. Cannot toggle favorite.');
              return;
            }

            // Create workout object from response
            workout = Workout.fromJson(workoutResponse);
            isNewFavorite = true;
            if (kDebugMode)
              debugPrint('🔄 Found workout in database: ${workout.name}');
          }
        } catch (e) {
          if (kDebugMode) debugPrint('❌ Error checking favorite status: $e');
          return;
        }
      }

      if (isNewFavorite) {
        // Убедимся, что у нас есть объект тренировки
        if (workout == null) {
          if (kDebugMode)
            debugPrint(
                '❌ Cannot add to favorites: No workout object available');
          return;
        }

        // Create a complete copy of the workout with all visual and functional data
        final workoutCopy = workout.copyWith(
          id: workoutId,
          isFavorite: true,
        );

        if (kDebugMode) debugPrint('✅ Adding to favorites in database...');

        try {
          // Save to favorites
          final response = await _supabase.from('favorite_workouts').insert({
            'user_id': userId,
            'workout_id': workoutId,
            'workout_data': workoutCopy.toJson(),
          }).select();

          if (kDebugMode) debugPrint('✅ Database response: $response');
        } catch (dbError) {
          if (kDebugMode)
            debugPrint('❌ Database error while adding to favorites: $dbError');

          // Check if the error is due to an existing record
          if (dbError.toString().contains('duplicate key')) {
            if (kDebugMode)
              debugPrint(
                  '⚠️ Workout already in favorites, updating instead...');
            await _supabase
                .from('favorite_workouts')
                .update({'workout_data': workoutCopy.toJson()})
                .eq('user_id', userId)
                .eq('workout_id', workoutId);
          } else {
            // Rethrow if it's not a duplicate key error
            rethrow;
          }
        }

        // Add to local favorites list if not already there
        if (!_customWorkouts.any((w) => w.id == workoutId)) {
          _customWorkouts.add(workoutCopy);
          if (kDebugMode) debugPrint('✅ Added to local favorites list');
        } else {
          if (kDebugMode) debugPrint('⚠️ Already in local favorites list');
          // Update the existing workout in _customWorkouts
          final customIndex =
              _customWorkouts.indexWhere((w) => w.id == workoutId);
          if (customIndex >= 0) {
            _customWorkouts[customIndex] = workoutCopy;
            if (kDebugMode)
              debugPrint('✅ Updated existing workout in custom workouts');
          }
        }

        // Add to main workouts list if not already there
        if (workoutIndex == -1 && !_workouts.any((w) => w.id == workoutId)) {
          _workouts.add(workoutCopy);
          if (kDebugMode) debugPrint('✅ Added to main workouts list');
        }
      } else {
        if (kDebugMode) debugPrint('✅ Removing from favorites...');

        // Remove from favorites
        try {
          await _supabase
              .from('favorite_workouts')
              .delete()
              .eq('user_id', userId)
              .eq('workout_id', workoutId);

          if (kDebugMode) debugPrint('✅ Removed from database favorites');
        } catch (dbError) {
          if (kDebugMode)
            debugPrint(
                '❌ Database error while removing from favorites: $dbError');
          rethrow;
        }

        // Remove from local favorites
        final initialCount = _customWorkouts.length;
        _customWorkouts.removeWhere((w) => w.id == workoutId);
        final newCount = _customWorkouts.length;

        if (kDebugMode) {
          if (initialCount != newCount) {
            debugPrint('✅ Removed from local favorites list');
          } else {
            debugPrint('⚠️ Workout was not in local favorites list');
          }
        }
      }

      // Update original workout's favorite status in local state if it exists
      if (workoutIndex != -1) {
        _workouts[workoutIndex] =
            _workouts[workoutIndex].copyWith(isFavorite: isNewFavorite);
        if (kDebugMode)
          debugPrint('✅ Updated workout favorite status in local state');
      }

      // Update in workouts table if needed
      try {
        // Проверяем существование записи в таблице workouts перед обновлением
        final existingWorkout = await _supabase
            .from('workouts')
            .select()
            .eq('id', workoutId)
            .maybeSingle();

        if (existingWorkout != null) {
          await _supabase
              .from('workouts')
              .update({'is_favorite': isNewFavorite})
              .eq('user_id', userId)
              .eq('id', workoutId);
          if (kDebugMode)
            debugPrint('✅ Updated favorite status in workouts table');
        } else if (isNewFavorite && workout != null) {
          // Если записи нет, но мы добавляем в избранное, то создаем запись
          await _supabase.from('workouts').insert({
            'id': workoutId,
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
          if (kDebugMode)
            debugPrint('✅ Created new workout record in workouts table');
        }
      } catch (dbError) {
        if (kDebugMode)
          debugPrint('⚠️ Could not update workouts table: $dbError');
        // Continue even if this fails, it's not critical
      }

      // Принудительно загружаем избранные тренировки для обновления UI
      await loadWorkouts();

      notifyListeners();
      if (kDebugMode)
        debugPrint('✅ Notified listeners of favorite status change');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error toggling favorite: $e');
      rethrow;
    }
  }

  void setDurationFilter(String duration) {
    _selectedDuration = duration;
    notifyListeners();
  }

  void setMusclesFilter(String muscles) {
    _selectedMuscles = muscles;
    notifyListeners();
  }

  void setEquipmentFilter(String equipment) {
    _selectedEquipment = equipment;
    notifyListeners();
  }

  void setDifficultyFilter(String difficulty) {
    _selectedDifficulty = difficulty;
    notifyListeners();
  }

  void setFocusFilter(String focus) {
    _selectedFocus = focus;
    notifyListeners();
  }

  Future<void> markWorkoutAsCompleted(String workoutId, DateTime date) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final dateKey = _getDateKey(date);

      // Find the workout
      final workout = _workouts.firstWhere((w) => w.id == workoutId);

      // Обновляем рейтинги всех упражнений в тренировке
      for (final exercise in workout.exercises) {
        try {
          await _exerciseRatingService.markExerciseAsUsed(exercise);
        } catch (e) {
          if (kDebugMode) debugPrint('Error updating exercise rating: $e');
          // Продолжаем выполнение, даже если не удалось обновить рейтинг
        }
      }

      // Create a complete copy with all visual and functional data
      final workoutCopy = workout.copyWith(
        id: const Uuid().v4(),
        createdAt: DateTime.now(),
        exercises: workout.exercises
            .map((e) => e.copyWith(
                  superSetId: e.superSetId,
                  videoUrl: e.videoUrl,
                  instructions: e.instructions,
                  commonMistakes: e.commonMistakes,
                  modifications: e.modifications,
                  exerciseTime: e.exerciseTime,
                  restTime: e.restTime,
                ))
            .toList(),
        warmUp: workout.warmUp,
        coolDown: workout.coolDown,
        totalDuration: workout.totalDuration,
        exerciseTime: workout.exerciseTime,
        restBetweenSets: workout.restBetweenSets,
        restBetweenExercises: workout.restBetweenExercises,
        instructions: workout.instructions,
        tips: workout.tips,
      );

      // Check if already completed
      final existingCompletions = await _supabase
          .from('completed_workouts')
          .select()
          .eq('user_id', userId)
          .eq('workout_id', workoutId)
          .eq('date', dateKey);

      if (existingCompletions.isEmpty) {
        // Save complete workout copy with all data
        await _supabase.from('completed_workouts').insert({
          'user_id': userId,
          'workout_id': workoutId,
          'workout_data': workoutCopy.toJson(),
          'visual_state': {
            'warm_up': workoutCopy.warmUp,
            'cool_down': workoutCopy.coolDown,
            'exercise_time': workoutCopy.exerciseTime.inSeconds,
            'rest_between_sets': workoutCopy.restBetweenSets.inSeconds,
            'rest_between_exercises':
                workoutCopy.restBetweenExercises.inMinutes,
            'total_duration': workoutCopy.totalDuration.inMinutes,
            'instructions': workoutCopy.instructions,
            'tips': workoutCopy.tips,
            'completed_exercises': workout.exercises
                .map((e) => {
                      'id': e.id,
                      'sets_completed': e.sets,
                      'weight_used': e.weight,
                      'notes': e.notes,
                    })
                .toList(),
          },
          'date': dateKey,
          'completed_at': DateTime.now().toUtc().toIso8601String(),
        });

        // Also save to workout history with complete data
        await _supabase.from('workout_history').insert({
          'user_id': userId,
          'workout_id': workoutId,
          'workout_data': workoutCopy.toJson(),
          'visual_state': {
            'warm_up': workoutCopy.warmUp,
            'cool_down': workoutCopy.coolDown,
            'exercise_time': workoutCopy.exerciseTime.inSeconds,
            'rest_between_sets': workoutCopy.restBetweenSets.inSeconds,
            'rest_between_exercises':
                workoutCopy.restBetweenExercises.inMinutes,
            'total_duration': workoutCopy.totalDuration.inMinutes,
            'instructions': workoutCopy.instructions,
            'tips': workoutCopy.tips,
            'completed_exercises': workout.exercises
                .map((e) => {
                      'id': e.id,
                      'sets_completed': e.sets,
                      'weight_used': e.weight,
                      'notes': e.notes,
                    })
                .toList(),
          },
          'completed_at': DateTime.now().toUtc().toIso8601String(),
        });

        // Update local state
        if (!_completedWorkouts.containsKey(dateKey)) {
          _completedWorkouts[dateKey] = <String>{};
        }
        _completedWorkouts[dateKey]!.add(workoutId);

        // Add to workout history with complete data
        _workoutHistory.insert(0, workoutCopy);

        // Add to completed workouts list
        final workoutLog = WorkoutLog(
          id: workoutCopy.id,
          workoutName: workoutCopy.name,
          date: date,
          duration: Duration(minutes: workoutCopy.duration),
          exercises: workoutCopy.exercises
              .map((e) => ExerciseLog.fromExercise(e))
              .toList(),
          isCompleted: true,
          isFavorite: workoutCopy.isFavorite,
        );
        _workoutLogs.insert(0, workoutLog);

        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error marking workout as completed: $e');
      rethrow;
    }
  }

  Future<void> loadStatistics() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final logs = await _supabase
          .from('workout_logs')
          .select()
          .eq('user_id', userId)
          .order('workout_date', ascending: false);

      if (logs == null || logs.isEmpty) {
        _totalWorkouts = 0;
        _totalSets = 0;
        _totalHours = 0;
        _workoutStreak = 0;
        _lastWorkoutDate = null;
        notifyListeners();
        return;
      }

      // Подсчитываем общую статистику
      _totalWorkouts = logs.length;
      _totalSets = 0;
      _totalHours = 0.0;

      for (var log in logs) {
        final exercises = List<Map<String, dynamic>>.from(log['exercises']);
        _totalSets += exercises.fold<int>(
          0,
          (sum, exercise) => sum + List.from(exercise['sets']).length,
        );

        // Преобразуем duration в число перед делением
        final durationValue = log['duration'];
        if (durationValue is int) {
          _totalHours += durationValue / 60.0;
        } else if (durationValue is double) {
          _totalHours += durationValue / 60.0;
        } else if (durationValue is String) {
          // Пытаемся преобразовать строку в число
          final durationInt = int.tryParse(durationValue);
          if (durationInt != null) {
            _totalHours += durationInt / 60.0;
          } else {
            // Если строка в формате HH:MM:SS
            final parts = durationValue.split(':');
            if (parts.length == 3) {
              final hours = int.tryParse(parts[0]) ?? 0;
              final minutes = int.tryParse(parts[1]) ?? 0;
              _totalHours += hours + (minutes / 60.0);
            }
          }
        }
      }

      // Создаем список дат тренировок и сортируем их в порядке убывания
      final sortedDates = logs
          .map((log) => DateTime.parse(log['workout_date']))
          .map((date) => DateTime(date.year, date.month, date.day))
          .toList()
        ..sort((a, b) => b.compareTo(a));

      _lastWorkoutDate = sortedDates.isNotEmpty ? sortedDates.first : null;

      // Создаем множество уникальных дат тренировок
      final Set<String> uniqueDates = sortedDates
          .map((date) =>
              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}')
          .toSet();

      // Проверяем текущий стрик
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Форматируем текущую дату для сравнения
      final todayFormatted =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      // Начинаем расчет стрика
      int streak = 0;

      // Проверяем, есть ли тренировка сегодня
      if (uniqueDates.contains(todayFormatted)) {
        // Если да, начинаем стрик с 1
        streak = 1;

        // Проверяем предыдущие дни
        var checkDate = today.subtract(Duration(days: 1));

        while (true) {
          final checkDateFormatted =
              '${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}';

          if (uniqueDates.contains(checkDateFormatted)) {
            streak++;
            checkDate = checkDate.subtract(Duration(days: 1));
          } else {
            break;
          }
        }
      } else {
        // Если сегодня нет тренировки, проверяем вчерашний день
        final yesterday = today.subtract(Duration(days: 1));
        final yesterdayFormatted =
            '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

        if (uniqueDates.contains(yesterdayFormatted)) {
          // Если вчера была тренировка, начинаем стрик с 1
          streak = 1;

          // Проверяем предыдущие дни
          var checkDate = yesterday.subtract(Duration(days: 1));

          while (true) {
            final checkDateFormatted =
                '${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}';

            if (uniqueDates.contains(checkDateFormatted)) {
              streak++;
              checkDate = checkDate.subtract(Duration(days: 1));
            } else {
              break;
            }
          }
        } else {
          // Если ни сегодня, ни вчера не было тренировок, стрик равен 0
          streak = 0;
        }
      }

      // Обновляем значение стрика
      _workoutStreak = streak;

      if (kDebugMode) debugPrint('Calculated workout streak: $_workoutStreak');
      if (kDebugMode) debugPrint('Last workout date: $_lastWorkoutDate');
      if (kDebugMode) debugPrint('Total workouts: $_totalWorkouts');

      // Обновляем профиль с актуальной статистикой
      final authProvider = Provider.of<AuthProvider>(
          navigatorKey.currentContext!,
          listen: false);
      final profile = authProvider.userProfile;
      if (profile != null) {
        final updatedProfile = profile.copyWith(
          totalWorkouts: _totalWorkouts,
          totalSets: _totalSets,
          totalHours: _totalHours,
          workoutStreak: _workoutStreak,
          lastWorkoutDate: _lastWorkoutDate,
        );

        await authProvider.saveUserProfile(updatedProfile);
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading statistics: $e');
      if (kDebugMode) debugPrint('Error details: $e');
    }
  }

  // Обновление статистики в профиле пользователя
  Future<void> updateUserStats(WorkoutLog log) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final authProvider = Provider.of<AuthProvider>(
          navigatorKey.currentContext!,
          listen: false);

      if (authProvider.userProfile == null) return;

      // Подсчитываем количество сетов в тренировке
      final totalSetsInWorkout = log.exercises.fold<int>(
        0,
        (sum, exercise) => sum + exercise.sets.length,
      );

      // Переводим минуты в часы
      final hoursInWorkout = log.duration.inMinutes / 60.0;

      // Обновляем статистику в профиле
      final updatedProfile = authProvider.userProfile!.copyWith(
        totalWorkouts: authProvider.userProfile!.totalWorkouts + 1,
        totalSets: authProvider.userProfile!.totalSets + totalSetsInWorkout,
        totalHours: authProvider.userProfile!.totalHours + hoursInWorkout,
        lastWorkoutDate: DateTime.now(),
      );

      // Сохраняем обновленный профиль
      await authProvider.saveUserProfile(updatedProfile);

      // Обновляем локальные данные
      _totalWorkouts = updatedProfile.totalWorkouts;
      _totalSets = updatedProfile.totalSets;
      _totalHours = updatedProfile.totalHours;

      if (kDebugMode)
        debugPrint(
            'Статистика пользователя обновлена: Всего тренировок: $_totalWorkouts, Всего сетов: $_totalSets');

      notifyListeners();
    } catch (e) {
      if (kDebugMode)
        debugPrint('Ошибка обновления статистики пользователя: $e');
    }
  }

  // Сохранение истории упражнений
  Future<void> saveExerciseHistory(
      Exercise exercise, List<SetLog> sets, DateTime date) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Подготавливаем данные для сохранения
      final exerciseData = {
        'user_id': userId,
        'exercise_name': exercise.name,
        'exercise_date': date.toUtc().toIso8601String(),
        'sets': sets
            .map((s) => {
                  'reps': s.reps,
                  'weight': s.weight,
                  'duration': s.duration?.inSeconds,
                  'notes': s.notes,
                })
            .toList(),
        'muscle_group': exercise.targetMuscleGroup,
      };

      // Сохраняем историю упражнения
      await _supabase.from('exercise_history').insert(exerciseData);

      if (kDebugMode)
        debugPrint('История упражнения ${exercise.name} сохранена');
    } catch (e) {
      if (kDebugMode) debugPrint('Ошибка сохранения истории упражнения: $e');
    }
  }

  // Добавляю новый метод для создания персонализированной тренировки
  Future<Workout?> createPersonalizedWorkout({
    required String focusArea,
    required String difficulty,
    int exerciseCount = 5,
    int duration = 45,
  }) async {
    try {
      if (_userProfile == null) {
        if (kDebugMode)
          debugPrint(
              'Cannot create personalized workout: user profile not loaded');
        return null;
      }

      if (kDebugMode)
        debugPrint(
            'Creating personalized workout for ${_userProfile!.name}, focus: $focusArea');

      // Используем генератор для создания персонализированной тренировки
      final workout = await _workoutGenerator.generatePersonalizedWorkout(
        userProfile: _userProfile!,
        focusArea: focusArea,
        difficulty: difficulty,
        exerciseCount: exerciseCount,
        duration: duration,
      );

      // Добавляем сгенерированную тренировку в список тренировок пользователя
      _customWorkouts.add(workout);
      notifyListeners();

      // Сохраняем в базу данных
      await saveWorkout(workout);

      return workout;
    } catch (e) {
      if (kDebugMode) debugPrint('Error creating personalized workout: $e');
      return null;
    }
  }

  // Метод для обновления упражнения
  Future<void> updateExercise(Exercise exercise) async {
    try {
      bool exerciseUpdated = false;

      // Обновляем упражнение в пресетных тренировках
      for (var i = 0; i < _presetWorkouts.length; i++) {
        var workout = _presetWorkouts[i];
        final exerciseIndex =
            workout.exercises.indexWhere((e) => e.id == exercise.id);
        if (exerciseIndex != -1) {
          final updatedExercises = List<Exercise>.from(workout.exercises);
          updatedExercises[exerciseIndex] = exercise;

          final updatedWorkout = workout.copyWith(exercises: updatedExercises);
          _presetWorkouts[i] = updatedWorkout;
          exerciseUpdated = true;
        }
      }

      // Обновляем упражнение в пользовательских тренировках
      for (var i = 0; i < _customWorkouts.length; i++) {
        var workout = _customWorkouts[i];
        final exerciseIndex =
            workout.exercises.indexWhere((e) => e.id == exercise.id);
        if (exerciseIndex != -1) {
          final updatedExercises = List<Exercise>.from(workout.exercises);
          updatedExercises[exerciseIndex] = exercise;

          final updatedWorkout = workout.copyWith(exercises: updatedExercises);
          _customWorkouts[i] = updatedWorkout;
          exerciseUpdated = true;
        }
      }

      // Обновляем упражнение в основном списке тренировок
      for (var i = 0; i < _workouts.length; i++) {
        var workout = _workouts[i];
        final exerciseIndex =
            workout.exercises.indexWhere((e) => e.id == exercise.id);
        if (exerciseIndex != -1) {
          final updatedExercises = List<Exercise>.from(workout.exercises);
          updatedExercises[exerciseIndex] = exercise;

          final updatedWorkout = workout.copyWith(exercises: updatedExercises);
          _workouts[i] = updatedWorkout;
          exerciseUpdated = true;
        }
      }

      if (exerciseUpdated) {
        notifyListeners();
      }

      // Если пользователь авторизован, обновляем данные в Supabase
      final userId = _supabase.auth.currentUser?.id;
      if (userId != null) {
        try {
          await _supabase
              .from('exercises')
              .update(exercise.toJson())
              .eq('id', exercise.id)
              .eq('user_id', userId);

          debugPrint(
              'Упражнение ${exercise.name} успешно обновлено в базе данных');
        } catch (dbError) {
          debugPrint(
              'Ошибка при обновлении упражнения в базе данных: $dbError');
        }
      }
    } catch (e) {
      debugPrint('Ошибка при обновлении упражнения: $e');
    }
  }
}

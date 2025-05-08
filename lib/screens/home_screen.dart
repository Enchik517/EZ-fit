import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/workout_provider.dart';
import '../models/workout.dart';
import '../widgets/workout_card.dart';
import '../widgets/stats_card.dart';
import '../providers/auth_provider.dart';
import '../screens/active_workout_screen.dart';
import '../screens/streak_screen.dart';
import '../screens/profile_screen.dart';
import '../widgets/workout_details_modal.dart';
import '../screens/workout_details_screen.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'active_workout_screen.dart';
import '../models/exercise.dart';
import '../widgets/add_exercise_bottom_sheet.dart';
import '../screens/exercise_history_screen.dart';
import '../widgets/exercise_video_instructions.dart';
import '../widgets/filter_bottom_sheets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math' as Math;
import '../services/exercise_rating_service.dart';
import '../services/workout_service.dart';
import '../services/exercise_image_service.dart';
import '../services/video_thumbnail_service.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedTimeRange = 'Last 7 days';
  final List<String> _timeRanges = [
    'Last 7 days',
    'Last 30 days',
    'This Year',
    'All-Time'
  ];
  int _selectedIndex = 0;
  String _selectedDuration = 'All';
  String _selectedMuscles = 'All';
  String _selectedEquipment = 'All';
  String _selectedDifficulty = 'All';
  String _selectedFocus = 'All';
  List<Exercise> exercises = [];
  String _selectedFilter = 'All';
  List<Exercise> _filteredExercises = [];

  final List<String> _durations = [
    '15 min',
    '30 min',
    '45 min',
    '60 min',
    '90 min'
  ];
  final List<String> _muscleGroups = [
    'All',
    'Chest',
    'Back',
    'Shoulders',
    'Arms',
    'Legs',
    'Core',
    'Full Body',
    'Triceps',
    'Biceps',
    'Quads',
    'Glutes',
    'Hamstrings',
    'Calves'
  ];
  final List<String> _equipment = [
    'All',
    'None',
    'Dumbbells',
    'Barbell',
    'Resistance Band',
    'Pull-up Bar',
    'Box',
    'Bench',
    'Kettlebell'
  ];
  final List<String> _difficulties = [
    'All',
    'Beginner',
    'Intermediate',
    'Advanced'
  ];
  final List<String> _focuses = [
    'All',
    'Strength',
    'Hypertrophy',
    'Endurance',
    'HIIT',
    'Cardio',
    'Flexibility'
  ];

  String _selectedDurationFilter = '45 min';
  Set<String> _selectedMusclesFilters = {'All'};
  Set<String> _selectedEquipmentFilters = {'All'};
  Set<String> _selectedDifficultyFilters = {'All'};

  // Обновляем лимиты для упражнений по времени
  final Map<String, int> _durationLimits = {
    '15 min': 2,
    '30 min': 5,
    '45 min': 7,
    '60 min': 9,
    '90 min': 14,
  };

  final ExerciseRatingService _ratingService = ExerciseRatingService();

  // Добавляем переменную для отслеживания состояния загрузки
  bool _isLoading = false;

  // Добавляем поле для хранения контроллеров видео
  final Map<String, VideoPlayerController> _videoControllers = {};

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: [SystemUiOverlay.top],
    );

    // Синхронизируем фильтры с WorkoutProvider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final workoutProvider =
          Provider.of<WorkoutProvider>(context, listen: false);
      _selectedDurationFilter = workoutProvider.homeDurationFilter;
      _selectedMusclesFilters = workoutProvider.homeMusclesFilters;
      _selectedEquipmentFilters = workoutProvider.homeEquipmentFilters;
      _selectedDifficultyFilters = workoutProvider.homeDifficultyFilters;
    });

    // Загружаем данные после инициализации виджета
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      print('🚀 Начинаю загрузку данных приложения');
      // Сначала загружаем упражнения
      await loadExercises();
      // Затем загружаем другие данные
      await _loadData();
      // После загрузки всех данных инициализируем видеоконтроллеры
      _preloadVideoControllersForVisibleExercises();
      print('✅ Инициализация данных завершена');
    });
  }

  // Метод для исправления токенов Supabase в URL
  String _fixSupabaseTokens(String url) {
    if (url.isEmpty) return url;

    // Проверка на истекший токен Supabase
    if (url.contains('supabase.co/storage/v1/object/sign') &&
        !url.contains('token=eyJ')) {
      // Токен истек, нужно использовать публичный URL
      final baseUrl = url.split('?')[0]; // Берем только URL без параметров
      final fileName = baseUrl.split('/').last;
      final publicUrl =
          'https://efctwzpqpukhpqvpirrt.supabase.co/storage/v1/object/public/videos/$fileName';
      print('🔑 Исправляем истекший токен, новый URL: $publicUrl');
      return publicUrl;
    }
    return url;
  }

  @override
  void dispose() {
    // Освобождаем видео-контроллеры при выходе с экрана
    for (var controller in _videoControllers.values) {
      controller.dispose();
    }
    _videoControllers.clear();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0: // Home
        break;
      case 1: // Workout
        Navigator.pushNamed(context, '/workouts');
        break;
      case 2: // Chat
        Navigator.pushNamed(context, '/chat');
        break;
      case 3: // Profile
        Navigator.pushNamed(context, '/profile');
        break;
    }
  }

  Future<void> _loadData() async {
    try {
      final workoutProvider =
          Provider.of<WorkoutProvider>(context, listen: false);
      await workoutProvider.loadWorkouts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading workouts: $e')),
        );
      }
    }
  }

  Future<void> loadExercises() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      print('📚 Загружаю упражнения из WorkoutService...');

      // Используем централизованный список упражнений из WorkoutService
      final newExercises = WorkoutService.getAllExercises();
      print('📊 Получено ${newExercises.length} упражнений из WorkoutService');

      // Получаем историю упражнений для сортировки
      final exerciseHistory = await _getExerciseHistory();
      print('📆 Загружена история для ${exerciseHistory.length} упражнений');

      // Сортируем упражнения по дате последнего выполнения
      newExercises.sort((a, b) {
        final dateA = exerciseHistory[a.name];
        final dateB = exerciseHistory[b.name];

        // Если нет истории, помещаем в начало (null считается "раньше")
        if (dateA == null && dateB == null) {
          return 0;
        } else if (dateA == null) {
          return -1;
        } else if (dateB == null) {
          return 1;
        }

        // Сортируем по дате (сначала те, что давно не выполнялись)
        return dateA.compareTo(dateB);
      });

      if (mounted) {
        setState(() {
          exercises = newExercises;
          _isLoading = false;
          print('✅ Упражнения успешно загружены и отсортированы');
        });

        // Применяем фильтры после загрузки
        _filterExercises();
      }
    } catch (e, stackTrace) {
      print('❌ Ошибка загрузки упражнений: $e');
      print('📜 Стек вызовов: $stackTrace');

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки упражнений: $e')),
        );
      }
    }
  }

  Future<Map<String, DateTime>> _getExerciseHistory() async {
    final Map<String, DateTime> lastPerformedDates = {};

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return lastPerformedDates;

      // Получаем историю всех упражнений пользователя
      final response = await Supabase.instance.client
          .from('exercise_history')
          .select('exercise_name, created_at')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      // Создаем словарь: название упражнения -> дата последнего выполнения
      for (var record in response) {
        final exerciseName = record['exercise_name'] as String;
        if (record['created_at'] != null) {
          final workoutDate = DateTime.parse(record['created_at']);
          if (!lastPerformedDates.containsKey(exerciseName) ||
              workoutDate.isAfter(lastPerformedDates[exerciseName]!)) {
            lastPerformedDates[exerciseName] = workoutDate;
          }
        }
      }

      debugPrint('Loaded history for ${lastPerformedDates.length} exercises');
    } catch (e) {
      debugPrint('Error loading exercise history: $e');
    }

    return lastPerformedDates;
  }

  // Метод для предварительной загрузки видеоконтроллеров
  void _preloadVideoControllersForVisibleExercises() {
    // Максимальное количество одновременно загружаемых видео
    const int maxPreloadedVideos = 5;
    int loadedCount = 0;

    print(
        '🎬 Начинаю предварительную загрузку видеоконтроллеров для ${_filteredExercises.length} упражнений');

    // Проходим по отфильтрованным упражнениям (те, что будут отображаться)
    for (var exercise in _filteredExercises) {
      // Проверяем наличие URL видео
      if (exercise.videoUrl != null && exercise.videoUrl!.isNotEmpty) {
        // Пропускаем YouTube видео, они обрабатываются отдельно
        if (exercise.videoUrl!.contains('youtube.com') ||
            exercise.videoUrl!.contains('youtu.be')) {
          print('⏩ Пропускаем YouTube видео для: ${exercise.name}');
          continue;
        }

        // Исправляем токен в URL, если необходимо
        String videoUrl = _fixSupabaseTokens(exercise.videoUrl!);

        // Если контроллер еще не создан для этого URL
        if (!_videoControllers.containsKey(videoUrl)) {
          try {
            print('🎮 Предварительная загрузка видео для: ${exercise.name}');
            // Создаем и инициализируем контроллер
            final controller = VideoPlayerController.network(videoUrl);
            _videoControllers[videoUrl] = controller;

            // Инициализируем контроллер
            controller.initialize().then((_) {
              print(
                  '✅ Контроллер предварительно инициализирован для: ${exercise.name}');
              if (mounted) {
                setState(() {});
                // После инициализации устанавливаем параметры
                controller.setLooping(true);
                controller.setVolume(0);
              }
            }).catchError((error) {
              print(
                  '❌ Ошибка предварительной инициализации контроллера для ${exercise.name}: $error');
              // Удаляем неудачно инициализированный контроллер
              if (_videoControllers.containsKey(videoUrl)) {
                _videoControllers.remove(videoUrl);
              }
            });

            // Увеличиваем счетчик загруженных видео
            loadedCount++;

            // Ограничиваем количество предварительно загружаемых видео
            if (loadedCount >= maxPreloadedVideos) {
              print(
                  '🛑 Достигнут лимит предзагрузки ($maxPreloadedVideos видео)');
              break;
            }
          } catch (e) {
            print('❌ Ошибка создания контроллера для ${exercise.name}: $e');
          }
        } else {
          print('♻️ Контроллер уже существует для: ${exercise.name}');
        }
      }
    }

    print(
        '✅ Предзагрузка завершена, загружено $loadedCount видео из ${_filteredExercises.length} упражнений');
  }

  // Улучшенный метод фильтрации упражнений с последующей загрузкой превью
  void _filterExercises() {
    print('🔍 Применяю фильтры к ${exercises.length} упражнениям');

    // Логируем текущие фильтры для отладки
    _logCurrentFilters();

    // Получаем актуальные значения фильтров из провайдера
    final workoutProvider =
        Provider.of<WorkoutProvider>(context, listen: false);
    _selectedDurationFilter = workoutProvider.homeDurationFilter;
    _selectedMusclesFilters = workoutProvider.homeMusclesFilters;
    _selectedEquipmentFilters = workoutProvider.homeEquipmentFilters;
    _selectedDifficultyFilters = workoutProvider.homeDifficultyFilters;

    // Логируем обновленные фильтры
    print('🔄 После синхронизации с провайдером:');
    _logCurrentFilters();

    // Сначала освобождаем контроллеры для упражнений, которые больше не будут отображаться
    List<String> urlsToRemove = [];
    for (var url in _videoControllers.keys) {
      // Если упражнение с данным URL больше не в отфильтрованных, помечаем для удаления
      bool exerciseFound = false;
      for (var exercise in exercises) {
        if (exercise.videoUrl != null &&
            _fixSupabaseTokens(exercise.videoUrl!) == url) {
          exerciseFound = true;
          break;
        }
      }
      if (!exerciseFound) {
        urlsToRemove.add(url);
      }
    }

    // Удаляем и освобождаем неиспользуемые контроллеры
    for (var url in urlsToRemove) {
      try {
        print('🗑️ Освобождаю неиспользуемый контроллер: $url');
        _videoControllers[url]?.dispose();
        _videoControllers.remove(url);
      } catch (e) {
        print('⚠️ Ошибка при освобождении контроллера: $e');
      }
    }

    setState(() {
      // Применяем фильтры
      _filteredExercises = exercises.where((exercise) {
        // Применение фильтров
        final bool matchesFilter = _selectedFilter == 'All' ||
            exercise.muscleGroup.toLowerCase() == _selectedFilter.toLowerCase();

        // Фильтр по группе мышц
        final bool matchesMuscle = _selectedMusclesFilters.contains('All') ||
            _selectedMusclesFilters.contains(exercise.muscleGroup.capitalize());

        // Фильтр по оборудованию
        final bool matchesEquipment = _selectedEquipmentFilters
                .contains('All') ||
            _selectedEquipmentFilters.contains(exercise.equipment.capitalize());

        // Фильтр по сложности
        final bool matchesDifficulty =
            _selectedDifficultyFilters.contains('All') ||
                _selectedDifficultyFilters
                    .contains(exercise.difficultyLevel.capitalize());

        return matchesFilter &&
            matchesMuscle &&
            matchesEquipment &&
            matchesDifficulty;
      }).toList();

      // Ограничиваем количество упражнений в зависимости от выбранной длительности
      int limit = _durationLimits[_selectedDurationFilter] ?? 7;
      if (_filteredExercises.length > limit) {
        _filteredExercises = _filteredExercises.sublist(0, limit);
      }

      print('🔎 Отфильтровано ${_filteredExercises.length} упражнений');
    });

    // После фильтрации сразу загружаем видеоконтроллеры для отображаемых упражнений
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preloadVideoControllersForVisibleExercises();
    });
  }

  Widget _buildWorkoutSection(WorkoutProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const StreakScreen(),
                  ),
                );
              },
              child:
                  Consumer<AuthProvider>(builder: (context, authProvider, _) {
                final streakValue =
                    authProvider.userProfile?.workoutStreak ?? 0;
                return Row(
                  children: [
                    Icon(Icons.local_fire_department, color: Colors.orange),
                    SizedBox(width: 4),
                    Text(
                      '$streakValue',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                );
              }),
            ),
            Consumer<AuthProvider>(builder: (context, authProvider, _) {
              final userName = authProvider.userProfile?.fullName ??
                  authProvider.userProfile?.name ??
                  'there';
              return Text(
                'Hey, $userName',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                ),
              );
            }),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileScreen(),
                  ),
                );
              },
              child:
                  Consumer<AuthProvider>(builder: (context, authProvider, _) {
                // Получаем аватарку пользователя, если она есть
                final String? avatarUrl = authProvider.userProfile?.avatarUrl;
                final String firstInitial =
                    authProvider.userProfile?.fullName?.isNotEmpty == true
                        ? authProvider.userProfile!.fullName![0].toUpperCase()
                        : (authProvider.userProfile?.name?.isNotEmpty == true
                            ? authProvider.userProfile!.name![0].toUpperCase()
                            : 'A');

                // Если есть URL аватарки, показываем изображение
                return CircleAvatar(
                  backgroundColor: Colors.blue,
                  backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                      ? NetworkImage(avatarUrl)
                      : null,
                  child: avatarUrl == null || avatarUrl.isEmpty
                      ? Text(firstInitial)
                      : null,
                );
              }),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Time range selector
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _timeRanges.map((range) {
              final isSelected = range == _selectedTimeRange;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(range),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedTimeRange = range);
                    }
                  },
                  backgroundColor: Colors.grey[900],
                  selectedColor: Colors.white,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.black : Colors.white,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        SizedBox(height: 20),
        // Stats cards
        Container(
          height: 72,
          child: Row(
            children: [
              _buildStatsCard(
                value: provider.totalWorkouts.toString(),
                label: 'WORKOUTS',
                gradient: [Color(0xFFC66000), Colors.white],
              ),
              SizedBox(width: 8),
              _buildStatsCard(
                value: provider.totalSets.toString(),
                label: 'SETS',
                gradient: [Color(0xFF009DFF), Color(0xFFFF0004)],
              ),
              SizedBox(width: 8),
              _buildStatsCard(
                value: provider.totalHours.toStringAsFixed(1),
                label: 'HOURS',
                gradient: [
                  Color(0xFFEACDE9),
                  Color(0xFFEE0BD7),
                  Color(0xFF1BF57D)
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Заголовок Workout
        Text(
          'Workout',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        // Сначала фильтры
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterButton('45 min', Icons.timer),
              SizedBox(width: 8),
              _buildFilterButton('Muscles', Icons.fitness_center),
              SizedBox(width: 8),
              _buildFilterButton('Equipment', Icons.sports_gymnastics),
              SizedBox(width: 8),
              _buildFilterButton('Difficulty', Icons.star),
              SizedBox(width: 8),
              // Добавляем кнопку настроек (шестеренки)
              InkWell(
                onTap: () {
                  _showSettingsDialog();
                },
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Settings',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.settings,
                        color: Colors.white,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Количество упражнений с кнопкой плюс
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_filteredExercises.length} exercises',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              width: 26,
              height: 25,
              child: IconButton(
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
                icon: Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 24,
                ),
                onPressed: () {
                  _showAddExerciseModal();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _buildExercisesList(),
        ),
        Container(
          width: double.infinity,
          height: 56,
          margin: EdgeInsets.only(top: 16, bottom: 80),
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ActiveWorkoutScreen(
                    exercises: _filteredExercises,
                    onComplete: () {
                      // Можно добавить действия после завершения тренировки
                    },
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '⚡',
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.amber[400],
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'START WORKOUT',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterButton(String label, IconData icon) {
    return InkWell(
      onTap: () {
        switch (label) {
          case '45 min':
            _showDurationPicker();
            break;
          case 'Muscles':
            _showMusclesPicker();
            break;
          case 'Equipment':
            _showEquipmentPicker();
            break;
          case 'Difficulty':
            _showDifficultyFilterDialog();
            break;
        }
      },
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Text(
              _getDisplayLabel(label),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.arrow_drop_down,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  String _getDisplayLabel(String label) {
    final workoutProvider =
        Provider.of<WorkoutProvider>(context, listen: false);

    switch (label) {
      case '45 min':
        return workoutProvider.homeDurationFilter;
      case 'Muscles':
        return workoutProvider.homeMusclesFilters.contains('All')
            ? 'All muscles'
            : '${workoutProvider.homeMusclesFilters.length} selected';
      case 'Equipment':
        return workoutProvider.homeEquipmentFilters.contains('All')
            ? 'All equipment'
            : '${workoutProvider.homeEquipmentFilters.length} selected';
      case 'Difficulty':
        return workoutProvider.homeDifficultyFilters.contains('All')
            ? 'All levels'
            : '${workoutProvider.homeDifficultyFilters.length} selected';
      default:
        return label;
    }
  }

  void _showDurationPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DurationFilterSheet(
        durations: _durations,
        selectedDuration: Provider.of<WorkoutProvider>(context, listen: false)
            .homeDurationFilter,
        durationLimits: _durationLimits,
        onDurationSelected: (duration) {
          Provider.of<WorkoutProvider>(context, listen: false)
              .setHomeDurationFilter(duration);
          setState(() {
            _selectedDurationFilter = duration;
          });
          _filterExercises();
        },
      ),
    );
  }

  void _showMusclesPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => MusclesFilterSheet(
        muscleGroups: _muscleGroups,
        selectedMuscles: Provider.of<WorkoutProvider>(context, listen: false)
            .homeMusclesFilters,
        onApply: (selected) {
          Provider.of<WorkoutProvider>(context, listen: false)
              .setHomeMusclesFilters(selected);
          setState(() {
            _selectedMusclesFilters = selected;
          });
          _filterExercises();
        },
      ),
    );
  }

  void _showEquipmentPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => EquipmentFilterSheet(
        equipment: _equipment,
        selectedEquipment: Provider.of<WorkoutProvider>(context, listen: false)
            .homeEquipmentFilters,
        onApply: (selected) {
          Provider.of<WorkoutProvider>(context, listen: false)
              .setHomeEquipmentFilters(selected);
          setState(() {
            _selectedEquipmentFilters = selected;
          });
          _filterExercises();
        },
      ),
    );
  }

  void _showDifficultyFilterDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DifficultyFilterSheet(
        difficulties: _difficulties,
        selectedDifficulties:
            Provider.of<WorkoutProvider>(context, listen: false)
                .homeDifficultyFilters,
        onApply: (selected) {
          Provider.of<WorkoutProvider>(context, listen: false)
              .setHomeDifficultyFilters(selected);
          setState(() {
            _selectedDifficultyFilters = selected;
          });
          _filterExercises();
        },
      ),
    );
  }

  Widget _buildExercisesList() {
    // Разделяем упражнения на обычные и суперсеты
    List<Exercise> regularExercises = [];
    Map<String?, List<Exercise>> supersets = {};

    // Сначала группируем упражнения по superSetId
    for (var exercise in _filteredExercises) {
      if (exercise.superSetId != null) {
        if (!supersets.containsKey(exercise.superSetId)) {
          supersets[exercise.superSetId!] = [];
        }
        supersets[exercise.superSetId]!.add(exercise);
      } else {
        regularExercises.add(exercise);
      }
    }

    // Проверяем суперсеты на валидность (минимум 2 упражнения)
    // Если суперсет невалидный, переносим упражнения в обычные
    supersets.forEach((id, exercises) {
      if (exercises.length < 2) {
        regularExercises.addAll(exercises);
        supersets[id] = [];
      }
    });

    // Удаляем пустые суперсеты
    supersets.removeWhere((key, value) => value.isEmpty);

    // Создаем список всех элементов для отображения
    List<Widget> allItems = [];

    // Сначала добавляем валидные суперсеты
    for (var superset in supersets.values) {
      allItems.add(
        Container(
          margin: EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Color(0xFF252527),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Text(
                  'SUPERSET — ${superset.first.sets} rounds',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ...superset
                  .map((exercise) => Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.white.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Превью изображение упражнения для суперсетов
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(
                                width: 44,
                                height: 44,
                                child: _getExercisePreviewImage(exercise),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    exercise.name,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '${exercise.sets} sets • ${exercise.reps} reps • ${exercise.weight ?? 50} lbs',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.6),
                                      fontSize: 13,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () =>
                                  _showExerciseOptions(context, exercise),
                              child: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.more_horiz,
                                  color: Colors.white70,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ],
          ),
        ),
      );
    }

    // Затем добавляем обычные упражнения
    for (var exercise in regularExercises) {
      allItems.add(
        Container(
          margin: EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Color(0xFF252527),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                // Превью изображение упражнения для обычных упражнений
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: _getExercisePreviewImage(exercise),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.name,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${exercise.sets} sets • ${exercise.reps} reps • ${exercise.weight ?? 50} lbs',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 13,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _showExerciseOptions(context, exercise),
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.more_horiz,
                      color: Colors.white70,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView(
      children: allItems,
    );
  }

  Widget _buildSettingsSheet() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Settings',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ListTile(
          leading: Icon(Icons.timer, color: Colors.white),
          title: Text('Duration', style: TextStyle(color: Colors.white)),
          onTap: () {
            Navigator.pop(context);
            _showDurationPicker();
          },
        ),
        ListTile(
          leading: Icon(Icons.fitness_center, color: Colors.white),
          title: Text('Muscles', style: TextStyle(color: Colors.white)),
          onTap: () {
            Navigator.pop(context);
            _showMusclesPicker();
          },
        ),
        ListTile(
          leading: Icon(Icons.sports_gymnastics, color: Colors.white),
          title: Text('Equipment', style: TextStyle(color: Colors.white)),
          onTap: () {
            Navigator.pop(context);
            _showEquipmentPicker();
          },
        ),
        ListTile(
          leading: Icon(Icons.star, color: Colors.white),
          title: Text('Difficulty', style: TextStyle(color: Colors.white)),
          onTap: () {
            Navigator.pop(context);
            _showDifficultyFilterDialog();
          },
        ),
      ],
    );
  }

  void _showAddExerciseModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewPadding.bottom),
        child: AddExerciseBottomSheet(
          allExercises: exercises,
          onExercisesAdded: (selectedExercises) {
            setState(() {
              // Добавляем выбранные упражнения и обновляем список
              _filteredExercises.addAll(selectedExercises);
            });
          },
        ),
      ),
    );
  }

  String _getExerciseEmoji(String equipment) {
    switch (equipment.toLowerCase()) {
      case 'dumbbells':
        return '🏋️';
      case 'bench':
        return '🛏️';
      case 'none':
        return '🦵';
      default:
        return '💪';
    }
  }

  // Добавим метод для показа красивых уведомлений
  void _showCustomSnackBar(String message,
      {required IconData icon, Color? color}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 2),
        backgroundColor: Color(0xFF252527),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        content: Row(
          children: [
            Icon(
              icon,
              color: color ?? Colors.white,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleFavorite(String workoutId) {
    try {
      // Ensure workoutId is a valid UUID format
      if (!_isValidUUID(workoutId)) {
        throw FormatException('Invalid UUID format');
      }

      // Your existing favorite logic here
      // ...
    } catch (e) {
      _showCustomSnackBar(
        "Error updating favorites: Invalid workout ID",
        icon: Icons.error,
        color: Colors.red.shade800,
      );
    }
  }

  // Add this helper method to validate UUID format
  bool _isValidUUID(String? uuid) {
    if (uuid == null) return false;

    RegExp uuidRegExp = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    );

    return uuidRegExp.hasMatch(uuid);
  }

  Widget _buildStatsCard({
    required String value,
    required String label,
    required List<Color> gradient,
  }) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient.map((c) => c.withOpacity(0.71)).toList(),
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExerciseOptions(BuildContext context, Exercise e) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewPadding.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: Color(0xFF1C1C1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                margin: EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Title
              Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(
                  e.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              // First group - no dividers
              _buildOptionTile(
                icon: Icons.play_circle_outline,
                iconColor: Colors.blue,
                title: 'Video & Instructions',
                onTap: () {
                  Navigator.pop(context);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => ExerciseVideoInstructions(
                      exercise: e,
                      videoUrl: e.videoUrl,
                    ),
                  );
                },
              ),
              _buildOptionTile(
                icon: Icons.history,
                iconColor: Colors.purple,
                title: 'Exercise History',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ExerciseHistoryScreen(
                        exercise: e,
                      ),
                    ),
                  );
                },
              ),
              _buildOptionTile(
                icon: Icons.swap_horiz,
                iconColor: Colors.blue,
                title: 'Replace',
                onTap: () {
                  Navigator.pop(context);
                  // Replace logic
                },
              ),

              // Divider with gradient
              Container(
                height: 1,
                margin: EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.white.withOpacity(0.15),
                      Colors.transparent,
                    ],
                    stops: [0.0, 0.5, 1.0],
                  ),
                ),
              ),

              // Second group
              _buildOptionTile(
                icon: Icons.thumb_up,
                iconColor: Colors.green,
                title: 'Recommend more',
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    // Обновляем предпочтение пользователя (лайк)
                    await _ratingService.updateUserPreference(e, 1);
                    _showCustomSnackBar(
                      "We'll recommend more exercises like ${e.name}",
                      icon: Icons.thumb_up,
                      color: Colors.green.shade800,
                    );
                  } catch (error) {
                    _showCustomSnackBar(
                      "Couldn't update preference: $error",
                      icon: Icons.error_outline,
                      color: Colors.red.shade800,
                    );
                  }
                },
              ),

              Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.white.withOpacity(0.15),
                      Colors.transparent,
                    ],
                    stops: [0.0, 0.5, 1.0],
                  ),
                ),
              ),

              _buildOptionTile(
                icon: Icons.thumb_down,
                iconColor: Colors.orange,
                title: 'Recommend less',
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    // Обновляем предпочтение пользователя (дизлайк)
                    await _ratingService.updateUserPreference(e, -1);
                    _showCustomSnackBar(
                      "We'll recommend fewer exercises like ${e.name}",
                      icon: Icons.thumb_down,
                      color: Colors.orange.shade800,
                    );
                  } catch (error) {
                    _showCustomSnackBar(
                      "Couldn't update preference: $error",
                      icon: Icons.error_outline,
                      color: Colors.red.shade800,
                    );
                  }
                },
              ),

              Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.white.withOpacity(0.15),
                      Colors.transparent,
                    ],
                    stops: [0.0, 0.5, 1.0],
                  ),
                ),
              ),

              _buildOptionTile(
                icon: Icons.block,
                iconColor: Colors.red,
                title: "Don't recommend again",
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    // Устанавливаем сильный негативный рейтинг
                    final updatedExercise =
                        e.copyWith(baseRating: 1.0, userPreference: -1);
                    await _ratingService.updateExerciseRating(updatedExercise);
                    _showCustomSnackBar(
                      "You won't see ${e.name} in recommendations anymore",
                      icon: Icons.block,
                      color: Colors.red.shade800,
                    );
                  } catch (error) {
                    _showCustomSnackBar(
                      "Couldn't update preference: $error",
                      icon: Icons.error_outline,
                      color: Colors.red.shade800,
                    );
                  }
                },
              ),

              Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.white.withOpacity(0.15),
                      Colors.transparent,
                    ],
                    stops: [0.0, 0.5, 1.0],
                  ),
                ),
              ),

              _buildOptionTile(
                icon: Icons.delete,
                iconColor: Colors.red,
                title: 'Delete from this workout',
                isDestructive: true,
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _filteredExercises.remove(e);
                  });
                },
              ),

              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 18,
              ),
            ),
            SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                color: isDestructive ? Colors.red : Colors.white,
                fontSize: 16,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Метод для отображения диалога настроек
  void _showSettingsDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Индикатор перетаскивания
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
              SizedBox(height: 24),
              // Заголовок
              Text(
                'Settings',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 16),
              // Быстрые действия с фильтрами
              _buildSettingsOption(
                icon: Icons.restart_alt,
                color: Colors.blue,
                title: 'Reset All Filters',
                subtitle: 'Return to default filter settings',
                onTap: () {
                  final workoutProvider =
                      Provider.of<WorkoutProvider>(context, listen: false);

                  // Сбрасываем фильтры в провайдере
                  workoutProvider.setHomeDurationFilter('45 min');
                  workoutProvider
                      .setHomeMusclesFilters(Set<String>.from(['All']));
                  workoutProvider
                      .setHomeEquipmentFilters(Set<String>.from(['All']));
                  workoutProvider
                      .setHomeDifficultyFilters(Set<String>.from(['All']));

                  // Обновляем локальное состояние
                  setState(() {
                    _selectedDurationFilter = '45 min';
                    _selectedMusclesFilters = Set<String>.from(['All']);
                    _selectedEquipmentFilters = Set<String>.from(['All']);
                    _selectedDifficultyFilters = Set<String>.from(['All']);
                  });

                  // Применяем фильтры
                  _filterExercises();

                  Navigator.pop(context);
                  _showCustomSnackBar(
                    "All filters have been reset",
                    icon: Icons.check_circle,
                    color: Colors.green,
                  );
                },
              ),
              Divider(color: Colors.grey[800]),
              _buildSettingsOption(
                icon: Icons.save,
                color: Colors.amber,
                title: 'Save Current Filters as Preset',
                subtitle: 'Create a preset with your current filters',
                onTap: () {
                  // В будущей версии можно реализовать сохранение
                  Navigator.pop(context);
                  _showCustomSnackBar(
                    "This feature will be available soon",
                    icon: Icons.info,
                    color: Colors.blue,
                  );
                },
              ),
              Divider(color: Colors.grey[800]),
              _buildSettingsOption(
                icon: Icons.fitness_center,
                color: Colors.purple,
                title: 'Advanced Exercise Settings',
                subtitle: 'Customize your exercise preferences',
                onTap: () {
                  Navigator.pop(context);
                  // В будущей версии можно добавить экран
                  _showCustomSnackBar(
                    "This feature will be available soon",
                    icon: Icons.info,
                    color: Colors.blue,
                  );
                },
              ),
              Divider(color: Colors.grey[800]),
              _buildSettingsOption(
                icon: Icons.sort,
                color: Colors.green,
                title: 'Sort Exercises',
                subtitle: 'Change the exercise sorting method',
                onTap: () {
                  Navigator.pop(context);
                  _showSortingOptionsDialog();
                },
              ),
              SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // Вспомогательный метод для создания опций в диалоге настроек
  Widget _buildSettingsOption({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[600],
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  // Новый метод для отображения диалога сортировки
  void _showSortingOptionsDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Sort Exercises',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.history, color: Colors.white),
                title: Text('Last performed date',
                    style: TextStyle(color: Colors.white)),
                subtitle: Text(
                    'Exercises you haven\'t done recently appear first',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  _showCustomSnackBar(
                    "Exercises sorted by last performed date",
                    icon: Icons.check_circle,
                    color: Colors.green,
                  );
                  // Текущая логика сортировки уже реализована по дате
                },
              ),
              ListTile(
                leading: Icon(Icons.sort_by_alpha, color: Colors.white),
                title:
                    Text('Alphabetical', style: TextStyle(color: Colors.white)),
                subtitle: Text('Sort exercises by name',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _filteredExercises.sort((a, b) => a.name.compareTo(b.name));
                  });
                  _showCustomSnackBar(
                    "Exercises sorted alphabetically",
                    icon: Icons.check_circle,
                    color: Colors.green,
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.fitness_center, color: Colors.white),
                title:
                    Text('Muscle group', style: TextStyle(color: Colors.white)),
                subtitle: Text('Group exercises by muscle',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _filteredExercises
                        .sort((a, b) => a.muscleGroup.compareTo(b.muscleGroup));
                  });
                  _showCustomSnackBar(
                    "Exercises sorted by muscle group",
                    icon: Icons.check_circle,
                    color: Colors.green,
                  );
                },
              ),
              SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // Добавляем вспомогательный метод для получения превью изображения упражнения
  Widget _getExercisePreviewImage(Exercise exercise) {
    // Проверяем наличие URL видео
    String? videoUrl = exercise.videoUrl;
    bool hasVideo = videoUrl != null && videoUrl.isNotEmpty;

    // Отладочная информация для выявления проблемы
    print('🎬 Генерация превью для упражнения: ${exercise.name}');
    print('🎬 URL видео: $videoUrl');

    // Исправляем токен в URL, если необходимо
    if (hasVideo) {
      videoUrl = _fixSupabaseTokens(videoUrl!);
    }

    // Проверяем наличие URL изображения
    String? imageUrl = exercise.imageUrl;
    bool hasImage = imageUrl != null && imageUrl.isNotEmpty;

    print('🖼️ URL изображения: $imageUrl');

    // Если есть видео URL, отображаем видео
    if (hasVideo && videoUrl != null) {
      // Проверяем, является ли это YouTube видео
      bool isYoutubeVideo =
          videoUrl.contains('youtube.com') || videoUrl.contains('youtu.be');

      print('👾 Тип видео: ${isYoutubeVideo ? "YouTube" : "Обычное видео"}');

      // Для YouTube видео показываем специальную миниатюру
      if (isYoutubeVideo) {
        return GestureDetector(
          onTap: () => _showVideoFullscreen(exercise),
          child: _buildYoutubeThumbnail(videoUrl),
        );
      }

      // Проверяем, есть ли уже контроллер для этого URL
      if (!_videoControllers.containsKey(videoUrl)) {
        print('🎮 Создаем новый контроллер для: $videoUrl');
        try {
          final controller = VideoPlayerController.network(videoUrl);
          _videoControllers[videoUrl] = controller;
          // Инициализируем контроллер заранее
          controller.initialize().then((_) {
            print('✅ Контроллер успешно инициализирован для: $videoUrl');
            if (mounted) setState(() {});
          }).catchError((error) {
            print('❌ Ошибка инициализации контроллера: $error');
          });
        } catch (e) {
          print('❌ Ошибка создания контроллера: $e');
          // В случае ошибки показываем изображение или иконку по умолчанию
          if (hasImage && imageUrl != null) {
            return _buildImageFallback(imageUrl, exercise);
          } else {
            return _buildDefaultExerciseIcon(exercise);
          }
        }
      } else {
        print('♻️ Используем существующий контроллер для: $videoUrl');
      }

      final videoController = _videoControllers[videoUrl]!;

      return GestureDetector(
        onTap: () => _showVideoFullscreen(exercise),
        child: FutureBuilder(
          future: videoController.value.isInitialized
              ? Future.value(null)
              : videoController.initialize(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingThumbnail();
            }

            if (snapshot.hasError) {
              print('❌ Ошибка загрузки видео: ${snapshot.error}');
              if (hasImage && imageUrl != null) {
                return _buildImageFallback(imageUrl, exercise);
              } else {
                return _buildDefaultExerciseIcon(exercise);
              }
            }

            if (videoController.value.isInitialized) {
              // Когда видео инициализировано, отображаем первый кадр
              if (!videoController.value.isPlaying) {
                videoController.setLooping(true);
                videoController.setVolume(0); // Отключаем звук
                videoController.play(); // Запускаем видео для показа анимации
                print('▶️ Запускаем воспроизведение видео для: $videoUrl');
              }

              return Stack(
                fit: StackFit.expand,
                children: [
                  // Сам видеоплеер
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: FittedBox(
                        fit: BoxFit.cover,
                        clipBehavior: Clip.hardEdge,
                        child: SizedBox(
                          width: videoController.value.size.width,
                          height: videoController.value.size.height,
                          child: VideoPlayer(videoController),
                        ),
                      ),
                    ),
                  ),

                  // Тонкая прозрачная накладка, чтобы подчеркнуть что это видео
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.5),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Маленькая иконка воспроизведения
                  Positioned(
                    right: 4,
                    bottom: 4,
                    child: Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ],
              );
            } else {
              // Пока видео загружается, показываем заглушку
              return _buildLoadingThumbnail();
            }
          },
        ),
      );
    }

    // Если есть изображение, отображаем его
    if (hasImage && imageUrl != null) {
      return _buildImageFallback(imageUrl, exercise);
    }

    // Если нет ни видео, ни изображения, используем стандартную иконку на основе группы мышц
    return _buildDefaultExerciseIcon(exercise);
  }

  // Метод для отображения изображения с обработкой ошибок
  Widget _buildImageFallback(String imageUrl, Exercise exercise) {
    return GestureDetector(
      onTap: exercise.videoUrl != null && exercise.videoUrl!.isNotEmpty
          ? () => _showVideoFullscreen(exercise)
          : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          width: 44,
          height: 44,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildLoadingThumbnail();
          },
          errorBuilder: (context, error, stackTrace) {
            print('❌ Ошибка загрузки изображения: $error');
            return _buildDefaultExerciseIcon(exercise);
          },
        ),
      ),
    );
  }

  // Метод для создания миниатюры YouTube видео
  Widget _buildYoutubeThumbnail(String videoUrl) {
    // Извлекаем ID видео из URL
    String? videoId;
    if (videoUrl.contains('youtube.com/watch')) {
      videoId = Uri.parse(videoUrl).queryParameters['v'];
    } else if (videoUrl.contains('youtu.be/')) {
      videoId = videoUrl.split('youtu.be/')[1].split('?')[0];
    }

    if (videoId == null) {
      return _buildLoadingThumbnail();
    }

    // URL для получения миниатюры YouTube
    String thumbnailUrl = 'https://img.youtube.com/vi/$videoId/0.jpg';

    return Stack(
      fit: StackFit.expand,
      children: [
        // Миниатюра YouTube
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            thumbnailUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return _buildLoadingThumbnail();
            },
            errorBuilder: (context, error, stackTrace) {
              return _buildDefaultExerciseIcon(Exercise(
                name: 'YouTube Video',
                description: '',
                muscleGroup: 'Unknown',
                equipment: 'None',
                difficultyLevel: 'Intermediate',
                targetMuscleGroup: 'Unknown',
              ));
            },
          ),
        ),

        // Тонкая прозрачная накладка для выделения
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.5),
                ],
              ),
            ),
          ),
        ),

        // Иконка YouTube в углу
        Positioned(
          right: 4,
          bottom: 4,
          child: Icon(
            Icons.play_circle_outline,
            color: Colors.red,
            size: 16,
          ),
        ),
      ],
    );
  }

  // Метод для отображения индикатора загрузки в виде миниатюры
  Widget _buildLoadingThumbnail() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            strokeWidth: 2.0,
          ),
        ),
      ),
    );
  }

  // Метод для создания стандартной иконки упражнения на основе группы мышц
  Widget _buildDefaultExerciseIcon(Exercise exercise) {
    // Определяем цвет в зависимости от группы мышц
    Color iconColor;
    IconData iconData;

    // Выбираем цвет и иконку в зависимости от группы мышц
    switch (exercise.muscleGroup.toLowerCase().split(',').first.trim()) {
      case 'chest':
        iconColor = Colors.red;
        iconData = Icons.fitness_center;
        break;
      case 'back':
        iconColor = Colors.blue;
        iconData = Icons.fitness_center;
        break;
      case 'shoulders':
        iconColor = Colors.orange;
        iconData = Icons.fitness_center;
        break;
      case 'arms':
      case 'biceps':
      case 'triceps':
        iconColor = Colors.purple;
        iconData = Icons.fitness_center;
        break;
      case 'legs':
      case 'quads':
      case 'hamstrings':
      case 'calves':
        iconColor = Colors.green;
        iconData = Icons.accessibility_new;
        break;
      case 'core':
      case 'abs':
        iconColor = Colors.amber;
        iconData = Icons.accessibility_new;
        break;
      default:
        iconColor = Colors.blue;
        iconData = Icons.fitness_center;
    }

    return Container(
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Icon(
          iconData,
          color: iconColor,
          size: 24,
        ),
      ),
    );
  }

  // Показывает видео на полный экран
  void _showVideoFullscreen(Exercise exercise) {
    if (exercise.videoUrl == null || exercise.videoUrl!.isEmpty) return;

    // Исправляем потенциально недействительные токены в URL
    String videoUrl = _fixSupabaseTokens(exercise.videoUrl!);

    // Для отладки покажем информацию о видео
    print('🎬 Открытие видео в полноэкранном режиме: ${exercise.name}');
    print('🔗 URL видео: $videoUrl');

    // Проверяем, является ли это YouTube видео
    if (videoUrl.contains('youtube.com') || videoUrl.contains('youtu.be')) {
      // Для YouTube видео пытаемся открыть в браузере или YouTube приложении
      final url = Uri.parse(videoUrl);
      _launchYoutubeVideo(url);
      return;
    }

    // Открываем экран с видео упражнения
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            title: Text(exercise.name, style: TextStyle(color: Colors.white)),
            iconTheme: IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: _buildVideoPlayer(videoUrl),
          ),
        ),
      ),
    );
  }

  // Открывает YouTube видео
  Future<void> _launchYoutubeVideo(Uri url) async {
    try {
      // Открываем URL-ссылку в браузере или приложении YouTube
      final canLaunch = await canLaunchUrl(url);
      if (canLaunch) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        // Если не смогли открыть, показываем сообщение
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось открыть видео')),
        );
      }
    } catch (e) {
      print('Ошибка при открытии YouTube: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при открытии видео')),
      );
    }
  }

  // Создаёт видеоплеер для полноэкранного режима
  Widget _buildVideoPlayer(String videoUrl) {
    print('🎦 Создаю полноэкранный плеер для: $videoUrl');

    // Создаем новый контроллер для полноэкранного видео
    final videoController = VideoPlayerController.network(videoUrl);

    return FutureBuilder(
      future: videoController.initialize(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Показываем индикатор загрузки
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          );
        }

        if (snapshot.hasError) {
          print(
              '❌ Ошибка инициализации полноэкранного плеера: ${snapshot.error}');
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 48),
                SizedBox(height: 16),
                Text(
                  'Не удалось загрузить видео',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  'Пожалуйста, проверьте соединение с интернетом',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          );
        }

        if (videoController.value.isInitialized) {
          // Начинаем воспроизведение
          videoController.play();

          // Убеждаемся, что контроллер будет освобожден при закрытии экрана
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              final modalRoute = ModalRoute.of(context);
              if (modalRoute != null) {
                modalRoute.addScopedWillPopCallback(() async {
                  if (videoController.value.isInitialized) {
                    videoController.pause();
                    videoController.dispose();
                  }
                  return true;
                });
              }
            }
          });

          return AspectRatio(
            aspectRatio: videoController.value.aspectRatio,
            child: Stack(
              alignment: Alignment.center,
              children: [
                VideoPlayer(videoController),

                // Добавляем элементы управления
                _buildVideoControls(videoController),
              ],
            ),
          );
        } else {
          // Если не удалось инициализировать, показываем ошибку
          print('❌ Контроллер не инициализирован, но ошибки нет');
          return Center(
            child: Text(
              'Не удалось загрузить видео',
              style: TextStyle(color: Colors.white),
            ),
          );
        }
      },
    );
  }

  // Создаёт элементы управления для видеоплеера
  Widget _buildVideoControls(VideoPlayerController controller) {
    return GestureDetector(
      onTap: () {
        // Переключаем воспроизведение/паузу при нажатии
        if (controller.value.isPlaying) {
          controller.pause();
        } else {
          controller.play();
        }
        // Обновляем UI
        setState(() {});
      },
      child: Container(
        color: Colors.transparent,
        child: Center(
          child: controller.value.isPlaying
              ? Container() // Ничего не показываем во время воспроизведения
              : Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkoutProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Всегда отображаем интерфейс, игнорируя проверку наличия профиля
        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _isLoading
                        ? Center(
                            child: Container(
                              width: 240,
                              padding: EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Color(0xFF1C1C1E),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.1),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Color(0xFF3D5AFE).withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: SizedBox(
                                      width: 40,
                                      height: 40,
                                      child: CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Color(0xFF3D5AFE)),
                                        strokeWidth: 3,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 20),
                                  Column(
                                    children: [
                                      Text(
                                        'Personalizing',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      SizedBox(height: 6),
                                      Text(
                                        'Creating your perfect workout',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.7),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          )
                        : _buildWorkoutSection(provider),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Вспомогательный метод для отладки фильтров
  void _logCurrentFilters() {
    print('📋 ТЕКУЩИЕ ФИЛЬТРЫ:');
    print('⏱️ Длительность: $_selectedDurationFilter');
    print('💪 Группы мышц: ${_selectedMusclesFilters.join(', ')}');
    print('🔧 Оборудование: ${_selectedEquipmentFilters.join(', ')}');
    print('⭐ Сложность: ${_selectedDifficultyFilters.join(', ')}');

    // Проверяем также значения в провайдере
    final workoutProvider =
        Provider.of<WorkoutProvider>(context, listen: false);
    print('📊 ФИЛЬТРЫ В ПРОВАЙДЕРЕ:');
    print('⏱️ Длительность: ${workoutProvider.homeDurationFilter}');
    print('💪 Группы мышц: ${workoutProvider.homeMusclesFilters.join(', ')}');
    print(
        '🔧 Оборудование: ${workoutProvider.homeEquipmentFilters.join(', ')}');
    print('⭐ Сложность: ${workoutProvider.homeDifficultyFilters.join(', ')}');
  }
}

// Добавляем расширение для метода capitalize()
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

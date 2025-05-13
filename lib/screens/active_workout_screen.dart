import 'package:flutter/material.dart';
import 'dart:async';
import '../models/exercise.dart';
import '../models/workout_log.dart';
import '../models/workout.dart';
import 'exercise_set_screen.dart';
import 'package:provider/provider.dart';
import '../providers/workout_provider.dart';
import 'workout_details_screen.dart';
import 'workout_summary_screen.dart';
import '../services/workout_service.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import 'package:video_player/video_player.dart';
import '../patches/exercise_favorite_patch.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../providers/subscription_provider.dart';
import '../widgets/subscription_required_widget.dart';

class ActiveWorkoutScreen extends StatefulWidget {
  final List<Exercise> exercises;
  final VoidCallback onComplete;
  final WorkoutLog? previousWorkoutLog;

  const ActiveWorkoutScreen({
    Key? key,
    required this.exercises,
    required this.onComplete,
    this.previousWorkoutLog,
  }) : super(key: key);

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  Duration _elapsed = Duration.zero;
  late Timer _timer;
  int _currentExerciseIndex = 0;
  final Map<Exercise, List<SetLog>> _exerciseSets = {};
  Map<String, bool> _favoriteExercises = {};
  // Карта для хранения видео-контроллеров
  final Map<String, VideoPlayerController> _videoControllers = {};

  @override
  void initState() {
    super.initState();
    _startTimer();
    _loadExerciseSets();

    // Initialize Map for exercise logs
    for (var exercise in widget.exercises) {
      _exerciseSets[exercise] = [];
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    // Освобождаем видео-контроллеры при выходе
    for (var controller in _videoControllers.values) {
      controller.dispose();
    }
    _videoControllers.clear();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsed += const Duration(seconds: 1);
      });
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return hours == '00' ? '$minutes:$seconds' : '$hours:$minutes:$seconds';
  }

  void _updateExerciseSets(Exercise exercise, int reps, double weight) {
    setState(() {
      if (_exerciseSets.containsKey(exercise)) {
        _exerciseSets[exercise]!.add(SetLog(reps: reps, weight: weight));
      } else {
        _exerciseSets[exercise] = [SetLog(reps: reps, weight: weight)];
      }
    });
  }

  void _handleSetComplete(int reps, double weight) {
    if (_currentExerciseIndex < widget.exercises.length - 1) {
      setState(() {
        _currentExerciseIndex++;
      });

      final nextExercise = widget.exercises[_currentExerciseIndex];

      // Add detailed logging
      print('👉 Transition to exercise: ${nextExercise.name}');
      print('👉 Direct access to videoUrl: ${nextExercise.videoUrl}');
      print('👉 Exercise object: ${nextExercise.toString()}');

      String? validVideoUrl = _getValidVideoUrl(nextExercise);
      print('👉 URL after check: $validVideoUrl');

      // Open next exercise screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ExerciseSetScreen(
            exercise: nextExercise,
            onSetComplete: _handleSetComplete,
            elapsed: _elapsed,
            videoUrl: validVideoUrl, // Pass checked URL
            nextExercise: _currentExerciseIndex < widget.exercises.length - 1
                ? widget.exercises[_currentExerciseIndex + 1]
                : null,
            exerciseSets: _exerciseSets,
            updateExerciseSets: _updateExerciseSets,
          ),
        ),
      );
    } else {
      // Complete workout
      final workoutProvider =
          Provider.of<WorkoutProvider>(context, listen: false);

      // Create ExerciseLog list from exercises
      final exerciseLogs = <ExerciseLog>[];

      for (var exercise in widget.exercises) {
        final sets = _exerciseSets[exercise] ?? [];
        if (sets.isNotEmpty) {
          exerciseLogs.add(ExerciseLog(
            exercise: exercise,
            sets: sets,
          ));
        }
      }

      // Create workout log
      final workoutLog = WorkoutLog(
        workoutName: 'Workout ${DateTime.now().day}/${DateTime.now().month}',
        date: DateTime.now(),
        duration: _elapsed,
        exercises: exerciseLogs,
      );

      // Save workout log
      workoutProvider.logWorkout(workoutLog).then((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => WorkoutSummaryScreen(
              workoutLog: workoutLog,
              uncompletedExercises: widget.exercises.where((exercise) {
                final sets = _exerciseSets[exercise] ?? [];
                return sets.length < int.parse(exercise.sets);
              }).toList(),
            ),
          ),
        );
      });
    }
  }

  // Check video URL validity and handle special cases
  String? _getValidVideoUrl(Exercise exercise) {
    print('🔍 Check URL for "${exercise.name}": ${exercise.videoUrl}');

    // First, check if we have fresh data from WorkoutService
    final freshExercise = WorkoutService.getExerciseByName(exercise.name);

    if (freshExercise != null && freshExercise.videoUrl != null) {
      final url = freshExercise.videoUrl;

      // If URL contains [project-ref], replace with correct Supabase ID
      if (url!.contains('[project-ref]')) {
        final correctedUrl =
            url.replaceAll('[project-ref]', 'efctwzpqpukhpqvpirrt');
        print('🔄 Corrected URL: $correctedUrl');
        return correctedUrl;
      }

      // Check if URL in WorkoutService has changed compared to what we have
      if (exercise.videoUrl != freshExercise.videoUrl) {
        print('⚠️ URL in WorkoutService differs from URL in exercise object:');
        print('  Original: ${exercise.videoUrl}');
        print('  From WorkoutService: ${freshExercise.videoUrl}');
        // Prefer URL from WorkoutService
        return freshExercise.videoUrl;
      }
    }

    // If there's no URL at all, try to generate one
    if (exercise.videoUrl == null || exercise.videoUrl!.isEmpty) {
      print('❌ URL missing for "${exercise.name}"');

      // Try to generate URL based on exercise name
      final generatedUrl = _generateVideoUrl(exercise.name);
      print('🔄 Generating URL based on name: $generatedUrl');
      return generatedUrl;
    }

    // Check absolute URL
    try {
      final uri = Uri.parse(exercise.videoUrl!);
      if (!uri.isAbsolute) {
        print(
            '❌ URL is not absolute for "${exercise.name}": ${exercise.videoUrl}');
        return null;
      }
    } catch (e) {
      print('❌ Error parsing URL for "${exercise.name}": $e');
      return null;
    }

    // If URL contains [project-ref], replace with correct Supabase ID
    if (exercise.videoUrl!.contains('[project-ref]')) {
      final correctedUrl = exercise.videoUrl!
          .replaceAll('[project-ref]', 'efctwzpqpukhpqvpirrt');
      print('🔄 Corrected URL: $correctedUrl');
      return correctedUrl;
    }

    print('✅ Video URL valid for "${exercise.name}": ${exercise.videoUrl}');
    return exercise.videoUrl;
  }

  // Generate video URL based on exercise name
  String _generateVideoUrl(String exerciseName) {
    // Convert name to slug for URL
    final slug = exerciseName.toLowerCase().replaceAll(' ', '-');

    // Check for dash at the end and remove if present
    final videoSlug =
        slug.endsWith('-') ? slug.substring(0, slug.length - 1) : slug;

    return 'https://efctwzpqpukhpqvpirrt.supabase.co/storage/v1/object/public/videos/$videoSlug.mp4';
  }

  // Method to determine if exercise is part of a superset
  bool _isPartOfSuperset(Exercise exercise) {
    return exercise.superSetId != null;
  }

  // Method to determine if exercise is first in a superset
  bool _isFirstInSuperset(Exercise exercise, int index) {
    if (!_isPartOfSuperset(exercise)) return false;

    if (index == 0) return true;

    final prevExercise = widget.exercises[index - 1];
    return prevExercise.superSetId != exercise.superSetId;
  }

  // Method to get number of exercises in a superset
  int _getSupersetRounds(String? supersetId) {
    if (supersetId == null) return 0;

    return widget.exercises.where((e) => e.superSetId == supersetId).length;
  }

  // Загрузка избранных упражнений через новый патч
  Future<void> _loadFavoriteExercises() async {
    // Функционал избранных упражнений отключен
    // Оставляем пустую карту, чтобы избежать ошибок в других местах
    if (mounted) {
      setState(() {
        _favoriteExercises = {};
      });
    }
  }

  // Toggle favorite status of exercise - ОТКЛЮЧЕНО
  Future<void> _toggleFavorite(Exercise exercise) async {
    // Функционал избранных упражнений отключен
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Функция добавления упражнений в избранное отключена'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // Check if exercise is in favorites - всегда возвращает false
  bool _isFavorite(Exercise exercise) {
    return false;
  }

  // Handle back button press
  Future<bool> _onWillPop() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Finish Workout?'),
            content: const Text('Progress will be saved'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Finish'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showStopWorkoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finish Workout?'),
        content: const Text('Progress will be saved'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Finish'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context);

    if (!subscriptionProvider.isSubscribed) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          title: const Text('Тренировка'),
          automaticallyImplyLeading: true,
        ),
        body: const SubscriptionRequiredWidget(
          featureName: 'Тренировка',
          description: 'Для выполнения тренировок необходима премиум подписка.',
          icon: Icon(
            Icons.sports_gymnastics,
            color: Colors.amber,
            size: 64,
          ),
        ),
      );
    }

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF201A18),
              Color(0xFF151211),
              Color(0xFF0F0D0C),
              Colors.black,
            ],
            stops: [0.0, 0.4, 0.7, 1.0],
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            title:
                const Text('Focus Mode', style: TextStyle(color: Colors.white)),
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              // Пустые действия в AppBar
            ],
          ),
          body: Stack(
            children: [
              // Неоновые эффекты
              Positioned(
                left: -50,
                top: 100,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.2),
                        blurRadius: 120,
                        spreadRadius: 40,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: -30,
                bottom: 120,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.2),
                        blurRadius: 120,
                        spreadRadius: 40,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: 100,
                top: 50,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepOrange.withOpacity(0.15),
                        blurRadius: 100,
                        spreadRadius: 30,
                      ),
                    ],
                  ),
                ),
              ),

              // Основное содержимое
              Column(
                children: [
                  // Таймер
                  Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 32),
                    child: Text(
                      _formatDuration(_elapsed),
                      style: const TextStyle(
                        fontSize: 60,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),

                  // Заголовок с количеством упражнений
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        Text(
                          '${widget.exercises.length} exercises',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.add, color: Colors.white),
                          onPressed: () {
                            // Add exercise
                          },
                        ),
                      ],
                    ),
                  ),

                  // Список упражнений
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      itemCount: widget.exercises.length,
                      itemBuilder: (context, index) {
                        final exercise = widget.exercises[index];
                        final isCurrentExercise =
                            index == _currentExerciseIndex;
                        final isCompleted = _exerciseSets[exercise]?.length ==
                            int.parse(exercise.sets);
                        final hasProgress =
                            _exerciseSets[exercise]?.isNotEmpty ?? false;
                        final progressText = hasProgress
                            ? "${_exerciseSets[exercise]!.length}/${exercise.sets} logged"
                            : "${exercise.sets} sets × ${exercise.reps}";

                        // Check if this is part of a superset
                        final isSuperset = _isPartOfSuperset(exercise);
                        final isFirstInSuperset =
                            _isFirstInSuperset(exercise, index);
                        final isLastInSuperset = isSuperset &&
                            (index == widget.exercises.length - 1 ||
                                widget.exercises[index + 1].superSetId !=
                                    exercise.superSetId);

                        // Card color based on status
                        Color cardColor = Colors.grey.shade900;
                        if (isCompleted) {
                          cardColor = Color(0xFF1E6E5F);
                        }

                        // If this is part of a superset but not first or last
                        if (isSuperset) {
                          // If first exercise in superset, start group with header
                          if (isFirstInSuperset) {
                            final rounds =
                                _getSupersetRounds(exercise.superSetId);
                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Superset header
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        top: 8, bottom: 8, left: 16, right: 16),
                                    child: Row(
                                      children: [
                                        Text(
                                          "SUPERSET",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          " — $rounds rounds",
                                          style: TextStyle(
                                            color:
                                                Colors.white.withOpacity(0.7),
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // First exercise in superset
                                  _buildSupersetExerciseCard(
                                      exercise,
                                      cardColor,
                                      isCompleted,
                                      hasProgress,
                                      progressText),

                                  // Add remaining exercises from the same superset
                                  _buildRemainingSuperset(
                                      exercise.superSetId!, index),
                                ],
                              ),
                            );
                          } else {
                            // If not first exercise in superset, skip here (they are added inside buildRemainingSuperset)
                            return const SizedBox.shrink();
                          }
                        }

                        // Regular exercises (not part of superset)
                        return _buildExerciseCard(exercise, cardColor,
                            isCompleted, hasProgress, progressText);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Нижняя панель
          bottomNavigationBar: Container(
            height: 120,
            color: Colors.transparent,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // Основная панель
                Positioned(
                  bottom: 20,
                  child: Container(
                    width: 212,
                    height: 58,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Левая кнопка - иконка info вместо звезды
                        Padding(
                          padding: const EdgeInsets.only(left: 15),
                          child: GestureDetector(
                            onTap: () {
                              // Получаем текущую тренировку и добавляем в избранное
                              _addCurrentWorkoutToFavorites();
                            },
                            child: Icon(
                              Icons.star_border_outlined,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),

                        // Пустое пространство для центральной кнопки
                        SizedBox(width: 80),

                        // Правая кнопка - комментарий
                        Padding(
                          padding: const EdgeInsets.only(right: 15),
                          child: GestureDetector(
                            onTap: () {
                              // Comment logic
                            },
                            child: Icon(
                              Icons.chat_outlined,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Центральная кнопка - шахматный флаг в белом круге
                Positioned(
                  bottom: 19,
                  child: GestureDetector(
                    onTap: () {
                      // Code for transition to workout summary
                      final exerciseLogs = <ExerciseLog>[];

                      for (var exercise in widget.exercises) {
                        final sets = _exerciseSets[exercise] ?? [];
                        exerciseLogs.add(ExerciseLog(
                          exercise: exercise,
                          sets: sets,
                        ));
                      }

                      final workoutLog = WorkoutLog(
                        workoutName: 'Focus Mode Workout',
                        date: DateTime.now(),
                        duration: _elapsed,
                        exercises: exerciseLogs,
                      );

                      final uncompletedExercises =
                          widget.exercises.where((exercise) {
                        final sets = _exerciseSets[exercise] ?? [];
                        return sets.length < int.parse(exercise.sets);
                      }).toList();

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WorkoutSummaryScreen(
                            workoutLog: workoutLog,
                            uncompletedExercises: uncompletedExercises,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.3),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: 30,
                          height: 30,
                          child: CustomPaint(
                            painter: CheckeredFlagPainter(),
                            size: Size(30, 30),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseCard(Exercise exercise, Color cardColor,
      bool isCompleted, bool hasProgress, String progressText) {
    // Получаем валидный URL для видео
    String? validVideoUrl = _getValidVideoUrl(exercise);

    // Проверяем сначала наличие изображения
    bool hasImage = exercise.imageUrl != null && exercise.imageUrl!.isNotEmpty;
    bool hasVideo = validVideoUrl != null && validVideoUrl.isNotEmpty;

    return GestureDetector(
      onTap: () {
        // Add detailed logging
        print('🖱️ Click on exercise: ${exercise.name}');
        print('🖱️ Direct access to videoUrl: ${exercise.videoUrl}');
        print('🖱️ Exercise object: ${exercise.toString()}');

        // Get checked video URL
        String? validVideoUrl = _getValidVideoUrl(exercise);
        print('🖱️ URL after check: $validVideoUrl');

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ExerciseSetScreen(
              exercise: exercise,
              onSetComplete: _handleSetComplete,
              elapsed: _elapsed,
              videoUrl: validVideoUrl,
              nextExercise: _currentExerciseIndex < widget.exercises.length - 1
                  ? widget.exercises[_currentExerciseIndex + 1]
                  : null,
              exerciseSets: _exerciseSets,
              updateExerciseSets: _updateExerciseSets,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Видеоплеер или превью видео в квадратике
            GestureDetector(
              onTap: hasVideo
                  ? () {
                      // При нажатии на миниатюру, если есть видео, открываем видео на полный экран
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ExerciseSetScreen(
                            exercise: exercise,
                            onSetComplete: _handleSetComplete,
                            elapsed: _elapsed,
                            videoUrl: validVideoUrl,
                            nextExercise: null,
                            exerciseSets: _exerciseSets,
                            updateExerciseSets: _updateExerciseSets,
                          ),
                        ),
                      );
                    }
                  : null,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 40,
                  height: 40,
                  color: Colors.white,
                  child: hasImage && exercise.imageUrl != null
                      ? Image.network(
                          exercise.imageUrl!,
                          fit: BoxFit.cover,
                          width: 40,
                          height: 40,
                          errorBuilder: (context, error, stackTrace) {
                            return hasVideo
                                ? _buildVideoThumbnail(validVideoUrl!)
                                : Icon(Icons.fitness_center,
                                    color: Colors.black54, size: 24);
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            );
                          },
                        )
                      : hasVideo
                          ? _buildVideoThumbnail(validVideoUrl!)
                          : Icon(Icons.fitness_center,
                              color: Colors.black54, size: 24),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Основная информация о упражнении
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              exercise.name,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '${exercise.sets} sets × ${exercise.reps} reps',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[350],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Кнопка избранного - ЗАМЕНЕНА на иконку информации
                      IconButton(
                        icon: Icon(
                          Icons.info_outline,
                          color: Colors.grey[400],
                          size: 24,
                        ),
                        onPressed: () => _showExerciseInfo(exercise),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                        splashRadius: 20,
                      ),
                    ],
                  ),
                  isCompleted
                      ? const Text(
                          'Completed',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        )
                      : const SizedBox.shrink(),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.more_horiz, color: Colors.white70),
              onPressed: () {
                _showExerciseOptionsMenu(exercise);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Show context menu with options for exercise
  void _showExerciseOptionsMenu(Exercise exercise) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  _isFavorite(exercise) ? Icons.star : Icons.star_border,
                  color:
                      _isFavorite(exercise) ? Color(0xFFFFD700) : Colors.white,
                ),
                title: Text(
                  _isFavorite(exercise)
                      ? 'Remove from favorites'
                      : 'Add to favorites',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _toggleFavorite(exercise);
                },
              ),
              ListTile(
                leading: Icon(Icons.info_outline, color: Colors.white),
                title: Text('Exercise Information',
                    style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  // Here you can open exercise description
                },
              ),
              ListTile(
                leading: Icon(Icons.swap_horiz, color: Colors.white),
                title: Text('Replace Exercise',
                    style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  // Here you can implement exercise replacement
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Метод для построения оставшихся суперсетов (без первого)
  Widget _buildRemainingSuperset(String supersetId, int startIndex) {
    final List<Widget> exerciseCards = [];

    // Start from next index after startIndex
    for (int i = startIndex + 1; i < widget.exercises.length; i++) {
      final exercise = widget.exercises[i];

      // If this is exercise from the same superset
      if (exercise.superSetId == supersetId) {
        final isCompleted =
            _exerciseSets[exercise]?.length == int.parse(exercise.sets);
        final hasProgress = _exerciseSets[exercise]?.isNotEmpty ?? false;
        final progressText = hasProgress
            ? "${_exerciseSets[exercise]!.length}/${exercise.sets} logged"
            : "${exercise.sets} sets × ${exercise.reps}";

        Color cardColor = Colors.grey.shade800;
        if (isCompleted) {
          cardColor = Colors.green.shade800.withOpacity(0.7);
        } else if (hasProgress) {
          cardColor = Colors.orange.shade800.withOpacity(0.5);
        }

        exerciseCards.add(_buildSupersetExerciseCard(
            exercise, cardColor, isCompleted, hasProgress, progressText));
      } else {
        // If encountered exercise from another superset or regular, stop here
        break;
      }
    }

    return Column(children: exerciseCards);
  }

  // Создает миниатюру видео с переиспользованием контроллеров
  Widget _buildVideoThumbnail(String videoUrl) {
    // Проверяем, является ли это YouTube видео
    bool isYoutubeVideo =
        videoUrl.contains('youtube.com') || videoUrl.contains('youtu.be');

    // Для YouTube видео показываем специальную миниатюру
    if (isYoutubeVideo) {
      return _buildYoutubeThumbnail(videoUrl);
    }

    // Проверяем, есть ли уже контроллер для этого URL
    if (!_videoControllers.containsKey(videoUrl)) {
      _videoControllers[videoUrl] = VideoPlayerController.network(videoUrl);
    }

    final videoController = _videoControllers[videoUrl]!;

    return FutureBuilder(
      future: videoController.value.isInitialized
          ? Future.value(null)
          : videoController.initialize(),
      builder: (context, snapshot) {
        if (videoController.value.isInitialized) {
          // Когда видео инициализировано, отображаем первый кадр
          if (!videoController.value.isPlaying) {
            videoController.setLooping(true);
            videoController.setVolume(0); // Отключаем звук
            videoController.play(); // Запускаем видео для показа анимации
          }

          return Stack(
            children: [
              // Сам видеоплеер
              SizedBox(
                width: 40,
                height: 40,
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

              // Тонкая прозрачная накладка, чтобы подчеркнуть что это видео
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.3),
                      ],
                    ),
                  ),
                ),
              ),

              // Маленькая иконка воспроизведения
              Positioned(
                right: 2,
                bottom: 2,
                child: Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 12,
                ),
              ),
            ],
          );
        } else {
          // Пока видео загружается, показываем заглушку
          return Container(
            width: 40,
            height: 40,
            color: Colors.black,
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          );
        }
      },
    );
  }

  // Создает миниатюру YouTube видео
  Widget _buildYoutubeThumbnail(String youtubeUrl) {
    // Получаем ID видео из URL
    String? videoId = _extractYoutubeVideoId(youtubeUrl);

    if (videoId != null) {
      // Формируем URL миниатюры
      String thumbnailUrl = 'https://img.youtube.com/vi/$videoId/0.jpg';

      return Stack(
        children: [
          // Миниатюра YouTube
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.network(
              thumbnailUrl,
              fit: BoxFit.cover,
              width: 40,
              height: 40,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.red.shade900,
                  child: Center(
                    child: Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                );
              },
            ),
          ),

          // Логотип YouTube
          Positioned(
            right: 2,
            top: 2,
            child: Container(
              padding: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(2),
              ),
              child: Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 10,
              ),
            ),
          ),
        ],
      );
    } else {
      // Если не удалось извлечь ID, отображаем стандартную иконку YouTube
      return Container(
        width: 40,
        height: 40,
        color: Colors.red.shade900,
        child: Center(
          child: Icon(
            Icons.play_arrow,
            color: Colors.white,
            size: 20,
          ),
        ),
      );
    }
  }

  // Извлекает ID видео из URL YouTube
  String? _extractYoutubeVideoId(String url) {
    RegExp regExp;

    // Проверяем разные форматы URL YouTube
    if (url.contains('youtube.com')) {
      regExp = RegExp(
          r'.*(?:(?:youtu\.be\/|v\/|vi\/|u\/\w\/|embed\/|shorts\/)|(?:(?:watch)?\?v(?:i)?=|\&v(?:i)?=))([^#\&\?]*).*');
    } else if (url.contains('youtu.be')) {
      regExp = RegExp(r'.*youtu\.be\/([^#\&\?]*).*');
    } else {
      return null;
    }

    Match? match = regExp.firstMatch(url);
    return match?.group(1);
  }

  // Build exercise card inside superset
  Widget _buildSupersetExerciseCard(Exercise exercise, Color cardColor,
      bool isCompleted, bool hasProgress, String progressText) {
    // Получаем валидный URL для видео
    String? validVideoUrl = _getValidVideoUrl(exercise);

    // Проверяем сначала наличие изображения
    bool hasImage = exercise.imageUrl != null && exercise.imageUrl!.isNotEmpty;
    bool hasVideo = validVideoUrl != null && validVideoUrl.isNotEmpty;

    return GestureDetector(
      onTap: () {
        // Add detailed logging
        print('🖱️ Click on superset exercise: ${exercise.name}');
        print('🖱️ Direct access to videoUrl: ${exercise.videoUrl}');

        // Get checked video URL
        String? validVideoUrl = _getValidVideoUrl(exercise);
        print('🖱️ URL after check: $validVideoUrl');

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ExerciseSetScreen(
              exercise: exercise,
              onSetComplete: _handleSetComplete,
              elapsed: _elapsed,
              videoUrl: validVideoUrl,
              nextExercise: null, // Don't automatically move, return to list
              exerciseSets: _exerciseSets,
              updateExerciseSets: _updateExerciseSets,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Видеоплеер или превью видео в квадратике
            GestureDetector(
              onTap: hasVideo
                  ? () {
                      // При нажатии на миниатюру, если есть видео, открываем видео на полный экран
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ExerciseSetScreen(
                            exercise: exercise,
                            onSetComplete: _handleSetComplete,
                            elapsed: _elapsed,
                            videoUrl: validVideoUrl,
                            nextExercise: null,
                            exerciseSets: _exerciseSets,
                            updateExerciseSets: _updateExerciseSets,
                          ),
                        ),
                      );
                    }
                  : null,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 40,
                  height: 40,
                  color: Colors.white,
                  child: hasImage && exercise.imageUrl != null
                      ? Image.network(
                          exercise.imageUrl!,
                          fit: BoxFit.cover,
                          width: 40,
                          height: 40,
                          errorBuilder: (context, error, stackTrace) {
                            return hasVideo
                                ? _buildVideoThumbnail(validVideoUrl!)
                                : Icon(Icons.fitness_center,
                                    color: Colors.black54, size: 24);
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            );
                          },
                        )
                      : hasVideo
                          ? _buildVideoThumbnail(validVideoUrl!)
                          : Icon(Icons.fitness_center,
                              color: Colors.black54, size: 24),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          exercise.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  isCompleted
                      ? const Text(
                          'Completed',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        )
                      : Text(
                          '${exercise.sets} sets × ${exercise.reps} reps',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.more_horiz, color: Colors.white70),
              onPressed: () {
                _showExerciseOptionsMenu(exercise);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Load exercise sets
  void _loadExerciseSets() {
    for (var exercise in widget.exercises) {
      if (_exerciseSets[exercise] == null) {
        _exerciseSets[exercise] = [];
      }
    }
  }

  // Load favorite exercises
  Future<void> _loadFavoriteStatus() async {
    try {
      final user = await UserService.getCurrentUser();
      if (user != null && user.favoriteExercises != null) {
        setState(() {
          for (var exerciseId in user.favoriteExercises!) {
            _favoriteExercises[exerciseId] = true;
          }
        });
      }
    } catch (e) {
      print('❌ Error loading favorite exercises: $e');
    }
  }

  // Новый метод для отображения информации об упражнении
  void _showExerciseInfo(Exercise exercise) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          exercise.name,
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Description:',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              exercise.description,
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(height: 10),
            Text(
              'Target muscles: ${exercise.targetMuscleGroup}',
              style: TextStyle(color: Colors.white),
            ),
            Text(
              'Difficulty: ${exercise.difficulty}',
              style: TextStyle(color: Colors.white),
            ),
            Text(
              'Equipment: ${exercise.equipment}',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Новый метод для добавления текущей тренировки в избранное
  void _addCurrentWorkoutToFavorites() async {
    try {
      // Создаем уникальный UUID в правильном формате
      final uuid = Uuid();
      final workoutId = uuid.v4(); // Создаем правильный UUID v4

      // Создаем новую тренировку из текущего набора упражнений
      final workout = Workout(
        id: workoutId,
        name: 'Focus Mode Workout',
        description: 'Custom workout created from Focus Mode',
        exercises: widget.exercises,
        duration: 45, // примерное время тренировки в минутах
        difficulty: 'medium',
        equipment: _getUniqueEquipment(),
        targetMuscles: _getUniqueTargetMuscles(),
        focus: 'custom',
        isFavorite: true,
      );

      // Показываем индикатор загрузки
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 2,
              ),
              SizedBox(width: 16),
              Text('Добавление тренировки в избранное...'),
            ],
          ),
          duration: Duration(seconds: 1),
        ),
      );

      // Получаем ID пользователя
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Пользователь не авторизован');
      }

      // Подготавливаем данные для сохранения в таблицу workouts
      // Важно: преобразуем все данные в правильные типы для PostgreSQL
      final workoutData = {
        'id': workoutId, // UUID уже в правильном формате
        'user_id': userId, // UUID уже в правильном формате
        'name': workout.name,
        'description': workout.description,
        'difficulty': workout.difficulty,
        'equipment': workout.equipment, // Это массив строк для PostgreSQL
        'target_muscles':
            workout.targetMuscles, // Это массив строк для PostgreSQL
        'focus': workout.focus,
        'duration': workout.duration,
        'is_favorite': true, // Булев тип
        'created_at': DateTime.now().toIso8601String()
      };

      // Подготавливаем данные для таблицы favorite_workouts
      final favoriteData = {
        'user_id': userId, // UUID
        'workout_id': workoutId, // UUID
        'workout_name': workout.name,
        'workout_data': workout.toJson(), // JSONB
        'created_at': DateTime.now().toIso8601String(),
      };

      print('📦 Данные для сохранения в БД: $workoutData');

      // Сохраняем в базу данных
      // 1. Добавляем запись в таблицу workouts
      await Supabase.instance.client.from('workouts').insert(workoutData);

      // 2. Добавляем запись в таблицу избранных тренировок
      await Supabase.instance.client
          .from('favorite_workouts')
          .insert(favoriteData);

      // Обновляем провайдер для обновления списка тренировок
      final workoutProvider =
          Provider.of<WorkoutProvider>(context, listen: false);
      await workoutProvider.loadWorkouts();

      // Показываем сообщение об успехе
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Тренировка добавлена в избранное'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('❌ Ошибка добавления тренировки в избранное: $e');

      // Показываем сообщение об ошибке
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  // Вспомогательный метод для получения уникального оборудования из текущего набора упражнений
  List<String> _getUniqueEquipment() {
    final Set<String> equipment = {};
    for (var exercise in widget.exercises) {
      if (exercise.equipment.isNotEmpty) {
        equipment.add(exercise.equipment);
      }
    }
    return equipment.toList();
  }

  // Вспомогательный метод для получения уникальных целевых групп мышц
  List<String> _getUniqueTargetMuscles() {
    final Set<String> muscles = {};
    for (var exercise in widget.exercises) {
      if (exercise.targetMuscleGroup.isNotEmpty) {
        muscles.add(exercise.targetMuscleGroup);
      }
    }
    return muscles.toList();
  }
}

// Custom widget for checkered flag pattern
class CheckeredFlagIcon extends StatelessWidget {
  final double size;

  const CheckeredFlagIcon({Key? key, this.size = 24.0}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: CheckeredFlagPainter(),
    );
  }
}

class CheckeredFlagPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final cellSize = size.width / 4;

    // Белый фон
    paint.color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Черные клетки
    paint.color = Colors.black;
    canvas.drawRect(Rect.fromLTWH(0, 0, cellSize, cellSize), paint);
    canvas.drawRect(Rect.fromLTWH(cellSize * 2, 0, cellSize, cellSize), paint);
    canvas.drawRect(Rect.fromLTWH(0, cellSize * 2, cellSize, cellSize), paint);
    canvas.drawRect(
        Rect.fromLTWH(cellSize * 2, cellSize * 2, cellSize, cellSize), paint);

    canvas.drawRect(
        Rect.fromLTWH(cellSize, cellSize, cellSize, cellSize), paint);
    canvas.drawRect(
        Rect.fromLTWH(cellSize * 3, cellSize, cellSize, cellSize), paint);
    canvas.drawRect(
        Rect.fromLTWH(cellSize, cellSize * 3, cellSize, cellSize), paint);
    canvas.drawRect(
        Rect.fromLTWH(cellSize * 3, cellSize * 3, cellSize, cellSize), paint);

    // Тонкая рамка
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 0.8;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(CheckeredFlagPainter oldDelegate) => false;
}

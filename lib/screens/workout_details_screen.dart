import 'package:flutter/material.dart';
import '../models/workout.dart';
import '../models/exercise.dart';
import 'active_workout_screen.dart';
import 'package:provider/provider.dart';
import '../providers/workout_provider.dart';
import 'dart:async';
import '../services/exercise_rating_service.dart';
import '../patches/favorite_patch.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WorkoutDetailsScreen extends StatefulWidget {
  final Workout workout;

  const WorkoutDetailsScreen({
    Key? key,
    required this.workout,
  }) : super(key: key);

  @override
  State<WorkoutDetailsScreen> createState() => _WorkoutDetailsScreenState();
}

class _WorkoutDetailsScreenState extends State<WorkoutDetailsScreen> {
  Timer? _timer;
  int _seconds = 0;
  final ExerciseRatingService _ratingService = ExerciseRatingService();
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _isFavorite = widget.workout.isFavorite;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++;
      });
    });
  }

  // Добавляем список альтернативных упражнений
  final List<Exercise> _alternativeExercises = [
    // Грудные
    Exercise.basic(
        name: 'Push-ups',
        targetMuscleGroup: 'Chest',
        equipment: 'none',
        difficulty: 'beginner',
        sets: '3',
        reps: '10'),
    Exercise.basic(
        name: 'Diamond Push-ups',
        targetMuscleGroup: 'Chest',
        equipment: 'none',
        difficulty: 'intermediate',
        sets: '3',
        reps: '10'),
    Exercise.basic(
        name: 'Dumbbell Bench Press',
        targetMuscleGroup: 'Chest',
        equipment: 'dumbbells',
        difficulty: 'intermediate',
        sets: '4',
        reps: '10'),
    // Спина
    Exercise.basic(
        name: 'Pull-ups',
        targetMuscleGroup: 'Back',
        equipment: 'pull-up bar',
        difficulty: 'intermediate',
        sets: '3',
        reps: '8'),
    Exercise.basic(
        name: 'Inverted Rows',
        targetMuscleGroup: 'Back',
        equipment: 'bar',
        difficulty: 'beginner',
        sets: '3',
        reps: '12'),
    Exercise.basic(
        name: 'Dumbbell Rows',
        targetMuscleGroup: 'Back',
        equipment: 'dumbbells',
        difficulty: 'beginner',
        sets: '3',
        reps: '12'),
    // Ноги
    Exercise.basic(
        name: 'Bodyweight Squats',
        targetMuscleGroup: 'Legs',
        equipment: 'none',
        difficulty: 'beginner',
        sets: '4',
        reps: '15'),
    Exercise.basic(
        name: 'Lunges',
        targetMuscleGroup: 'Legs',
        equipment: 'none',
        difficulty: 'beginner',
        sets: '3',
        reps: '12'),
    Exercise.basic(
        name: 'Jump Squats',
        targetMuscleGroup: 'Legs',
        equipment: 'none',
        difficulty: 'intermediate',
        sets: '3',
        reps: '10'),
    // Плечи
    Exercise.basic(
        name: 'Pike Push-ups',
        targetMuscleGroup: 'Shoulders',
        equipment: 'none',
        difficulty: 'intermediate',
        sets: '3',
        reps: '8'),
    Exercise.basic(
        name: 'Lateral Raises',
        targetMuscleGroup: 'Shoulders',
        equipment: 'dumbbells',
        difficulty: 'beginner',
        sets: '3',
        reps: '12'),
    // Руки
    Exercise.basic(
        name: 'Diamond Push-ups',
        targetMuscleGroup: 'Triceps',
        equipment: 'none',
        difficulty: 'intermediate',
        sets: '3',
        reps: '12'),
    Exercise.basic(
        name: 'Chin-ups',
        targetMuscleGroup: 'Biceps',
        equipment: 'pull-up bar',
        difficulty: 'intermediate',
        sets: '3',
        reps: '8'),
    // Пресс
    Exercise.basic(
        name: 'Crunches',
        targetMuscleGroup: 'Core',
        equipment: 'none',
        difficulty: 'beginner',
        sets: '3',
        reps: '20'),
    Exercise.basic(
        name: 'Plank',
        targetMuscleGroup: 'Core',
        equipment: 'none',
        difficulty: 'beginner',
        sets: '3',
        reps: '45 sec'),
    Exercise.basic(
        name: 'Russian Twists',
        targetMuscleGroup: 'Core',
        equipment: 'none',
        difficulty: 'intermediate',
        sets: '3',
        reps: '20'),
  ];

  void _showExerciseOptions(BuildContext context, int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.sync, color: Colors.white),
              title:
                  const Text('Replace', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _replaceExercise(index);
              },
            ),
            ListTile(
              leading: const Icon(Icons.arrow_upward, color: Colors.green),
              title: const Text('Recommend more',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _recommendMore(index);
              },
            ),
            ListTile(
              leading: const Icon(Icons.arrow_downward, color: Colors.orange),
              title: const Text('Recommend less',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _recommendLess(index);
              },
            ),
            ListTile(
              leading: const Icon(Icons.block, color: Colors.red),
              title: const Text('Don\'t recommend again',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _dontRecommend(index);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete from this workout',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _deleteExercise(index);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showReplaceExerciseDialog(int index) {
    final currentExercise = widget.workout.exercises[index];

    // Получаем упражнения той же группы мышц
    final matchingExercises = _alternativeExercises
        .where((e) => e.targetMuscleGroup == currentExercise.targetMuscleGroup)
        .toList();

    // Если нет упражнений для этой группы мышц, берем все упражнения
    final exercisesToChooseFrom =
        matchingExercises.isEmpty ? _alternativeExercises : matchingExercises;

    // Перемешиваем список и берем первые 6 (или меньше, если упражнений меньше)
    exercisesToChooseFrom.shuffle();
    final selectedExercises = exercisesToChooseFrom.take(6).toList();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Replace Exercise',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    onPressed: () {
                      Navigator.pop(context);
                      _showReplaceExerciseDialog(index);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Target: ${currentExercise.targetMuscleGroup.toUpperCase()}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              ...selectedExercises
                  .map((exercise) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey[800]!,
                            width: 1,
                          ),
                        ),
                        child: ListTile(
                          title: Text(
                            exercise.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${exercise.sets} sets × ${exercise.reps} reps',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                              Text(
                                'Difficulty: ${exercise.difficulty}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                          trailing: exercise.equipment != 'none'
                              ? Icon(
                                  Icons.fitness_center,
                                  color: Colors.white.withOpacity(0.7),
                                  size: 20,
                                )
                              : null,
                          onTap: () {
                            setState(() {
                              widget.workout.exercises[index] = exercise;
                            });
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Replaced with ${exercise.name}'),
                                action: SnackBarAction(
                                  label: 'Undo',
                                  onPressed: () {
                                    setState(() {
                                      widget.workout.exercises[index] =
                                          currentExercise;
                                    });
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ))
                  .toList(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _replaceExercise(int index) {
    _showReplaceExerciseDialog(index);
  }

  void _recommendMore(int index) async {
    try {
      // Обновляем предпочтение пользователя (лайк)
      final exercise = widget.workout.exercises[index];
      await _ratingService.updateUserPreference(exercise, 1);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Will recommend more exercises like ${exercise.name}'),
          backgroundColor: Colors.green.shade800,
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not update preference: $error'),
          backgroundColor: Colors.red.shade800,
        ),
      );
    }
  }

  void _recommendLess(int index) async {
    try {
      // Обновляем предпочтение пользователя (дизлайк)
      final exercise = widget.workout.exercises[index];
      await _ratingService.updateUserPreference(exercise, -1);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Will recommend less exercises like ${exercise.name}'),
          backgroundColor: Colors.orange.shade800,
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not update preference: $error'),
          backgroundColor: Colors.red.shade800,
        ),
      );
    }
  }

  void _dontRecommend(int index) async {
    try {
      // Устанавливаем сильный негативный рейтинг
      final exercise = widget.workout.exercises[index];
      final updatedExercise =
          exercise.copyWith(baseRating: 1.0, userPreference: -1);
      await _ratingService.updateExerciseRating(updatedExercise);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Won\'t recommend ${exercise.name} anymore'),
          backgroundColor: Colors.red.shade800,
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not update preference: $error'),
          backgroundColor: Colors.red.shade800,
        ),
      );
    }
  }

  void _deleteExercise(int index) {
    final deletedExercise = widget.workout.exercises[index];
    setState(() {
      widget.workout.exercises.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Exercise deleted from workout'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              widget.workout.exercises.insert(index, deletedExercise);
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF8B0000), // Dark red
              Color(0xFF4A1C1C), // Dark brown
              Color(0xFF1C4A1C), // Dark green
              Color(0xFF1C1C4A), // Dark blue
            ],
            stops: [0.0, 0.3, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with close button and title
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 20),
                      ),
                    ),
                    const Text(
                      'Focus Mode',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Inter',
                        letterSpacing: -0.5,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        _showRatingsDialog(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.insights,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),

              // Timer
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  _formatTime(_seconds),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 82,
                    fontWeight: FontWeight.w800,
                    fontStyle: FontStyle.italic,
                    fontFamily: 'Inter',
                    letterSpacing: -2,
                    height: 1,
                    shadows: [
                      Shadow(
                        offset: Offset(0, 4),
                        blurRadius: 8,
                        color: Colors.black38,
                      ),
                    ],
                  ),
                ),
              ),

              // Exercise count
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${widget.workout.exercises.length} exercises',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Inter',
                        letterSpacing: -0.5,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber[400],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.black,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),

              // Exercise list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: widget.workout.exercises.length,
                  itemBuilder: (context, index) {
                    final exercise = widget.workout.exercises[index];
                    final isCompleted = index == 0 || index == 2;
                    final isInProgress = index == 3;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (index == 1)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8, top: 8),
                            child: Row(
                              children: const [
                                Text(
                                  'SUPERSET',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                Text(
                                  ' — 3 rounds',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: isCompleted
                                  ? [
                                      const Color(0xFF4CAF50),
                                      const Color(0xFF388E3C),
                                    ]
                                  : isInProgress
                                      ? [
                                          const Color(0xFFFFB74D),
                                          const Color(0xFFF57C00),
                                        ]
                                      : [
                                          Colors.grey.shade800,
                                          Colors.grey.shade900,
                                        ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {},
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Colors.black26,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        isCompleted
                                            ? Icons.check
                                            : Icons.fitness_center,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            exercise.name,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: -0.5,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            isCompleted
                                                ? 'Completed'
                                                : isInProgress
                                                    ? '2/4 logged'
                                                    : '${exercise.sets} sets • ${exercise.reps} reps • 50 lbs',
                                            style: TextStyle(
                                              color:
                                                  Colors.white.withOpacity(0.8),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              letterSpacing: 0.2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () =>
                                          _showExerciseOptions(context, index),
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.black26,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.more_vert,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Bottom navigation
              Container(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildBottomButton(
                      icon: Icons.star,
                      isActive: _isFavorite,
                      activeColor: Colors.amber[400]!,
                      onTap: _toggleFavorite,
                    ),
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.amber[400]!, Colors.orange[700]!],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber[400]!.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(32),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ActiveWorkoutScreen(
                                  exercises: widget.workout.exercises,
                                  onComplete: () {
                                    // Добавьте здесь необходимые действия после завершения тренировки
                                  },
                                ),
                              ),
                            );
                          },
                          child: const Icon(
                            Icons.flag,
                            color: Colors.black,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                    _buildBottomButton(
                      icon: Icons.share,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Share functionality coming soon')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButton({
    required IconData icon,
    bool isActive = false,
    Color activeColor = Colors.white,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Icon(
            icon,
            color: isActive ? activeColor : Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${hours > 0 ? '$hours:' : ''}${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // Метод для отображения диалога с рейтингами упражнений
  void _showRatingsDialog(BuildContext context) async {
    // Получаем все упражнения с их рейтингами
    final exercises = await _ratingService.getExercisesWithRatings();

    // Сортируем по текущему рейтингу (от высокого к низкому)
    exercises.sort((a, b) =>
        b.calculateCurrentRating().compareTo(a.calculateCurrentRating()));

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Exercise Ratings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Exercises sorted by current rating',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: exercises.length,
                  itemBuilder: (context, index) {
                    final exercise = exercises[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exercise.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: LinearProgressIndicator(
                                  value:
                                      exercise.calculateCurrentRating() / 100,
                                  backgroundColor: Colors.grey[800],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _getRatingColor(
                                        exercise.calculateCurrentRating()),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                exercise
                                    .calculateCurrentRating()
                                    .toStringAsFixed(1),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Muscle: ${exercise.muscleGroup} • Used: ${exercise.usageCount} times',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'Preference: ${_getPreferenceText(exercise.userPreference)} • Favorite: ${exercise.isFavorite ? "Yes" : "No"}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Close',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRatingColor(double rating) {
    if (rating < 30) return Colors.blue.shade300;
    if (rating < 50) return Colors.green.shade300;
    if (rating < 70) return Colors.amber.shade300;
    return Colors.red.shade300;
  }

  String _getPreferenceText(int preference) {
    switch (preference) {
      case 1:
        return "Like";
      case -1:
        return "Dislike";
      default:
        return "Neutral";
    }
  }

  void _toggleFavorite() async {
    // Показываем индикатор загрузки
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 2,
            ),
            const SizedBox(width: 16),
            Text(_isFavorite
                ? 'Удаление из избранного...'
                : 'Добавление в избранное...'),
          ],
        ),
        duration: const Duration(seconds: 1),
      ),
    );

    // Сохраняем текущее состояние для отката при ошибке
    final previousState = _isFavorite;

    // Сразу обновляем UI для лучшего UX
    setState(() {
      _isFavorite = !_isFavorite;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Пользователь не авторизован');
      }

      if (_isFavorite) {
        // Добавляем в избранное
        print('📌 Добавление "${widget.workout.name}" в избранное...');

        // Создаем копию тренировки с обновленным флагом
        final workoutWithFavorite = widget.workout.copyWith(isFavorite: true);

        // Проверяем существование записи
        final existingRecord = await Supabase.instance.client
            .from('favorite_workouts')
            .select()
            .eq('user_id', userId)
            .eq('workout_id', widget.workout.id)
            .maybeSingle();

        if (existingRecord != null) {
          // Обновляем существующую запись
          await Supabase.instance.client.from('favorite_workouts').update({
            'workout_data': workoutWithFavorite.toJson(),
            'updated_at': DateTime.now().toIso8601String(),
          }).eq('id', existingRecord['id']);

          print('✅ Запись обновлена в таблице favorite_workouts');
        } else {
          // Создаем новую запись
          await Supabase.instance.client.from('favorite_workouts').insert({
            'user_id': userId,
            'workout_id': widget.workout.id,
            'workout_name': widget.workout.name,
            'workout_data': workoutWithFavorite.toJson(),
            'created_at': DateTime.now().toIso8601String(),
          });

          print('✅ Запись добавлена в таблицу favorite_workouts');
        }

        // Также обновляем статус в таблице workouts
        await Supabase.instance.client
            .from('workouts')
            .update({'is_favorite': true}).eq('id', widget.workout.id);

        print('✅ Статус обновлен в таблице workouts');

        // Обновляем провайдер
        final workoutProvider =
            Provider.of<WorkoutProvider>(context, listen: false);
        await workoutProvider.loadWorkouts();
      } else {
        // Удаляем из избранного
        print('🗑️ Удаление "${widget.workout.name}" из избранного...');

        // Удаляем запись
        await Supabase.instance.client
            .from('favorite_workouts')
            .delete()
            .eq('user_id', userId)
            .eq('workout_id', widget.workout.id);

        print('✅ Запись удалена из таблицы favorite_workouts');

        // Также обновляем статус в таблице workouts
        await Supabase.instance.client
            .from('workouts')
            .update({'is_favorite': false}).eq('id', widget.workout.id);

        print('✅ Статус обновлен в таблице workouts');

        // Обновляем провайдер
        final workoutProvider =
            Provider.of<WorkoutProvider>(context, listen: false);
        await workoutProvider.loadWorkouts();
      }

      // Показываем уведомление об успехе
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isFavorite
              ? '${widget.workout.name} добавлена в избранное'
              : '${widget.workout.name} удалена из избранного'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('❌ Ошибка: $e');

      // В случае ошибки откатываем UI к исходному состоянию
      setState(() {
        _isFavorite = previousState;
      });

      // Показываем ошибку
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}

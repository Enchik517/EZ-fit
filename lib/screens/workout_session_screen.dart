import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/workout.dart';
import '../models/workout_log.dart';
import '../providers/workout_provider.dart';
import 'dart:async';
import 'package:uuid/uuid.dart';
import './workout_summary_screen.dart';
import '../models/exercise.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/exercise_image_service.dart';
import '../services/video_thumbnail_service.dart';

class WorkoutSessionScreen extends StatefulWidget {
  final Workout workout;

  const WorkoutSessionScreen({
    super.key,
    required this.workout,
  });

  @override
  State<WorkoutSessionScreen> createState() => _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends State<WorkoutSessionScreen> {
  late List<bool> _completedExercises;
  final _startTime = DateTime.now();
  bool _isCompleting = false;
  int _currentExerciseIndex = 0;
  Timer? _timer;
  int _seconds = 0;
  bool _isResting = false;
  int _currentSet = 1;
  List<TextEditingController> _repsControllers = [];
  List<TextEditingController> _weightControllers = [];
  List<List<SetLog>> _exerciseSets = [];

  @override
  void initState() {
    super.initState();
    _completedExercises = List.filled(widget.workout.exercises.length, false);
    _initializeControllers();
    _startTimer();
  }

  void _initializeControllers() {
    // Инициализируем контроллеры и логи сетов для каждого упражнения
    _exerciseSets = List.generate(
      widget.workout.exercises.length,
      (i) => [],
    );

    // Инициализируем контроллеры для текущего упражнения
    _resetExerciseControllers();
  }

  void _resetExerciseControllers() {
    // Очищаем старые контроллеры
    for (var controller in _repsControllers) {
      controller.dispose();
    }
    for (var controller in _weightControllers) {
      controller.dispose();
    }

    final exercise = widget.workout.exercises[_currentExerciseIndex];
    // Извлекаем только первое число из строки
    final defaultReps =
        RegExp(r'\d+').firstMatch(exercise.reps)?.group(0) ?? '10';

    _repsControllers = List.generate(
      int.parse(exercise.sets),
      (index) => TextEditingController(text: defaultReps),
    );

    _weightControllers = List.generate(
      int.parse(exercise.sets),
      (index) => TextEditingController(text: "50"),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _repsControllers) {
      controller.dispose();
    }
    for (var controller in _weightControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _seconds = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++;
      });
    });
  }

  void _skipRest() {
    setState(() {
      _isResting = false;
      _startTimer();
    });
  }

  void _logSet() {
    final exercise = widget.workout.exercises[_currentExerciseIndex];

    // Получаем целевое количество подходов
    final targetSets = getTargetSets(exercise);

    // Проверяем, не превышено ли максимальное количество подходов
    if (_exerciseSets[_currentExerciseIndex].length >= targetSets) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum number of sets already reached'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final repsText = _repsControllers[_currentSet - 1].text.trim();
    final weightText = _weightControllers[_currentSet - 1].text.trim();

    // Validate input is not empty
    if (repsText.isEmpty || weightText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both reps and weight'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate input is numeric
    if (!RegExp(r'^\d+$').hasMatch(repsText) ||
        !RegExp(r'^\d+\.?\d*$').hasMatch(weightText)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid numbers for reps and weight'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Create new SetLog with validated input
      final setLog = SetLog(
        reps: int.parse(repsText),
        weight: double.parse(weightText),
      );

      setState(() {
        // Add set to list of sets for current exercise
        _exerciseSets[_currentExerciseIndex].add(setLog);

        if (_currentSet < int.parse(exercise.sets)) {
          _currentSet++;
          _isResting = true;
          _startTimer();
        } else {
          // Mark exercise as completed
          _completedExercises[_currentExerciseIndex] = true;
          if (_currentExerciseIndex < widget.workout.exercises.length - 1) {
            _currentExerciseIndex++;
            _currentSet = 1;
            _isResting = true;
            _resetExerciseControllers();
            _startTimer();
          } else {
            // Если это последнее упражнение, показываем итоги
            _completeWorkout();
          }
        }
      });

      // Показываем уведомление об успешном логировании
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 10,
            content: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.fitness_center, color: Colors.white),
                ),
                SizedBox(width: 16),
                Text(
                  'Set ${_currentSet} completed! 💪',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 1),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 10,
          content: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.error_outline, color: Colors.white),
              ),
              SizedBox(width: 16),
              Text(
                'Error logging set. Please try again.',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _completeWorkout() async {
    if (_isCompleting) return;

    setState(() => _isCompleting = true);
    _timer?.cancel();

    try {
      final workoutProvider =
          Provider.of<WorkoutProvider>(context, listen: false);
      final duration = DateTime.now().difference(_startTime);

      // Более точное определение выполненных и невыполненных упражнений
      final completedExercises = <ExerciseLog>[];
      final uncompletedExercises = <Exercise>[];

      // Проходим по всем упражнениям и проверяем их состояние
      for (int i = 0; i < widget.workout.exercises.length; i++) {
        final exercise = widget.workout.exercises[i];
        final sets = _exerciseSets[i];

        // Получаем целевое количество сетов
        int targetSets = getTargetSets(exercise);

        // Добавим отладочную печать
        print('Exercise: ${exercise.name}');
        print('Sets completed: ${sets.length}, Target: $targetSets');
        print('Marked as completed by user: ${_completedExercises[i]}');

        // Проверяем полное выполнение
        bool isFullyCompleted = false;

        // Если пользователь нажал кнопку "завершить упражнение" или все сеты выполнены
        if (_completedExercises[i] || sets.length >= targetSets) {
          isFullyCompleted = true;
        }

        print('Final is fully completed: $isFullyCompleted');

        // Если упражнение полностью выполнено
        if (isFullyCompleted) {
          completedExercises.add(ExerciseLog(
            exercise: exercise,
            sets: sets,
          ));
        }
        // Если упражнение имеет хотя бы один сет, но не все
        else if (sets.isNotEmpty) {
          // Добавляем как частично выполненное
          completedExercises.add(ExerciseLog(
            exercise: exercise,
            sets: sets,
          ));

          // Также добавляем в невыполненные, чтобы можно было продолжить
          uncompletedExercises.add(exercise);
        }
        // Если нет сетов вообще
        else {
          uncompletedExercises.add(exercise);
        }
      }

      // Создаем лог тренировки
      final workoutLog = WorkoutLog(
        workoutName: widget.workout.name,
        date: _startTime,
        duration: duration,
        exercises: completedExercises,
        isCompleted: uncompletedExercises.isEmpty,
        endTime: DateTime.now(),
      );

      await workoutProvider.addWorkoutLog(workoutLog);

      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WorkoutSummaryScreen(
              workoutLog: workoutLog,
              uncompletedExercises: uncompletedExercises,
            ),
          ),
        );
      }
    } catch (e, stackTrace) {
      print('Error during workout completion: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error completing workout: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCompleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentExercise = widget.workout.exercises[_currentExerciseIndex];
    final isLastExercise =
        _currentExerciseIndex == widget.workout.exercises.length - 1;
    final isLastSet = _currentSet == int.parse(currentExercise.sets);
    final allCompleted = _completedExercises.every((completed) => completed);

    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black,
              Color(0xFF1C1C1C),
              Color(0xFF2D1810),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        // Показываем диалог подтверждения перед выходом
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: const Color(0xFF1C1C1E),
                            title: const Text(
                              'End Workout?',
                              style: TextStyle(color: Colors.white),
                            ),
                            content: const Text(
                              'Are you sure you want to end this workout? Progress will be saved.',
                              style: TextStyle(color: Colors.white70),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _completeWorkout();
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                child: const Text('End Workout'),
                              ),
                            ],
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.close, color: Colors.white),
                      ),
                    ),
                    const Text(
                      'Focus',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    // Кнопка завершения тренировки
                    GestureDetector(
                      onTap: _completeWorkout,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.green,
                        ),
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
                    fontSize: 64,
                    fontWeight: FontWeight.w800,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 2,
                    height: 1,
                  ),
                ),
              ),

              // Exercise List
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.workout.exercises.length,
                itemBuilder: (context, index) {
                  final exercise = widget.workout.exercises[index];
                  final isCurrentExercise = index == _currentExerciseIndex;
                  final isCompleted = _completedExercises[index];
                  final hasProgress = _exerciseSets[index].isNotEmpty;

                  return Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isCompleted
                            ? [
                                const Color(0xFF4CAF50),
                                const Color(0xFF388E3C),
                              ]
                            : hasProgress
                                ? [
                                    const Color(0xFF4CAF50).withOpacity(0.3),
                                    const Color(0xFF388E3C).withOpacity(0.3),
                                  ]
                                : [
                                    Colors.black26,
                                    Colors.black12,
                                  ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isCompleted
                            ? const Color(0xFF4CAF50)
                            : isCurrentExercise
                                ? Colors.amber
                                : Colors.white12,
                        width: isCompleted || isCurrentExercise ? 2 : 1,
                      ),
                      boxShadow: isCompleted
                          ? [
                              BoxShadow(
                                color: const Color(0xFF4CAF50).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Изображение превью упражнения
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            width: 60,
                            height: 60,
                            child: _getExercisePreviewImage(exercise),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      exercise.name,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: isCurrentExercise ? 24 : 18,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                  ),
                                  if (isCompleted)
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF4CAF50),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                ],
                              ),
                              if (isCurrentExercise) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Set $_currentSet of ${exercise.sets}',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                              if (_exerciseSets[index].isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _exerciseSets[index].map((set) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isCompleted
                                            ? Colors.white.withOpacity(0.2)
                                            : Colors.black26,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${set.reps}×${set.weight}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              // Input Section (only show for current exercise)
              if (!_completedExercises[_currentExerciseIndex])
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white12,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'REPS',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'WEIGHT (lbs)',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInputField(
                              _repsControllers[_currentSet - 1],
                              '',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildInputField(
                              _weightControllers[_currentSet - 1],
                              '',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              // Bottom Navigation
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: _logSet,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'LOG SET',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                    if ((isLastExercise && isLastSet) || allCompleted)
                      Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.check, color: Colors.white),
                            onPressed: _isCompleting ? null : _completeWorkout,
                          ),
                        ),
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

  Widget _buildInputField(TextEditingController controller, String label) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white24,
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        onChanged: (value) {
          // Remove any non-numeric characters
          final numericOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
          if (numericOnly != value) {
            controller.text = numericOnly;
            controller.selection = TextSelection.fromPosition(
              TextPosition(offset: numericOnly.length),
            );
          }
        },
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 14,
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // Добавим вспомогательный метод для получения целевого числа сетов
  int getTargetSets(Exercise exercise) {
    try {
      return int.parse(exercise.sets);
    } catch (e) {
      // Если не удалось преобразовать, пробуем извлечь число из строки
      final match = RegExp(r'\d+').firstMatch(exercise.sets);
      return match != null ? int.tryParse(match.group(0)!) ?? 3 : 3;
    }
  }

  // Добавляем вспомогательный метод для получения превью изображения упражнения
  Widget _getExercisePreviewImage(Exercise exercise) {
    // Явно указываем приоритет видео, если оно есть
    if (exercise.videoUrl != null && exercise.videoUrl!.isNotEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          VideoThumbnailService.buildVideoThumbnail(
            exercise.videoUrl!,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            title: exercise.name,
          ),
          // Добавляем иконку воспроизведения поверх превью
          Center(
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      );
    }

    // Если нет видео, используем обычное изображение
    return ExerciseImageService.buildExerciseImage(
      exercise,
      width: double.infinity,
      height: double.infinity,
    );
  }

  // Создаем виджет иконки по умолчанию для упражнения
  Widget _buildDefaultExerciseIcon(Exercise exercise) {
    return ExerciseImageService.buildDefaultExerciseIcon(exercise);
  }
}

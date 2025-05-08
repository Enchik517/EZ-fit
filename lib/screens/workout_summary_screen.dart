import 'package:flutter/material.dart';
import '../models/workout_log.dart';
import '../models/exercise.dart';
import '../models/workout.dart';
import 'active_workout_screen.dart';
import 'package:provider/provider.dart';
import '../providers/workout_provider.dart';
import 'dart:math' show min;
import '../providers/auth_provider.dart';

class WorkoutSummaryScreen extends StatelessWidget {
  final WorkoutLog workoutLog;
  final List<Exercise> uncompletedExercises;

  const WorkoutSummaryScreen({
    Key? key,
    required this.workoutLog,
    required this.uncompletedExercises,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final totalSets = workoutLog.exercises.fold<int>(
      0,
      (sum, exercise) => sum + exercise.sets.length,
    );

    final totalReps = workoutLog.exercises.fold<int>(
      0,
      (sum, exercise) =>
          sum +
          exercise.sets.fold<int>(
            0,
            (setSum, set) => setSum + set.reps,
          ),
    );

    final totalWeight = workoutLog.exercises.fold<double>(
      0,
      (sum, exercise) =>
          sum +
          exercise.sets.fold<double>(
            0,
            (setSum, set) => setSum + ((set.weight ?? 0) * set.reps),
          ),
    );

    final targetMuscles = workoutLog.exercises
        .map((e) => e.exercise.targetMuscleGroup)
        .toSet()
        .toList();

    // Добавляем отладочную печать для понимания содержимого данных
    for (final exerciseLog in workoutLog.exercises) {
      print('Summary - Exercise: ${exerciseLog.exercise.name}');
      print('Summary - Sets: ${exerciseLog.sets.length}');
      print('Summary - isCompleted: ${exerciseLog.isCompleted}');
    }

    final fullyCompletedExercises =
        workoutLog.exercises.where((e) => e.isCompleted).toList();

    print('Fully completed count: ${fullyCompletedExercises.length}');

    final partiallyCompletedExercises = workoutLog.exercises
        .where((e) => !e.isCompleted && e.sets.isNotEmpty)
        .toList();

    print('Partially completed count: ${partiallyCompletedExercises.length}');

    final completelyUncompletedExercises = uncompletedExercises
        .where((exercise) => !partiallyCompletedExercises
            .any((e) => e.exercise.id == exercise.id))
        .toList();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          uncompletedExercises.isEmpty
              ? '🎉 Workout Complete!'
              : '📊 Workout Summary',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Статистика
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue.withOpacity(0.2),
                    Colors.purple.withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatCard(
                        icon: Icons.timer,
                        value: '${workoutLog.duration.inMinutes}',
                        label: 'Minutes',
                        color: Colors.blue,
                      ),
                      _buildStatCard(
                        icon: Icons.fitness_center,
                        value: totalSets.toString(),
                        label: 'Sets',
                        color: Colors.green,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatCard(
                        icon: Icons.repeat,
                        value: totalReps.toString(),
                        label: 'Total Reps',
                        color: Colors.orange,
                      ),
                      _buildStatCard(
                        icon: Icons.monitor_weight,
                        value: '${totalWeight.toStringAsFixed(1)}',
                        label: 'Total Weight (lbs)',
                        color: Colors.purple,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Группы мышц
            if (targetMuscles.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Text(
                  '💪 Target Muscle Groups',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: targetMuscles.map((muscle) {
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.blue.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        muscle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],

            // Выполненные упражнения
            if (fullyCompletedExercises.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Completed Exercises',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${fullyCompletedExercises.length} exercises',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              ...fullyCompletedExercises.map((exerciseLog) {
                return Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.green.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.fitness_center,
                        color: Colors.green[400],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              exerciseLog.exercise.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (exerciseLog.sets.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: exerciseLog.sets.map((set) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${set.reps} × ${set.weight} lbs',
                                      style: TextStyle(
                                        color: Colors.green[100],
                                        fontSize: 14,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Text(
                        '${min(exerciseLog.sets.length, getTargetSets(exerciseLog.exercise))}/${getTargetSets(exerciseLog.exercise)} sets',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],

            // Незавершенные упражнения
            if (partiallyCompletedExercises.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                child: Row(
                  children: [
                    const Icon(
                      Icons.incomplete_circle,
                      color: Colors.amber,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Partially Completed',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${partiallyCompletedExercises.length} remaining',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              ...partiallyCompletedExercises.map((exerciseLog) {
                return Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.amber.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.fitness_center,
                        color: Colors.amber[400],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              exerciseLog.exercise.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (exerciseLog.sets.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: exerciseLog.sets.map((set) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${set.reps} × ${set.weight} lbs',
                                      style: TextStyle(
                                        color: Colors.amber[100],
                                        fontSize: 14,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Text(
                        '${min(exerciseLog.sets.length, getTargetSets(exerciseLog.exercise))}/${getTargetSets(exerciseLog.exercise)} sets',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],

            // Полностью невыполненные упражнения
            if (completelyUncompletedExercises.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Uncompleted Exercises',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${completelyUncompletedExercises.length} remaining',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              ...completelyUncompletedExercises.map((exercise) {
                return Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.red.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.fitness_center,
                        color: Colors.red[400],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          exercise.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        '${exercise.sets} sets',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],

            const SizedBox(height: 100), // Отступ для кнопок
          ],
        ),
      ),
      bottomNavigationBar: uncompletedExercises.isNotEmpty
          ? _buildBottomButtons(context)
          : _buildCompletionButton(context),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: () async {
                // Показываем загрузку
                final loadingSnackBar = SnackBar(
                  behavior: SnackBarBehavior.floating,
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 10,
                  backgroundColor: Colors.black.withOpacity(0.8),
                  content: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(width: 20),
                      Text(
                        "Finishing workout...",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    ],
                  ),
                  duration: Duration(seconds: 1),
                );
                ScaffoldMessenger.of(context).showSnackBar(loadingSnackBar);

                // Получаем провайдеры
                final workoutProvider =
                    Provider.of<WorkoutProvider>(context, listen: false);
                final authProvider =
                    Provider.of<AuthProvider>(context, listen: false);

                // Создаем финальный лог с отметкой о завершении
                final finalWorkoutLog = WorkoutLog(
                  id: workoutLog.id,
                  workoutName: workoutLog.workoutName,
                  date: workoutLog.date,
                  duration: workoutLog.duration,
                  exercises: workoutLog.exercises,
                  notes: workoutLog.notes,
                  isCompleted: true, // Помечаем как ЗАВЕРШЕННУЮ - только здесь!
                  isFavorite: workoutLog.isFavorite,
                  endTime: DateTime.now(),
                );

                try {
                  // Сохраняем финальный лог
                  await workoutProvider.addWorkoutLog(finalWorkoutLog);

                  // Обновляем статистику пользователя в профиле
                  await workoutProvider.updateUserStats(finalWorkoutLog);

                  // Обновляем стрик тренировок
                  await workoutProvider.updateWorkoutStreak(authProvider);

                  // Загружаем обновленную статистику
                  await workoutProvider.loadStatistics();

                  // Перезагружаем профиль пользователя
                  await authProvider.loadUserProfile();

                  // Показываем уведомление об успешном завершении
                  final successSnackBar = SnackBar(
                    behavior: SnackBarBehavior.floating,
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 10,
                    content: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.check_circle, color: Colors.white),
                        ),
                        SizedBox(width: 16),
                        Text(
                          "Workout completed! Great job! 💪",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: Color(0xFF00BE13),
                    duration: Duration(seconds: 2),
                  );

                  // Возвращаемся на главный экран
                  if (context.mounted) {
                    // Показываем сообщение об успехе
                    ScaffoldMessenger.of(context).showSnackBar(successSnackBar);

                    // Переходим на главный экран
                    Navigator.of(context).pushReplacementNamed('/main');
                  }
                } catch (e) {
                  // В случае ошибки показываем уведомление
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        behavior: SnackBarBehavior.floating,
                        margin:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 10,
                        content: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.error_outline,
                                  color: Colors.white),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                "Error saving workout: ${e.toString()}",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
              ),
              child: const Text(
                'End Workout',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FilledButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ActiveWorkoutScreen(
                      exercises: uncompletedExercises,
                      onComplete: () {
                        Navigator.of(context).pushReplacementNamed('/main');
                      },
                      previousWorkoutLog: workoutLog,
                    ),
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Continue Workout',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: FilledButton(
        onPressed: () async {
          // Показываем загрузку
          final loadingSnackBar = SnackBar(
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 10,
            backgroundColor: Colors.black.withOpacity(0.8),
            content: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
                SizedBox(width: 20),
                Text(
                  "Finishing workout...",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                )
              ],
            ),
            duration: Duration(seconds: 1),
          );
          ScaffoldMessenger.of(context).showSnackBar(loadingSnackBar);

          // Получаем провайдеры
          final workoutProvider =
              Provider.of<WorkoutProvider>(context, listen: false);
          final authProvider =
              Provider.of<AuthProvider>(context, listen: false);

          // Создаем финальный лог с отметкой о завершении
          final finalWorkoutLog = WorkoutLog(
            id: workoutLog.id,
            workoutName: workoutLog.workoutName,
            date: workoutLog.date,
            duration: workoutLog.duration,
            exercises: workoutLog.exercises,
            notes: workoutLog.notes,
            isCompleted: true, // Помечаем как завершенную
            isFavorite: workoutLog.isFavorite,
            endTime: DateTime.now(),
          );

          try {
            // Сохраняем финальный лог
            await workoutProvider.addWorkoutLog(finalWorkoutLog);

            // Обновляем статистику пользователя в профиле
            await workoutProvider.updateUserStats(finalWorkoutLog);

            // Обновляем стрик тренировок
            await workoutProvider.updateWorkoutStreak(authProvider);

            // Загружаем обновленную статистику
            await workoutProvider.loadStatistics();

            // Перезагружаем профиль пользователя
            await authProvider.loadUserProfile();

            // Показываем уведомление об успешном завершении
            final successSnackBar = SnackBar(
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 10,
              content: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.check_circle, color: Colors.white),
                  ),
                  SizedBox(width: 16),
                  Text(
                    "Workout completed! Great job! 💪",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              backgroundColor: Color(0xFF00BE13),
              duration: Duration(seconds: 2),
            );

            // Возвращаемся на главный экран
            if (context.mounted) {
              // Показываем сообщение об успехе
              ScaffoldMessenger.of(context).showSnackBar(successSnackBar);

              // Переходим на главный экран
              Navigator.of(context).pushReplacementNamed('/main');
            }
          } catch (e) {
            // В случае ошибки показываем уведомление
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
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
                      Expanded(
                        child: Text(
                          "Error saving workout: ${e.toString()}",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
        style: FilledButton.styleFrom(
          backgroundColor: Colors.green,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Complete Workout',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  int getTargetSets(Exercise exercise) {
    try {
      return int.parse(exercise.sets);
    } catch (e) {
      // Если не удалось преобразовать, пробуем извлечь число из строки
      final match = RegExp(r'\d+').firstMatch(exercise.sets);
      return match != null ? int.tryParse(match.group(0)!) ?? 3 : 3;
    }
  }

  int min(int a, int b) {
    return a < b ? a : b;
  }
}

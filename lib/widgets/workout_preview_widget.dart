import 'package:flutter/material.dart';
import '../models/workout.dart';
import '../providers/subscription_provider.dart';
import 'package:provider/provider.dart';

class WorkoutPreviewWidget extends StatelessWidget {
  final Workout workout;
  final bool showFullExerciseList;
  final int maxExercises;

  const WorkoutPreviewWidget({
    Key? key,
    required this.workout,
    this.showFullExerciseList = false,
    this.maxExercises = 3,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final subscriptionProvider =
        Provider.of<SubscriptionProvider>(context, listen: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Заголовок тренировки
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                workout.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Сложность: ${workout.difficulty} • ${workout.duration} мин',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                workout.description,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),

        // Информация о тренировке
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16.0),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoItem(
                label: 'Упражнения',
                value: workout.exercises.length.toString(),
                icon: Icons.fitness_center,
              ),
              _buildInfoItem(
                label: 'Сложность',
                value: workout.difficulty,
                icon: Icons.trending_up,
              ),
              _buildInfoItem(
                label: 'Длительность',
                value: '${workout.duration} мин',
                icon: Icons.timer,
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Список упражнений (ограниченный)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Упражнения',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: showFullExerciseList
                    ? workout.exercises.length
                    : workout.exercises.length > maxExercises
                        ? maxExercises
                        : workout.exercises.length,
                itemBuilder: (context, index) {
                  final exercise = workout.exercises[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.amber,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                exercise.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '${exercise.sets} подходов × ${exercise.reps} повторений',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              // "Показать больше" для неподписанных пользователей
              if (!showFullExerciseList &&
                  workout.exercises.length > maxExercises)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Center(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        subscriptionProvider.showSubscription();
                      },
                      icon: const Icon(Icons.lock, size: 16),
                      label: const Text(
                        'Получить доступ к полной тренировке',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.amber,
                        side: const BorderSide(color: Colors.amber),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.amber,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

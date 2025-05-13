import 'package:flutter/material.dart';
import '../models/workout.dart';
import '../providers/subscription_provider.dart';
import 'package:provider/provider.dart';

class WorkoutPreviewWidget extends StatelessWidget {
  final Workout workout;

  const WorkoutPreviewWidget({
    Key? key,
    required this.workout,
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
                workout.description,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildInfoChip(Icons.timer, '${workout.duration} мин'),
                  const SizedBox(width: 8),
                  _buildInfoChip(Icons.fitness_center, workout.difficulty),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                      Icons.local_fire_department, '${workout.calories} ккал'),
                ],
              ),
            ],
          ),
        ),

        // Превью упражнений (первые 2)
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Предварительный просмотр упражнений',
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
                itemCount:
                    workout.exercises.length > 2 ? 2 : workout.exercises.length,
                itemBuilder: (context, index) {
                  final exercise = workout.exercises[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      backgroundColor: Colors.amber,
                      child: Icon(Icons.fitness_center, color: Colors.black),
                    ),
                    title: Text(
                      exercise.name,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      '${exercise.sets} сетов × ${exercise.reps}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  );
                },
              ),

              // Если есть еще упражнения, показываем сообщение
              if (workout.exercises.length > 2)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'и ещё ${workout.exercises.length - 2} упражнений',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Оформите подписку, чтобы получить доступ ко всем упражнениям и возможностям тренировки',
                  style: TextStyle(color: Colors.amber, fontSize: 16),
                ),
              ),
            ],
          ),
        ),

        // Кнопка подписки
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: ElevatedButton(
              onPressed: () {
                subscriptionProvider.showSubscription();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text(
                'Получить подписку',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.amber, size: 16),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

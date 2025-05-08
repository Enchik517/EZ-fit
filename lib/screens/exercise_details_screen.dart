import 'package:flutter/material.dart';
import '../models/exercise.dart';
import '../widgets/exercise_image_uploader.dart';
import '../services/exercise_image_service.dart';
import 'package:provider/provider.dart';
import '../providers/workout_provider.dart';

class ExerciseDetailsScreen extends StatefulWidget {
  final Exercise exercise;

  const ExerciseDetailsScreen({Key? key, required this.exercise})
      : super(key: key);

  @override
  State<ExerciseDetailsScreen> createState() => _ExerciseDetailsScreenState();
}

class _ExerciseDetailsScreenState extends State<ExerciseDetailsScreen> {
  late Exercise _exercise;

  @override
  void initState() {
    super.initState();
    _exercise = widget.exercise;
  }

  void _updateExerciseImage(String imageUrl) {
    setState(() {
      _exercise = _exercise.copyWith(imageUrl: imageUrl);
    });

    // Обновляем упражнение в провайдере тренировок
    final workoutProvider =
        Provider.of<WorkoutProvider>(context, listen: false);
    workoutProvider.updateExercise(_exercise);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _exercise.name,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заменяем контейнер с иконкой на виджет загрузки изображения
            ExerciseImageUploader(
              exercise: _exercise,
              onImageUploaded: _updateExerciseImage,
              height: 200,
              width: double.infinity,
            ),
            const SizedBox(height: 24),
            if (_exercise.videoUrl != null && _exercise.videoUrl!.isNotEmpty)
              ElevatedButton.icon(
                icon: const Icon(Icons.play_circle_outline),
                label: const Text('Смотреть видео'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  // Тут можно добавить открытие видео
                },
              ),
            if (_exercise.videoUrl != null) const SizedBox(height: 24),
            Text(
              'Детали',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Группа мышц', _exercise.muscleGroup),
            _buildDetailRow('Подходы', _exercise.sets.toString()),
            _buildDetailRow('Повторения', _exercise.reps.toString()),
            if (_exercise.weight != null)
              _buildDetailRow('Вес', '${_exercise.weight} кг'),
            if (_exercise.difficultyLevel != null)
              _buildDetailRow('Сложность', _exercise.difficultyLevel),
            if (_exercise.description != null)
              _buildDetailRow('Описание', _exercise.description),
            if (_exercise.instructions != null)
              _buildDetailRow('Инструкции', _exercise.instructions!),
            if (_exercise.commonMistakes != null &&
                _exercise.commonMistakes!.isNotEmpty)
              _buildDetailList(
                  'Распространенные ошибки', _exercise.commonMistakes!),
            if (_exercise.modifications != null &&
                _exercise.modifications!.isNotEmpty)
              _buildDetailList(
                  'Модификации упражнения', _exercise.modifications!),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailList(String label, List<String> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4, left: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(color: Colors.white)),
                    Expanded(
                      child: Text(
                        item,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/exercise.dart';

class ExerciseVideoInstructions extends StatefulWidget {
  final Exercise exercise;
  final String? videoUrl;

  const ExerciseVideoInstructions({
    Key? key,
    required this.exercise,
    this.videoUrl,
  }) : super(key: key);

  @override
  _ExerciseVideoInstructionsState createState() =>
      _ExerciseVideoInstructionsState();
}

class _ExerciseVideoInstructionsState extends State<ExerciseVideoInstructions> {
  VideoPlayerController? _controller;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    String videoUrl = widget.videoUrl ?? '';

    // Проверяем, есть ли URL видео
    if (videoUrl.isEmpty) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      return;
    }

    try {
      _controller = VideoPlayerController.network(videoUrl);

      // Инициализируем контроллер
      await _controller!.initialize();

      // Получаем первый кадр и ставим на паузу
      if (_controller!.value.isInitialized) {
        // Показываем первый кадр и ставим на паузу
        await _controller!.seekTo(Duration(milliseconds: 100));
        await _controller!.pause();
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Ошибка инициализации видео: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewPadding.bottom,
      ),
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
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              widget.exercise.name,
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Video player (paused) or placeholder
          Container(
            width: double.infinity,
            height: 220,
            margin: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Video player или заглушка
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _buildVideoOrPlaceholder(),
                ),

                // Overlay с затемнением и иконкой
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),

                // Значок паузы
                Center(
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    child: Icon(
                      _hasError ? Icons.videocam_off : Icons.pause,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Exercise instructions
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Instructions'),
                SizedBox(height: 8),
                _buildInstructionsText(widget.exercise.instructions),
                SizedBox(height: 16),
                _buildSectionTitle('Target Muscle'),
                SizedBox(height: 8),
                _buildInfoItem(widget.exercise.targetMuscleGroup.toUpperCase()),
                SizedBox(height: 16),
                _buildSectionTitle('Sets & Reps'),
                SizedBox(height: 8),
                _buildInfoItem(
                    "${widget.exercise.sets} sets × ${widget.exercise.reps} reps"),
                SizedBox(height: 16),
                _buildSectionTitle('Equipment Needed'),
                SizedBox(height: 8),
                _buildInfoItem(widget.exercise.equipment.toUpperCase()),
                SizedBox(height: 16),
                _buildSectionTitle('Difficulty'),
                SizedBox(height: 8),
                _buildDifficultyIndicator(widget.exercise.difficultyLevel),
              ],
            ),
          ),

          // Bottom padding
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildVideoOrPlaceholder() {
    if (_isLoading) {
      // Показываем индикатор загрузки
      return Container(
        color: Colors.black,
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    } else if (_hasError ||
        _controller == null ||
        !_controller!.value.isInitialized) {
      // Показываем изображение если видео не загрузилось
      return _buildVideoPlaceholder(widget.exercise);
    } else {
      // Показываем кадр из видео
      return AspectRatio(
        aspectRatio: _controller!.value.aspectRatio,
        child: VideoPlayer(_controller!),
      );
    }
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildInstructionsText(String? instructions) {
    return Text(
      instructions ?? 'No instructions available for this exercise.',
      style: TextStyle(
        color: Colors.white.withOpacity(0.8),
        fontSize: 14,
        height: 1.5,
      ),
    );
  }

  Widget _buildInfoItem(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildDifficultyIndicator(String difficulty) {
    int level = 1;

    if (difficulty.toLowerCase().contains('intermediate')) {
      level = 2;
    } else if (difficulty.toLowerCase().contains('advanced')) {
      level = 3;
    }

    return Row(
      children: List.generate(3, (index) {
        return Container(
          width: 50,
          height: 8,
          margin: EdgeInsets.only(right: index < 2 ? 4 : 0),
          decoration: BoxDecoration(
            color: index < level
                ? _getDifficultyColor(level)
                : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Color _getDifficultyColor(int level) {
    switch (level) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.amber;
      case 3:
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  Widget _buildVideoPlaceholder(Exercise exercise) {
    String imageUrl;

    // Определяем изображение в зависимости от группы мышц
    if (exercise.muscleGroup.toLowerCase().contains('chest')) {
      imageUrl =
          'https://images.unsplash.com/photo-1534368959876-26bf04f2c947?w=800';
    } else if (exercise.muscleGroup.toLowerCase().contains('back')) {
      imageUrl =
          'https://images.unsplash.com/photo-1603287681836-b174ce5074c2?w=800';
    } else if (exercise.muscleGroup.toLowerCase().contains('leg')) {
      imageUrl =
          'https://images.unsplash.com/photo-1574680096145-d05b474e2155?w=800';
    } else if (exercise.muscleGroup.toLowerCase().contains('shoulder')) {
      imageUrl =
          'https://images.unsplash.com/photo-1530822847156-e092f2fc04c8?w=800';
    } else if (exercise.muscleGroup.toLowerCase().contains('arm') ||
        exercise.muscleGroup.toLowerCase().contains('bicep') ||
        exercise.muscleGroup.toLowerCase().contains('tricep')) {
      imageUrl =
          'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?w=800';
    } else if (exercise.muscleGroup.toLowerCase().contains('core') ||
        exercise.muscleGroup.toLowerCase().contains('abs')) {
      imageUrl =
          'https://images.unsplash.com/photo-1544216428-10c1ec0e76c1?w=800';
    } else {
      // Стандартное изображение
      imageUrl =
          'https://images.unsplash.com/photo-1517963879433-6ad2b056d712?w=800';
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.black54,
          child: Center(
            child: Icon(
              Icons.image_not_supported,
              color: Colors.white54,
              size: 48,
            ),
          ),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: Colors.black,
          child: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        );
      },
    );
  }
}

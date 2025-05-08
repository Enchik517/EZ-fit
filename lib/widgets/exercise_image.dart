import 'package:flutter/material.dart';
import '../services/exercise_image_service.dart';
import '../services/video_thumbnail_service.dart';
import '../models/exercise.dart';

class ExerciseImage extends StatefulWidget {
  final Exercise? exercise;
  final String? exerciseName;
  final String? imageUrl;
  final String? videoUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final String? title;

  const ExerciseImage({
    super.key,
    this.exercise,
    this.exerciseName,
    this.imageUrl,
    this.videoUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.title,
  }) : assert(
            exercise != null ||
                exerciseName != null ||
                imageUrl != null ||
                videoUrl != null,
            'Должен быть указан либо exercise, либо exerciseName, либо imageUrl/videoUrl');

  @override
  State<ExerciseImage> createState() => _ExerciseImageState();
}

class _ExerciseImageState extends State<ExerciseImage> {
  @override
  Widget build(BuildContext context) {
    final String displayTitle =
        widget.title ?? widget.exercise?.name ?? widget.exerciseName ?? '';

    // Если есть упражнение с видео - используем превью из видео
    if (widget.exercise?.videoUrl != null &&
        widget.exercise!.videoUrl!.isNotEmpty) {
      return VideoThumbnailService.buildVideoThumbnail(
        widget.exercise!.videoUrl!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        title: displayTitle,
      );
    }

    // Если напрямую передан videoUrl - используем его
    if (widget.videoUrl != null && widget.videoUrl!.isNotEmpty) {
      return VideoThumbnailService.buildVideoThumbnail(
        widget.videoUrl!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        title: displayTitle,
      );
    }

    // Если нет видео, но есть imageUrl - используем его
    if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
      return _buildImageFromUrl(widget.imageUrl!, displayTitle);
    }

    // Если есть упражнение с imageUrl - используем его
    if (widget.exercise?.imageUrl != null &&
        widget.exercise!.imageUrl!.isNotEmpty) {
      return _buildImageFromUrl(widget.exercise!.imageUrl!, displayTitle);
    }

    // В остальных случаях получаем URL через сервис
    final String imageUrl = _getExerciseImageUrl();
    return _buildImageFromUrl(imageUrl, displayTitle);
  }

  // Метод для отображения изображения из URL
  Widget _buildImageFromUrl(String url, String displayTitle) {
    return Container(
      width: widget.width,
      height: widget.height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Основное изображение
          Image.network(
            url,
            fit: widget.fit,
            width: widget.width,
            height: widget.height,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) {
                return child;
              }
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              debugPrint('⚠️ Ошибка загрузки изображения: $url');
              debugPrint('⚠️ Ошибка: $error');
              return _buildErrorWidget();
            },
          ),

          // Градиент внизу (если есть заголовок)
          if (displayTitle.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Text(
                  displayTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getExerciseImageUrl() {
    if (widget.exercise != null) {
      return ExerciseImageService.getExerciseImageUrl(widget.exercise!);
    }

    // Для других случаев используем стандартное изображение
    return _getDefaultImageForExerciseName(widget.exerciseName ?? '');
  }

  String _getDefaultImageForExerciseName(String name) {
    // Словарь изображений по умолчанию
    final Map<String, String> defaultImageUrls = {
      // Базовые упражнения (основные движения)
      'push':
          'https://images.unsplash.com/photo-1598971639058-fab3c3109a00?w=800',
      'squat':
          'https://images.unsplash.com/photo-1574680096145-d05b474e2155?w=800',
      'pull':
          'https://images.unsplash.com/photo-1598266863556-9e58b0592836?w=800',
      'lunge':
          'https://images.unsplash.com/photo-1597452485669-2c7bb5fef90d?w=800',
      'plank':
          'https://images.unsplash.com/photo-1566241142559-40e1dab266c6?w=800',
      'deadlift':
          'https://images.unsplash.com/photo-1594737625785-a6cbdabd333c?w=800',
      'row': 'https://images.unsplash.com/photo-1544033527-b192daee1f5b?w=800',
      'press':
          'https://images.unsplash.com/photo-1532029837206-abbe2b7620e3?w=800',
    };

    // Конвертируем в нижний регистр для сравнения
    final lowerName = name.toLowerCase();

    // Ищем соответствие в словаре
    for (final entry in defaultImageUrls.entries) {
      if (lowerName.contains(entry.key)) {
        return entry.value;
      }
    }

    // Для групп мышц
    if (lowerName.contains('chest') || lowerName.contains('pec')) {
      return 'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=800';
    } else if (lowerName.contains('back')) {
      return 'https://images.unsplash.com/photo-1541534741688-6078c6bfb5c5?w=800';
    } else if (lowerName.contains('leg') || lowerName.contains('quad')) {
      return 'https://images.unsplash.com/photo-1574680096145-d05b474e2155?w=800';
    } else if (lowerName.contains('shoulder')) {
      return 'https://images.unsplash.com/photo-1530822847156-e092f2fc04c8?w=800';
    } else if (lowerName.contains('arm') ||
        lowerName.contains('bicep') ||
        lowerName.contains('tricep')) {
      return 'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?w=800';
    } else if (lowerName.contains('core') || lowerName.contains('abs')) {
      return 'https://images.unsplash.com/photo-1544216428-10c1ec0e76c1?w=800';
    }

    // По умолчанию - общее изображение фитнеса
    return 'https://images.unsplash.com/photo-1517963879433-6ad2b056d712?w=800';
  }

  Widget _buildErrorWidget() {
    return Container(
      color: Colors.grey[800],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center,
              color: Colors.white.withOpacity(0.6),
              size: 40,
            ),
            if (widget.exercise != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  widget.exercise!.name,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

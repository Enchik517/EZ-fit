import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/exercise.dart';
import 'video_thumbnail_service.dart';

class ExerciseImageService {
  static final _supabase = Supabase.instance.client;

  // Метод для загрузки изображения в Supabase
  static Future<String?> uploadExerciseImage(
      String exerciseId, Uint8List imageBytes, String extension) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final path = 'exercises/$userId/${exerciseId}_image.$extension';

      await _supabase.storage
          .from('exercise_images')
          .uploadBinary(path, imageBytes);

      // Получаем публичный URL для загруженного изображения
      final imageUrl =
          _supabase.storage.from('exercise_images').getPublicUrl(path);

      return imageUrl;
    } catch (e) {
      debugPrint('Ошибка загрузки изображения упражнения: $e');
      return null;
    }
  }

  // Метод для обновления изображения упражнения в базе данных
  static Future<bool> updateExerciseImageUrl(
      String exerciseId, String imageUrl) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await _supabase
          .from('exercises')
          .update({'image_url': imageUrl})
          .eq('id', exerciseId)
          .eq('user_id', userId);

      return true;
    } catch (e) {
      debugPrint('Ошибка обновления URL изображения упражнения: $e');
      return false;
    }
  }

  // Метод для получения URL изображения для упражнения
  static String getExerciseImageUrl(Exercise exercise) {
    // Если у упражнения уже есть URL изображения, используем его
    if (exercise.imageUrl != null && exercise.imageUrl!.isNotEmpty) {
      debugPrint('🖼️ Используем заданный imageUrl: ${exercise.imageUrl}');
      return exercise.imageUrl!;
    }

    // Если есть видеоURL, используем его для генерации превью
    if (exercise.videoUrl != null && exercise.videoUrl!.isNotEmpty) {
      debugPrint('🎬 Будет использовано превью из видео: ${exercise.videoUrl}');
      return exercise.videoUrl!;
    }

    // Если нет ни изображения, ни видео, используем изображение по умолчанию
    // на основе имени упражнения
    debugPrint(
        '⚠️ Нет URL изображения или видео, используем стандартное изображение');
    return _getDefaultImageForName(exercise.name, exercise.muscleGroup);
  }

  // Получает стандартное изображение по имени упражнения и группе мышц
  static String _getDefaultImageForName(String name, String muscleGroup) {
    final Map<String, String> defaultImageUrls = {
      // Базовые упражнения
      'Push-Up':
          'https://images.unsplash.com/photo-1598971639058-fab3c3109a00?w=800',
      'Knee Push-Up':
          'https://images.unsplash.com/photo-1598971639058-fab3c3109a00?w=800',
      'Squat':
          'https://images.unsplash.com/photo-1574680096145-d05b474e2155?w=800',
      'Pull-Up':
          'https://images.unsplash.com/photo-1598266863556-9e58b0592836?w=800',
      'Lunge':
          'https://images.unsplash.com/photo-1597452485669-2c7bb5fef90d?w=800',
      'Plank':
          'https://images.unsplash.com/photo-1566241142559-40e1dab266c6?w=800',
    };

    // Поиск частичных совпадений в имени упражнения
    for (final entry in defaultImageUrls.entries) {
      if (name.toLowerCase().contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }

    // Если не нашли соответствия, определяем по группе мышц
    if (muscleGroup.toLowerCase().contains('chest')) {
      return 'https://images.unsplash.com/photo-1534368959876-26bf04f2c947?w=800';
    } else if (muscleGroup.toLowerCase().contains('back')) {
      return 'https://images.unsplash.com/photo-1603287681836-b174ce5074c2?w=800';
    } else if (muscleGroup.toLowerCase().contains('leg') ||
        muscleGroup.toLowerCase().contains('quad')) {
      return 'https://images.unsplash.com/photo-1574680096145-d05b474e2155?w=800';
    } else if (muscleGroup.toLowerCase().contains('shoulder')) {
      return 'https://images.unsplash.com/photo-1530822847156-e092f2fc04c8?w=800';
    } else if (muscleGroup.toLowerCase().contains('arm') ||
        muscleGroup.toLowerCase().contains('bicep') ||
        muscleGroup.toLowerCase().contains('tricep')) {
      return 'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?w=800';
    } else if (muscleGroup.toLowerCase().contains('core') ||
        muscleGroup.contains('abs')) {
      return 'https://images.unsplash.com/photo-1544216428-10c1ec0e76c1?w=800';
    }

    // По умолчанию
    return 'https://images.unsplash.com/photo-1517963879433-6ad2b056d712?w=800';
  }

  // Метод для проверки существования файла по URL
  static Future<bool> urlExists(String url) async {
    try {
      final response = await http.head(Uri.parse(url));
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      return false;
    }
  }

  // Создаем виджет для отображения изображения упражнения
  static Widget buildExerciseImage(
    Exercise exercise, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
  }) {
    try {
      // Если есть видео URL, используем превью из видео
      if (exercise.videoUrl != null && exercise.videoUrl!.isNotEmpty) {
        final Widget thumbnailWidget =
            VideoThumbnailService.buildVideoThumbnail(
          exercise.videoUrl!,
          width: width,
          height: height,
          fit: fit,
          title: exercise.name,
        );

        if (borderRadius != null) {
          return ClipRRect(
            borderRadius: borderRadius,
            child: thumbnailWidget,
          );
        }
        return thumbnailWidget;
      }

      // Если нет конкретного видео для этого упражнения,
      // используем демонстрационное видео для соответствующей группы мышц
      // или резервное изображение, если видео недоступны
      String demoVideoUrl = _getDemoVideoForExercise(exercise);

      final Widget thumbnailWidget = VideoThumbnailService.buildVideoThumbnail(
        demoVideoUrl,
        width: width,
        height: height,
        fit: fit,
        title: exercise.name,
      );

      if (borderRadius != null) {
        return ClipRRect(
          borderRadius: borderRadius,
          child: thumbnailWidget,
        );
      }
      return thumbnailWidget;
    } catch (e) {
      // При любой ошибке показываем стандартную иконку
      debugPrint('⚠️ Ошибка при построении изображения упражнения: $e');
      return buildDefaultExerciseIcon(
        exercise,
        width: width,
        height: height,
        backgroundColor: const Color(0xFF1E1E1E),
      );
    }
  }

  // Получает URL демонстрационного видео в зависимости от типа упражнения
  static String _getDemoVideoForExercise(Exercise exercise) {
    final muscleGroup = exercise.muscleGroup.toLowerCase();
    final name = exercise.name.toLowerCase();

    // Базовый URL для видео в Supabase
    const String baseSupabaseUrl =
        'https://efctwzpqpukhpqvpirrt.supabase.co/storage/v1/object/public/exercises/';

    // Категоризация по имени упражнения
    if (name.contains('push-up') ||
        name.contains('push up') ||
        name.contains('отжим')) {
      return '${baseSupabaseUrl}demo/push_up.mp4'; // Демонстрация отжиманий
    } else if (name.contains('squat') || name.contains('присед')) {
      return '${baseSupabaseUrl}demo/squat.mp4'; // Демонстрация приседаний
    } else if (name.contains('pull-up') ||
        name.contains('pull up') ||
        name.contains('подтяг')) {
      return '${baseSupabaseUrl}demo/pull_up.mp4'; // Демонстрация подтягиваний
    } else if (name.contains('lunge') || name.contains('выпад')) {
      return '${baseSupabaseUrl}demo/lunge.mp4'; // Демонстрация выпадов
    } else if (name.contains('plank') || name.contains('планк')) {
      return '${baseSupabaseUrl}demo/plank.mp4'; // Демонстрация планки
    } else if (name.contains('deadlift') || name.contains('тяга')) {
      return '${baseSupabaseUrl}demo/deadlift.mp4'; // Демонстрация тяги
    } else if (name.contains('bench press') || name.contains('жим лежа')) {
      return '${baseSupabaseUrl}demo/bench_press.mp4'; // Демонстрация жима лежа
    }

    // Категоризация по группе мышц, если не нашли по имени
    if (muscleGroup.contains('chest')) {
      return '${baseSupabaseUrl}demo/chest.mp4'; // Упражнения на грудь
    } else if (muscleGroup.contains('back')) {
      return '${baseSupabaseUrl}demo/back.mp4'; // Упражнения на спину
    } else if (muscleGroup.contains('leg') || muscleGroup.contains('quad')) {
      return '${baseSupabaseUrl}demo/legs.mp4'; // Упражнения на ноги
    } else if (muscleGroup.contains('shoulder')) {
      return '${baseSupabaseUrl}demo/shoulders.mp4'; // Упражнения на плечи
    } else if (muscleGroup.contains('arm') ||
        muscleGroup.contains('bicep') ||
        muscleGroup.contains('tricep')) {
      return '${baseSupabaseUrl}demo/arms.mp4'; // Упражнения на руки
    } else if (muscleGroup.contains('core') || muscleGroup.contains('abs')) {
      return '${baseSupabaseUrl}demo/core.mp4'; // Упражнения на пресс
    }

    // Общее демонстрационное видео по умолчанию
    return '${baseSupabaseUrl}demo/default.mp4';
  }

  // Создаем виджет для отображения иконки по умолчанию
  static Widget buildDefaultExerciseIcon(
    Exercise exercise, {
    double? width,
    double? height,
    Color backgroundColor = const Color(0xFF1E1E1E),
    Color iconColor = Colors.white70,
  }) {
    // Защита от бесконечных значений и NaN
    if (width != null && !width.isFinite) {
      debugPrint('⚠️ Предотвращение ошибки: width=$width заменено на null');
      width = null;
    }

    if (height != null && !height.isFinite) {
      debugPrint('⚠️ Предотвращение ошибки: height=$height заменено на null');
      height = null;
    }

    // Определяем иконку в зависимости от группы мышц
    IconData iconData = Icons.fitness_center;

    // Выбираем иконку в зависимости от группы мышц
    if (exercise.muscleGroup.toLowerCase().contains('chest')) {
      iconData = Icons.accessibility_new;
    } else if (exercise.muscleGroup.toLowerCase().contains('back')) {
      iconData = Icons.accessibility;
    } else if (exercise.muscleGroup.toLowerCase().contains('leg')) {
      iconData = Icons.directions_run;
    } else if (exercise.muscleGroup.toLowerCase().contains('core') ||
        exercise.muscleGroup.toLowerCase().contains('abs')) {
      iconData = Icons.airline_seat_flat;
    } else if (exercise.muscleGroup.toLowerCase().contains('shoulder')) {
      iconData = Icons.accessibility_new;
    } else if (exercise.muscleGroup.toLowerCase().contains('arm') ||
        exercise.muscleGroup.toLowerCase().contains('bicep') ||
        exercise.muscleGroup.toLowerCase().contains('tricep')) {
      iconData = Icons.fitness_center;
    }

    return Container(
      width: width,
      height: height,
      color: backgroundColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min, // Фиксируем проблему переполнения
          children: [
            Icon(
              iconData,
              size: 28, // Уменьшаем размер иконки
              color: iconColor,
            ),
            if (width != null && width > 100 && width.isFinite)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  exercise.name,
                  style: TextStyle(color: iconColor, fontSize: 12),
                  textAlign: TextAlign.center,
                  maxLines: 1, // Ограничиваем до одной строки
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:cached_memory_image/cached_memory_image.dart';
import 'package:path_provider/path_provider.dart';

class VideoThumbnailService {
  static final Map<String, Uint8List> _thumbnailCache = {};

  /// Получает превью из видео по URL
  static Future<Uint8List?> getThumbnailFromVideo(String videoUrl) async {
    try {
      // Формируем ключ для кэша, используя хеш от URL
      final String cacheKey = 'video_thumb_${videoUrl.hashCode}';

      // Проверяем кэш в памяти
      if (_thumbnailCache.containsKey(cacheKey)) {
        debugPrint('🎬 Используем кэшированное превью для: $videoUrl');
        return _thumbnailCache[cacheKey];
      }

      debugPrint('🎬 Генерируем превью для: $videoUrl');

      // Пробуем загрузить из файловой системы устройства
      try {
        final appDir = await getApplicationDocumentsDirectory();
        final file = File('${appDir.path}/thumbnails/$cacheKey.jpg');

        // Если файл существует, загрузим из него
        if (await file.exists()) {
          debugPrint('✅ Загружаем превью из файлового кэша: $cacheKey');
          final cachedData = await file.readAsBytes();
          if (cachedData.isNotEmpty) {
            _thumbnailCache[cacheKey] = cachedData;
            return cachedData;
          }
        }
      } catch (e) {
        debugPrint('❌ Ошибка при загрузке из файлового кэша: $e');
        // Продолжаем, если произошла ошибка при загрузке из кэша
      }

      // Если URL содержит [project-ref], заменяем на правильный Supabase ID
      if (videoUrl.contains('[project-ref]')) {
        videoUrl = videoUrl.replaceAll('[project-ref]', 'efctwzpqpukhpqvpirrt');
      }

      // Проверяем, если это Supabase видео
      if (videoUrl.contains('supabase')) {
        // Пробуем сначала загрузить готовое превью
        final previewUrl = videoUrl.replaceAll('.mp4', '_preview.jpg');
        debugPrint('🎬 Пробуем загрузить готовое превью: $previewUrl');

        try {
          final previewResponse = await http.get(Uri.parse(previewUrl));
          if (previewResponse.statusCode == 200 &&
              previewResponse.bodyBytes.length > 100) {
            debugPrint('✅ Загружено готовое превью из Supabase');
            _thumbnailCache[cacheKey] = previewResponse.bodyBytes;
            _saveToFileCache(cacheKey, previewResponse.bodyBytes);
            return previewResponse.bodyBytes;
          }
        } catch (e) {
          debugPrint('⚠️ Ошибка при загрузке готового превью: $e');
        }
      }

      // Для мобильных устройств используем VideoThumbnail
      if (!kIsWeb) {
        final mobileThumbnail =
            await _generateThumbnailFromRemoteVideo(videoUrl);
        if (mobileThumbnail != null) {
          _thumbnailCache[cacheKey] = mobileThumbnail;
          _saveToFileCache(cacheKey, mobileThumbnail);
          return mobileThumbnail;
        }
      } else {
        // Для веб просто возвращаем пустые данные и отображаем заглушку
        debugPrint('🌐 Веб-платформа не поддерживает генерацию превью видео');
        return null;
      }

      return null;
    } catch (e) {
      debugPrint('❌ Ошибка при создании превью: $e');
      return null;
    }
  }

  /// Генерирует превью из удаленного видео (мобильные устройства)
  static Future<Uint8List?> _generateThumbnailFromRemoteVideo(
      String videoUrl) async {
    try {
      // Проверяем доступность видео
      final response = await http.head(Uri.parse(videoUrl)).timeout(
            Duration(seconds: 5),
            onTimeout: () => http.Response('Error', 408),
          );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint(
            '❌ Видео недоступно по URL: $videoUrl (${response.statusCode})');
        return null;
      }

      // Генерируем превью
      final uint8list = await VideoThumbnail.thumbnailData(
        video: videoUrl,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 400,
        quality: 75,
      );

      if (uint8list != null) {
        debugPrint('✅ Превью успешно сгенерировано для: $videoUrl');
        return uint8list;
      } else {
        debugPrint('❌ Не удалось сгенерировать превью для: $videoUrl');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Ошибка при генерации превью: $e');
      return null;
    }
  }

  /// Виджет для отображения превью видео
  static Widget buildVideoThumbnail(
    String videoUrl, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    String? title,
    Widget? errorWidget,
    Widget? loadingWidget,
  }) {
    // Проверка валидности URL
    if (videoUrl.isEmpty) {
      return _buildErrorPlaceholder(width, height, errorWidget, title);
    }

    // Быстрая проверка на ошибку 400 для Supabase URL
    if (videoUrl.contains('supabase') && videoUrl.contains('/demo/')) {
      // Логируем использование альтернативного изображения вместо недоступного видео
      debugPrint(
          '🔄 Используем альтернативное изображение вместо видео: $videoUrl');
      return _buildImageBasedOnExerciseType(
          videoUrl, width, height, fit, title);
    }

    return FutureBuilder<Uint8List?>(
      future: getThumbnailFromVideo(videoUrl),
      builder: (context, snapshot) {
        // Отображаем загрузку
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loadingWidget ?? _buildLoadingPlaceholder(width, height, null);
        }

        // Отображаем ошибку или используем альтернативное изображение
        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          debugPrint('❌ Ошибка получения превью: ${snapshot.error}');

          // Если видео из Supabase, используем альтернативное изображение вместо заглушки
          if (videoUrl.contains('supabase')) {
            return _buildImageBasedOnExerciseType(
                videoUrl, width, height, fit, title);
          }

          return errorWidget ??
              _buildErrorPlaceholder(width, height, null, title);
        }

        // Если есть данные - отображаем превью
        return Stack(
          fit: StackFit.passthrough,
          children: [
            Container(
              width: width,
              height: height,
              child: Image.memory(
                snapshot.data!,
                fit: fit,
                width: width,
                height: height,
                cacheWidth: width?.toInt(),
                cacheHeight: height?.toInt(),
                filterQuality: FilterQuality.medium,
                gaplessPlayback:
                    true, // Предотвращает мерцание при перезагрузке
              ),
            ),
            // Отображаем название, если предоставлено
            if (title != null && title.isNotEmpty)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 12.0),
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
                    title,
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
        );
      },
    );
  }

  // Вспомогательный метод для отображения заглушки при ошибке
  static Widget _buildErrorPlaceholder(
    double? width,
    double? height,
    Widget? errorWidget,
    String? title,
  ) {
    if (errorWidget != null) return errorWidget;

    return Container(
      width: width,
      height: height,
      color: Colors.black54,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.videocam, color: Colors.white70, size: 32),
                SizedBox(height: 8),
                if (title != null && title.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      title,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Вспомогательный метод для отображения заглушки при загрузке
  static Widget _buildLoadingPlaceholder(
    double? width,
    double? height,
    Widget? loadingWidget,
  ) {
    if (loadingWidget != null) return loadingWidget;

    return Container(
      width: width,
      height: height,
      color: Colors.black54,
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          strokeWidth: 2,
        ),
      ),
    );
  }

  /// Сохраняет превью в файловый кэш
  static Future<void> _saveToFileCache(String cacheKey, Uint8List data) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${appDir.path}/thumbnails');

      // Создаем директорию, если она не существует
      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }

      final file = File('${cacheDir.path}/$cacheKey.jpg');
      await file.writeAsBytes(data);
      debugPrint('✅ Сохранено превью в файловый кэш: $cacheKey');
    } catch (e) {
      debugPrint('❌ Ошибка при сохранении превью в файловый кэш: $e');
    }
  }

  // Новый метод для создания альтернативного изображения на основе типа упражнения
  static Widget _buildImageBasedOnExerciseType(String videoUrl, double? width,
      double? height, BoxFit fit, String? title) {
    String imageUrl =
        'https://images.unsplash.com/photo-1517963879433-6ad2b056d712?w=800'; // Изображение по умолчанию

    // Определяем группу мышц или тип упражнения из URL
    if (videoUrl.contains('chest')) {
      imageUrl =
          'https://images.unsplash.com/photo-1534368959876-26bf04f2c947?w=800';
    } else if (videoUrl.contains('back')) {
      imageUrl =
          'https://images.unsplash.com/photo-1603287681836-b174ce5074c2?w=800';
    } else if (videoUrl.contains('legs')) {
      imageUrl =
          'https://images.unsplash.com/photo-1574680096145-d05b474e2155?w=800';
    } else if (videoUrl.contains('shoulders')) {
      imageUrl =
          'https://images.unsplash.com/photo-1530822847156-e092f2fc04c8?w=800';
    } else if (videoUrl.contains('arm') ||
        videoUrl.contains('bicep') ||
        videoUrl.contains('tricep')) {
      imageUrl =
          'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?w=800';
    } else if (videoUrl.contains('core') || videoUrl.contains('abs')) {
      imageUrl =
          'https://images.unsplash.com/photo-1544216428-10c1ec0e76c1?w=800';
    } else if (videoUrl.contains('push_up')) {
      imageUrl =
          'https://images.unsplash.com/photo-1598971639058-fab3c3109a00?w=800';
    } else if (videoUrl.contains('squat')) {
      imageUrl =
          'https://images.unsplash.com/photo-1574680096145-d05b474e2155?w=800';
    } else if (videoUrl.contains('pull_up')) {
      imageUrl =
          'https://images.unsplash.com/photo-1598266863556-9e58b0592836?w=800';
    } else if (videoUrl.contains('plank')) {
      imageUrl =
          'https://images.unsplash.com/photo-1566241142559-40e1dab266c6?w=800';
    }

    // Защита от NaN и Infinity
    int? safeWidth, safeHeight;
    if (width != null && width.isFinite && width > 0) {
      safeWidth = width.toInt();
    }
    if (height != null && height.isFinite && height > 0) {
      safeHeight = height.toInt();
    }

    return Stack(
      fit: StackFit.passthrough,
      children: [
        Container(
          width: width,
          height: height,
          child: Image.network(
            imageUrl,
            fit: fit,
            width: width,
            height: height,
            cacheWidth: safeWidth,
            cacheHeight: safeHeight,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return _buildLoadingPlaceholder(width, height, null);
            },
            errorBuilder: (context, error, stackTrace) {
              debugPrint('Ошибка загрузки изображения: $error');
              return _buildErrorPlaceholder(width, height, null, title);
            },
          ),
        ),
        // Отображаем название, если предоставлено
        if (title != null && title.isNotEmpty)
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
                title,
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
    );
  }
}

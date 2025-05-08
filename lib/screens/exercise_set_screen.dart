import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/exercise.dart';
import '../models/workout_log.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../providers/workout_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/workout_service.dart';
import 'package:http/http.dart' as http;

class ExerciseSetScreen extends StatefulWidget {
  final Exercise exercise;
  final Function(int reps, double weight) onSetComplete;
  final Duration elapsed;
  final String? videoUrl;
  final Exercise? nextExercise;
  final Map<Exercise, List<SetLog>> exerciseSets;
  final Function(Exercise, int, double) updateExerciseSets;

  const ExerciseSetScreen({
    Key? key,
    required this.exercise,
    required this.onSetComplete,
    required this.elapsed,
    this.videoUrl,
    this.nextExercise,
    required this.exerciseSets,
    required this.updateExerciseSets,
  }) : super(key: key);

  @override
  State<ExerciseSetScreen> createState() => _ExerciseSetScreenState();
}

class _ExerciseSetScreenState extends State<ExerciseSetScreen> {
  VideoPlayerController? _videoController;
  late Timer _timer;
  late Duration _elapsed;
  late TextEditingController _repsController;
  late TextEditingController _weightController;
  List<bool> _completedSets = [];
  int _currentSet = 0; // Начинаем с 0
  bool _isResting = false;
  late int _totalSets;
  Timer? _restTimer;
  int _restTimeRemaining = 30;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    print('🔍 Инициализация для упражнения: ${widget.exercise.name}');
    print('🔍 URL видео: ${widget.videoUrl}');
    _initializeVideo();
    _elapsed = widget.elapsed;
    _startTimer();
    _repsController = TextEditingController(text: widget.exercise.reps);
    _weightController = TextEditingController(text: '12');

    _totalSets = int.parse(widget.exercise.sets);
    _completedSets = List.generate(_totalSets, (index) => false);

    // Восстанавливаем состояние завершенных сетов
    if (widget.exerciseSets.containsKey(widget.exercise)) {
      final completedSetsCount =
          widget.exerciseSets[widget.exercise]?.length ?? 0;
      for (var i = 0; i < completedSetsCount && i < _totalSets; i++) {
        _completedSets[i] = true;
      }
      _currentSet = completedSetsCount;
    }
  }

  Future<void> _initializeVideo() async {
    // Проверяем наличие и валидность URL
    if (widget.videoUrl == null || widget.videoUrl!.isEmpty) {
      print('❌ URL видео отсутствует или пустой');

      // Пробуем получить URL из WorkoutService напрямую
      final freshExercise =
          WorkoutService.getExerciseByName(widget.exercise.name);
      final videoUrl = freshExercise?.videoUrl;

      if (videoUrl == null || videoUrl.isEmpty) {
        print('❌ URL также отсутствует в WorkoutService');
        return;
      }

      print('✅ Нашли URL в WorkoutService: $videoUrl');

      // Проверяем доступность видео
      final isAvailable = await _checkVideoAvailability(videoUrl);
      if (!isAvailable) {
        print('❌ Видео недоступно по URL: $videoUrl');
        return;
      }

      // Продолжаем с найденным URL
      _initializeVideoWithUrl(videoUrl);
      return;
    }

    // Проверяем доступность видео
    final isAvailable = await _checkVideoAvailability(widget.videoUrl!);
    if (!isAvailable) {
      print('❌ Видео недоступно по URL: ${widget.videoUrl}');

      // Пробуем альтернативный URL
      final alternativeUrl = _getAlternativeVideoUrl(widget.exercise.name);
      if (alternativeUrl != null) {
        print('🔄 Пробуем альтернативный URL: $alternativeUrl');
        final altIsAvailable = await _checkVideoAvailability(alternativeUrl);
        if (altIsAvailable) {
          print('✅ Альтернативный URL доступен');
          _initializeVideoWithUrl(alternativeUrl);
          return;
        }
      }

      return;
    }

    // Используем предоставленный URL
    _initializeVideoWithUrl(widget.videoUrl!);
  }

  // Функция для проверки доступности видео
  Future<bool> _checkVideoAvailability(String url) async {
    try {
      // Если URL содержит [project-ref], заменяем на правильный Supabase ID
      if (url.contains('[project-ref]')) {
        url = url.replaceAll('[project-ref]', 'efctwzpqpukhpqvpirrt');
      }

      print('🔍 Проверяем доступность видео: $url');

      // Проверка на YouTube ссылку
      if (url.contains('youtube.com') || url.contains('youtu.be')) {
        return true; // Для YouTube не проверяем
      }

      // Используем HTTP HEAD запрос для проверки доступности
      final response = await http.head(Uri.parse(url)).timeout(
            Duration(seconds: 5),
            onTimeout: () => http.Response('Error', 408),
          );

      print('📊 Статус ответа: ${response.statusCode}');
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      print('❌ Ошибка при проверке доступности видео: $e');
      return false;
    }
  }

  // Получаем альтернативный URL для видео
  String? _getAlternativeVideoUrl(String exerciseName) {
    // Формируем правильный slug для URL
    final slug = exerciseName.toLowerCase().replaceAll(' ', '-');

    // Проверяем, есть ли тире в конце slug
    final videoSlug =
        slug.endsWith('-') ? slug.substring(0, slug.length - 1) : slug;

    return 'https://efctwzpqpukhpqvpirrt.supabase.co/storage/v1/object/public/videos/$videoSlug.mp4';
  }

  Future<void> _initializeVideoWithUrl(String videoUrl) async {
    // Если URL содержит [project-ref], заменяем на правильный Supabase ID
    if (videoUrl.contains('[project-ref]')) {
      videoUrl = videoUrl.replaceAll('[project-ref]', 'efctwzpqpukhpqvpirrt');
      print('🔄 Исправлен URL видео: $videoUrl');
    }

    // Проверка на YouTube ссылку
    if (videoUrl.contains('youtube.com') || videoUrl.contains('youtu.be')) {
      print('⚠️ Обнаружена YouTube ссылка: $videoUrl');
      // Для YouTube не инициализируем VideoController,
      // будем использовать специальный просмотр через WebView или браузер
      return;
    }

    try {
      final uri = Uri.parse(videoUrl);
      if (!uri.isAbsolute) {
        print('❌ URL не является абсолютным: $videoUrl');
        return;
      }

      // Для подписанных URL с Supabase используем оригинальный URL без изменений
      print(
          '🔍 Пытаемся инициализировать видео для упражнения "${widget.exercise.name}"');
      print('🔍 URL видео: $videoUrl');

      // Не пытаемся модифицировать URL - используем как есть
      _videoController = VideoPlayerController.network(videoUrl);

      print('⏳ Контроллер создан, ожидание инициализации...');

      try {
        await _videoController!.initialize().timeout(Duration(seconds: 15));
        print(
            '✅ Видео успешно инициализировано! Размер: ${_videoController!.value.size}');
        await _videoController!.setLooping(true);
        await _videoController!.play();

        setState(() {
          _isVideoInitialized = true;
        });
      } catch (e) {
        print('❌ Ошибка при инициализации видео: $e');
        if (_videoController != null) {
          await _videoController!.dispose();
          _videoController = null;
        }
      }
    } catch (e, stackTrace) {
      print('❌ Ошибка при инициализации видео:');
      print('❌ ${e.toString()}');
      print('❌ Стек вызовов:');
      print('❌ $stackTrace');

      if (_videoController != null) {
        await _videoController!.dispose();
        _videoController = null;
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _elapsed += Duration(seconds: 1);
      });
    });
  }

  void _startRestTimer() {
    setState(() {
      _isResting = true;
      _restTimeRemaining = 30;
    });

    _restTimer?.cancel();
    _restTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_restTimeRemaining > 0) {
        setState(() {
          _restTimeRemaining--;
        });
      } else {
        _restTimer?.cancel();
        setState(() {
          _isResting = false;
        });
      }
    });
  }

  void _handleSetComplete() {
    if (_currentSet >= _totalSets) {
      // Если все подходы уже выполнены, просто возвращаемся назад
      Navigator.pop(context);
      return;
    } // Защита от лишних нажатий

    final reps = int.tryParse(_repsController.text) ?? 0;
    final weight = double.tryParse(_weightController.text) ?? 0;

    setState(() {
      _completedSets[_currentSet] = true;
      _currentSet++;
    });

    // Обновляем сеты для текущего упражнения
    widget.updateExerciseSets(widget.exercise, reps, weight);

    // Сохраняем в историю упражнений
    final workoutProvider =
        Provider.of<WorkoutProvider>(context, listen: false);
    workoutProvider
        .saveExerciseHistory(
      widget.exercise,
      [SetLog(reps: reps, weight: weight)],
      DateTime.now(),
    )
        .catchError((e) {
      debugPrint('Ошибка при сохранении истории упражнения: $e');
    });

    // Если это упражнение в суперсете
    if (widget.exercise.superSetId != null) {
      // Находим следующее упражнение в суперсете
      final nextExercise = _findNextExerciseInSuperset();

      if (nextExercise != null) {
        // Проверяем, завершены ли все подходы в суперсете
        final allSetsCompleted = _areAllSetsCompleted(nextExercise);

        if (!allSetsCompleted) {
          _navigateToNextExercise(nextExercise);
          return;
        }
      }
    }

    // Если все подходы выполнены или это обычное упражнение
    if (_currentSet >= _totalSets) {
      // Вместо перехода к следующему упражнению - возвращаемся назад к списку упражнений
      Navigator.pop(context);
    } else {
      _startRestTimer();
    }
  }

  bool _areAllSetsCompleted(Exercise exercise) {
    final completedSets = widget.exerciseSets[exercise]?.length ?? 0;
    final totalSets = int.parse(exercise.sets);
    return completedSets >= totalSets;
  }

  Exercise? _findNextExerciseInSuperset() {
    if (widget.exercise.superSetId == null) return null;

    // Получаем все упражнения с тем же superSetId
    final supersetExercises = widget.exerciseSets.keys
        .where((e) => e.superSetId == widget.exercise.superSetId)
        .toList();

    // Находим индекс текущего упражнения
    final currentIndex = supersetExercises.indexOf(widget.exercise);

    // Если есть следующее упражнение в суперсете
    if (currentIndex < supersetExercises.length - 1) {
      return supersetExercises[currentIndex + 1];
    }

    // Если это последнее упражнение, возвращаемся к первому
    return supersetExercises[0];
  }

  void _navigateToNextExercise(Exercise nextExercise) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ExerciseSetScreen(
          exercise: nextExercise,
          onSetComplete: widget.onSetComplete,
          elapsed: _elapsed,
          videoUrl: nextExercise.videoUrl,
          nextExercise: null,
          exerciseSets: widget.exerciseSets,
          updateExerciseSets: widget.updateExerciseSets,
        ),
      ),
    );
  }

  @override
  void dispose() {
    if (_videoController != null) {
      _videoController!.dispose();
    }
    _timer.cancel();
    _restTimer?.cancel();
    _repsController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  // Метод для создания видеоплеера
  Widget _buildVideoPlayer() {
    if (_videoController == null || !_isVideoInitialized) {
      return _buildVideoPlaceholder();
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        AspectRatio(
          aspectRatio:
              16 / 9, // Фиксированное соотношение сторон как на изображении
          child: Container(
            width: double.infinity,
            height: 180, // Уменьшенная высота плеера
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.black,
            ),
            child: VideoPlayer(_videoController!),
          ),
        ),
        Positioned.fill(
          child: GestureDetector(
            onTap: () {
              setState(() {
                if (_videoController!.value.isPlaying) {
                  _videoController!.pause();
                } else {
                  _videoController!.play();
                }
              });
            },
            child: Container(
              color: Colors.transparent,
              child: Center(
                child: _videoController!.value.isPlaying
                    ? Container() // Ничего не показываем, когда видео воспроизводится
                    : Container(
                        width: 40, // Уменьшенный размер кнопки плей
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.play_arrow,
                            color: Colors.white, size: 24),
                      ),
              ),
            ),
          ),
        ),
        // Название упражнения внизу поверх видео
        Positioned(
          left: 16,
          bottom: 16,
          child: Text(
            widget.exercise.name,
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
              shadows: [
                Shadow(
                  offset: Offset(0, 1),
                  blurRadius: 3.0,
                  color: Colors.black.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Icon(Icons.play_arrow, color: Colors.white, size: 14),
                SizedBox(width: 3),
                Text(
                  'Video',
                  style: TextStyle(
                      color: Colors.white, fontSize: 11, fontFamily: 'Inter'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Создаем виджет плейсхолдера для видео
  Widget _buildVideoPlaceholder() {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: 180, // Уменьшенная высота плейсхолдера
          color: Colors.black54,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.videocam_off, color: Colors.white70, size: 36),
                SizedBox(height: 6),
                Text(
                  'Видео недоступно',
                  style: TextStyle(
                      color: Colors.white70, fontSize: 14, fontFamily: 'Inter'),
                ),
              ],
            ),
          ),
        ),
        // Название упражнения внизу поверх видео
        Positioned(
          left: 16,
          bottom: 16,
          child: Text(
            widget.exercise.name,
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
              shadows: [
                Shadow(
                  offset: Offset(0, 1),
                  blurRadius: 3.0,
                  color: Colors.black.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Метод для открытия YouTube видео
  Future<void> _openYouTubeVideo() async {
    if (widget.videoUrl == null) return;

    print('🎬 Пытаемся открыть YouTube видео: ${widget.videoUrl}');
    try {
      final Uri url = Uri.parse(widget.videoUrl!);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        print('❌ Не удалось открыть URL: ${widget.videoUrl}');
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Не удалось открыть видео')));
      }
    } catch (e) {
      print('❌ Ошибка при открытии YouTube: $e');
    }
  }

  // Плейсхолдер для YouTube видео
  Widget _buildYouTubePlayer() {
    return Stack(
      children: [
        GestureDetector(
          onTap: _openYouTubeVideo,
          child: Container(
            width: double.infinity,
            height: 180, // Уменьшенная высота плейсхолдера
            decoration: BoxDecoration(
              color: Colors.black87,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_circle_fill, color: Colors.red, size: 40),
                  SizedBox(height: 8),
                  Text(
                    'Нажмите, чтобы открыть видео',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Inter'),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Название упражнения внизу поверх видео
        Positioned(
          left: 16,
          bottom: 16,
          child: Text(
            widget.exercise.name,
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
              shadows: [
                Shadow(
                  offset: Offset(0, 1),
                  blurRadius: 3.0,
                  color: Colors.black.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Icon(Icons.play_arrow, color: Colors.white, size: 14),
                SizedBox(width: 3),
                Text(
                  'Video',
                  style: TextStyle(
                      color: Colors.white, fontSize: 11, fontFamily: 'Inter'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Focus Mode',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF201A18), // Более темный коричневый цвет вверху
              Color(0xFF151211),
              Color(0xFF0F0D0C),
              Colors.black,
            ],
            stops: [0.0, 0.4, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Отображение времени - с шрифтом Inter
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  _formatDuration(_elapsed),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 60, // Увеличиваем размер таймера
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Inter',
                    fontStyle: FontStyle.italic, // Курсивом как на изображении
                  ),
                ),
              ),

              // Блок с видео и деталями упражнения
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Карточка упражнения с закругленными углами
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Color(0xFF1C1C1E), // темно-серый фон
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child:
                                _videoController != null && _isVideoInitialized
                                    ? _buildVideoPlayer()
                                    : widget.videoUrl != null &&
                                            (widget.videoUrl!
                                                    .contains('youtube.com') ||
                                                widget.videoUrl!
                                                    .contains('youtu.be'))
                                        ? _buildYouTubePlayer()
                                        : _buildVideoPlaceholder(),
                          ),
                        ),

                        SizedBox(height: 16),

                        // Строки с информацией о подходах без заголовков (как на изображении)
                        for (int i = 0; i < _totalSets; i++) _buildSetRow(i),

                        // Кнопка "Добавить подход"
                        Padding(
                          padding: const EdgeInsets.only(top: 16, bottom: 16),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _totalSets++;
                                _completedSets.add(false);
                              });
                            },
                            child: Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  margin: EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.amber,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.add,
                                      color: Colors.black,
                                      size: 18,
                                    ),
                                  ),
                                ),
                                Text(
                                  'Add Set',
                                  style: TextStyle(
                                    color: Colors.amber,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Кнопка LOG SET внизу экрана
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                child: Container(
                  height: 45,
                  width: 180,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _handleSetComplete,
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Color(0xFF4CAF50),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              _currentSet >= _totalSets
                                  ? 'RETURN TO EXERCISES'
                                  : 'LOG SET',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  // Создаем строку с подходом по дизайну с изображения
  Widget _buildSetRow(int index) {
    final isCurrentSet = index == _currentSet;
    final isCompleted = _completedSets[index];

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Номер сета или галочка
          Container(
            width: 24,
            height: 24,
            margin: EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: isCompleted ? Color(0xFF4CAF50) : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              border: isCompleted
                  ? null
                  : Border.all(
                      color: Colors.grey.withOpacity(0.7),
                      width: 1,
                    ),
            ),
            child: isCompleted
                ? Center(
                    child: Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    ),
                  )
                : Center(
                    child: Text(
                      (index + 1).toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
          ),

          // Поле ввода повторений (зеленый цвет как на изображении)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                isCompleted || isCurrentSet || index == 2
                    ? Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          'Reps',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    : SizedBox.shrink(),
                Container(
                  height: 50,
                  margin: EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: isCompleted || isCurrentSet
                      ? isCompleted
                          ? Text(
                              _repsController.text,
                              style: TextStyle(
                                color: Color(
                                    0xFF4CAF50), // Зеленый цвет для повторений
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Inter',
                              ),
                            )
                          : TextField(
                              controller: _repsController,
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              style: TextStyle(
                                color: Color(
                                    0xFF4CAF50), // Зеленый цвет для повторений
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Inter',
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                                hintText: '8',
                                hintStyle: TextStyle(
                                  color: Colors.grey.withOpacity(0.7),
                                  fontSize: 24,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            )
                      : Text(
                          '8',
                          style: TextStyle(
                            color: Colors.grey.withOpacity(0.7),
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Inter',
                          ),
                        ),
                ),
              ],
            ),
          ),

          SizedBox(width: 8),

          // Поле ввода веса (числа как на изображении)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                isCompleted || isCurrentSet || index == 2
                    ? Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          'Weight (kg / lb)',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    : SizedBox.shrink(),
                Container(
                  height: 50,
                  margin: EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: isCompleted || isCurrentSet
                      ? isCompleted
                          ? Text(
                              _weightController.text,
                              style: TextStyle(
                                color: Colors.white, // Белый цвет для веса
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Inter',
                              ),
                            )
                          : TextField(
                              controller: _weightController,
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              style: TextStyle(
                                color: Colors.white, // Белый цвет для веса
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Inter',
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                                hintText: '12',
                                hintStyle: TextStyle(
                                  color: Colors.grey.withOpacity(0.7),
                                  fontSize: 24,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            )
                      : Text(
                          '12',
                          style: TextStyle(
                            color: Colors.grey.withOpacity(0.7),
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Inter',
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

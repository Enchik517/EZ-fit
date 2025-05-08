import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../models/exercise.dart';
import '../services/exercise_image_service.dart';
import '../services/video_thumbnail_service.dart';

class WorkoutCategoryScreen extends StatefulWidget {
  final String categoryName;
  final String categoryDescription;

  const WorkoutCategoryScreen({
    Key? key,
    required this.categoryName,
    required this.categoryDescription,
  }) : super(key: key);

  @override
  State<WorkoutCategoryScreen> createState() => _WorkoutCategoryScreenState();
}

class _WorkoutCategoryScreenState extends State<WorkoutCategoryScreen> {
  List<Exercise> exercises = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    try {
      final String jsonString =
          await rootBundle.loadString('assets/exercise.json');
      final List<dynamic> jsonData = json.decode(jsonString);

      // Фильтруем упражнения в зависимости от категории
      List<String> exerciseNames =
          _getExercisesForCategory(widget.categoryName);

      // Преобразуем данные JSON в объекты Exercise
      List<Exercise> loadedExercises = [];
      for (var item in jsonData) {
        if (exerciseNames.contains(item['name'])) {
          loadedExercises.add(Exercise.fromJson(item));
        }
      }

      setState(() {
        exercises = loadedExercises;
        isLoading = false;
      });
    } catch (e) {
      print('Ошибка загрузки упражнений: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Метод для получения списка упражнений для выбранной категории
  List<String> _getExercisesForCategory(String category) {
    switch (category) {
      case 'Express Workouts':
        return [
          'Push-Up',
          'Bodyweight Squat',
          'Forward Lunge',
          'Reverse Lunge',
          'High Plank',
          'Low Plank (Elbow Plank)',
          'Glute Bridge',
          'Superman',
          'Inchworm',
          'Mountain Climber',
        ];
      case 'HIIT':
        return [
          'Jump Squat',
          'Plank Jacks',
          'Mountain Climber',
          'Burpee',
          'Jumping Lunge',
        ];
      case 'Home Vibe':
        return [
          'Push-Up',
          'Knee Push-Up',
          'Incline Push-Up',
          'Wide Grip Push-Up',
          'Spiderman Push-Up',
          'Hindu Push-Up',
          'Bodyweight Squat',
          'Sumo Squat',
          'Narrow Squat',
          'Jump Squat',
          'Split Squat (Bodyweight)',
          'Bulgarian Split Squat (Bodyweight)',
          'Pistol Squat',
          'Wall Sit',
          'Air Squat',
          'Duck Walk',
          'Forward Lunge',
          'Reverse Lunge',
          'Walking Lunge',
          'Curtsy Lunge',
          'Side Lunge',
          'Jumping Lunge',
          'Clock Lunge',
          'Overhead Lunge',
          'Lunge with Twist',
          'Elevated Lunge',
          'High Plank',
          'Low Plank (Elbow Plank)',
          'Side Plank',
          'Plank with Shoulder Taps',
          'Plank Jacks',
          'Plank Up-Downs',
          'Reverse Plank',
          'Single-Leg Plank',
          'Bird Dog Plank',
          'Spider Plank',
          'Burpee',
          'Mountain Climber',
          'Donkey Kick',
          'Glute Bridge',
          'Superman',
          'Bear Crawl',
          'Crab Walk',
          'Inchworm',
          'Hip Thrust (Bodyweight)',
          'V-Up',
        ];
      case 'Peaches 🍑':
        return [
          'Sumo Squat',
          'Split Squat (Bodyweight)',
          'Bulgarian Split Squat (Bodyweight)',
          'Curtsy Lunge',
          'Side Lunge',
          'Donkey Kick',
          'Glute Bridge',
          'Superman',
          'Hip Thrust (Bodyweight)',
          'Barbell Deadlift',
          'Barbell Romanian Deadlift',
          'Barbell Hip Thrust',
        ];
      case 'Strength':
        return [
          'Decline Push-Up',
          'Close Grip Push-Up',
          'Diamond Push-Up',
          'Pike Push-Up',
          'Pistol Squat',
          'Barbell Back Squat',
          'Barbell Front Squat',
          'Barbell Deadlift',
          'Barbell Romanian Deadlift',
          'Barbell Lunge',
          'Barbell Bench Press',
          'Barbell Incline Bench Press',
          'Barbell Decline Bench Press',
          'Barbell Overhead Press',
          'Barbell Bent-Over Row',
          'Barbell Clean',
          'Barbell Snatch',
          'Barbell Hip Thrust',
          'Barbell Shrug',
        ];
      case 'Full Body':
        return [
          'Burpee',
          'Bear Crawl',
          'Crab Walk',
          'Inchworm',
          'Barbell Clean',
          'Barbell Snatch',
        ];
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          widget.categoryName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              widget.categoryDescription,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
              ),
            ),
          ),
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(
                color: Colors.blue,
              ),
            )
          else if (exercises.isEmpty)
            Center(
              child: Text(
                'Упражнения не найдены',
                style: TextStyle(color: Colors.grey[400]),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: exercises.length,
                itemBuilder: (context, index) {
                  final exercise = exercises[index];
                  return GestureDetector(
                    onTap: () {
                      // Добавим тактильный отклик
                      HapticFeedback.lightImpact();
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF1E1E1E),
                            const Color(0xFF0E0E0E),
                          ],
                          stops: const [0.0, 1.0],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Декоративный элемент
                          Positioned(
                            right: -20,
                            top: -20,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                gradient: RadialGradient(
                                  colors: [
                                    Colors.blue.withOpacity(0.1),
                                    Colors.blue.withOpacity(0.0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  left: BorderSide(
                                    color: _getDifficultyColor(
                                        exercise.difficultyLevel),
                                    width: 6,
                                  ),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Превью изображение упражнения
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: SizedBox(
                                            width: 60,
                                            height: 60,
                                            child: _getExercisePreviewImage(
                                                exercise),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                exercise.name,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                exercise.description,
                                                style: TextStyle(
                                                  color: Colors.grey[400],
                                                  fontSize: 14,
                                                  height: 1.5,
                                                  letterSpacing: 0.3,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        _buildDifficultyBadge(
                                            exercise.difficultyLevel),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildInfoChip(
                                            'Equipment',
                                            exercise.equipment,
                                            _getEquipmentIcon(
                                                exercise.equipment),
                                            Colors.green.shade300,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _buildInfoChip(
                                            'Target',
                                            exercise.muscleGroup,
                                            _getMuscleGroupIcon(
                                                exercise.muscleGroup),
                                            Colors.orange.shade300,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return Colors.green.shade400;
      case 'intermediate':
        return Colors.orange.shade400;
      case 'advanced':
        return Colors.red.shade400;
      default:
        return Colors.blue.shade400;
    }
  }

  Widget _buildDifficultyBadge(String difficulty) {
    final color = _getDifficultyColor(difficulty);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getDifficultyIcon(difficulty),
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            difficulty,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getDifficultyIcon(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return Icons.star_border;
      case 'intermediate':
        return Icons.star_half;
      case 'advanced':
        return Icons.star;
      default:
        return Icons.star_border;
    }
  }

  IconData _getEquipmentIcon(String equipment) {
    switch (equipment.toLowerCase()) {
      case 'none':
        return Icons.accessibility_new;
      case 'dumbbells':
        return Icons.fitness_center;
      case 'barbell':
        return Icons.sports_gymnastics;
      case 'kettlebell':
        return Icons.fitness_center;
      case 'resistance band':
        return Icons.linear_scale;
      case 'pullup bar':
        return Icons.horizontal_rule;
      default:
        return Icons.fitness_center;
    }
  }

  IconData _getMuscleGroupIcon(String muscleGroup) {
    switch (muscleGroup.toLowerCase()) {
      case 'chest':
        return Icons.accessibility_new;
      case 'back':
        return Icons.accessibility_new;
      case 'legs':
        return Icons.accessibility_new;
      case 'shoulders':
        return Icons.accessibility_new;
      case 'arms':
        return Icons.accessibility_new;
      case 'core':
        return Icons.accessibility_new;
      default:
        return Icons.accessibility_new;
    }
  }

  Widget _buildInfoChip(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.2),
            color.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 18,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                _buildMarqueeText(value, Colors.grey[300]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarqueeText(String text, Color? textColor) {
    return SizedBox(
      height: 18,
      child: MarqueeWidget(
        text: text,
        textStyle: TextStyle(
          color: textColor,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

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

class MarqueeWidget extends StatefulWidget {
  final String text;
  final TextStyle textStyle;
  final Axis direction;
  final Duration animationDuration;
  final Duration backDuration;
  final Duration pauseDuration;

  const MarqueeWidget({
    Key? key,
    required this.text,
    required this.textStyle,
    this.direction = Axis.horizontal,
    this.animationDuration = const Duration(milliseconds: 6000),
    this.backDuration = const Duration(milliseconds: 800),
    this.pauseDuration = const Duration(milliseconds: 1500),
  }) : super(key: key);

  @override
  State<MarqueeWidget> createState() => _MarqueeWidgetState();
}

class _MarqueeWidgetState extends State<MarqueeWidget> {
  late ScrollController _scrollController;
  bool _showMarquee = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkTextSize();
      if (_showMarquee) {
        _scroll();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _checkTextSize() {
    final textWidth = _textSize(
      widget.text,
      widget.textStyle,
    ).width;

    if (mounted) {
      final containerWidth = context.size?.width ?? 0;
      setState(() {
        _showMarquee = textWidth > containerWidth;
      });
    }
  }

  Size _textSize(String text, TextStyle style) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(minWidth: 0, maxWidth: double.infinity);
    return textPainter.size;
  }

  void _scroll() async {
    if (!mounted || !_showMarquee) return;

    // Ждем некоторое время перед началом прокрутки
    await Future.delayed(widget.pauseDuration);
    if (!mounted) return;

    // Прокручиваем до конца
    await _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: widget.animationDuration,
      curve: Curves.easeInOut,
    );
    if (!mounted) return;

    // Ждем некоторое время в конце
    await Future.delayed(widget.pauseDuration);
    if (!mounted) return;

    // Прокручиваем обратно в начало
    await _scrollController.animateTo(
      0.0,
      duration: widget.backDuration,
      curve: Curves.easeOut,
    );
    if (!mounted) return;

    // Запускаем цикл заново
    _scroll();
  }

  @override
  Widget build(BuildContext context) {
    if (!_showMarquee) {
      return Text(
        widget.text,
        style: widget.textStyle,
        overflow: TextOverflow.ellipsis,
      );
    }

    return SingleChildScrollView(
      scrollDirection: widget.direction,
      controller: _scrollController,
      physics: const NeverScrollableScrollPhysics(),
      child: Text(
        widget.text,
        style: widget.textStyle,
      ),
    );
  }
}

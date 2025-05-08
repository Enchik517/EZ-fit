import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;

// Перечисление для выравнивания текста на верхнем уровне
enum TextAlignment { left, center, right }

class PlanReadyScreen extends StatefulWidget {
  final VoidCallback onGetPlan;
  final String gender;
  final double? currentWeight;
  final double? targetWeight;
  final List<String>? focusAreas;

  const PlanReadyScreen({
    Key? key,
    required this.onGetPlan,
    required this.gender,
    this.currentWeight,
    this.targetWeight,
    this.focusAreas,
  }) : super(key: key);

  @override
  State<PlanReadyScreen> createState() => _PlanReadyScreenState();
}

class _PlanReadyScreenState extends State<PlanReadyScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _curveAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _point1Animation;
  late Animation<double> _point2Animation;
  late Animation<double> _point3Animation;
  late Animation<double> _emojiAnimation;

  @override
  void initState() {
    super.initState();

    // Увеличиваем длительность анимации для более плавного отображения
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 4000),
    );

    // Создаем анимации с более плавными кривыми для меньшей нагрузки на процессор
    _curveAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic, // Более плавная кривая
    );

    _opacityAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Interval(0.0, 0.7, curve: Curves.easeIn),
    );

    // Делаем анимации смайликов более последовательными и эффектными
    _point1Animation = CurvedAnimation(
      parent: _animationController,
      curve: Interval(0.1, 0.5,
          curve: Curves.elasticOut), // Возвращаем упругую анимацию
    );

    _point2Animation = CurvedAnimation(
      parent: _animationController,
      curve: Interval(0.35, 0.75, curve: Curves.elasticOut),
    );

    _point3Animation = CurvedAnimation(
      parent: _animationController,
      curve: Interval(0.6, 0.95, curve: Curves.elasticOut),
    );

    _emojiAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Interval(0.7, 1.0,
          curve: Curves.bounceOut), // Возвращаем пружинящую анимацию
    );

    // Небольшая задержка перед запуском для предотвращения заикания UI
    Future.delayed(Duration(milliseconds: 100), () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Вычисляем данные для карточек
    final DateTime targetDate = _calculateTargetDate();
    final String formattedDate = DateFormat('d MMMM').format(targetDate);

    // Определяем фокус тренировки
    final String workoutFocus = _determineWorkoutFocus();

    // Определяем продолжительность тренировки
    final String workoutDuration = '20-30 min';

    // Рассчитываем примерные калории
    final int caloriesPerDay = _calculateDailyCalories();

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 40),

          // Чекмарк иконка
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.check,
              color: Colors.white,
              size: 40,
            ),
          ),

          SizedBox(height: 16),

          // Заголовок
          Text(
            'Your Plan is Ready',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),

          SizedBox(height: 24),

          // Карточка прогресса веса
          Container(
            margin: EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Верхняя надпись
                      Text(
                        'Based on your answers,',
                        style: GoogleFonts.inter(
                          color: Colors.grey[700],
                          fontSize: 12,
                        ),
                      ),

                      SizedBox(height: 8),

                      // Предсказание веса
                      RichText(
                        text: TextSpan(
                          style: GoogleFonts.inter(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                          children: [
                            TextSpan(text: 'You\'ll be '),
                            TextSpan(
                              text:
                                  '${widget.targetWeight?.toStringAsFixed(1) ?? "94.8"} kg',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(text: ' by'),
                          ],
                        ),
                      ),

                      SizedBox(height: 4),

                      // Целевая дата
                      Text(
                        formattedDate,
                        style: GoogleFonts.inter(
                          color: Colors.red,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // Анимированный график прогресса веса
                SizedBox(
                  height: 150,
                  child: RepaintBoundary(
                    child: AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: AnimatedWeightProgressPainter(
                            startWeight: widget.currentWeight ?? 100.8,
                            midWeight: (widget.currentWeight ?? 100.8) *
                                0.97, // -3% для промежуточной точки
                            targetWeight: widget.targetWeight ?? 94.8,
                            targetDate: targetDate,
                            curveProgress: _curveAnimation.value,
                            opacityProgress: _opacityAnimation.value,
                            point1Progress: _point1Animation.value,
                            point2Progress: _point2Animation.value,
                            point3Progress: _point3Animation.value,
                            emojiProgress: _emojiAnimation.value,
                          ),
                          isComplex:
                              true, // Указываем Flutter, что рисование сложное
                          willChange: true, // И будет меняться
                        );
                      },
                    ),
                  ),
                ),

                // Процент успеха
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    '83% of people in a similar situation to you have lost their weight using Juffit.',
                    style: GoogleFonts.inter(
                      color: Colors.grey[700],
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16),

          // Карточка с деталями плана
          Container(
            margin: EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Plan Content',
                    style: GoogleFonts.inter(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                // Область фокуса тренировки
                _buildPlanDetailRow(
                  icon: Icons.fitness_center,
                  iconColor: Colors.blue,
                  title: 'Workout Area',
                  value: workoutFocus,
                ),

                // Продолжительность тренировки
                _buildPlanDetailRow(
                  icon: Icons.timer,
                  iconColor: Colors.orange,
                  title: 'Workout Duration',
                  value: workoutDuration,
                ),

                // Калории в день
                _buildPlanDetailRow(
                  icon: Icons.local_fire_department,
                  iconColor: Colors.red,
                  title: 'Calories',
                  value: '$caloriesPerDay kcal / day',
                  isLast: true,
                ),
              ],
            ),
          ),

          SizedBox(height: 24),

          // Кнопка GET MY PLAN
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: widget.onGetPlan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'GET MY PLAN',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),

          SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPlanDetailRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    String? imageAsset,
    bool isLast = false,
  }) {
    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        border: !isLast
            ? Border(bottom: BorderSide(color: Colors.grey[200]!))
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  DateTime _calculateTargetDate() {
    // Простая логика для определения целевой даты
    return DateTime.now().add(Duration(days: 30));
  }

  String _determineWorkoutFocus() {
    if (widget.focusAreas != null && widget.focusAreas!.isNotEmpty) {
      if (widget.focusAreas!.contains('Legs') ||
          widget.focusAreas!.contains('Glutes')) {
        return 'Lower body';
      } else if (widget.focusAreas!.contains('Chest') ||
          widget.focusAreas!.contains('Arms')) {
        return 'Upper body';
      } else if (widget.focusAreas!.contains('Core')) {
        return 'Core';
      }
    }
    return 'Full body'; // По умолчанию
  }

  int _calculateDailyCalories() {
    // Базовая формула для расчета примерного расхода калорий
    if (widget.gender == 'Male') {
      return 163;
    } else {
      return 143;
    }
  }
}

class AnimatedWeightProgressPainter extends CustomPainter {
  final double startWeight;
  final double midWeight;
  final double targetWeight;
  final DateTime targetDate;

  // Параметры анимации
  final double curveProgress;
  final double opacityProgress;
  final double point1Progress;
  final double point2Progress;
  final double point3Progress;
  final double emojiProgress;

  // Кэшируем значения для оптимизации
  // Этот подход уменьшит количество вычислений при каждом кадре анимации
  Offset? _cachedStartPoint;
  Offset? _cachedMidPoint;
  Offset? _cachedEndPoint;
  Path? _cachedPath1;
  Path? _cachedPath2;
  Paint? _cachedLinePaint1;
  Paint? _cachedLinePaint2;
  Paint? _cachedFillPaint1;
  Paint? _cachedFillPaint2;

  // Добавляем определение основных цветов для графика
  final Color primaryColor = Colors.blue[400]!;
  final Color midColor = Colors.purple[400]!;
  final Color endColor = Colors.pinkAccent;

  // Эмодзи для каждой точки с более интересными вариантами
  final List<String> emojis = ['💪', '🔥', '🏆'];

  AnimatedWeightProgressPainter({
    required this.startWeight,
    required this.midWeight,
    required this.targetWeight,
    required this.targetDate,
    required this.curveProgress,
    required this.opacityProgress,
    required this.point1Progress,
    required this.point2Progress,
    required this.point3Progress,
    required this.emojiProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final padding = 20.0;

    // Вычисляем точки для графика только один раз и кэшируем их
    _cachedStartPoint ??= Offset(padding, height * 0.3);
    _cachedMidPoint ??= Offset(width * 0.4, height * 0.5);
    _cachedEndPoint ??= Offset(width - padding, height * 0.7);

    final startPoint = _cachedStartPoint!;
    final midPoint = _cachedMidPoint!;
    final endPoint = _cachedEndPoint!;

    // Анимированные сегменты кривой - используем оптимизированный метод
    _drawAnimatedCurveOptimized(canvas, size, startPoint, midPoint, endPoint);

    // Рисуем анимированные точки на графике с эмодзи
    if (point1Progress > 0) {
      _drawAnimatedPoint(canvas, startPoint, primaryColor, emojis[0],
          point1Progress, '${startWeight.toStringAsFixed(1)}kg', 1);
    }

    if (point2Progress > 0) {
      _drawAnimatedPoint(canvas, midPoint, midColor, emojis[1], point2Progress,
          '${midWeight.toStringAsFixed(1)}kg', 2);
    }

    if (point3Progress > 0) {
      _drawAnimatedPoint(canvas, endPoint, endColor, emojis[2], point3Progress,
          '${targetWeight.toStringAsFixed(1)}kg', 3);

      // Добавляем эффект волны достижения цели
      if (point3Progress > 0.95 && emojiProgress > 0.5) {
        _drawTargetReachedEffect(canvas, endPoint, endColor, emojiProgress);
      }
    }

    // Рисуем метки времени с анимацией
    if (opacityProgress > 0.2) {
      double textOpacity = math.min(1.0, (opacityProgress - 0.2) * 2.0);

      _drawSafeText(
          canvas: canvas,
          text: 'Today',
          position: Offset(padding, height - 10),
          style: TextStyle(
              color: Colors.grey[600]!.withOpacity(textOpacity), fontSize: 10),
          alignment: TextAlignment.left,
          maxWidth: width * 0.3);
    }

    if (opacityProgress > 0.4) {
      double textOpacity = math.min(1.0, (opacityProgress - 0.4) * 2.0);

      _drawSafeText(
          canvas: canvas,
          text: 'Last week',
          position: Offset(width * 0.4, height - 10),
          style: TextStyle(
              color: Colors.grey[600]!.withOpacity(textOpacity), fontSize: 10),
          alignment: TextAlignment.center,
          maxWidth: width * 0.3);
    }

    // Дату отрисовываем с анимацией - только если она видима (для оптимизации)
    if (emojiProgress > 0.5) {
      double badgeOpacity = math.min(1.0, (emojiProgress - 0.5) * 2.0);
      double badgeScale = badgeOpacity * 1.2;

      // Сохраняем состояние холста
      canvas.save();

      // Анимация масштабирования для бейджа
      canvas.translate(endPoint.dx, endPoint.dy - 20);
      canvas.scale(badgeScale);
      canvas.translate(-endPoint.dx, -(endPoint.dy - 20));

      _drawDateBadge(canvas, endPoint, DateFormat('MMM').format(targetDate),
          DateFormat('d').format(targetDate), width, badgeOpacity);

      // Восстанавливаем холст
      canvas.restore();
    }
  }

  // Оптимизированный метод для рисования анимированной кривой с градиентом
  void _drawAnimatedCurveOptimized(Canvas canvas, Size size, Offset startPoint,
      Offset midPoint, Offset endPoint) {
    final height = size.height;
    final padding = 20.0;

    // Вычисляем точки контроля
    final cp1 = Offset(startPoint.dx + (midPoint.dx - startPoint.dx) * 0.5,
        startPoint.dy - 10);

    final cp2 = Offset(
        midPoint.dx + (endPoint.dx - midPoint.dx) * 0.3, midPoint.dy - 15);

    // Сегмент 1 (начало -> середина)
    if (curveProgress > 0) {
      double progress1 = math.min(1.0, curveProgress * 2.0);

      // Вычисляем текущую конечную точку для первого сегмента
      final currentMidPoint = Offset(
          startPoint.dx + (midPoint.dx - startPoint.dx) * progress1,
          startPoint.dy + (midPoint.dy - startPoint.dy) * progress1);

      // Вычисляем текущую контрольную точку
      final currentCP1 = Offset(
          startPoint.dx + (cp1.dx - startPoint.dx) * progress1,
          startPoint.dy + (cp1.dy - startPoint.dy) * progress1);

      // Рисуем первый сегмент - используем кэширование путей
      if (_cachedPath1 == null) {
        _cachedPath1 = Path()
          ..moveTo(startPoint.dx, startPoint.dy)
          ..quadraticBezierTo(currentCP1.dx, currentCP1.dy, currentMidPoint.dx,
              currentMidPoint.dy);
      }

      _drawCurveSegmentOptimized(canvas, startPoint, currentMidPoint,
          _cachedPath1!, primaryColor, midColor, height, padding, 1);

      // Сегмент 2 (середина -> конец)
      if (curveProgress > 0.5) {
        double progress2 = math.min(1.0, (curveProgress - 0.5) * 2.0);

        // Вычисляем текущую конечную точку для второго сегмента
        final currentEndPoint = Offset(
            midPoint.dx + (endPoint.dx - midPoint.dx) * progress2,
            midPoint.dy + (endPoint.dy - midPoint.dy) * progress2);

        // Вычисляем текущую контрольную точку для второго сегмента
        final currentCP2 = Offset(
            midPoint.dx + (cp2.dx - midPoint.dx) * progress2,
            midPoint.dy + (cp2.dy - midPoint.dy) * progress2);

        // Рисуем второй сегмент - используем кэширование путей
        if (_cachedPath2 == null) {
          _cachedPath2 = Path()
            ..moveTo(midPoint.dx, midPoint.dy)
            ..quadraticBezierTo(currentCP2.dx, currentCP2.dy,
                currentEndPoint.dx, currentEndPoint.dy);
        }

        _drawCurveSegmentOptimized(canvas, midPoint, currentEndPoint,
            _cachedPath2!, midColor, endColor, height, padding, 2);
      }
    }
  }

  // Оптимизированный метод для рисования сегмента кривой с заливкой
  void _drawCurveSegmentOptimized(
      Canvas canvas,
      Offset startPoint,
      Offset endPoint,
      Path path,
      Color startColor,
      Color endColor,
      double height,
      double padding,
      int segmentIndex) {
    // Создаем или используем кэшированную градиентную заливку для линии
    final linePaint = segmentIndex == 1
        ? (_cachedLinePaint1 ??= Paint()
          ..shader = LinearGradient(
            colors: [startColor, endColor],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ).createShader(Rect.fromPoints(startPoint, endPoint))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0
          ..strokeCap = StrokeCap.round)
        : (_cachedLinePaint2 ??= Paint()
          ..shader = LinearGradient(
            colors: [startColor, endColor],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ).createShader(Rect.fromPoints(startPoint, endPoint))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0
          ..strokeCap = StrokeCap.round);

    // Рисуем кривую линию
    canvas.drawPath(path, linePaint);

    // Создаем заливку под кривой - мы используем тот же путь, но добавляем линии вниз и назад
    final fillPath = Path.from(path)
      ..lineTo(endPoint.dx, height - padding)
      ..lineTo(startPoint.dx, height - padding)
      ..close();

    // Создаем или используем кэшированную градиентную заливку
    final fillPaint = segmentIndex == 1
        ? (_cachedFillPaint1 ??= Paint()
          ..shader = LinearGradient(
            colors: [startColor.withOpacity(0.2), endColor.withOpacity(0.05)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(Rect.fromLTWH(
              startPoint.dx, 0, endPoint.dx - startPoint.dx, height))
          ..style = PaintingStyle.fill)
        : (_cachedFillPaint2 ??= Paint()
          ..shader = LinearGradient(
            colors: [startColor.withOpacity(0.2), endColor.withOpacity(0.05)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(Rect.fromLTWH(
              startPoint.dx, 0, endPoint.dx - startPoint.dx, height))
          ..style = PaintingStyle.fill);

    // Применяем прозрачность динамически, не пересоздавая Paint
    fillPaint.color = fillPaint.color.withOpacity(opacityProgress);
    canvas.drawPath(fillPath, fillPaint);
  }

  // Метод для рисования анимированной точки с эмодзи
  void _drawAnimatedPoint(Canvas canvas, Offset position, Color color,
      String emoji, double progress, String label, int pointIndex) {
    // Если прогресс слишком мал - пропускаем отрисовку полностью для оптимизации
    if (progress < 0.01) return;

    // Более продвинутый эффект прыжка для точки - варьируется для каждой точки
    final jumpOffset = pointIndex * 0.2; // Смещение фазы для каждой точки
    final yOffset =
        math.sin((progress + jumpOffset) * math.pi) * (8.0 + pointIndex * 1.5);

    // Более интересная анимация для эмодзи - добавляем вращение и масштабирование
    final emojiYOffset = -math.sin((progress + jumpOffset) * math.pi * 1.5) *
        (12.0 + pointIndex * 2.0);
    final emojiXOffset = math.cos((progress + jumpOffset) * math.pi * 2) *
        (5.0 + pointIndex * 1.0);
    final emojiRotation = math.sin((progress + jumpOffset) * math.pi * 0.8) *
        (0.2 + pointIndex * 0.05);
    final scale = 1.0 +
        math.sin((progress + jumpOffset) * math.pi) *
            (0.25 + pointIndex * 0.05);

    final pointPos = Offset(position.dx, position.dy - yOffset);

    // Проверка на null или недопустимые значения color
    if (color == null) {
      color = Colors.blue; // Используем запасной цвет
    }

    // Безопасно устанавливаем opacity для свечения
    final glowOpacity = (0.3 * progress).clamp(0.0, 1.0);
    final outerGlowPaint = Paint()
      ..color = _getSafeColor(color, glowOpacity)
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(
          BlurStyle.normal, 4.0 * progress); // Добавляем размытие для свечения

    canvas.drawCircle(pointPos, 10.0 * progress, outerGlowPaint);

    // Рисуем основной круг с безопасным opacity
    final pointOpacity = progress.clamp(0.0, 1.0);
    final pointPaint = Paint()
      ..color = _getSafeColor(color, pointOpacity)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(pointPos, 7.0 * progress, pointPaint);

    // Рисуем внутренний белый круг
    final innerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(pointPos, 3.5 * progress, innerPaint);

    // Отрисовка эмодзи с улучшенной анимацией
    if (progress > 0.5) {
      final emojiOpacity = math.min(1.0, (progress - 0.5) * 2.0);

      // Пропускаем отрисовку почти невидимых эмодзи
      if (emojiOpacity > 0.05) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: emoji,
            style: TextStyle(
              fontSize: 28 * scale, // Увеличиваем размер эмодзи
            ),
          ),
          textDirection: ui.TextDirection.ltr,
          textAlign: TextAlign.center,
        );

        textPainter.layout();

        // Сохраняем состояние холста
        canvas.save();

        // Улучшенное позиционирование и эффекты для эмодзи
        final emojiX = position.dx + emojiXOffset;
        final emojiY = position.dy - 45 + emojiYOffset; // Поднимаем эмодзи выше

        // Добавляем трансформации для более крутой анимации
        canvas.translate(emojiX, emojiY);
        canvas.rotate(emojiRotation); // Добавляем вращение
        canvas.scale(scale * emojiOpacity);

        // Рисуем эмодзи
        textPainter.paint(
            canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));

        // Добавляем круговое свечение вокруг эмодзи
        if (progress > 0.8) {
          final emojiGlowOpacity = (0.15 * progress).clamp(0.0, 1.0);
          final glowPaint = Paint()
            ..color = _getSafeColor(color, emojiGlowOpacity)
            ..style = PaintingStyle.fill
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10.0 * progress);

          canvas.drawCircle(Offset(0, 0), textPainter.width / 1.8, glowPaint);
        }

        // Восстанавливаем холст
        canvas.restore();

        // Добавляем маленькие блики вокруг эмодзи для эффекта сияния
        if (progress > 0.85) {
          final sparkleSize = 4.0 * progress;
          final sparkleOpacity = math.sin(progress * math.pi * 4) * 0.7;
          final safeSparkleOpacity =
              sparkleOpacity > 0 ? sparkleOpacity.clamp(0.0, 1.0) : 0.0;
          final sparklePaint = Paint()
            ..color = _getSafeColor(Colors.white, safeSparkleOpacity)
            ..style = PaintingStyle.fill;

          // Рисуем блики в случайных позициях вокруг эмодзи
          for (int i = 0; i < 5; i++) {
            final angle =
                i * math.pi * 2 / 5 + math.sin(progress * math.pi * 2) * 0.5;
            final distance = 35.0 + math.sin(progress * math.pi * 3 + i) * 8.0;
            final sparkleX = position.dx + math.cos(angle) * distance;
            final sparkleY = position.dy - 45 + math.sin(angle) * distance;

            canvas.drawCircle(
                Offset(sparkleX, sparkleY), sparkleSize, sparklePaint);
          }
        }
      }
    }

    // Рисуем метку веса с анимацией и лучшим оформлением
    if (progress > 0.7 && label.isNotEmpty) {
      double labelOpacity = math.min(1.0, (progress - 0.7) * 3.0);

      // Пропускаем отрисовку почти невидимых меток
      if (labelOpacity > 0.05) {
        // Рисуем подложку для метки веса
        final safeLabelBgOpacity = (labelOpacity * 0.2).clamp(0.0, 1.0);
        final labelBgPaint = Paint()
          ..color = _getSafeColor(color, safeLabelBgOpacity)
          ..style = PaintingStyle.fill;

        final labelPosition = Offset(position.dx, position.dy + 20);
        final labelWidth = 70.0;
        final labelHeight = 22.0;

        final labelRect = RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: labelPosition, width: labelWidth, height: labelHeight),
          Radius.circular(labelHeight / 2),
        );

        canvas.drawRRect(labelRect, labelBgPaint);

        // Рисуем текст веса на подложке
        _drawSafeText(
            canvas: canvas,
            text: label,
            position: labelPosition,
            style: TextStyle(
              color: _getSafeColor(color, labelOpacity),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
            alignment: TextAlignment.center,
            maxWidth: 60);
      }
    }
  }

  // Вспомогательный метод для безопасного создания цвета с прозрачностью
  Color _getSafeColor(Color baseColor, double opacity) {
    if (baseColor == null) {
      return Colors.transparent;
    }

    // Убедимся, что opacity в допустимом диапазоне
    final safeOpacity = opacity.clamp(0.0, 1.0);

    try {
      return baseColor.withOpacity(safeOpacity);
    } catch (e) {
      // Если преобразование не удалось, вернем запасной цвет
      return Colors.blue.withOpacity(safeOpacity);
    }
  }

  // Новый метод для безопасной отрисовки текста с ограничением по ширине
  void _drawSafeText({
    required Canvas canvas,
    required String text,
    required Offset position,
    required TextStyle style,
    TextAlignment alignment = TextAlignment.left,
    double maxWidth = 100,
  }) {
    // Определяем выравнивание текста
    ui.TextAlign textAlign =
        ui.TextAlign.left; // Устанавливаем значение по умолчанию
    double xOffset = 0;

    switch (alignment) {
      case TextAlignment.left:
        textAlign = ui.TextAlign.left;
        break;
      case TextAlignment.center:
        textAlign = ui.TextAlign.center;
        xOffset = -maxWidth / 2;
        break;
      case TextAlignment.right:
        textAlign = ui.TextAlign.right;
        xOffset = -maxWidth;
        break;
    }

    final builder = ui.ParagraphBuilder(ui.ParagraphStyle(
      textAlign: textAlign,
      fontSize: style.fontSize ?? 12.0,
      ellipsis: '...',
      maxLines: 1,
    ))
      ..pushStyle(style.getTextStyle())
      ..addText(text);

    final paragraph = builder.build()
      ..layout(ui.ParagraphConstraints(width: maxWidth));

    canvas.drawParagraph(paragraph,
        Offset(position.dx + xOffset, position.dy - paragraph.height / 2));
  }

  // Улучшенный метод для рисования бейджа с датой
  void _drawDateBadge(Canvas canvas, Offset endPoint, String month, String day,
      double screenWidth,
      [double opacity = 1.0]) {
    // Измеряем текст, чтобы определить размер бейджа
    final textStyle = TextStyle(
      color: Colors.white.withOpacity(opacity),
      fontSize: 10,
      fontWeight: FontWeight.w600,
    );

    final textWidth = _measureText("$month $day", textStyle);

    // Минимальная ширина бейджа
    final badgeWidth = textWidth + 20.0;
    final badgeHeight = 26.0;

    // Убедимся, что бейдж не выходит за пределы экрана
    double xPos = endPoint.dx;
    if (xPos + badgeWidth / 2 > screenWidth - 10) {
      xPos = screenWidth - badgeWidth / 2 - 10;
    }

    // Рисуем красный прямоугольник
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(
          center: Offset(xPos, endPoint.dy - 20),
          width: badgeWidth,
          height: badgeHeight),
      Radius.circular(badgeHeight / 2),
    );

    final paint = Paint()
      ..color = Colors.red.withOpacity(opacity)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(rect, paint);

    // Рисуем текст месяца и дня вместе, центрированный внутри бейджа
    _drawSafeText(
        canvas: canvas,
        text: "$month $day",
        position: Offset(xPos, endPoint.dy - 20),
        style: textStyle,
        alignment: TextAlignment.center,
        maxWidth: badgeWidth - 10);
  }

  // Вспомогательный метод для измерения ширины текста
  double _measureText(String text, TextStyle style) {
    final builder = ui.ParagraphBuilder(ui.ParagraphStyle(
      fontSize: style.fontSize ?? 12.0,
    ))
      ..pushStyle(style.getTextStyle())
      ..addText(text);

    final paragraph = builder.build()
      ..layout(ui.ParagraphConstraints(width: double.infinity));

    return paragraph.longestLine;
  }

  // Добавляем новый метод для эффекта достижения цели
  void _drawTargetReachedEffect(
      Canvas canvas, Offset position, Color color, double progress) {
    // Создаем эффект расходящихся волн
    final waveCount = 3;
    final maxRadius = 50.0;

    for (int i = 0; i < waveCount; i++) {
      // Фазовое смещение для каждой волны
      final phaseOffset = i * 0.33;
      // Прогресс для этой волны (0-1)
      final waveProgress = (progress - phaseOffset).clamp(0.0, 1.0);

      if (waveProgress <= 0) continue;

      // Радиус расходящейся волны
      final radius = waveProgress * maxRadius;
      // Уменьшающаяся прозрачность с увеличением радиуса
      final opacity = (1.0 - waveProgress) * 0.3;

      final wavePaint = Paint()
        ..color = color.withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2.0);

      canvas.drawCircle(position, radius, wavePaint);
    }

    // Добавляем блики "звездочки" достижения
    if (progress > 0.8) {
      final starCount = 8;
      final starRays = 5;
      final innerRadius = 4.0;
      final outerRadius = 15.0;

      for (int i = 0; i < starCount; i++) {
        final starAngle = i * math.pi * 2 / starCount;
        final starX = position.dx + math.cos(starAngle) * 30.0 * progress;
        final starY = position.dy + math.sin(starAngle) * 30.0 * progress;

        final starPaint = Paint()
          ..color = Colors.yellow.withOpacity((progress - 0.8) * 5)
          ..style = PaintingStyle.fill;

        // Рисуем звездочку
        final starPath = Path();
        for (int j = 0; j < starRays * 2; j++) {
          final rayAngle = j * math.pi / starRays;
          final radius = j.isEven ? outerRadius : innerRadius;
          final x = starX + math.cos(rayAngle) * radius * progress;
          final y = starY + math.sin(rayAngle) * radius * progress;

          if (j == 0) {
            starPath.moveTo(x, y);
          } else {
            starPath.lineTo(x, y);
          }
        }
        starPath.close();

        canvas.drawPath(starPath, starPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is AnimatedWeightProgressPainter) {
      return oldDelegate.curveProgress != curveProgress ||
          oldDelegate.opacityProgress != opacityProgress ||
          oldDelegate.point1Progress != point1Progress ||
          oldDelegate.point2Progress != point2Progress ||
          oldDelegate.point3Progress != point3Progress ||
          oldDelegate.emojiProgress != emojiProgress;
    }
    return true;
  }
}

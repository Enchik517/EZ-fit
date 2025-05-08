import 'package:flutter/material.dart' hide TextDirection;
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import '../screens/weight_trend_screen.dart'; // Импортируем, чтобы получить доступ к enum

// Создадим собственную локальную реализацию TextDirection
// Это временное решение для компиляции
enum MyTextDirection { ltr, rtl }

// Enum для выравнивания текста (вынесен на уровень модуля)
enum TextAlignment { left, center, right }

class WeightPredictionScreen extends StatefulWidget {
  final VoidCallback onNext;
  final double currentWeight;
  final double? targetWeight;
  final dynamic weightTrend;
  final int? workoutFrequency;
  final bool isMetric;

  const WeightPredictionScreen({
    Key? key,
    required this.onNext,
    required this.currentWeight,
    this.targetWeight,
    this.weightTrend,
    this.workoutFrequency,
    required this.isMetric,
  }) : super(key: key);

  @override
  _WeightPredictionScreenState createState() => _WeightPredictionScreenState();
}

class _WeightPredictionScreenState extends State<WeightPredictionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _curveAnimation;
  late Animation<double> _badgeAnimation;
  double _animationProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 3),
    );

    _curveAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _badgeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Interval(0.7, 1.0, curve: Curves.elasticOut),
    );

    // Обновляем значение анимации при каждом изменении
    _controller.addListener(() {
      setState(() {
        _animationProgress = _curveAnimation.value;
      });
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Рассчитываем прогнозируемую дату и вес
    final targetDate = _calculateTargetDate();
    final predictedWeight = _calculatePredictedWeight();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 32),

        // Title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'You are in the right place',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        SizedBox(height: 32),

        // Prediction card with graph
        Container(
          margin: EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // От текущего веса
                        _buildWeightBox(
                          label: 'Current',
                          weight: widget.currentWeight,
                          isMetric: widget.isMetric,
                        ),
                        // К предсказанному весу
                        _buildWeightBox(
                          label: 'Predicted',
                          weight: predictedWeight,
                          isMetric: widget.isMetric,
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Target date: ${DateFormat('MMM d').format(targetDate)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Weight progress graph
              SizedBox(
                height: 250,
                width: double.infinity,
                child: CustomPaint(
                  painter: AnimatedWeightPredictionPainter(
                    currentWeight: widget.currentWeight,
                    targetWeight: predictedWeight,
                    targetDate: targetDate,
                    isMetric: widget.isMetric,
                    animationValue: _animationProgress,
                    badgeAnimationValue: _badgeAnimation.value,
                  ),
                ),
              ),
            ],
          ),
        ),

        Spacer(),

        // Next button
        Padding(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: widget.onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Next',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Метод для отображения блока с весом
  Widget _buildWeightBox({
    required String label,
    required double weight,
    required bool isMetric,
  }) {
    // Конвертируем вес, если необходимо
    final double displayWeight = isMetric ? weight : weight * 2.20462;
    final String unit = isMetric ? 'kg' : 'lbs';

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '${displayWeight.toStringAsFixed(1)} $unit',
            style: GoogleFonts.inter(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Рассчитываем целевую дату на основе данных пользователя
  DateTime _calculateTargetDate() {
    int daysNeeded = 30; // Стандартное значение

    // Получаем String версию enum значения
    String? trendString = _getWeightTrendString();

    // Корректируем дни в зависимости от тренда веса и частоты тренировок
    if (trendString == 'Gaining') {
      daysNeeded = 45; // Набор требует больше времени
    } else if (trendString == 'Losing') {
      daysNeeded = 35; // Потеря обычно быстрее при похудении
    } else if (trendString == 'Stable') {
      daysNeeded = 40; // Со стабильного веса нужно больше времени для изменений
    }

    // Частота тренировок влияет на скорость
    if (widget.workoutFrequency != null) {
      if (widget.workoutFrequency! >= 5) {
        daysNeeded =
            (daysNeeded * 0.8).round(); // Больше тренировок = быстрее результат
      } else if (widget.workoutFrequency! <= 2) {
        daysNeeded = (daysNeeded * 1.2)
            .round(); // Меньше тренировок = медленнее результат
      }
    }

    return DateTime.now().add(Duration(days: daysNeeded));
  }

  // Вспомогательный метод для получения строкового представления enum
  String? _getWeightTrendString() {
    if (widget.weightTrend == null) return null;

    // Если это уже строка, возвращаем как есть
    if (widget.weightTrend is String) return widget.weightTrend;

    // Если это enum WeightTrend, преобразуем в строку
    if (widget.weightTrend is WeightTrend) {
      switch (widget.weightTrend) {
        case WeightTrend.losing:
          return 'Losing';
        case WeightTrend.stable:
          return 'Stable';
        case WeightTrend.gaining:
          return 'Gaining';
      }
    }

    // Попробуем получить имя значения enum
    try {
      return widget.weightTrend.toString().split('.').last;
    } catch (e) {
      return null;
    }
  }

  // Рассчитываем предсказанный вес
  double _calculatePredictedWeight() {
    if (widget.targetWeight != null) {
      // Если есть целевой вес, используем его с некоторой поправкой
      double difference = widget.currentWeight - widget.targetWeight!;
      return widget.currentWeight -
          (difference * 0.85); // Достигаем 85% пути к цели
    } else {
      // Получаем String версию enum значения
      String? trendString = _getWeightTrendString();

      // Иначе предсказываем вес на основе тренда
      if (trendString == 'Gaining') {
        return widget.currentWeight +
            (widget.currentWeight * 0.05); // +5% от текущего веса
      } else if (trendString == 'Losing') {
        return widget.currentWeight -
            (widget.currentWeight * 0.07); // -7% от текущего веса
      } else {
        // Для стабильного веса небольшая потеря
        return widget.currentWeight -
            (widget.currentWeight * 0.03); // -3% от текущего веса
      }
    }
  }
}

// Новый анимированный класс для рисования с анимацией
class AnimatedWeightPredictionPainter extends CustomPainter {
  final double currentWeight;
  final double targetWeight;
  final DateTime targetDate;
  final bool isMetric;
  final double animationValue;
  final double badgeAnimationValue;

  AnimatedWeightPredictionPainter({
    required this.currentWeight,
    required this.targetWeight,
    required this.targetDate,
    required this.isMetric,
    required this.animationValue,
    required this.badgeAnimationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final padding = 20.0;

    // Цвета и настройки
    final Color primaryColor = Color(0xFFD81B60); // Розовый как на скриншоте
    final Color blueColor = Color(0xFF2979FF); // Синий для начала графика

    // Рисуем оси
    final axisPaint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // X-axis (time)
    canvas.drawLine(
      Offset(padding, height - padding),
      Offset(width - padding, height - padding),
      axisPaint,
    );

    // Вычисляем точки кривой
    final startX = padding;
    final endX = width - padding;
    final startY = height - padding - _normalizeWeight(currentWeight, height);
    final endY = height - padding - _normalizeWeight(targetWeight, height);

    // Создаем градиент для кривой
    final gradientPaint = Paint()
      ..shader = LinearGradient(
        colors: [blueColor, Color(0xFF8860F5), primaryColor],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(0, 0, width, height))
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // Рисуем кривую с анимацией
    final path = Path();
    path.moveTo(startX, startY);

    // Контрольные точки для плавной кривой
    final controlPoint1 =
        Offset(startX + (endX - startX) * 0.35, startY + (endY - startY) * 0.1);
    final controlPoint2 =
        Offset(startX + (endX - startX) * 0.65, endY - (endY - startY) * 0.1);

    // Текущая конечная точка анимации
    final currentEndX =
        animationValue < 1.0 ? startX + (endX - startX) * animationValue : endX;

    final currentEndY =
        animationValue < 1.0 ? startY + (endY - startY) * animationValue : endY;

    // Рассчитываем текущие контрольные точки
    final currentCP1 = Offset(
      startX +
          (controlPoint1.dx - startX) * math.min(1.0, animationValue * 1.5),
      startY +
          (controlPoint1.dy - startY) * math.min(1.0, animationValue * 1.5),
    );

    final currentCP2 = Offset(
      startX +
          (controlPoint2.dx - startX) * math.min(1.0, animationValue * 1.5),
      startY +
          (controlPoint2.dy - startY) * math.min(1.0, animationValue * 1.5),
    );

    path.cubicTo(
      currentCP1.dx,
      currentCP1.dy,
      currentCP2.dx,
      currentCP2.dy,
      currentEndX,
      currentEndY,
    );

    // Заливка под кривой с градиентом
    final fillPath = Path.from(path);
    fillPath.lineTo(currentEndX, height - padding);
    fillPath.lineTo(startX, height - padding);
    fillPath.close();

    final fillGradient = LinearGradient(
      colors: [
        blueColor.withOpacity(0.2),
        primaryColor.withOpacity(0.05),
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(Rect.fromLTWH(0, 0, width, height));

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = fillGradient
        ..style = PaintingStyle.fill,
    );

    // Рисуем линию кривой поверх заливки
    canvas.drawPath(path, gradientPaint);

    // Рисуем маркер "Today" (синяя точка)
    final todayDotPaint = Paint()
      ..color = blueColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(startX, startY),
      6,
      todayDotPaint,
    );

    // Рисуем метку целевой даты с анимацией
    if (animationValue > 0.7) {
      final targetOpacity = math.min(1.0, (animationValue - 0.7) * 3.3);

      final targetDotPaint = Paint()
        ..color = Colors.white.withOpacity(targetOpacity)
        ..style = PaintingStyle.fill;

      final targetDotOutlinePaint = Paint()
        ..color = primaryColor.withOpacity(targetOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawCircle(
        Offset(currentEndX, currentEndY),
        6,
        targetDotPaint,
      );

      canvas.drawCircle(
        Offset(currentEndX, currentEndY),
        6,
        targetDotOutlinePaint,
      );
    }

    // Форматирование дат
    String todayText = 'Today';
    String targetDateText = DateFormat('MMM d').format(targetDate);

    final textStyle = TextStyle(
      color: Colors.grey[600]!,
      fontSize: 12,
      fontWeight: FontWeight.w500,
    );

    // Рисуем текст "Today" внизу
    _drawSafeText(
      canvas: canvas,
      text: todayText,
      x: startX,
      y: height - padding + 15,
      style: textStyle,
      alignment: TextAlignment.left,
      maxWidth: width / 3,
      opacity: 1.0,
    );

    // Рисуем метку целевой даты внизу с анимацией появления
    _drawSafeText(
      canvas: canvas,
      text: targetDateText,
      x: endX,
      y: height - padding + 15,
      style: textStyle,
      alignment: TextAlignment.right,
      maxWidth: width / 3,
      opacity: animationValue,
    );
  }

  // Вспомогательный метод для оценки ширины текста
  double _estimateTextWidth(String text, TextStyle style) {
    return text.length * (style.fontSize ?? 14) * 0.6;
  }

  // Безопасный метод отрисовки текста
  void _drawSafeText({
    required Canvas canvas,
    required String text,
    required double x,
    required double y,
    required TextStyle style,
    required TextAlignment alignment,
    required double maxWidth,
    required double opacity,
  }) {
    // Создаем копию стиля с нужной прозрачностью
    final adjustedStyle = TextStyle(
      color: style.color?.withOpacity(opacity),
      fontSize: style.fontSize,
      fontWeight: style.fontWeight,
    );

    final builder = ui.ParagraphBuilder(ui.ParagraphStyle(
      textAlign: alignment == TextAlignment.center
          ? TextAlign.center
          : (alignment == TextAlignment.right
              ? TextAlign.right
              : TextAlign.left),
      fontSize: style.fontSize ?? 12.0,
      maxLines: 1,
      ellipsis: '...',
    ))
      ..pushStyle(adjustedStyle.getTextStyle())
      ..addText(text);

    final paragraph = builder.build()
      ..layout(ui.ParagraphConstraints(width: maxWidth));

    // Вычисляем позицию с учетом выравнивания
    double xPos = x;

    switch (alignment) {
      case TextAlignment.left:
        xPos = x;
        break;
      case TextAlignment.center:
        xPos = x - paragraph.width / 2;
        break;
      case TextAlignment.right:
        xPos = x - paragraph.width;
        break;
    }

    canvas.drawParagraph(paragraph, Offset(xPos, y));
  }

  // Нормализация значений веса
  double _normalizeWeight(double weight, double height) {
    // Определяем диапазон веса
    final maxWeight =
        currentWeight > targetWeight ? currentWeight : targetWeight;
    final minWeight =
        currentWeight < targetWeight ? currentWeight : targetWeight;
    final range = (maxWeight - minWeight).abs();

    // Используем минимум 5кг диапазон для лучшей визуализации
    final effectiveRange = range < 5 ? 5.0 : range;

    // Рассчитываем вертикальное пространство
    final verticalSpace = height - 32;

    // Нормализуем вес к высоте графика
    if (currentWeight > targetWeight) {
      // Потеря веса
      return ((currentWeight - weight) / effectiveRange) * verticalSpace * 0.8;
    } else {
      // Набор веса
      return ((weight - currentWeight) / effectiveRange) * verticalSpace * 0.8;
    }
  }

  @override
  bool shouldRepaint(covariant AnimatedWeightPredictionPainter oldDelegate) =>
      oldDelegate.currentWeight != currentWeight ||
      oldDelegate.targetWeight != targetWeight ||
      oldDelegate.targetDate != targetDate ||
      oldDelegate.animationValue != animationValue ||
      oldDelegate.badgeAnimationValue != badgeAnimationValue;
}

// Оставляем старый класс для обратной совместимости
class WeightPredictionPainter extends CustomPainter {
  final double currentWeight;
  final double targetWeight;
  final DateTime targetDate;
  final bool isMetric;

  WeightPredictionPainter({
    required this.currentWeight,
    required this.targetWeight,
    required this.targetDate,
    required this.isMetric,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Используем наш новый анимированный класс с анимацией 100%
    final animatedPainter = AnimatedWeightPredictionPainter(
      currentWeight: currentWeight,
      targetWeight: targetWeight,
      targetDate: targetDate,
      isMetric: isMetric,
      animationValue: 1.0,
      badgeAnimationValue: 1.0,
    );

    animatedPainter.paint(canvas, size);
  }

  @override
  bool shouldRepaint(covariant WeightPredictionPainter oldDelegate) =>
      oldDelegate.currentWeight != currentWeight ||
      oldDelegate.targetWeight != targetWeight ||
      oldDelegate.targetDate != targetDate;
}

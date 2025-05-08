import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter/scheduler.dart';
import 'dart:ui' as ui;

class PotentialPage extends StatefulWidget {
  final VoidCallback onNext;

  const PotentialPage({Key? key, required this.onNext}) : super(key: key);

  @override
  _PotentialPageState createState() => _PotentialPageState();
}

class _PotentialPageState extends State<PotentialPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _curveAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _point1Animation;
  late Animation<double> _point2Animation;
  late Animation<double> _point3Animation;
  late Animation<double> _emojiAnimation;

  @override
  void initState() {
    super.initState();
    // Инициализируем анимацию на 3 секунды
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 3000),
    );

    // Кривая для основной линии
    _curveAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );

    // Анимация прозрачности для эффекта появления
    _opacityAnimation = CurvedAnimation(
      parent: _controller,
      curve: Interval(0.1, 0.3, curve: Curves.easeIn),
    );

    // Анимации для точек с разным таймингом
    _point1Animation = CurvedAnimation(
      parent: _controller,
      curve: Interval(0.3, 0.5, curve: Curves.elasticOut),
    );

    _point2Animation = CurvedAnimation(
      parent: _controller,
      curve: Interval(0.5, 0.7, curve: Curves.elasticOut),
    );

    _point3Animation = CurvedAnimation(
      parent: _controller,
      curve: Interval(0.7, 0.9, curve: Curves.elasticOut),
    );

    // Анимация для эмодзи
    _emojiAnimation = CurvedAnimation(
      parent: _controller,
      curve: Interval(0.8, 1.0, curve: Curves.bounceOut),
    );

    // Запускаем анимацию
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'You have great potential to crush your goals',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.left,
          ),
          SizedBox(height: 48),
          Expanded(
            child: Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: AnimatedProgressGraphPainter(
                            curveProgress: _curveAnimation.value,
                            opacityProgress: _opacityAnimation.value,
                            point1Progress: _point1Animation.value,
                            point2Progress: _point2Animation.value,
                            point3Progress: _point3Animation.value,
                            emojiProgress: _emojiAnimation.value,
                          ),
                          size: Size.infinite,
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Based on historical data. For women in their 95s, muscle building takes consistency but your body will show amazing progress after regular training!',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 13,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: widget.onNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 4,
            ),
            child: Text(
              'Next',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedProgressGraphPainter extends CustomPainter {
  final double curveProgress;
  final double opacityProgress;
  final double point1Progress;
  final double point2Progress;
  final double point3Progress;
  final double emojiProgress;

  AnimatedProgressGraphPainter({
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

    // Области графика
    final double padding = 20.0;
    final double lineY = height * 0.7;

    // Обновленные цвета в соответствии с изображением
    final Color blueColor = Color(0xFF2196F3); // Синий для начала графика
    final Color purpleColor = Color(0xFF8860F5); // Фиолетовый для середины
    final Color pinkColor = Color(0xFFE81B60); // Розовый для конца

    // Позиции опорных точек
    final point1X = width * 0.3;
    final point2X = width * 0.6;
    final point3X = width * 0.9;

    // Позиции точек на графике (делаем их более соответствующими дизайну)
    final beginPoint = Offset(padding, lineY);
    final point1Y = lineY - height * 0.25; // Ниже, как на скриншоте
    final point2Y = lineY - height * 0.45; // Средняя высота
    final point3Y = lineY - height * 0.35; // Чуть ниже второй точки

    // Конечные координаты точек
    final point1 = Offset(point1X, point1Y);
    final point2 = Offset(point2X, point2Y);
    final point3 = Offset(point3X, point3Y);

    // Отрисовка осей X
    final axisPaint = Paint()
      ..color = Colors.grey[200]!
      ..strokeWidth = 1.0;

    canvas.drawLine(
      Offset(padding, height - padding),
      Offset(width - padding, height - padding),
      axisPaint,
    );

    // Подписи для осей X (даты)
    if (curveProgress > 0.3) {
      _drawVerticalDashedLine(canvas, Offset(point1X, height - padding),
          Offset(point1X, point1Y), blueColor.withOpacity(0.3));
      _drawAxisLabel(
          canvas, "3 Days", point1X, height - padding + 15, blueColor);
    }

    if (curveProgress > 0.6) {
      _drawVerticalDashedLine(canvas, Offset(point2X, height - padding),
          Offset(point2X, point2Y), purpleColor.withOpacity(0.3));
      _drawAxisLabel(
          canvas, "7 Days", point2X, height - padding + 15, purpleColor);
    }

    if (curveProgress > 0.9) {
      _drawVerticalDashedLine(canvas, Offset(point3X, height - padding),
          Offset(point3X, point3Y), pinkColor.withOpacity(0.3));
      _drawAxisLabel(
          canvas, "30 Days", point3X, height - padding + 15, pinkColor);
    }

    // Подпись "Today"
    _drawAxisLabel(canvas, "Today", padding, height - padding + 15, blueColor);

    // Добавляем подпись "Weight-loss effect" на вертикальной оси
    if (opacityProgress > 0.5) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: "Weight-loss effect",
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();

      // Сохраняем состояние холста перед вращением
      canvas.save();

      // Перемещаем точку начала координат
      canvas.translate(padding - 10, height / 2);

      // Поворачиваем холст
      canvas.rotate(-math.pi / 2);

      // Рисуем текст
      textPainter.paint(canvas, Offset(-textPainter.width / 2, 0));

      // Восстанавливаем холст
      canvas.restore();

      // Рисуем стрелку вверх
      final arrowPaint = Paint()
        ..color = Colors.grey[600]!
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      final arrowPath = Path();
      arrowPath.moveTo(padding - 10, height / 4);
      arrowPath.lineTo(padding - 10, height / 8);
      arrowPath.lineTo(padding - 13, height / 8 + 5);
      arrowPath.moveTo(padding - 10, height / 8);
      arrowPath.lineTo(padding - 7, height / 8 + 5);

      canvas.drawPath(arrowPath, arrowPaint);
    }

    // Разбиваем отрисовку на сегменты
    if (curveProgress > 0) {
      // Сегмент 1 (синий)
      if (curveProgress <= 0.33) {
        _drawGraphSegment(
            canvas, beginPoint, point1, curveProgress * 3, blueColor,
            beginColor: blueColor,
            endColor: blueColor,
            height: height,
            padding: padding);
      } else {
        _drawGraphSegment(canvas, beginPoint, point1, 1.0, blueColor,
            beginColor: blueColor,
            endColor: purpleColor,
            height: height,
            padding: padding);

        // Сегмент 2 (фиолетовый)
        if (curveProgress <= 0.66) {
          _drawGraphSegment(
              canvas, point1, point2, (curveProgress - 0.33) * 3, purpleColor,
              beginColor: purpleColor,
              endColor: purpleColor,
              height: height,
              padding: padding);
        } else {
          _drawGraphSegment(canvas, point1, point2, 1.0, purpleColor,
              beginColor: purpleColor,
              endColor: pinkColor,
              height: height,
              padding: padding);

          // Сегмент 3 (розовый)
          _drawGraphSegment(
              canvas, point2, point3, (curveProgress - 0.66) * 3, pinkColor,
              beginColor: pinkColor,
              endColor: pinkColor,
              height: height,
              padding: padding);
        }
      }
    }

    // Отрисовка точек с анимацией прыжков
    // Точка 1
    if (point1Progress > 0) {
      _drawAnimatedPoint(canvas, point1, blueColor, "😍", point1Progress, "");
    }

    // Точка 2
    if (point2Progress > 0) {
      _drawAnimatedPoint(canvas, point2, purpleColor, "😉", point2Progress, "");
    }

    // Точка 3
    if (point3Progress > 0) {
      _drawAnimatedPoint(canvas, point3, pinkColor, "😁", point3Progress, "");
    }

    // Добавляем метку "Goal" с анимацией
    if (point3Progress > 0.8 && emojiProgress > 0) {
      final goalScale = emojiProgress * 1.1;
      final goalOpacity = math.min(1.0, emojiProgress * 1.5);

      // Сохраняем состояние холста
      canvas.save();

      // Применяем трансформации для анимации
      canvas.translate(point3.dx - 30, point3.dy - 50);
      canvas.scale(goalScale);

      // Создаем пузырек с текстом "Goal"
      final goalBubbleRect = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(0, 0), width: 60, height: 30),
          Radius.circular(15));

      final goalPaint = Paint()
        ..color = pinkColor.withOpacity(goalOpacity)
        ..style = PaintingStyle.fill;

      canvas.drawRRect(goalBubbleRect, goalPaint);

      // Текст "Goal"
      final textPainter = TextPainter(
        text: TextSpan(
            text: 'Goal',
            style: TextStyle(
              color: Colors.white.withOpacity(goalOpacity),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            )),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );

      textPainter.layout();
      textPainter.paint(
          canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));

      // Восстанавливаем холст
      canvas.restore();
    }
  }

  // Вспомогательный метод для рисования сегмента графика
  void _drawGraphSegment(Canvas canvas, Offset startPoint, Offset endPoint,
      double progress, Color color,
      {required Color beginColor,
      required Color endColor,
      required double height,
      required double padding}) {
    if (progress <= 0) return;

    // Контрольные точки для плавности
    final controlPoint1 = Offset(
        startPoint.dx + (endPoint.dx - startPoint.dx) * 0.4,
        startPoint.dy + (endPoint.dy - startPoint.dy) * 0.2);

    final controlPoint2 = Offset(
        startPoint.dx + (endPoint.dx - startPoint.dx) * 0.6,
        endPoint.dy + (startPoint.dy - endPoint.dy) * 0.2);

    // Вычисляем текущую конечную точку
    final currentEndPoint = Offset(
        startPoint.dx + (endPoint.dx - startPoint.dx) * progress,
        startPoint.dy + (endPoint.dy - startPoint.dy) * progress);

    // Вычисляем текущие контрольные точки
    final currentCP1 = Offset(
        startPoint.dx + (controlPoint1.dx - startPoint.dx) * progress,
        startPoint.dy + (controlPoint1.dy - startPoint.dy) * progress);

    final currentCP2 = Offset(
        startPoint.dx + (controlPoint2.dx - startPoint.dx) * progress,
        startPoint.dy + (controlPoint2.dy - startPoint.dy) * progress);

    // Создаем градиент для линии
    final gradientPaint = Paint()
      ..shader = LinearGradient(
              colors: [beginColor, endColor],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight)
          .createShader(Rect.fromPoints(startPoint, endPoint))
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Рисуем линию
    final linePath = Path();
    linePath.moveTo(startPoint.dx, startPoint.dy);
    linePath.cubicTo(currentCP1.dx, currentCP1.dy, currentCP2.dx, currentCP2.dy,
        currentEndPoint.dx, currentEndPoint.dy);

    canvas.drawPath(linePath, gradientPaint);

    // Создаем заливку под линией
    final fillPath = Path();
    fillPath.moveTo(startPoint.dx, startPoint.dy);
    fillPath.cubicTo(currentCP1.dx, currentCP1.dy, currentCP2.dx, currentCP2.dy,
        currentEndPoint.dx, currentEndPoint.dy);
    fillPath.lineTo(currentEndPoint.dx, height - padding);
    fillPath.lineTo(startPoint.dx, height - padding);
    fillPath.close();

    // Рисуем заливку с градиентом
    final fillGradientPaint = Paint()
      ..shader = LinearGradient(
              colors: [beginColor.withOpacity(0.2), endColor.withOpacity(0.05)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter)
          .createShader(
              Rect.fromLTRB(startPoint.dx, 0, currentEndPoint.dx, height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillGradientPaint);
  }

  // Метод для рисования пунктирной вертикальной линии
  void _drawVerticalDashedLine(
      Canvas canvas, Offset start, Offset end, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const dashHeight = 4.0;
    const dashSpace = 3.0;

    double startY = start.dy;
    final endY = end.dy;

    while (startY > endY) {
      final dashEndY = math.max(startY - dashHeight, endY);
      canvas.drawLine(
          Offset(start.dx, startY), Offset(start.dx, dashEndY), paint);
      startY = dashEndY - dashSpace;
    }
  }

  // Метод для отрисовки подписей на осях
  void _drawAxisLabel(
      Canvas canvas, String text, double x, double y, Color color) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    textPainter.layout();
    textPainter.paint(canvas, Offset(x - textPainter.width / 2, y));
  }

  // Вспомогательный метод для отрисовки анимированной точки
  void _drawAnimatedPoint(Canvas canvas, Offset position, Color color,
      String emoji, double progress, String label) {
    // Эффект прыжка для точки и эмодзи
    final yOffset = math.sin(progress * math.pi) * 12.0;
    final emojiYOffset = -math.sin(progress * math.pi * 1.5) * 20.0;
    final emojiXOffset = math.cos(progress * math.pi * 2.0) * 8.0;
    final scale = 1.0 + math.sin(progress * math.pi) * 0.2;

    final pointPos = Offset(position.dx, position.dy - yOffset);

    // Рисуем круг с эффектом свечения
    final outerGlowPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(pointPos, 12.0, outerGlowPaint);

    // Рисуем основной круг
    final pointPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(pointPos, 8.0, pointPaint);

    // Рисуем внутренний белый круг
    final innerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(pointPos, 4.0, innerPaint);

    // Отрисовка эмодзи с анимацией
    final textPainter = TextPainter(
      text: TextSpan(
        text: emoji,
        style: TextStyle(
          fontSize: 32 * scale,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    textPainter.layout();

    // Сохраняем состояние холста
    canvas.save();

    // Устанавливаем позицию и масштаб
    final emojiX = position.dx + emojiXOffset;
    final emojiY = position.dy - 60 + emojiYOffset;

    canvas.translate(emojiX, emojiY);
    canvas.scale(scale);

    // Рисуем эмодзи
    textPainter.paint(
        canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));

    // Восстанавливаем холст
    canvas.restore();

    // Рисуем подпись если нужно
    if (label.isNotEmpty) {
      final labelPainter = TextPainter(
        text: TextSpan(
            text: label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            )),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );

      labelPainter.layout();
      labelPainter.paint(canvas,
          Offset(position.dx - labelPainter.width / 2, position.dy + 18));
    }
  }

  @override
  bool shouldRepaint(covariant AnimatedProgressGraphPainter oldDelegate) {
    return oldDelegate.curveProgress != curveProgress ||
        oldDelegate.opacityProgress != opacityProgress ||
        oldDelegate.point1Progress != point1Progress ||
        oldDelegate.point2Progress != point2Progress ||
        oldDelegate.point3Progress != point3Progress ||
        oldDelegate.emojiProgress != emojiProgress;
  }
}

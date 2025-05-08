import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math; // Обновляем импорт с именем
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class ProgressProjectionScreen extends StatefulWidget {
  final VoidCallback onNext;
  final String gender;
  final int? age;
  final double? currentWeight;
  final double? targetWeight;
  final double? height;
  final String? bodyFatRange;
  
  const ProgressProjectionScreen({
    Key? key, 
    required this.onNext,
    required this.gender,
    this.age,
    this.currentWeight,
    this.targetWeight,
    this.height,
    this.bodyFatRange,
  }) : super(key: key);

  @override
  _ProgressProjectionScreenState createState() =>
      _ProgressProjectionScreenState();
}

class _ProgressProjectionScreenState extends State<ProgressProjectionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _curveAnimation;
  late Animation<double> _pointsAnimation;
  late Animation<double> _emoji1Animation;
  late Animation<double> _emoji2Animation;
  late Animation<double> _emoji3Animation;
  double _animationProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 5),
    );

    _curveAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    // Анимация для точек
    _pointsAnimation = CurvedAnimation(
      parent: _controller,
      curve: Interval(0.7, 1.0, curve: Curves.elasticOut),
    );

    // Анимации для эмодзи с более выраженным эффектом
    _emoji1Animation = CurvedAnimation(
      parent: _controller,
      curve: Interval(0.75, 0.85, curve: Curves.elasticOut),
    );

    _emoji2Animation = CurvedAnimation(
      parent: _controller,
      curve: Interval(0.85, 0.95, curve: Curves.elasticOut),
    );

    _emoji3Animation = CurvedAnimation(
      parent: _controller,
      curve: Interval(0.95, 1.0, curve: Curves.elasticOut),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final weightDifference =
        (widget.currentWeight ?? 0) - (widget.targetWeight ?? 0);
    final isWeightLoss = weightDifference > 0;
    final goalDifficulty = _calculateDifficulty();
    
    return Scaffold(
      backgroundColor: Color(0xFF1E2026), // Темный фон как в других экранах
      body: SafeArea(
        child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
            SizedBox(height: 24),
        
        // Title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'You have great potential to\ncrush your goals',
            style: GoogleFonts.inter(
              color: Colors.white,
                  fontSize: 28,
              fontWeight: FontWeight.w700,
                  height: 1.3,
            ),
          ),
        ),
        
            SizedBox(height: 40),
        
        // Chart container
        Container(
          margin: EdgeInsets.symmetric(horizontal: 24),
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: BoxDecoration(
            color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 15,
                    offset: Offset(0, 5),
                  ),
                ],
          ),
          child: Column(
            children: [
              // Chart
              SizedBox(
                    height: 200,
                width: double.infinity,
                child: CustomPaint(
                  painter: ProgressGraphPainter(
                        animationValue: _animationProgress,
                        opacityValue: 1.0,
                        pointAnimationValue: _pointsAnimation.value,
                        emoji1AnimationValue: _emoji1Animation.value,
                        emoji2AnimationValue: _emoji2Animation.value,
                        emoji3AnimationValue: _emoji3Animation.value,
                  ),
                ),
              ),
              
                  SizedBox(height: 20),
              
              // Text description
              RichText(
                text: TextSpan(
                  style: GoogleFonts.inter(
                        color: Color(0xFF505050),
                        fontSize: 14,
                        height: 1.4,
                  ),
                  children: [
                    TextSpan(
                      text: 'Based on historical data. ',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                    TextSpan(
                          text: widget.gender == 'Female'
                              ? 'For women in their ${widget.age != null ? "${widget.age}s" : "20s"}'
                              : 'For men in their ${widget.age != null ? "${widget.age}s" : "20s"}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: _getPersonalizedText(isWeightLoss),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
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
                height: 56,
            child: ElevatedButton(
                  onPressed: widget.onNext,
              style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Color(0xFF2E9CFD), // Синяя кнопка как в других экранах
                    foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Next',
                style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
        ),
      ),
    );
  }
  
  double _calculateDifficulty() {
    // 0.0 = легко, 1.0 = сложно
    double difficulty = 0.5; // По умолчанию средняя сложность
    
    if (widget.currentWeight != null && widget.targetWeight != null) {
      // Разница в весе влияет на сложность
      final diff = (widget.currentWeight! - widget.targetWeight!).abs();
      if (diff > 20)
        difficulty += 0.3;
      else if (diff > 10)
        difficulty += 0.1;
      else if (diff < 5) difficulty -= 0.1;
    }
    
    if (widget.age != null) {
      // Возраст влияет на сложность
      if (widget.age! > 40)
        difficulty += 0.2;
      else if (widget.age! < 25) difficulty -= 0.1;
    }
    
    // Ограничиваем от 0.1 до 0.9
    return difficulty.clamp(0.1, 0.9);
  }
  
  String _getPersonalizedText(bool isWeightLoss) {
    if (widget.gender == 'Female') {
      if (isWeightLoss) {
        return ', weight loss is usually delayed at first, but after 7 days, you can burn off calories like crazy!';
      } else {
        return ', muscle building takes consistency but your body will show amazing progress after regular training!';
      }
    } else {
      if (isWeightLoss) {
        return ', men tend to lose weight more steadily, and you should see consistent results within the first 2 weeks!';
      } else {
        return ', muscle growth begins slowly, but after consistent training for 7 days, your body adapts and progress accelerates!';
      }
    }
  }
}

class ProgressGraphPainter extends CustomPainter {
  final double animationValue;
  final double opacityValue;
  final double pointAnimationValue;
  final double emoji1AnimationValue;
  final double emoji2AnimationValue;
  final double emoji3AnimationValue;
  
  ProgressGraphPainter({
    required this.animationValue,
    required this.opacityValue,
    required this.pointAnimationValue,
    required this.emoji1AnimationValue,
    required this.emoji2AnimationValue,
    required this.emoji3AnimationValue,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final height = size.height;
    final width = size.width;

    // Основные цвета
    final primaryColor =
        Color(0xFF2E9CFD); // Синий цвет для начальной части графика
    final middleColor = Color(0xFF8860F5); // Фиолетовый для средней части
    final endColor = Color(0xFFE81B60); // Красный для конечной части

    // Базовая линия и точки графика
    final baseY = height * 0.75;
    final startPoint = Offset(0, baseY);
    final endPoint = Offset(width, baseY * 0.5);
    final point1 = Offset(width * 0.3, baseY * 0.7);
    final point2 = Offset(width * 0.65, baseY * 0.4);

    // Настраиваем путь для графика
    final path = Path();
    path.moveTo(startPoint.dx, startPoint.dy);

    // Определяем контрольные точки для кривых Безье
    final cp1 = Offset(width * 0.15, baseY);
    final cp2 = Offset(width * 0.25, baseY * 0.85);
    final cp3 = Offset(width * 0.4, baseY * 0.6);
    final cp4 = Offset(width * 0.55, baseY * 0.4);
    final cp5 = Offset(width * 0.8, baseY * 0.35);
    final cp6 = Offset(width * 0.9, baseY * 0.4);

    // Рисуем кривую в зависимости от прогресса анимации
    if (animationValue <= 0.3) {
      // Первый сегмент (синий)
      final t = animationValue / 0.3;
      final currentPoint = Offset.lerp(startPoint, point1, t)!;
      path.cubicTo(
          Offset.lerp(startPoint, cp1, t)!.dx,
          Offset.lerp(startPoint, cp1, t)!.dy,
          Offset.lerp(startPoint, cp2, t)!.dx,
          Offset.lerp(startPoint, cp2, t)!.dy,
          currentPoint.dx,
          currentPoint.dy);

      // Рисуем синюю линию
      canvas.drawPath(
          path,
          Paint()
      ..color = primaryColor
            ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round);

      // Заливка градиентом
      final fillPath = Path.from(path);
      fillPath.lineTo(width, height);
      fillPath.lineTo(0, height);
      fillPath.close();

      final fillGradient = LinearGradient(
        colors: [primaryColor.withOpacity(0.3), Colors.transparent],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );

      canvas.drawPath(
          fillPath,
          Paint()
            ..shader =
                fillGradient.createShader(Rect.fromLTWH(0, 0, width, height))
            ..style = PaintingStyle.fill);
    } else if (animationValue <= 0.7) {
      // Первый сегмент полностью (синий)
      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, point1.dx, point1.dy);

      // Рисуем синюю линию первого сегмента
      canvas.drawPath(
          path,
          Paint()
      ..color = primaryColor
            ..strokeWidth = 3.0
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round);

      // Заливка градиентом для первого сегмента
      final fillPath1 = Path.from(path);
      fillPath1.lineTo(point1.dx, height);
      fillPath1.lineTo(0, height);
      fillPath1.close();

      final fillGradient1 = LinearGradient(
        colors: [primaryColor.withOpacity(0.3), Colors.transparent],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );

      canvas.drawPath(
          fillPath1,
          Paint()
            ..shader = fillGradient1
                .createShader(Rect.fromLTWH(0, 0, point1.dx, height))
            ..style = PaintingStyle.fill);

      // Второй сегмент (фиолетовый)
      final path2 = Path();
      path2.moveTo(point1.dx, point1.dy);

      final t = (animationValue - 0.3) / 0.4;
      final currentPoint = Offset.lerp(point1, point2, t)!;
      path2.cubicTo(
          Offset.lerp(point1, cp3, t)!.dx,
          Offset.lerp(point1, cp3, t)!.dy,
          Offset.lerp(point1, cp4, t)!.dx,
          Offset.lerp(point1, cp4, t)!.dy,
          currentPoint.dx,
          currentPoint.dy);

      // Рисуем фиолетовую линию второго сегмента
      canvas.drawPath(
          path2,
          Paint()
            ..color = middleColor
            ..strokeWidth = 3.0
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round);

      // Заливка градиентом для второго сегмента
      final fillPath2 = Path.from(path2);
      fillPath2.lineTo(currentPoint.dx, height);
      fillPath2.lineTo(point1.dx, height);
      fillPath2.close();

      final fillGradient2 = LinearGradient(
        colors: [middleColor.withOpacity(0.3), Colors.transparent],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );

      canvas.drawPath(
          fillPath2,
          Paint()
            ..shader = fillGradient2.createShader(Rect.fromLTWH(
                point1.dx, 0, currentPoint.dx - point1.dx, height))
            ..style = PaintingStyle.fill);
    } else {
      // Первый сегмент полностью (синий)
      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, point1.dx, point1.dy);

      // Рисуем синюю линию первого сегмента
      canvas.drawPath(
          path,
          Paint()
            ..color = primaryColor
            ..strokeWidth = 3.0
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round);

      // Заливка градиентом для первого сегмента
      final fillPath1 = Path.from(path);
      fillPath1.lineTo(point1.dx, height);
      fillPath1.lineTo(0, height);
      fillPath1.close();

      final fillGradient1 = LinearGradient(
        colors: [primaryColor.withOpacity(0.3), Colors.transparent],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );

      canvas.drawPath(
          fillPath1,
          Paint()
            ..shader = fillGradient1
                .createShader(Rect.fromLTWH(0, 0, point1.dx, height))
            ..style = PaintingStyle.fill);

      // Второй сегмент полностью (фиолетовый)
      final path2 = Path();
      path2.moveTo(point1.dx, point1.dy);
      path2.cubicTo(cp3.dx, cp3.dy, cp4.dx, cp4.dy, point2.dx, point2.dy);

      // Рисуем фиолетовую линию второго сегмента
      canvas.drawPath(
          path2,
          Paint()
            ..color = middleColor
            ..strokeWidth = 3.0
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round);

      // Заливка градиентом для второго сегмента
      final fillPath2 = Path.from(path2);
      fillPath2.lineTo(point2.dx, height);
      fillPath2.lineTo(point1.dx, height);
      fillPath2.close();

      final fillGradient2 = LinearGradient(
        colors: [middleColor.withOpacity(0.3), Colors.transparent],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );

      canvas.drawPath(
          fillPath2,
          Paint()
            ..shader = fillGradient2.createShader(
                Rect.fromLTWH(point1.dx, 0, point2.dx - point1.dx, height))
            ..style = PaintingStyle.fill);

      // Третий сегмент (красный)
      final path3 = Path();
      path3.moveTo(point2.dx, point2.dy);

      final t = (animationValue - 0.7) / 0.3;
      final currentPoint = Offset.lerp(point2, endPoint, t)!;
      path3.cubicTo(
          Offset.lerp(point2, cp5, t)!.dx,
          Offset.lerp(point2, cp5, t)!.dy,
          Offset.lerp(point2, cp6, t)!.dx,
          Offset.lerp(point2, cp6, t)!.dy,
          currentPoint.dx,
          currentPoint.dy);

      // Рисуем красную линию третьего сегмента
      canvas.drawPath(
          path3,
          Paint()
            ..color = endColor
            ..strokeWidth = 3.0
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round);

      // Заливка градиентом для третьего сегмента
      final fillPath3 = Path.from(path3);
      fillPath3.lineTo(currentPoint.dx, height);
      fillPath3.lineTo(point2.dx, height);
      fillPath3.close();

      final fillGradient3 = LinearGradient(
        colors: [endColor.withOpacity(0.3), Colors.transparent],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );

      canvas.drawPath(
          fillPath3,
          Paint()
            ..shader = fillGradient3.createShader(Rect.fromLTWH(
                point2.dx, 0, currentPoint.dx - point2.dx, height))
            ..style = PaintingStyle.fill);
    }

    // Отрисовка вертикальных пунктирных линий
    if (animationValue > 0.3) {
      _drawDashedLine(canvas, Offset(point1.dx, height - 40),
          Offset(point1.dx, point1.dy), primaryColor);
    }

    if (animationValue > 0.7) {
      _drawDashedLine(canvas, Offset(point2.dx, height - 40),
          Offset(point2.dx, point2.dy), middleColor);
    }

    if (animationValue > 0.9) {
      _drawDashedLine(canvas, Offset(endPoint.dx, height - 40),
          Offset(endPoint.dx, endPoint.dy), endColor);
    }

    // Отрисовка временных меток внизу
    if (animationValue > 0.3) {
      _drawTimeLabel(
          canvas, Offset(point1.dx, height - 20), "3 Days", primaryColor);
    }

    if (animationValue > 0.7) {
      _drawTimeLabel(
          canvas, Offset(point2.dx, height - 20), "7 Days", middleColor);
    }

    if (animationValue > 0.9) {
      _drawTimeLabel(
          canvas, Offset(endPoint.dx, height - 20), "30 Days", endColor);
    }

    // Отрисовка точек и эмодзи
    if (pointAnimationValue > 0) {
      if (emoji1AnimationValue > 0 && animationValue > 0.3) {
        _drawPointWithEmoji(
            canvas, point1, primaryColor, "😍", emoji1AnimationValue, "");
      }

      if (emoji2AnimationValue > 0 && animationValue > 0.7) {
        _drawPointWithEmoji(
            canvas, point2, middleColor, "😉", emoji2AnimationValue, "");
      }

      if (emoji3AnimationValue > 0 && animationValue > 0.9) {
        _drawPointWithEmoji(
            canvas, endPoint, endColor, "😁", emoji3AnimationValue, "",
            isGoal: true);
      }
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Color color) {
    final paint = Paint()
      ..color = color.withOpacity(0.5)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    const dashWidth = 4.0;
    const dashSpace = 4.0;

    double startDistance = 0.0;
    final distance = (end - start).distance;
    final delta =
        Offset((end.dx - start.dx) / distance, (end.dy - start.dy) / distance);

    while (startDistance < distance) {
      final dashEnd = startDistance + dashWidth < distance
          ? startDistance + dashWidth
          : distance;

      path.moveTo(
        start.dx + delta.dx * startDistance,
        start.dy + delta.dy * startDistance,
      );

      path.lineTo(
        start.dx + delta.dx * dashEnd,
        start.dy + delta.dy * dashEnd,
      );

      startDistance = dashEnd + dashSpace;
    }

    canvas.drawPath(path, paint);
  }

  void _drawTimeLabel(
      Canvas canvas, Offset position, String label, Color color) {
    final textPainter = TextPainter(
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

    textPainter.layout();
    textPainter.paint(
        canvas, Offset(position.dx - textPainter.width / 2, position.dy));
  }

  void _drawPointWithEmoji(Canvas canvas, Offset position, Color color,
      String emoji, double animation, String label,
      {bool isGoal = false}) {
    // Расширяем эффекты анимации для эмодзи
    final yOffset = math.sin(animation * math.pi) * 15.0; // Прыжок точки
    final emojiYOffset = -math.sin(animation * math.pi * 1.5) *
        25; // Более выраженное движение по вертикали
    final emojiXOffset = math.cos(animation * math.pi * 2) *
        10; // Добавляем движение по горизонтали
    final rotation = math.sin(animation * math.pi) * 0.1; // Небольшое вращение
    final scale =
        1.0 + math.sin(animation * math.pi) * 0.2; // Пульсация размера

    final pointPos = Offset(position.dx, position.dy - yOffset);

    // Рисуем точку с внешним кругом
    canvas.drawCircle(
        pointPos,
        12,
        Paint()
          ..color = color.withOpacity(0.2)
          ..style = PaintingStyle.fill);

    canvas.drawCircle(
        pointPos,
        8,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill);

    canvas.drawCircle(
        pointPos,
        4,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill);

    // Рисуем эмодзи с анимацией
    final emojiText = emoji;
    final textPainter = TextPainter(
      text: TextSpan(
          text: emojiText,
          style: TextStyle(
            fontSize: 32 * scale, // Меняем размер с анимацией
            fontFamily: _getEmojiFont(true),
          )),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    
    textPainter.layout();

    // Позиционируем эмодзи с учетом всех эффектов анимации
    final emojiX = position.dx - textPainter.width / 2 + emojiXOffset;
    final emojiY = position.dy - 60 + emojiYOffset;

    // Сохраняем текущее состояние холста перед трансформациями
    canvas.save();

    // Перемещаем центр вращения в центр эмодзи
    canvas.translate(
        emojiX + textPainter.width / 2, emojiY + textPainter.height / 2);

    // Вращаем холст
    canvas.rotate(rotation);

    // Рисуем эмодзи, скорректировав позицию с учетом трансформаций
    textPainter.paint(
        canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));

    // Восстанавливаем холст
    canvas.restore();

    // Рисуем подпись если она есть
    if (label.isNotEmpty) {
      final labelPainter = TextPainter(
        text: TextSpan(
            text: label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            )),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );

      labelPainter.layout();
      labelPainter.paint(canvas,
          Offset(position.dx - labelPainter.width / 2, position.dy + 18));
    }

    // Рисуем метку "Goal" если это финальная точка, смещая влево
    if (isGoal) {
      // Перемещаем надпись Goal чуть левее, чтобы не выходила за экран
      final goalXPosition = position.dx - 30; // Смещаем влево от точки
      final goalYPosition = position.dy - 55;

      // Анимируем появление надписи "Goal"
      final goalOpacity = math.min(1.0, animation * 2); // Плавное появление
      final goalScale = 0.8 + animation * 0.4; // Увеличение с анимацией

      // Сохраняем состояние холста
      canvas.save();

      // Перемещаем центр трансформации
      canvas.translate(goalXPosition, goalYPosition);

      // Масштабируем надпись
      canvas.scale(goalScale);

      final goalRect = RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(0, 0), // Центр уже перемещен выше
              width: 60,
              height: 26),
          Radius.circular(13));

      canvas.drawRRect(
          goalRect, Paint()..color = color.withOpacity(goalOpacity));

      final goalText = TextPainter(
        text: TextSpan(
            text: "Goal",
            style: TextStyle(
              color: Colors.white.withOpacity(goalOpacity),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            )),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );

      goalText.layout();
      goalText.paint(canvas, Offset(-goalText.width / 2, -goalText.height / 2));

      // Восстанавливаем холст
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ProgressGraphPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.opacityValue != opacityValue ||
        oldDelegate.pointAnimationValue != pointAnimationValue ||
        oldDelegate.emoji1AnimationValue != emoji1AnimationValue ||
        oldDelegate.emoji2AnimationValue != emoji2AnimationValue ||
        oldDelegate.emoji3AnimationValue != emoji3AnimationValue;
  }
}

// Определяем подходящий шрифт для эмоджи в зависимости от платформы
String? _getEmojiFont(bool useAppleStyle) {
  if (!useAppleStyle) return null;
  
  try {
    if (Platform.isIOS || Platform.isMacOS) {
      // На iOS и macOS используем системный шрифт для эмоджи
      return null;
    } else {
      // На других платформах пытаемся использовать Apple Color Emoji
      return 'Apple Color Emoji';
    }
  } catch (e) {
    // Для веб и других платформ, где Platform недоступен
    return null;
  }
} 

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

class PlanGeneratingScreen extends StatefulWidget {
  final VoidCallback onNext;

  const PlanGeneratingScreen({
    Key? key,
    required this.onNext,
  }) : super(key: key);

  @override
  State<PlanGeneratingScreen> createState() => _PlanGeneratingScreenState();
}

class _PlanGeneratingScreenState extends State<PlanGeneratingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final List<bool> _completedSteps = [false, false, false, false, false];
  double _progressValue = 0.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    // Запускаем последовательную анимацию шагов
    _startStepsAnimation();
  }

  void _startStepsAnimation() async {
    for (int i = 0; i < _completedSteps.length; i++) {
      await Future.delayed(Duration(milliseconds: 800));
      if (mounted) {
        // Проверяем, что виджет все еще в дереве
        setState(() {
          _completedSteps[i] = true;
          _progressValue = (i + 1) / _completedSteps.length;
        });
      } else {
        return; // Если виджет удален, прекращаем выполнение
      }
    }

    // Завершаем анимацию и переходим к следующему экрану
    await Future.delayed(Duration(milliseconds: 1000));
    // НЕ останавливаем анимацию здесь, так как это может привести к ошибке,
    // если контроллер уже уничтожен в dispose()
    // Вместо этого проверяем, существует ли контроллер и не освобожден ли он
    if (mounted && _animationController.isAnimating) {
      // Безопасно вызываем переход к следующему экрану
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onNext?.call();
        }
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(height: 48),

        // Анимированные глаза
        SizedBox(
          height: 80,
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (_animationController.value * 0.1),
                child: Image.asset(
                  'assets/animations/Eyes.webp',
                  width: 100,
                  height: 60,
                ),
              );
            },
          ),
        ),

        SizedBox(height: 24),

        // Текст заголовка
        Text(
          'hold on, we are\ngenerating your plan',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),

        SizedBox(height: 48),

        // Список шагов
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStep(0, 'Creating full fitness profile'),
              SizedBox(height: 16),
              _buildStep(1, 'Analyzing activity'),
              SizedBox(height: 16),
              _buildStep(2, 'Analyzing injuries and conditions'),
              SizedBox(height: 16),
              _buildStep(3, 'Matching with target weight and body'),
              SizedBox(height: 16),
              _buildStep(4, 'Generating first workout'),
            ],
          ),
        ),

        Spacer(),

        // Индикатор прогресса
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _progressValue,
                  minHeight: 8,
                  backgroundColor: Colors.grey[800],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${(_progressValue * 100).toInt()}%',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 24),

        // Кнопка Next
        Padding(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed:
                  _completedSteps.every((step) => step) ? widget.onNext : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                disabledBackgroundColor: Colors.grey[800],
                disabledForegroundColor: Colors.grey[500],
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

  Widget _buildStep(int index, String text) {
    return Row(
      children: [
        // Индикатор шага
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1),
            color: _completedSteps[index] ? Colors.white : Colors.transparent,
          ),
          child: _completedSteps[index]
              ? Icon(Icons.check, color: Colors.black, size: 14)
              : null,
        ),
        SizedBox(width: 16),
        // Текст шага
        Text(
          text,
          style: GoogleFonts.inter(
            color: _completedSteps[index]
                ? Colors.white
                : Colors.white.withOpacity(0.6),
            fontSize: 14,
            fontWeight:
                _completedSteps[index] ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

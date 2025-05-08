import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TargetWaistSizeScreen extends StatefulWidget {
  final Function(double) onSelect;
  final double? currentWaistSize;
  final bool isMetric;
  final Function(bool) onUnitChanged;

  const TargetWaistSizeScreen({
    Key? key,
    required this.onSelect,
    this.currentWaistSize,
    required this.isMetric,
    required this.onUnitChanged,
  }) : super(key: key);

  @override
  State<TargetWaistSizeScreen> createState() => _TargetWaistSizeScreenState();
}

class _TargetWaistSizeScreenState extends State<TargetWaistSizeScreen> {
  late double _targetWaistSize;
  late bool _isMetric;

  @override
  void initState() {
    super.initState();
    _isMetric = widget.isMetric;
    // Инициализируем целевой размер талии как 90% от текущего размера
    if (widget.currentWaistSize != null) {
      _targetWaistSize = widget.currentWaistSize! * 0.9;
    } else {
      _targetWaistSize = _isMetric ? 72.0 : 28.3; // 72 cm ~ 28.3 inches
    }
  }

  double get _waistSizeCm =>
      _isMetric ? _targetWaistSize : _targetWaistSize * 2.54;
  double get _waistSizeInches =>
      _isMetric ? _targetWaistSize / 2.54 : _targetWaistSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Заголовок
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'What is your target waist size?',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        SizedBox(height: 12),

        // Подсказка
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'A healthy waist circumference differs by gender. For men, aim for less than 94 cm (37 inches). For women, aim for less than 80 cm (31.5 inches).',
            style: GoogleFonts.inter(
              color: Colors.grey[400],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        SizedBox(height: 32),

        // Переключатель единиц измерения
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildUnitToggle('cm', true),
            SizedBox(width: 16),
            _buildUnitToggle('inches', false),
          ],
        ),

        SizedBox(height: 48),

        // Отображение текущего значения
        Center(
          child: Text(
            _isMetric
                ? '${_waistSizeCm.round()} cm'
                : '${_waistSizeInches.round()} inches',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        SizedBox(height: 24),

        // Слайдер для выбора значения
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 8,
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.white24,
              thumbColor: Colors.white,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 12),
              overlayColor: Colors.white.withOpacity(0.2),
              overlayShape: RoundSliderOverlayShape(overlayRadius: 24),
            ),
            child: Slider(
              value: _targetWaistSize,
              min: _isMetric ? 40.0 : 16.0,
              max: _isMetric ? 180.0 : 71.0,
              onChanged: (value) {
                setState(() {
                  _targetWaistSize = value;
                });
              },
            ),
          ),
        ),

        Spacer(),

        // Если есть текущий размер, показываем разницу
        if (widget.currentWaistSize != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    'You need to reduce',
                    style: GoogleFonts.inter(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    _isMetric
                        ? '${(widget.currentWaistSize! - _waistSizeCm).toStringAsFixed(1)} cm'
                        : '${((widget.currentWaistSize! - _waistSizeInches) / 2.54).toStringAsFixed(1)} inches',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

        SizedBox(height: 24),

        // Кнопка Next
        Padding(
          padding: const EdgeInsets.all(24),
          child: ElevatedButton(
            onPressed: () => widget.onSelect(
                _isMetric ? _targetWaistSize : _targetWaistSize * 2.54),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Next',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUnitToggle(String text, bool isMetric) {
    final bool isSelected = this._isMetric == isMetric;

    return GestureDetector(
      onTap: () {
        setState(() {
          if (this._isMetric != isMetric) {
            this._isMetric = isMetric;
            // Конвертируем значение при смене единиц измерения
            if (isMetric) {
              // Из дюймов в сантиметры
              _targetWaistSize = _waistSizeCm;
            } else {
              // Из сантиметров в дюймы
              _targetWaistSize = _waistSizeInches;
            }
            // Обновляем глобальную настройку
            widget.onUnitChanged(isMetric);
          }
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white24,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: GoogleFonts.inter(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

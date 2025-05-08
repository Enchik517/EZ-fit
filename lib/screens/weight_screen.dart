import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WeightScreen extends StatefulWidget {
  final Function(double) onSelect;
  final double height;
  final bool isMetric; // добавляем параметр isMetric
  final Function(bool)
      onUnitChanged; // добавляем callback для обновления настройки

  const WeightScreen({
    Key? key,
    required this.onSelect,
    required this.height,
    required this.isMetric,
    required this.onUnitChanged,
  }) : super(key: key);

  @override
  State<WeightScreen> createState() => _WeightScreenState();
}

class _WeightScreenState extends State<WeightScreen> {
  late bool _isMetric; // true for kg, false for lbs
  double _selectedWeight = 70.0; // Initial value (default in kg)

  @override
  void initState() {
    super.initState();
    _isMetric = widget.isMetric;
    // Set initial weight value depending on selected units
    _selectedWeight = _isMetric ? 70.0 : 154.0; // 70 kg ~ 154 lbs
  }

  double get _weightInKg =>
      _isMetric ? _selectedWeight : _selectedWeight * 0.453592;
  double get _weightInLbs =>
      _isMetric ? _selectedWeight / 0.453592 : _selectedWeight;

  double get _minWeight => _isMetric ? 30.0 : 66.0; // 30 kg = ~66 lbs
  double get _maxWeight => _isMetric ? 200.0 : 440.0; // 200 kg = ~440 lbs

  double get _bmi {
    double weightInKg = _weightInKg;
    double heightInMeters = widget.height / 100;
    return (weightInKg / (heightInMeters * heightInMeters)).roundToDouble();
  }

  String get _bmiMessage {
    if (_bmi < 18.5) {
      return 'You may need to gain some weight';
    } else if (_bmi < 25) {
      return 'You\'ve got a great figure, keep it up!';
    } else if (_bmi < 30) {
      return 'You only need a bit more sweat';
    } else {
      return 'Let\'s work on getting you in better shape';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 32),

        // Title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'What is your weight?',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        SizedBox(height: 24),

        // Unit Toggle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            height: 36,
            decoration: BoxDecoration(
              color: Color(0xFF2C2C2E),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildToggleButton(
                    text: 'Pounds',
                    isSelected: !_isMetric,
                    onTap: () {
                      if (_isMetric) {
                        setState(() {
                          _isMetric = false;
                          _selectedWeight = _weightInLbs;
                          widget.onUnitChanged(false);
                        });
                      }
                    },
                  ),
                ),
                Expanded(
                  child: _buildToggleButton(
                    text: 'Kilograms',
                    isSelected: _isMetric,
                    onTap: () {
                      if (!_isMetric) {
                        setState(() {
                          _isMetric = true;
                          _selectedWeight = _weightInKg;
                          widget.onUnitChanged(true);
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: 32),

        // Weight Slider Area
        Container(
          margin: EdgeInsets.symmetric(horizontal: 24),
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                '${_selectedWeight.toStringAsFixed(0)} ${_isMetric ? 'kg' : 'lbs'}',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 24),
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 2,
                  activeTrackColor: Colors.white,
                  inactiveTrackColor: Colors.white.withOpacity(0.3),
                  thumbColor: Colors.white,
                  overlayColor: Colors.white.withOpacity(0.1),
                ),
                child: Slider(
                  value: _selectedWeight,
                  min: _minWeight,
                  max: _maxWeight,
                  onChanged: _updateWeight,
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 24),

        // BMI Info
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Your BMI:',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    '$_bmi',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Text(
                _bmiMessage,
                style: GoogleFonts.inter(
                  color: Colors.grey[400],
                  fontSize: 14,
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
              onPressed: () {
                widget.onSelect(
                    _isMetric ? _selectedWeight : _selectedWeight * 0.453592);
              },
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

  Widget _buildToggleButton({
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        margin: EdgeInsets.all(2),
        child: Text(
          text,
          style: GoogleFonts.inter(
            color: isSelected ? Colors.black : Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  void _updateWeight(double value) {
    setState(() {
      _selectedWeight = value;
    });
  }
}

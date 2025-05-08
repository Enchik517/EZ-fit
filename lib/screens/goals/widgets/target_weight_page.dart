import 'package:flutter/material.dart';

class TargetWeightPage extends StatefulWidget {
  final VoidCallback onNext;

  const TargetWeightPage({Key? key, required this.onNext}) : super(key: key);

  @override
  _TargetWeightPageState createState() => _TargetWeightPageState();
}

class _TargetWeightPageState extends State<TargetWeightPage> {
  bool _isKg = true;
  double _targetWeightKg = 65;
  String _selectedRate = '0.5';

  final List<Map<String, String>> _rates = [
    {'value': '0.25', 'label': '0.25 kg per week', 'description': 'Slow & steady'},
    {'value': '0.5', 'label': '0.5 kg per week', 'description': 'Recommended'},
    {'value': '1.0', 'label': '1.0 kg per week', 'description': 'Aggressive'},
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'What is your target weight?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildUnitToggle('kg', true),
              SizedBox(width: 16),
              _buildUnitToggle('lbs', false),
            ],
          ),
          SizedBox(height: 48),
          Container(
            height: 100,
            child: SliderTheme(
              data: SliderThemeData(
                activeTrackColor: Colors.white,
                inactiveTrackColor: Colors.white.withOpacity(0.3),
                thumbColor: Colors.white,
                overlayColor: Colors.white.withOpacity(0.1),
              ),
              child: Slider(
                value: _targetWeightKg,
                min: 40,
                max: 150,
                divisions: 110,
                label: _isKg 
                    ? '${_targetWeightKg.round()} kg'
                    : '${(_targetWeightKg * 2.20462).round()} lbs',
                onChanged: (value) {
                  setState(() => _targetWeightKg = value);
                },
              ),
            ),
          ),
          Text(
            _isKg 
                ? '${_targetWeightKg.round()} kg'
                : '${(_targetWeightKg * 2.20462).round()} lbs',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32),
          Text(
            'What is your target goal rate?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: _rates.length,
              separatorBuilder: (_, __) => SizedBox(height: 12),
              itemBuilder: (context, index) {
                final rate = _rates[index];
                final isSelected = _selectedRate == rate['value'];
                return _buildRateOption(
                  rate['label']!,
                  rate['description']!,
                  isSelected,
                  () => setState(() => _selectedRate = rate['value']!),
                );
              },
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

  Widget _buildUnitToggle(String text, bool isKg) {
    return GestureDetector(
      onTap: () => setState(() => _isKg = isKg),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: _isKg == isKg 
              ? Colors.white 
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: _isKg == isKg ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildRateOption(
    String label,
    String description,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      color: isSelected ? Colors.black54 : Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Colors.black,
              ),
          ],
        ),
      ),
    );
  }
} 
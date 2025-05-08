import 'package:flutter/material.dart';

class MainGoalPage extends StatefulWidget {
  final VoidCallback onNext;

  const MainGoalPage({Key? key, required this.onNext}) : super(key: key);

  @override
  _MainGoalPageState createState() => _MainGoalPageState();
}

class _MainGoalPageState extends State<MainGoalPage> {
  String? _selectedGoal;

  final List<Map<String, String>> _goals = [
    {
      'value': 'lose_weight',
      'label': 'Lose Weight',
      'description': 'Reduce body fat and get leaner'
    },
    {
      'value': 'gain_muscle',
      'label': 'Gain Muscle',
      'description': 'Build strength and muscle mass'
    },
    {
      'value': 'tone_up',
      'label': 'Look More Toned',
      'description': 'Improve muscle definition and body shape'
    },
    {
      'value': 'maintain',
      'label': 'Stay in Shape',
      'description': 'Maintain current fitness level'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'What is your main goal?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 48),
          Expanded(
            child: ListView.separated(
              itemCount: _goals.length,
              separatorBuilder: (_, __) => SizedBox(height: 16),
              itemBuilder: (context, index) {
                final goal = _goals[index];
                final isSelected = _selectedGoal == goal['value'];
                
                return _buildGoalOption(
                  goal['label']!,
                  goal['description']!,
                  isSelected,
                  () => setState(() => _selectedGoal = goal['value']),
                );
              },
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: _selectedGoal != null ? widget.onNext : null,
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

  Widget _buildGoalOption(
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
                      fontSize: 18,
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
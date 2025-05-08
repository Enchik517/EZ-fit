import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/workout_provider.dart';
import '../models/workout.dart';
import '../models/user_profile.dart';

class GoalsScreen extends StatefulWidget {
  final Function(List<String>)? onSave;
  
  const GoalsScreen({Key? key, this.onSave}) : super(key: key);

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final List<String> _availableGoals = [
    'Lose Weight',
    'Build Muscle',
    'Improve Strength',
    'Increase Endurance', 
    'Enhance Flexibility',
    'Better Balance',
    'Reduce Stress',
    'Prepare for Event',
    'Maintain Health',
    'Rehabilitation',
  ];

  final List<String> _selectedGoals = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Select Your Goals',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'What are your fitness goals?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Select all that apply. This helps us personalize your workout experience.',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
              ),
            ),
          ),
          SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: _availableGoals.length,
              itemBuilder: (context, index) {
                final goal = _availableGoals[index];
                final isSelected = _selectedGoals.contains(goal);
                
                return _buildGoalTile(goal, isSelected);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _selectedGoals.isNotEmpty ? _saveGoals : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  disabledBackgroundColor: Colors.blue.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Continue',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalTile(String goal, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedGoals.remove(goal);
            } else {
              _selectedGoals.add(goal);
            }
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.withOpacity(0.2) : Color(0xFF252527),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.blue : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  goal,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              if (isSelected)
                Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveGoals() {
    // Здесь можно сохранить выбранные цели в профиле пользователя
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_selectedGoals.length} goals selected')),
    );
    
    // Вызываем коллбек, если он предоставлен
    if (widget.onSave != null) {
      widget.onSave!(_selectedGoals);
    } else {
      // После сохранения возвращаемся на предыдущий экран
      Navigator.pop(context);
    }
  }
} 
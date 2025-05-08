import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/survey_provider.dart';

class WorkoutFrequencyPage extends StatelessWidget {
  final VoidCallback onNext;

  const WorkoutFrequencyPage({Key? key, required this.onNext}) : super(key: key);

  final List<Map<String, String>> _frequencies = const [
    {'value': '0', 'label': '0 sessions/week', 'description': 'Complete beginner'},
    {'value': '1-3', 'label': '1-3 sessions/week', 'description': 'Occasional workouts'},
    {'value': '4-6', 'label': '4-6 sessions/week', 'description': 'Regular training'},
    {'value': '7+', 'label': '7+ sessions/week', 'description': 'Advanced athlete'},
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SurveyProvider>();
    final selectedFrequency = provider.data.workoutFrequency;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF2A2A2A),
            Color(0xFF1C1C1C),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'How often do you workout?',
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
                itemCount: _frequencies.length,
                separatorBuilder: (_, __) => SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final frequency = _frequencies[index];
                  final isSelected = selectedFrequency == frequency['value'];
                  
                  return _buildFrequencyOption(
                    context,
                    frequency['label']!,
                    frequency['description']!,
                    isSelected,
                    () => context.read<SurveyProvider>()
                        .updateWorkoutFrequency(frequency['value']!),
                  );
                },
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: selectedFrequency != null ? onNext : null,
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
      ),
    );
  }

  Widget _buildFrequencyOption(
    BuildContext context,
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
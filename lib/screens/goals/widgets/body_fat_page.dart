import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/survey_provider.dart';

class BodyFatPage extends StatelessWidget {
  final VoidCallback onNext;

  const BodyFatPage({Key? key, required this.onNext}) : super(key: key);

  final List<Map<String, dynamic>> _ranges = const [
    {'range': '10-15%', 'description': 'Athletic'},
    {'range': '16-20%', 'description': 'Fit'},
    {'range': '21-25%', 'description': 'Average'},
    {'range': '26-30%', 'description': 'Above Average'},
    {'range': '31%+', 'description': 'High'},
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SurveyProvider>();
    final selectedRange = provider.data.bodyFatRange;

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
              'What is your body fat level?',
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
                itemCount: _ranges.length,
                separatorBuilder: (_, __) => SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final range = _ranges[index];
                  final isSelected = selectedRange == range['range'];

                  return _buildRangeOption(
                    context,
                    range['range'],
                    range['description'],
                    isSelected,
                  );
                },
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: selectedRange != null ? onNext : null,
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

  Widget _buildRangeOption(
    BuildContext context,
    String range,
    String description,
    bool isSelected,
  ) {
    return InkWell(
      onTap: () => context.read<SurveyProvider>().updateBodyFatRange(range),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  range,
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
            Spacer(),
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

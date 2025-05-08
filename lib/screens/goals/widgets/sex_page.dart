import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/survey_provider.dart';

class SexPage extends StatelessWidget {
  final VoidCallback onNext;

  const SexPage({Key? key, required this.onNext}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SurveyProvider>();
    final selectedSex = provider.data.sex;

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
              'What is your sex?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 48),
            _buildOption(context, 'Male', '♂', selectedSex == 'Male'),
            SizedBox(height: 16),
            _buildOption(context, 'Female', '♀', selectedSex == 'Female'),
            Spacer(),
            ElevatedButton(
              onPressed: selectedSex != null ? onNext : null,
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

  Widget _buildOption(BuildContext context, String text, String icon, bool isSelected) {
    return InkWell(
      onTap: () => context.read<SurveyProvider>().updateSex(text),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(
              icon,
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(width: 16),
            Text(
              text,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
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
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../../providers/survey_provider.dart';

class BirthDatePage extends StatelessWidget {
  final VoidCallback onNext;

  const BirthDatePage({Key? key, required this.onNext}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SurveyProvider>();
    final selectedDate = provider.data.birthDate ?? 
        DateTime.now().subtract(Duration(days: 365 * 25));

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
              'When were you born?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 48),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: selectedDate,
                maximumDate: DateTime.now().subtract(Duration(days: 365 * 13)),
                minimumDate: DateTime.now().subtract(Duration(days: 365 * 100)),
                onDateTimeChanged: (DateTime newDate) {
                  context.read<SurveyProvider>().updateBirthDate(newDate);
                },
              ),
            ),
            Spacer(),
            ElevatedButton(
              onPressed: selectedDate != null ? onNext : null,
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
} 
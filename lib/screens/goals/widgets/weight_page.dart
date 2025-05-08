import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/survey_provider.dart';

class WeightPage extends StatelessWidget {
  final VoidCallback onNext;

  const WeightPage({Key? key, required this.onNext}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SurveyProvider>();
    final weightKg = provider.data.weightKg ?? 70.0;
    final isKg = true; // Можно добавить в provider если нужно сохранять выбранные единицы

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
              'What is your weight?',
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
                _buildUnitToggle(context, 'kg', true),
                SizedBox(width: 16),
                _buildUnitToggle(context, 'lbs', false),
              ],
            ),
            SizedBox(height: 48),
            Container(
              height: 200,
              child: SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: Colors.white,
                  inactiveTrackColor: Colors.white.withOpacity(0.3),
                  thumbColor: Colors.white,
                  overlayColor: Colors.white.withOpacity(0.1),
                ),
                child: Slider(
                  value: weightKg,
                  min: 40,
                  max: 150,
                  divisions: 110,
                  label: isKg 
                      ? '${weightKg.round()} kg'
                      : '${(weightKg * 2.20462).round()} lbs',
                  onChanged: (value) {
                    context.read<SurveyProvider>().updateWeightKg(value);
                  },
                ),
              ),
            ),
            Text(
              isKg 
                  ? '${weightKg.round()} kg'
                  : '${(weightKg * 2.20462).round()} lbs',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            Spacer(),
            ElevatedButton(
              onPressed: onNext,
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

  Widget _buildUnitToggle(BuildContext context, String text, bool isKg) {
    return GestureDetector(
      onTap: () {
        // TODO: Добавить переключение единиц измерения если нужно
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: isKg == (text == 'kg')
              ? Colors.white 
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isKg == (text == 'kg') ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
} 
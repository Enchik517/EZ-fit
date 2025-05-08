import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/survey_provider.dart';

class HeightPage extends StatelessWidget {
  final VoidCallback onNext;

  const HeightPage({Key? key, required this.onNext}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SurveyProvider>();
    final heightCm = provider.data.heightCm ?? 170.0;
    final isCm = true; // Можно добавить в provider если нужно сохранять выбранные единицы

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
              'What is your height?',
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
                _buildUnitToggle(context, 'cm', true),
                SizedBox(width: 16),
                _buildUnitToggle(context, 'ft', false),
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
                  value: heightCm,
                  min: 120,
                  max: 220,
                  divisions: 100,
                  label: isCm 
                      ? '${heightCm.round()} cm'
                      : '${(heightCm / 30.48).toStringAsFixed(1)} ft',
                  onChanged: (value) {
                    context.read<SurveyProvider>().updateHeightCm(value);
                  },
                ),
              ),
            ),
            Text(
              isCm 
                  ? '${heightCm.round()} cm'
                  : '${(heightCm / 30.48).toStringAsFixed(1)} ft',
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

  Widget _buildUnitToggle(BuildContext context, String text, bool isCm) {
    return GestureDetector(
      onTap: () {
        // TODO: Добавить переключение единиц измерения если нужно
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: isCm == (text == 'cm')
              ? Colors.white 
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isCm == (text == 'cm') ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
} 
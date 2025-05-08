import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum BodyFatLevel {
  level1, // 10-13%
  level2, // 14-17%
  level3, // 18-23%
  level4, // 24-28%
  level5, // 29-33%
  level6, // 34-37%
  level7, // 38-42%
  level8, // 43-49%
  level9, // 50%+
}

class BodyFatScreen extends StatefulWidget {
  final Function(BodyFatLevel) onSelect;
  final bool isMale;

  const BodyFatScreen({
    Key? key,
    required this.onSelect,
    this.isMale = true,
  }) : super(key: key);

  @override
  State<BodyFatScreen> createState() => _BodyFatScreenState();
}

class _BodyFatScreenState extends State<BodyFatScreen> {
  BodyFatLevel? _selectedLevel;

  String _getLevelText(BodyFatLevel level) {
    switch (level) {
      case BodyFatLevel.level1:
        return '10-13%';
      case BodyFatLevel.level2:
        return '14-17%';
      case BodyFatLevel.level3:
        return '18-23%';
      case BodyFatLevel.level4:
        return '24-28%';
      case BodyFatLevel.level5:
        return '29-33%';
      case BodyFatLevel.level6:
        return '34-37%';
      case BodyFatLevel.level7:
        return '38-42%';
      case BodyFatLevel.level8:
        return '43-49%';
      case BodyFatLevel.level9:
        return '50%+';
    }
  }

  String _getImagePath(BodyFatLevel level) {
    // Всегда используем женские изображения, так как мужские могут отсутствовать
    switch (level) {
      case BodyFatLevel.level1:
        return 'assets/images/bodyfat_reference_corrected/01_female_10-13_bf.png';
      case BodyFatLevel.level2:
        return 'assets/images/bodyfat_reference_corrected/02_female_14-17_bf.png';
      case BodyFatLevel.level3:
        return 'assets/images/bodyfat_reference_corrected/03_female_18-23_bf.png';
      case BodyFatLevel.level4:
        return 'assets/images/bodyfat_reference_corrected/04_female_24-28_bf.png';
      case BodyFatLevel.level5:
        return 'assets/images/bodyfat_reference_corrected/04_female_24-28_bf.png'; // Используем близкий аналог
      case BodyFatLevel.level6:
        return 'assets/images/bodyfat_reference_corrected/08_female_34-37_bf.png';
      case BodyFatLevel.level7:
        return 'assets/images/bodyfat_reference_corrected/06_female_38-42_bf.png';
      case BodyFatLevel.level8:
        return 'assets/images/bodyfat_reference_corrected/07_female_43-46_bf.png';
      case BodyFatLevel.level9:
        return 'assets/images/bodyfat_reference_corrected/09_female_47-50_bf.png';
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What is your body fat level?',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Don\'t worry about being too precise. A visual assessment is sufficient.',
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 24),

        // Body Fat Grid
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.count(
              crossAxisCount: 3,
              childAspectRatio: 0.75,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: BodyFatLevel.values
                  .map((level) => _buildBodyFatCard(level))
                  .toList(),
            ),
          ),
        ),

        // Next button
        Padding(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _selectedLevel != null
                  ? () => widget.onSelect(_selectedLevel!)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                disabledBackgroundColor: Color(0xFF2C2C2E),
                disabledForegroundColor: Colors.grey,
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

  Widget _buildBodyFatCard(BodyFatLevel level) {
    final isSelected = _selectedLevel == level;
    final percentText = _getLevelText(level);
    final imagePath = _getImagePath(level);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedLevel = level;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Body image
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      print('Error loading image $imagePath: $error');
                      // Показываем иконку в случае ошибки загрузки изображения
                      return Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withOpacity(0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.person_outline,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            // Percentage text
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                percentText,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

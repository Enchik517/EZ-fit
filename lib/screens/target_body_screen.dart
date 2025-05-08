import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TargetBodyScreen extends StatefulWidget {
  final Function(String) onSelect;
  final bool isMale;

  const TargetBodyScreen({
    Key? key,
    required this.onSelect,
    required this.isMale,
  }) : super(key: key);

  @override
  State<TargetBodyScreen> createState() => _TargetBodyScreenState();
}

class _TargetBodyScreenState extends State<TargetBodyScreen> {
  String? _selectedBodyFatRange;

  final List<String> _bodyFatRanges = [
    '0-12%',
    '12-17%',
    '18-22%',
    '24-26%',
    '26-32%',
    '32-37%',
    '38-42%',
    '42-46%',
    '50%+'
  ];

  String _getImagePath(int index) {
    // Используем женские изображения с правильными именами файлов
    switch (index) {
      case 0:
        return 'assets/images/bodyfat_reference_corrected/01_female_10-13_bf.png';
      case 1:
        return 'assets/images/bodyfat_reference_corrected/02_female_14-17_bf.png';
      case 2:
        return 'assets/images/bodyfat_reference_corrected/03_female_18-23_bf.png';
      case 3:
        return 'assets/images/bodyfat_reference_corrected/04_female_24-28_bf.png';
      case 4:
        return 'assets/images/bodyfat_reference_corrected/04_female_24-28_bf.png'; // Используем повторно для близкого диапазона
      case 5:
        return 'assets/images/bodyfat_reference_corrected/08_female_34-37_bf.png';
      case 6:
        return 'assets/images/bodyfat_reference_corrected/06_female_38-42_bf.png';
      case 7:
        return 'assets/images/bodyfat_reference_corrected/07_female_43-46_bf.png';
      case 8:
        return 'assets/images/bodyfat_reference_corrected/09_female_47-50_bf.png';
      default:
        return 'assets/images/bodyfat_reference_corrected/01_female_10-13_bf.png';
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
          child: Text(
            'What is your target body?',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        SizedBox(height: 8),

        // Subtitle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Don\'t worry about being too precise. A visual assessment is sufficient.',
            style: GoogleFonts.inter(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
        ),

        SizedBox(height: 32),

        // Grid of body types
        Expanded(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: GridView.builder(
              padding: EdgeInsets.all(12),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.8,
              ),
              itemCount: 9,
              itemBuilder: (context, index) {
                return _buildBodyTypeItem(index);
              },
            ),
          ),
        ),

        SizedBox(height: 24),

        // Next button
        Padding(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _selectedBodyFatRange != null
                  ? () => widget.onSelect(_selectedBodyFatRange!)
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

  Widget _buildBodyTypeItem(int index) {
    final range = _bodyFatRanges[index];
    final isSelected = _selectedBodyFatRange == range;
    final imagePath = _getImagePath(index);

    return GestureDetector(
      onTap: () => setState(() => _selectedBodyFatRange = range),
      child: Container(
        decoration: BoxDecoration(
          color: Color(0xFF2C2C2E),
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
        ),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    print('Error loading image $imagePath: $error');
                    // Показываем иконку в случае ошибки загрузки изображения
                    return Container(
                      color: Colors.black12,
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
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.1) : null,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
              ),
              child: Text(
                range,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

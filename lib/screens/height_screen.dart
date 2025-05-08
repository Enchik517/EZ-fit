import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HeightScreen extends StatefulWidget {
  final Function(double) onSelect;

  const HeightScreen({Key? key, required this.onSelect}) : super(key: key);

  @override
  State<HeightScreen> createState() => _HeightScreenState();
}

class _HeightScreenState extends State<HeightScreen> {
  bool _isImperial = true; // true для feet/inches, false для сантиметров
  int? selectedHeight;

  final List<String> imperialHeights = List.generate(
    48, // 4 feet to 8 feet
    (i) {
      int totalInches = 48 + i; // Starting from 4 feet (48 inches)
      int feet = totalInches ~/ 12;
      int inches = totalInches % 12;
      return '$feet ft ${inches} in';
    }
  );

  final List<String> metricHeights = List.generate(
    121, // 120cm to 240cm
    (i) => '${120 + i} cm',
  );

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
            'What is your height?',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        SizedBox(height: 24),

        // Unit Toggle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            height: 36,
            decoration: BoxDecoration(
              color: Color(0xFF2C2C2E),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildToggleButton(
                    text: 'Feet and inches',
                    isSelected: _isImperial,
                    onTap: () => setState(() => _isImperial = true),
                  ),
                ),
                Expanded(
                  child: _buildToggleButton(
                    text: 'Centimeters',
                    isSelected: !_isImperial,
                    onTap: () => setState(() => _isImperial = false),
                  ),
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: 32),

        // Height Picker
        Container(
          margin: EdgeInsets.symmetric(horizontal: 24),
          height: 200,
          decoration: BoxDecoration(
            color: Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListWheelScrollView.useDelegate(
            itemExtent: 40,
            diameterRatio: 100,
            physics: FixedExtentScrollPhysics(),
            onSelectedItemChanged: (index) {
              setState(() => selectedHeight = index);
            },
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: _isImperial ? imperialHeights.length : metricHeights.length,
              builder: (context, index) {
                final isSelected = selectedHeight == index;
                final text = _isImperial ? imperialHeights[index] : metricHeights[index];
                return Center(
                  child: Text(
                    text,
                    style: GoogleFonts.inter(
                      color: isSelected ? Colors.white : Colors.white.withOpacity(0.3),
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        Spacer(),

        // Next button
        Padding(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: selectedHeight != null
                  ? () {
                      double heightInCm;
                      if (_isImperial) {
                        // Convert feet and inches to centimeters
                        int totalInches = 48 + (selectedHeight ?? 0);
                        heightInCm = totalInches * 2.54;
                      } else {
                        heightInCm = 120 + (selectedHeight ?? 0).toDouble();
                      }
                      widget.onSelect(heightInCm);
                    }
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

  Widget _buildToggleButton({
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        margin: EdgeInsets.all(2),
        child: Text(
          text,
          style: GoogleFonts.inter(
            color: isSelected ? Colors.black : Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
} 
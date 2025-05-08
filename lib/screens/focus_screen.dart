import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FocusScreen extends StatefulWidget {
  final Function(List<String>) onSelect;

  const FocusScreen({
    Key? key,
    required this.onSelect,
  }) : super(key: key);

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  final Map<String, bool> _selectedFocus = {
    'Glutes': false,
    'Abs': false,
    'Biceps': false,
    'Triceps': false,
  };

  final Map<String, String> _focusEmojis = {
    'Glutes': '🍑',
    'Abs': '💪',
    'Biceps': '💪',
    'Triceps': '💪',
  };

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
            'What is your focus?',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        SizedBox(height: 32),

        // Focus options
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _selectedFocus.keys.map((focus) => _buildFocusChip(focus)).toList(),
        ),

        Spacer(),

        // Next button
        Padding(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _selectedFocus.values.any((selected) => selected)
                ? () => widget.onSelect(
                    _selectedFocus.entries
                        .where((entry) => entry.value)
                        .map((entry) => entry.key)
                        .toList(),
                  )
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

  Widget _buildFocusChip(String focus) {
    final isSelected = _selectedFocus[focus] ?? false;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFocus[focus] = !isSelected;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.1) : Color(0xFF2C2C2E),
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(color: Colors.white, width: 1)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              focus,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            SizedBox(width: 4),
            Text(
              _focusEmojis[focus] ?? '',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
} 
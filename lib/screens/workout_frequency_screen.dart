import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum WorkoutFrequency {
  none,
  low,
  medium,
  high
}

class WorkoutFrequencyScreen extends StatefulWidget {
  final Function(WorkoutFrequency) onSelect;

  const WorkoutFrequencyScreen({
    Key? key,
    required this.onSelect,
  }) : super(key: key);

  @override
  State<WorkoutFrequencyScreen> createState() => _WorkoutFrequencyScreenState();
}

class _WorkoutFrequencyScreenState extends State<WorkoutFrequencyScreen> {
  WorkoutFrequency? _selectedFrequency;

  String _getFrequencyText(WorkoutFrequency frequency) {
    switch (frequency) {
      case WorkoutFrequency.none:
        return '0 sessions / week';
      case WorkoutFrequency.low:
        return '1-3 sessions / week';
      case WorkoutFrequency.medium:
        return '4-6 sessions / week';
      case WorkoutFrequency.high:
        return '7+ sessions / week';
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
            'How often do you workout?',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        SizedBox(height: 32),

        // Options
        ...WorkoutFrequency.values.map((frequency) => 
          _buildOptionCard(frequency)
        ).toList(),

        Spacer(),

        // Next button
        Padding(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _selectedFrequency != null
                  ? () => widget.onSelect(_selectedFrequency!)
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

  Widget _buildOptionCard(WorkoutFrequency frequency) {
    final isSelected = _selectedFrequency == frequency;
    final frequencyText = _getFrequencyText(frequency);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedFrequency = frequency;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.white : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  frequencyText,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ),
              Container(
                height: 24,
                width: 24,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Color(0xFF2C2C2E),
                  shape: BoxShape.circle,
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        color: Colors.black,
                        size: 16,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 
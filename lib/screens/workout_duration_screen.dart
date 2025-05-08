import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum WorkoutDuration {
  short,
  medium,
  long,
  extraLong,
  custom
}

class WorkoutDurationScreen extends StatefulWidget {
  final Function(WorkoutDuration) onSelect;

  const WorkoutDurationScreen({
    Key? key,
    required this.onSelect,
  }) : super(key: key);

  @override
  State<WorkoutDurationScreen> createState() => _WorkoutDurationScreenState();
}

class _WorkoutDurationScreenState extends State<WorkoutDurationScreen> {
  WorkoutDuration? _selectedDuration;

  String _getDurationText(WorkoutDuration duration) {
    switch (duration) {
      case WorkoutDuration.short:
        return '30 minutes';
      case WorkoutDuration.medium:
        return '45 minutes';
      case WorkoutDuration.long:
        return '60 minutes';
      case WorkoutDuration.extraLong:
        return '90 minutes';
      case WorkoutDuration.custom:
        return '120 minutes';
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
            'How long do you workout?',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        SizedBox(height: 32),

        // Options
        ...WorkoutDuration.values.map((duration) => 
          _buildOptionCard(duration)
        ).toList(),

        Spacer(),

        // Next button
        Padding(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _selectedDuration != null
                  ? () => widget.onSelect(_selectedDuration!)
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

  Widget _buildOptionCard(WorkoutDuration duration) {
    final isSelected = _selectedDuration == duration;
    final durationText = _getDurationText(duration);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedDuration = duration;
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
                  durationText,
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
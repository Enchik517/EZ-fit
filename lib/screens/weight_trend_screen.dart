import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum WeightTrend {
  losing,
  gaining,
  stable,
  notSure,
}

class WeightTrendScreen extends StatefulWidget {
  final Function(WeightTrend) onSelect;

  const WeightTrendScreen({
    Key? key,
    required this.onSelect,
  }) : super(key: key);

  @override
  State<WeightTrendScreen> createState() => _WeightTrendScreenState();
}

class _WeightTrendScreenState extends State<WeightTrendScreen> {
  WeightTrend? _selectedTrend;

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
            'How has your weight trended for the past few weeks?',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        SizedBox(height: 32),

        // Options
        _buildOptionCard(
          trend: WeightTrend.losing,
          text: 'I have been losing weight',
          icon: Icons.arrow_downward,
        ),
        
        _buildOptionCard(
          trend: WeightTrend.gaining,
          text: 'I have been gaining weight',
          icon: Icons.arrow_upward,
        ),
        
        _buildOptionCard(
          trend: WeightTrend.stable,
          text: 'I have been weight stable',
          icon: Icons.remove,
        ),
        
        _buildOptionCard(
          trend: WeightTrend.notSure,
          text: 'Not sure',
          icon: Icons.help_outline,
        ),

        Spacer(),

        // Next button
        Padding(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _selectedTrend != null
                  ? () => widget.onSelect(_selectedTrend!)
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

  Widget _buildOptionCard({
    required WeightTrend trend,
    required String text,
    required IconData icon,
  }) {
    final isSelected = _selectedTrend == trend;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedTrend = trend;
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
                  text,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ),
              Container(
                height: 32,
                width: 32,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Color(0xFF2C2C2E),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isSelected ? Colors.black : Colors.white,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 
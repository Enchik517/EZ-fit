import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BirthDateScreen extends StatefulWidget {
  final Function(DateTime) onSelect;

  const BirthDateScreen({Key? key, required this.onSelect}) : super(key: key);

  @override
  State<BirthDateScreen> createState() => _BirthDateScreenState();
}

class _BirthDateScreenState extends State<BirthDateScreen> {
  int? selectedMonth;
  int? selectedDay;
  int? selectedYear;

  final List<String> months = [
    'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep',
    'Oct', 'Nov', 'Dec', 'Jan', 'Feb', 'Mar'
  ];

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
            'When were you born?',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        SizedBox(height: 32),

        // Date picker
        Container(
          margin: EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 200,
                child: Row(
                  children: [
                    // Month Column
                    Expanded(
                      child: _buildScrollColumn(
                        items: months,
                        selectedIndex: selectedMonth,
                        onSelected: (index) => setState(() => selectedMonth = index),
                      ),
                    ),
                    // Vertical Divider
                    Container(
                      width: 0.5,
                      color: Colors.white.withOpacity(0.1),
                    ),
                    // Day Column
                    Expanded(
                      child: _buildScrollColumn(
                        items: List.generate(31, (i) => '${i + 1}'),
                        selectedIndex: selectedDay,
                        onSelected: (index) => setState(() => selectedDay = index),
                      ),
                    ),
                    // Vertical Divider
                    Container(
                      width: 0.5,
                      color: Colors.white.withOpacity(0.1),
                    ),
                    // Year Column
                    Expanded(
                      child: _buildScrollColumn(
                        items: List.generate(100, (i) => '${DateTime.now().year - 100 + i}'),
                        selectedIndex: selectedYear,
                        onSelected: (index) => setState(() => selectedYear = index),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
              onPressed: selectedMonth != null && selectedDay != null && selectedYear != null
                  ? () {
                      final currentYear = DateTime.now().year;
                      final date = DateTime(
                        currentYear - 100 + (selectedYear ?? 0),
                        (selectedMonth ?? 0) + 1,
                        1 + (selectedDay ?? 0),
                      );
                      widget.onSelect(date);
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

  Widget _buildScrollColumn({
    required List<String> items,
    required int? selectedIndex,
    required Function(int) onSelected,
  }) {
    return ListWheelScrollView.useDelegate(
      itemExtent: 40,
      diameterRatio: 100,
      physics: FixedExtentScrollPhysics(),
      onSelectedItemChanged: onSelected,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: items.length,
        builder: (context, index) {
          final isSelected = selectedIndex == index;
          return Center(
            child: Text(
              items[index],
              style: GoogleFonts.inter(
                color: isSelected ? Colors.white : Colors.white.withOpacity(0.3),
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }
} 
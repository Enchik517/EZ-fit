import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class InjuriesScreen extends StatefulWidget {
  final Function(List<String>, String?) onSelect;
  final String gender;

  const InjuriesScreen({
    Key? key,
    required this.onSelect,
    required this.gender,
  }) : super(key: key);

  @override
  State<InjuriesScreen> createState() => _InjuriesScreenState();
}

class _InjuriesScreenState extends State<InjuriesScreen> {
  final Map<String, bool> _selectedInjuries = {
    'Knee': false,
    'Lower Back': false,
    'Ankle': false,
    'Wrist': false,
    'Hip': false,
  };

  bool _isPregnant = false;
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFemale = widget.gender == 'Female';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 32),

        // Title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Do you have any important\ninjuries or conditions?',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        SizedBox(height: 24),

        // Pregnancy checkbox (only for women)
        if (isFemale)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              decoration: BoxDecoration(
                color: Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: CheckboxListTile(
                value: _isPregnant,
                onChanged: (value) {
                  setState(() => _isPregnant = value ?? false);
                },
                title: Text(
                  'Pregnant',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                checkColor: Colors.black,
                activeColor: Colors.white,
                side: BorderSide(color: Colors.white),
              ),
            ),
          ),

        SizedBox(height: 24),

        // Injuries section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Injuries',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        SizedBox(height: 16),

        // Injuries list
        Expanded(
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: 24),
            children: _selectedInjuries.entries.map((entry) {
              return Container(
                margin: EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: entry.value ? Color(0xFF3A3A3C) : Color(0xFF2C2C2E),
                  borderRadius: BorderRadius.circular(12),
                  border: entry.value 
                    ? Border.all(color: Colors.white, width: 1)
                    : null,
                ),
                child: ListTile(
                  onTap: () {
                    setState(() {
                      _selectedInjuries[entry.key] = !entry.value;
                    });
                  },
                  title: Text(
                    entry.key,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: entry.value ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  trailing: entry.value 
                    ? Icon(Icons.check_circle, color: Colors.white)
                    : null,
                ),
              );
            }).toList(),
          ),
        ),

        // Other notes section
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Other notes',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Color(0xFF2C2C2E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _notesController,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Any discomfort you have. You can just type "right wrist hurts a bit" etc. in natural language',
                    hintStyle: GoogleFonts.inter(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.all(16),
                  ),
                  maxLines: 3,
                ),
              ),
            ],
          ),
        ),

        // Next button
        Padding(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                final selectedInjuries = _selectedInjuries.entries
                    .where((e) => e.value)
                    .map((e) => e.key)
                    .toList();
                if (_isPregnant) {
                  selectedInjuries.add('Pregnant');
                }
                widget.onSelect(selectedInjuries, _notesController.text.isEmpty ? null : _notesController.text);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
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
} 
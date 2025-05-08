import 'package:flutter/material.dart';

class FocusPage extends StatefulWidget {
  final VoidCallback onNext;

  const FocusPage({Key? key, required this.onNext}) : super(key: key);

  @override
  _FocusPageState createState() => _FocusPageState();
}

class _FocusPageState extends State<FocusPage> {
  final Set<String> _selectedAreas = {};

  final List<Map<String, dynamic>> _areas = [
    {
      'id': 'glutes',
      'label': 'Glutes',
      'icon': '🍑',
      'description': 'Build and shape your glutes'
    },
    {
      'id': 'abs',
      'label': 'Abs',
      'icon': '💪',
      'description': 'Get defined abs'
    },
    {
      'id': 'arms',
      'label': 'Arms',
      'icon': '💪',
      'description': 'Tone your arms'
    },
    {
      'id': 'legs',
      'label': 'Legs',
      'icon': '🦵',
      'description': 'Build strong legs'
    },
    {
      'id': 'back',
      'label': 'Back',
      'icon': '🔙',
      'description': 'Strengthen your back'
    },
    {
      'id': 'chest',
      'label': 'Chest',
      'icon': '👕',
      'description': 'Build chest muscles'
    },
    {
      'id': 'shoulders',
      'label': 'Shoulders',
      'icon': '🎯',
      'description': 'Sculpt your shoulders'
    },
    {
      'id': 'core',
      'label': 'Core',
      'icon': '⭕',
      'description': 'Strengthen your core'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'What areas would you like to focus on?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          Text(
            'Select up to 3 areas',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
              ),
              itemCount: _areas.length,
              itemBuilder: (context, index) {
                final area = _areas[index];
                return _buildAreaCard(
                  area['id'],
                  area['label'],
                  area['icon'],
                  area['description'],
                );
              },
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: _selectedAreas.isNotEmpty ? widget.onNext : null,
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
    );
  }

  Widget _buildAreaCard(String id, String label, String icon, String description) {
    final isSelected = _selectedAreas.contains(id);

    return InkWell(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedAreas.remove(id);
          } else if (_selectedAreas.length < 3) {
            _selectedAreas.add(id);
          }
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              icon,
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              description,
              style: TextStyle(
                color: isSelected ? Colors.black54 : Colors.white70,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
} 
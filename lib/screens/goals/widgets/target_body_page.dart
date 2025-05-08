import 'package:flutter/material.dart';

class TargetBodyPage extends StatefulWidget {
  final VoidCallback onNext;

  const TargetBodyPage({Key? key, required this.onNext}) : super(key: key);

  @override
  _TargetBodyPageState createState() => _TargetBodyPageState();
}

class _TargetBodyPageState extends State<TargetBodyPage> {
  String? _selectedRange;

  final List<Map<String, dynamic>> _ranges = [
    {
      'range': '8-12%',
      'description': 'Athletic/Competition',
      'subtitle': 'Visible abs, very defined muscles'
    },
    {
      'range': '13-17%',
      'description': 'Lean & Fit',
      'subtitle': 'Some muscle definition, athletic look'
    },
    {
      'range': '18-22%',
      'description': 'Fit & Healthy',
      'subtitle': 'Balanced look, healthy appearance'
    },
    {
      'range': '23-27%',
      'description': 'Average',
      'subtitle': 'Normal, everyday appearance'
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
            'What is your target body?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          Text(
            'Don\'t worry about being too precise, this helps us understand your goals better',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 48),
          Expanded(
            child: ListView.separated(
              itemCount: _ranges.length,
              separatorBuilder: (_, __) => SizedBox(height: 16),
              itemBuilder: (context, index) {
                final range = _ranges[index];
                final isSelected = _selectedRange == range['range'];
                
                return _buildRangeOption(
                  range['range'],
                  range['description'],
                  range['subtitle'],
                  isSelected,
                );
              },
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: _selectedRange != null ? widget.onNext : null,
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

  Widget _buildRangeOption(
    String range,
    String description,
    String subtitle,
    bool isSelected,
  ) {
    return InkWell(
      onTap: () => setState(() => _selectedRange = range),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    description,
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    range,
                    style: TextStyle(
                      color: isSelected ? Colors.black87 : Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isSelected ? Colors.black54 : Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Colors.black,
              ),
          ],
        ),
      ),
    );
  }
} 
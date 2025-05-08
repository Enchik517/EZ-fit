import 'package:flutter/material.dart';

class InjuriesPage extends StatefulWidget {
  final VoidCallback onNext;

  const InjuriesPage({Key? key, required this.onNext}) : super(key: key);

  @override
  _InjuriesPageState createState() => _InjuriesPageState();
}

class _InjuriesPageState extends State<InjuriesPage> {
  final Set<String> _selectedConditions = {};
  final TextEditingController _notesController = TextEditingController();

  final List<Map<String, String>> _conditions = [
    {'id': 'pregnant', 'label': 'Pregnant'},
    {'id': 'knee', 'label': 'Knee Issues'},
    {'id': 'back', 'label': 'Lower Back Pain'},
    {'id': 'shoulder', 'label': 'Shoulder Problems'},
    {'id': 'neck', 'label': 'Neck Pain'},
    {'id': 'wrist', 'label': 'Wrist Issues'},
    {'id': 'ankle', 'label': 'Ankle Problems'},
    {'id': 'hip', 'label': 'Hip Issues'},
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Do you have any important injuries or conditions?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  ..._conditions.map((condition) => _buildConditionTile(
                    condition['id']!,
                    condition['label']!,
                  )),
                  SizedBox(height: 24),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _notesController,
                      maxLines: 4,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Other notes or conditions...',
                        hintStyle: TextStyle(color: Colors.white54),
                        contentPadding: EdgeInsets.all(16),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: widget.onNext,
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

  Widget _buildConditionTile(String id, String label) {
    final isSelected = _selectedConditions.contains(id);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedConditions.remove(id);
            } else {
              _selectedConditions.add(id);
            }
          });
        },
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                color: isSelected ? Colors.black : Colors.white,
              ),
              SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 
import 'package:flutter/material.dart';

class PlanGenerationPage extends StatefulWidget {
  final VoidCallback onNext;

  const PlanGenerationPage({Key? key, required this.onNext}) : super(key: key);

  @override
  _PlanGenerationPageState createState() => _PlanGenerationPageState();
}

class _PlanGenerationPageState extends State<PlanGenerationPage> {
  final List<String> _steps = [
    'Creating your profile',
    'Analyzing your activity level',
    'Calculating optimal workout frequency',
    'Selecting exercises based on your goals',
    'Generating personalized plan',
    'Finalizing recommendations',
  ];

  int _currentStep = 0;
  bool _isDone = false;

  @override
  void initState() {
    super.initState();
    _startGeneration();
  }

  void _startGeneration() async {
    for (int i = 0; i < _steps.length; i++) {
      await Future.delayed(Duration(milliseconds: 1500));
      if (mounted) {
        setState(() => _currentStep = i);
      }
    }
    await Future.delayed(Duration(milliseconds: 500));
    if (mounted) {
      setState(() => _isDone = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _isDone ? 'Your Plan is Ready!' : 'Hold on, we are generating your plan',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 48),
          if (_isDone) ...[
            _buildSuccessContent(),
          ] else ...[
            _buildLoadingContent(),
          ],
          Spacer(),
          if (_isDone)
            ElevatedButton(
              onPressed: widget.onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'GET MY PLAN',
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

  Widget _buildLoadingContent() {
    return Column(
      children: [
        ..._steps.asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value;
          final isCompleted = index < _currentStep;
          final isCurrent = index == _currentStep;

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isCompleted ? Colors.green : Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: isCompleted
                      ? Icon(Icons.check, color: Colors.white, size: 16)
                      : isCurrent
                          ? CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              strokeWidth: 2,
                            )
                          : null,
                ),
                SizedBox(width: 16),
                Text(
                  step,
                  style: TextStyle(
                    color: isCompleted || isCurrent ? Colors.white : Colors.white54,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSuccessContent() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 64,
          ),
          SizedBox(height: 24),
          Text(
            'You\'ll reach your goal by',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '2 March 2024',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 24),
          _buildPlanPreview(),
        ],
      ),
    );
  }

  Widget _buildPlanPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your plan includes:',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        _buildPlanItem(Icons.fitness_center, 'Personalized workouts'),
        _buildPlanItem(Icons.restaurant_menu, 'Nutrition guidelines'),
        _buildPlanItem(Icons.trending_up, 'Progress tracking'),
        _buildPlanItem(Icons.tips_and_updates, 'Expert tips'),
      ],
    );
  }

  Widget _buildPlanItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.white70,
            size: 20,
          ),
          SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
} 
import 'package:flutter/material.dart';

/// Диалоговое окно выбора продолжительности тренировки
class DurationFilterSheet extends StatelessWidget {
  final List<String> durations;
  final String selectedDuration;
  final Map<String, int> durationLimits;
  final Function(String) onDurationSelected;

  const DurationFilterSheet({
    Key? key,
    required this.durations,
    required this.selectedDuration,
    required this.durationLimits,
    required this.onDurationSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Handle
          _buildHandle(),

          // Header
          _buildHeader('Select Duration', subtitle: 'Workout length'),

          // List
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(vertical: 8),
              itemCount: durations.length,
              itemBuilder: (context, index) {
                final duration = durations[index];
                final isSelected = duration == selectedDuration;

                return _buildOptionTile(
                  context: context,
                  title: duration,
                  subtitle: '${durationLimits[duration]} exercises',
                  icon: Icons.timer,
                  isSelected: isSelected,
                  onTap: () {
                    Navigator.pop(context);
                    onDurationSelected(duration);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Диалоговое окно выбора групп мышц
class MusclesFilterSheet extends StatefulWidget {
  final List<String> muscleGroups;
  final Set<String> selectedMuscles;
  final Function(Set<String>) onApply;

  const MusclesFilterSheet({
    Key? key,
    required this.muscleGroups,
    required this.selectedMuscles,
    required this.onApply,
  }) : super(key: key);

  @override
  State<MusclesFilterSheet> createState() => _MusclesFilterSheetState();
}

class _MusclesFilterSheetState extends State<MusclesFilterSheet> {
  late Set<String> _selectedMuscles;

  @override
  void initState() {
    super.initState();
    _selectedMuscles = Set.from(widget.selectedMuscles);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Handle
          _buildHandle(),

          // Header
          _buildHeader(
            'Target Muscles',
            action: _buildResetButton(() {
              setState(() {
                _selectedMuscles = {'All'};
              });
            }),
          ),

          // List
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(vertical: 8),
              itemCount: widget.muscleGroups.length,
              itemBuilder: (context, index) {
                final muscle = widget.muscleGroups[index];
                final isSelected = _selectedMuscles.contains(muscle);

                // Подбор иконки для группы мышц
                IconData iconData = _getMuscleIcon(muscle);

                return _buildOptionTile(
                  context: context,
                  title: muscle,
                  icon: iconData,
                  isSelected: isSelected,
                  onTap: () {
                    setState(() {
                      if (muscle == 'All') {
                        if (!_selectedMuscles.contains('All')) {
                          _selectedMuscles = {'All'};
                        }
                      } else {
                        _selectedMuscles.remove('All');
                        if (_selectedMuscles.contains(muscle)) {
                          _selectedMuscles.remove(muscle);
                        } else {
                          _selectedMuscles.add(muscle);
                        }
                        if (_selectedMuscles.isEmpty) {
                          _selectedMuscles.add('All');
                        }
                      }
                    });
                  },
                );
              },
            ),
          ),

          // Apply Button
          _buildApplyButton(() {
            widget.onApply(_selectedMuscles);
            Navigator.pop(context);
          }),
        ],
      ),
    );
  }

  IconData _getMuscleIcon(String muscle) {
    switch (muscle.toLowerCase()) {
      case 'chest':
        return Icons.fitness_center;
      case 'back':
        return Icons.arrow_back;
      case 'shoulders':
        return Icons.arrow_upward;
      case 'arms':
        return Icons.front_hand;
      case 'legs':
        return Icons.airline_seat_legroom_extra;
      case 'core':
        return Icons.rectangle;
      case 'full body':
        return Icons.accessibility_new;
      case 'triceps':
        return Icons.fitness_center;
      case 'biceps':
        return Icons.fitness_center;
      case 'quads':
        return Icons.airline_seat_legroom_extra;
      case 'glutes':
        return Icons.airline_seat_legroom_extra;
      case 'hamstrings':
        return Icons.airline_seat_legroom_extra;
      case 'calves':
        return Icons.airline_seat_legroom_extra;
      default:
        return Icons.fitness_center;
    }
  }
}

/// Диалоговое окно выбора оборудования
class EquipmentFilterSheet extends StatefulWidget {
  final List<String> equipment;
  final Set<String> selectedEquipment;
  final Function(Set<String>) onApply;

  const EquipmentFilterSheet({
    Key? key,
    required this.equipment,
    required this.selectedEquipment,
    required this.onApply,
  }) : super(key: key);

  @override
  State<EquipmentFilterSheet> createState() => _EquipmentFilterSheetState();
}

class _EquipmentFilterSheetState extends State<EquipmentFilterSheet> {
  late Set<String> _selectedEquipment;

  @override
  void initState() {
    super.initState();
    _selectedEquipment = Set.from(widget.selectedEquipment);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Handle
          _buildHandle(),

          // Header
          _buildHeader(
            'Equipment',
            action: _buildResetButton(() {
              setState(() {
                _selectedEquipment = {'All'};
              });
            }),
          ),

          // List
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(vertical: 8),
              itemCount: widget.equipment.length,
              itemBuilder: (context, index) {
                final item = widget.equipment[index];
                final isSelected = _selectedEquipment.contains(item);

                // Эмодзи для оборудования
                String emoji = _getEquipmentEmoji(item);

                return _buildEmojiOptionTile(
                  context: context,
                  title: item,
                  emoji: emoji,
                  isSelected: isSelected,
                  onTap: () {
                    setState(() {
                      if (item == 'All') {
                        if (!_selectedEquipment.contains('All')) {
                          _selectedEquipment = {'All'};
                        }
                      } else {
                        _selectedEquipment.remove('All');
                        if (_selectedEquipment.contains(item)) {
                          _selectedEquipment.remove(item);
                        } else {
                          _selectedEquipment.add(item);
                        }
                        if (_selectedEquipment.isEmpty) {
                          _selectedEquipment.add('All');
                        }
                      }
                    });
                  },
                );
              },
            ),
          ),

          // Apply Button
          _buildApplyButton(() {
            widget.onApply(_selectedEquipment);
            Navigator.pop(context);
          }),
        ],
      ),
    );
  }

  String _getEquipmentEmoji(String equipment) {
    switch (equipment.toLowerCase()) {
      case 'dumbbells':
        return '🏋️';
      case 'barbell':
        return '💪';
      case 'resistance band':
        return '🔄';
      case 'pull-up bar':
        return '🧗';
      case 'box':
        return '📦';
      case 'bench':
        return '🛋️';
      case 'kettlebell':
        return '🔔';
      case 'none':
        return '🚶';
      case 'all':
        return '⭐';
      default:
        return '🏋️';
    }
  }
}

/// Диалоговое окно выбора уровня сложности
class DifficultyFilterSheet extends StatefulWidget {
  final List<String> difficulties;
  final Set<String> selectedDifficulties;
  final Function(Set<String>) onApply;

  const DifficultyFilterSheet({
    Key? key,
    required this.difficulties,
    required this.selectedDifficulties,
    required this.onApply,
  }) : super(key: key);

  @override
  State<DifficultyFilterSheet> createState() => _DifficultyFilterSheetState();
}

class _DifficultyFilterSheetState extends State<DifficultyFilterSheet> {
  late Set<String> _selectedDifficulties;

  @override
  void initState() {
    super.initState();
    _selectedDifficulties = Set.from(widget.selectedDifficulties);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Handle
          _buildHandle(),

          // Header
          _buildHeader(
            'Difficulty Level',
            action: _buildResetButton(() {
              setState(() {
                _selectedDifficulties = {'All'};
              });
            }),
          ),

          // List
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(vertical: 8),
              itemCount: widget.difficulties.length,
              itemBuilder: (context, index) {
                final difficulty = widget.difficulties[index];
                final isSelected = _selectedDifficulties.contains(difficulty);

                return _buildDifficultyTile(
                  context: context,
                  difficulty: difficulty,
                  isSelected: isSelected,
                  onTap: () {
                    setState(() {
                      if (difficulty == 'All') {
                        if (!_selectedDifficulties.contains('All')) {
                          _selectedDifficulties = {'All'};
                        }
                      } else {
                        _selectedDifficulties.remove('All');
                        if (_selectedDifficulties.contains(difficulty)) {
                          _selectedDifficulties.remove(difficulty);
                        } else {
                          _selectedDifficulties.add(difficulty);
                        }
                        if (_selectedDifficulties.isEmpty) {
                          _selectedDifficulties.add('All');
                        }
                      }
                    });
                  },
                );
              },
            ),
          ),

          // Apply Button
          _buildApplyButton(() {
            widget.onApply(_selectedDifficulties);
            Navigator.pop(context);
          }),
        ],
      ),
    );
  }
}

/// Общие вспомогательные методы для построения UI компонентов диалоговых окон

// Элемент-ручка сверху модального окна
Widget _buildHandle() {
  return Container(
    margin: EdgeInsets.symmetric(vertical: 12),
    width: 40,
    height: 4,
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.2),
      borderRadius: BorderRadius.circular(2),
    ),
  );
}

// Заголовок модального окна
Widget _buildHeader(String title, {String? subtitle, Widget? action}) {
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    decoration: BoxDecoration(
      border: Border(
        bottom: BorderSide(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
        subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 14,
                  fontFamily: 'Inter',
                ),
              )
            : action ?? SizedBox(),
      ],
    ),
  );
}

// Кнопка сброса фильтров
Widget _buildResetButton(VoidCallback onPressed) {
  return TextButton(
    onPressed: onPressed,
    style: TextButton.styleFrom(
      backgroundColor: Colors.blue.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),
    child: Text(
      'Reset',
      style: TextStyle(
        color: Colors.blue,
        fontSize: 14,
        fontFamily: 'Inter',
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}

// Элемент списка с иконкой
Widget _buildOptionTile({
  required BuildContext context,
  required String title,
  String? subtitle,
  required IconData icon,
  required bool isSelected,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    child: Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? Colors.blue.withOpacity(0.5) : Colors.transparent,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.blue.withOpacity(0.2)
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(
                icon,
                color: isSelected ? Colors.blue : Colors.white.withOpacity(0.7),
                size: 20,
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: subtitle != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontFamily: 'Inter',
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 13,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  )
                : Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: 'Inter',
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
          ),
          if (isSelected)
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check,
                color: Colors.white,
                size: 16,
              ),
            ),
        ],
      ),
    ),
  );
}

// Элемент списка с эмодзи
Widget _buildEmojiOptionTile({
  required BuildContext context,
  required String title,
  required String emoji,
  required bool isSelected,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    child: Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? Colors.blue.withOpacity(0.5) : Colors.transparent,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.blue.withOpacity(0.2)
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                emoji,
                style: TextStyle(fontSize: 20),
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: 'Inter',
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
          if (isSelected)
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check,
                color: Colors.white,
                size: 16,
              ),
            ),
        ],
      ),
    ),
  );
}

// Элемент списка сложности со звёздами
Widget _buildDifficultyTile({
  required BuildContext context,
  required String difficulty,
  required bool isSelected,
  required VoidCallback onTap,
}) {
  // Определение количества звезд для уровня сложности
  int stars;
  switch (difficulty.toLowerCase()) {
    case 'beginner':
      stars = 1;
      break;
    case 'intermediate':
      stars = 2;
      break;
    case 'advanced':
      stars = 3;
      break;
    default:
      stars = 0;
      break;
  }

  return InkWell(
    onTap: onTap,
    child: Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? Colors.blue.withOpacity(0.5) : Colors.transparent,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.blue.withOpacity(0.2)
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: difficulty == 'All'
                  ? Icon(
                      Icons.auto_awesome,
                      color: isSelected
                          ? Colors.blue
                          : Colors.white.withOpacity(0.7),
                      size: 20,
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                          stars,
                          (i) => Icon(
                                Icons.star,
                                color: isSelected
                                    ? Colors.amber
                                    : Colors.amber.withOpacity(0.5),
                                size: 12,
                              )),
                    ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              difficulty,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: 'Inter',
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
          if (isSelected)
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check,
                color: Colors.white,
                size: 16,
              ),
            ),
        ],
      ),
    ),
  );
}

// Кнопка "Применить фильтры"
Widget _buildApplyButton(VoidCallback onPressed) {
  return Container(
    width: double.infinity,
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Color(0xFF252527),
      border: Border(
        top: BorderSide(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
    ),
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        padding: EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
      ),
      child: Text(
        'Apply Filters',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}

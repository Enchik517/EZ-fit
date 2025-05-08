import 'package:flutter/material.dart';
import 'goals_screen.dart';
import 'disclaimer_screen.dart';

// Класс для управления потоком регистрации целей
class RegistrationFlow {
  // Список экранов в порядке прохождения
  static final List<Widget Function(BuildContext, VoidCallback)> _screens = [
    (context, onNext) => _GoalSelectionScreen(
          onNext: onNext,
        ),
    (context, onNext) => _GoalPriorityScreen(
          onNext: onNext,
        ),
    (context, onNext) => _BodyPartFocusScreen(
          onNext: onNext,
        ),
    (context, onNext) => _WeightGoalScreen(
          onNext: onNext,
        ),
    (context, onNext) => _BodyTypeScreen(
          onNext: onNext,
        ),
    (context, onNext) => _InjuriesLimitationsScreen(
          onNext: onNext,
        ),
    (context, onNext) => _WorkoutFrequencyScreen(
          onNext: onNext,
        ),
    (context, onNext) => _TimePerWorkoutScreen(
          onNext: onNext,
        ),
    (context, onNext) => _EquipmentScreen(
          onNext: onNext,
        ),
    (context, onNext) => _WorkoutLocationScreen(
          onNext: onNext,
        ),
    (context, onNext) => _ExperienceLevelScreen(
          onNext: onNext,
        ),
    (context, onNext) => _FitnessHistoryScreen(
          onNext: onNext,
        ),
    (context, onNext) => _MobilityAssessmentScreen(
          onNext: onNext,
        ),
    (context, onNext) => _PreferredWorkoutTypesScreen(
          onNext: onNext,
        ),
    (context, onNext) => _GoalTimeframeScreen(
          onNext: onNext,
        ),
    (context, onNext) => _SummaryScreen(
          onNext: onNext,
        ),
  ];

  // Метод для запуска потока регистрации с первого экрана
  static void start(BuildContext context, {VoidCallback? onComplete}) {
    _navigateToScreen(context, 0, onComplete);
  }

  // Метод для запуска потока с произвольного экрана (для тестирования)
  static void startFromIndex(BuildContext context, int index,
      {VoidCallback? onComplete}) {
    if (index < 0 || index >= _screens.length) {
      index = 0;
    }
    _navigateToScreen(context, index, onComplete);
  }

  // Внутренний метод для навигации между экранами
  static void _navigateToScreen(
      BuildContext context, int index, VoidCallback? onComplete) {
    //// Отладочное сообщение

    if (index >= _screens.length) {
      //      // Все экраны пройдены
      if (onComplete != null) {
        onComplete();
      } else {
        // Возвращаемся к начальному экрану
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
      return;
    }

    // Создаем функцию для перехода к следующему экрану
    void goToNext() {
      //      _navigateToScreen(context, index + 1, onComplete);
    }

    // Создаем текущий экран с функцией перехода к следующему
    Widget screen = _screens[index](context, goToNext);

    // Показываем экран с явной обработкой результата
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => screen))
        .then((_) {
      // Это будет вызвано, когда экран закроется
    });
  }
}

// Заглушки экранов для последовательности целей

class _GoalSelectionScreen extends StatefulWidget {
  final VoidCallback onNext;

  const _GoalSelectionScreen({Key? key, required this.onNext})
      : super(key: key);

  @override
  State<_GoalSelectionScreen> createState() => _GoalSelectionScreenState();
}

class _GoalSelectionScreenState extends State<_GoalSelectionScreen> {
  // Добавляем состояние для отслеживания выбранных целей
  final Map<String, bool> _selectedGoals = {
    'Lose Weight': false,
    'Build Muscle': false,
    'Improve Strength': false,
    'Increase Endurance': false,
    'Enhance Flexibility': false,
    'Better Posture': false,
    'Reduce Stress': false,
  };

  // Проверяем, выбрана ли хотя бы одна цель
  bool get _hasSelectedGoals =>
      _selectedGoals.values.any((selected) => selected);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('GOALS', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'What are your fitness goals?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'Select all that apply',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              children: _selectedGoals.keys
                  .map((goal) => _buildGoalTile(goal, _selectedGoals[goal]!))
                  .toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _hasSelectedGoals
                    ? () {
                        //                      // Явно выводим сообщение перед переходом к следующему экрану
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(
                                'Selected goals: ${_selectedGoals.entries.where((e) => e.value).map((e) => e.key).join(", ")}')));
                        // После небольшой задержки переходим к следующему экрану
                        Future.delayed(Duration(milliseconds: 500), () {
                          widget.onNext();
                        });
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  disabledBackgroundColor: Colors.blue.withOpacity(0.3),
                ),
                child: Text(
                  'Continue',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalTile(String goal, bool isSelected) {
    return ListTile(
      title: Text(goal,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
          )),
      contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
      trailing: Checkbox(
        value: isSelected,
        onChanged: (value) {
          // Обновляем состояние при изменении
          setState(() {
            _selectedGoals[goal] = value ?? false;
          });
        },
        activeColor: Colors.blue,
        checkColor: Colors.white,
        side: BorderSide(color: Colors.white, width: 1.5),
      ),
      onTap: () {
        // Позволяем также нажимать на строку для выбора
        setState(() {
          _selectedGoals[goal] = !isSelected;
        });
      },
    );
  }
}

class _GoalPriorityScreen extends StatelessWidget {
  final VoidCallback onNext;

  const _GoalPriorityScreen({Key? key, required this.onNext}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('GOALS', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'What\'s your main priority?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: ReorderableListView(
              padding: EdgeInsets.all(16),
              children: [
                _buildPriorityTile('Build Muscle', 1, Key('1')),
                _buildPriorityTile('Lose Weight', 2, Key('2')),
                _buildPriorityTile('Improve Strength', 3, Key('3')),
              ],
              onReorder: (oldIndex, newIndex) {},
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
                child: Text('Continue'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityTile(String goal, int priority, Key key) {
    return ListTile(
      key: key,
      title: Text(goal, style: TextStyle(color: Colors.white)),
      leading: CircleAvatar(
        backgroundColor: Colors.blue,
        child: Text('$priority'),
      ),
      trailing: Icon(Icons.drag_handle, color: Colors.grey),
    );
  }
}

class _BodyPartFocusScreen extends StatelessWidget {
  final VoidCallback onNext;

  const _BodyPartFocusScreen({Key? key, required this.onNext})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('Focus', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Which body parts do you want to focus on?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: GridView.count(
              crossAxisCount: 3,
              padding: EdgeInsets.all(16),
              children: [
                _buildBodyPartTile('Arms', Icons.fitness_center),
                _buildBodyPartTile('Chest', Icons.favorite),
                _buildBodyPartTile('Back', Icons.accessibility_new),
                _buildBodyPartTile('Legs', Icons.arrow_downward),
                _buildBodyPartTile('Core', Icons.crop_square),
                _buildBodyPartTile('Shoulders', Icons.arrow_upward),
                _buildBodyPartTile('Glutes', Icons.arrow_back),
                _buildBodyPartTile('Full Body', Icons.person),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
                child: Text('Continue'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyPartTile(String part, IconData icon) {
    return Card(
      color: Colors.grey[900],
      child: InkWell(
        onTap: () {},
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 40),
            SizedBox(height: 8),
            Text(part, style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

// Добавляем остальные экраны с изображения

class _WeightGoalScreen extends StatelessWidget {
  final VoidCallback onNext;

  const _WeightGoalScreen({Key? key, required this.onNext}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('GOALS', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Do you want to change your weight?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(16),
              children: [
                _buildWeightOption('Lose Weight', 'Reduce body fat'),
                _buildWeightOption('Maintain Weight', 'Stay at current weight'),
                _buildWeightOption('Gain Weight', 'Build muscle mass'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
                child: Text('Continue'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightOption(String title, String subtitle) {
    return Card(
      color: Colors.grey[900],
      margin: EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(title, style: TextStyle(color: Colors.white)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey)),
        onTap: () {},
      ),
    );
  }
}

class _BodyTypeScreen extends StatelessWidget {
  final VoidCallback onNext;

  const _BodyTypeScreen({Key? key, required this.onNext}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('GOALS', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Which body type best describes you?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: GridView.count(
              crossAxisCount: 3,
              padding: EdgeInsets.all(16),
              children: [
                _buildBodyTypeCard('Ectomorph', 'assets/ectomorph.png'),
                _buildBodyTypeCard('Mesomorph', 'assets/mesomorph.png'),
                _buildBodyTypeCard('Endomorph', 'assets/endomorph.png'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
                child: Text('Continue'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyTypeCard(String type, String imagePath) {
    return Card(
      color: Colors.grey[900],
      child: InkWell(
        onTap: () {},
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Placeholder instead of image for simplicity
            Icon(Icons.person_outline, size: 60, color: Colors.white),
            SizedBox(height: 8),
            Text(type, style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

// Остальные экраны можно сделать по аналогии
class _InjuriesLimitationsScreen extends StatelessWidget {
  final VoidCallback onNext;

  const _InjuriesLimitationsScreen({Key? key, required this.onNext})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('Injuries', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Do you have any injuries or limitations?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(16),
              children: [
                _buildInjuryCheckbox('Lower Back Pain'),
                _buildInjuryCheckbox('Knee Pain/Injury'),
                _buildInjuryCheckbox('Shoulder Pain/Injury'),
                _buildInjuryCheckbox('Neck Pain'),
                _buildInjuryCheckbox('Ankle/Foot Issues'),
                _buildInjuryCheckbox('Wrist/Hand Pain'),
                _buildInjuryCheckbox('Hip Issues'),
                _buildInjuryCheckbox('Other'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
                child: Text('Continue'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInjuryCheckbox(String injury) {
    return CheckboxListTile(
      title: Text(injury, style: TextStyle(color: Colors.white)),
      value: false,
      onChanged: (value) {},
      activeColor: Colors.blue,
    );
  }
}

// Добавляем еще несколько важных экранов в сокращенном виде
class _WorkoutFrequencyScreen extends StatelessWidget {
  final VoidCallback onNext;
  const _WorkoutFrequencyScreen({Key? key, required this.onNext})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('GOALS', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'How often can you workout?',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView(
              children: List.generate(
                  7,
                  (index) => ListTile(
                        title: Text('${index + 1} days per week',
                            style: TextStyle(color: Colors.white)),
                        trailing: Radio(
                            value: index, groupValue: 3, onChanged: (val) {}),
                      )),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: onNext,
              child: Text('Continue'),
              style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50)),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimePerWorkoutScreen extends StatelessWidget {
  final VoidCallback onNext;
  const _TimePerWorkoutScreen({Key? key, required this.onNext})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: Text('GOALS'), backgroundColor: Colors.transparent),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'How much time do you have per workout?',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                ListTile(
                    title: Text('15-30 minutes',
                        style: TextStyle(color: Colors.white))),
                ListTile(
                    title: Text('30-45 minutes',
                        style: TextStyle(color: Colors.white))),
                ListTile(
                    title: Text('45-60 minutes',
                        style: TextStyle(color: Colors.white))),
                ListTile(
                    title: Text('60+ minutes',
                        style: TextStyle(color: Colors.white))),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: onNext,
              child: Text('Continue'),
              style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50)),
            ),
          ),
        ],
      ),
    );
  }
}

class _EquipmentScreen extends StatelessWidget {
  final VoidCallback onNext;
  const _EquipmentScreen({Key? key, required this.onNext}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: Text('GOALS'), backgroundColor: Colors.transparent),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'What equipment do you have?',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
              child: Center(
                  child: Text('Equipment selection grid',
                      style: TextStyle(color: Colors.white)))),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: onNext,
              child: Text('Continue'),
              style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50)),
            ),
          ),
        ],
      ),
    );
  }
}

// Шаблоны для оставшихся экранов
class _WorkoutLocationScreen extends StatelessWidget {
  final VoidCallback onNext;
  const _WorkoutLocationScreen({Key? key, required this.onNext})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return _buildTemplateScreen(context, 'Where do you workout?', onNext);
  }
}

class _ExperienceLevelScreen extends StatelessWidget {
  final VoidCallback onNext;
  const _ExperienceLevelScreen({Key? key, required this.onNext})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return _buildTemplateScreen(
        context, 'What is your experience level?', onNext);
  }
}

class _FitnessHistoryScreen extends StatelessWidget {
  final VoidCallback onNext;
  const _FitnessHistoryScreen({Key? key, required this.onNext})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return _buildTemplateScreen(
        context, 'Tell us about your fitness history', onNext);
  }
}

class _MobilityAssessmentScreen extends StatelessWidget {
  final VoidCallback onNext;
  const _MobilityAssessmentScreen({Key? key, required this.onNext})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return _buildTemplateScreen(context, 'Mobility Assessment', onNext);
  }
}

class _PreferredWorkoutTypesScreen extends StatelessWidget {
  final VoidCallback onNext;
  const _PreferredWorkoutTypesScreen({Key? key, required this.onNext})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return _buildTemplateScreen(
        context, 'What types of workouts do you prefer?', onNext);
  }
}

class _GoalTimeframeScreen extends StatelessWidget {
  final VoidCallback onNext;
  const _GoalTimeframeScreen({Key? key, required this.onNext})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return _buildTemplateScreen(
        context, 'When do you want to achieve your goal?', onNext);
  }
}

class _SummaryScreen extends StatelessWidget {
  final VoidCallback onNext;
  const _SummaryScreen({Key? key, required this.onNext}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return _buildTemplateScreen(context, 'Your Fitness Profile', onNext);
  }
}

// Вспомогательная функция для создания шаблонных экранов
Widget _buildTemplateScreen(
    BuildContext context, String title, VoidCallback onNext) {
  return Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      title: Text('GOALS', style: TextStyle(color: Colors.white)),
      backgroundColor: Colors.transparent,
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            title,
            style: TextStyle(
                color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Center(
            child: Text('Screen content goes here',
                style: TextStyle(color: Colors.white70)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: onNext,
            child: Text('Continue'),
            style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50)),
          ),
        ),
      ],
    ),
  );
}

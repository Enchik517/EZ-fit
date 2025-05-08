import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../models/workout.dart';
import '../services/workout_planner.dart';
import '../providers/workout_provider.dart';
import '../screens/main_navigation_screen.dart';
import 'package:provider/provider.dart';

class Message {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  Message({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class TargetsScreen extends StatefulWidget {
  @override
  _TargetsScreenState createState() => _TargetsScreenState();
}

class _TargetsScreenState extends State<TargetsScreen> {
  final _formKey = GlobalKey<FormState>();
  double _height = 170;
  double _weight = 70;
  int _age = 25;
  String _gender = 'Male';
  ActivityLevel _activityLevel = ActivityLevel.moderatelyActive;
  FitnessLevel _fitnessLevel = FitnessLevel.beginner;
  List<String> _healthConditions = [];
  List<String> _availableEquipment = [];
  TimeAvailability _timeAvailability = TimeAvailability(daysPerWeek: 3, minutesPerSession: 60);
  List<String> _preferences = [];
  List<FitnessGoal> _goals = [];
  bool _showChat = false;
  List<Message> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<String> _genders = ['Male', 'Female', 'Other'];
  final List<String> _commonHealthConditions = [
    'None',
    'Back Pain',
    'Knee Issues',
    'Shoulder Pain',
    'Heart Condition',
    'Asthma',
    'Other'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_showChat ? 'AI Assistant' : 'Your Goals'),
        actions: [
          if (!_showChat && _goals.isNotEmpty)
            IconButton(
              icon: Icon(Icons.chat_bubble_outline),
              onPressed: () => _startAIChat(),
            ),
        ],
        leading: _showChat
            ? IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () => setState(() => _showChat = false),
              )
            : null,
      ),
      body: _showChat ? _buildChatInterface() : _buildTargetsForm(),
    );
  }

  void _startAIChat() {
    setState(() {
      _showChat = true;
      _messages = [
        Message(
          text: _generateInitialAIMessage(),
          isUser: false,
          timestamp: DateTime.now(),
        ),
      ];
    });
  }

  String _generateInitialAIMessage() {
    final profile = _getCurrentUserProfile();
    String message = 'Hi! Based on your profile, I\'ve analyzed your goals and created a personalized plan.\n\n';
    
    message += '📊 Profile Summary:\n';
    message += '• ${profile.fitnessLevel.toString().split('.').last.capitalize()} fitness level\n';
    message += '• Available ${profile.timeAvailability.daysPerWeek}x per week, ${profile.timeAvailability.minutesPerSession} mins/session\n';
    if (profile.healthConditions.isNotEmpty) {
      message += '• Health considerations: ${profile.healthConditions.join(", ")}\n';
    }
    
    message += '\n🎯 Your Goals:\n';
    for (var goal in profile.goals) {
      message += '• ${_getGoalEmoji(goal.type)} ${goal.type.toString().split('.').last.capitalize()}\n';
    }
    
    message += '\nI can help you:\n';
    message += '• Modify your training plan\n';
    message += '• Explain exercises\n';
    message += '• Track progress\n';
    message += '• Adjust intensity\n\n';
    
    message += 'What would you like to know about your plan?';
    return message;
  }

  Widget _buildTargetsForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: EdgeInsets.all(16),
        children: [
          _buildPersonalInfoSection(),
          SizedBox(height: 24),
          _buildHealthSection(),
          SizedBox(height: 24),
          _buildAvailabilitySection(),
          SizedBox(height: 24),
          _buildGoalsSection(),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: _saveProfile,
            child: Text('Generate Training Plan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFE91E63),
              padding: EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Personal Information',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        _buildNumberField(
          label: 'Height (cm)',
          value: _height,
          onChanged: (value) => setState(() => _height = value),
        ),
        SizedBox(height: 16),
        _buildNumberField(
          label: 'Weight (kg)',
          value: _weight,
          onChanged: (value) => setState(() => _weight = value),
        ),
        SizedBox(height: 16),
        _buildNumberField(
          label: 'Age',
          value: _age.toDouble(),
          onChanged: (value) => setState(() => _age = value.toInt()),
        ),
        SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _gender,
          decoration: InputDecoration(
            labelText: 'Gender',
            border: OutlineInputBorder(),
          ),
          items: _genders.map((gender) => DropdownMenuItem(
            value: gender,
            child: Text(gender),
          )).toList(),
          onChanged: (value) => setState(() => _gender = value!),
        ),
        SizedBox(height: 16),
        DropdownButtonFormField<FitnessLevel>(
          value: _fitnessLevel,
          decoration: InputDecoration(
            labelText: 'Fitness Level',
            border: OutlineInputBorder(),
          ),
          items: FitnessLevel.values.map((level) => DropdownMenuItem(
            value: level,
            child: Text(level.toString().split('.').last.capitalize()),
          )).toList(),
          onChanged: (value) => setState(() => _fitnessLevel = value!),
        ),
      ],
    );
  }

  Widget _buildHealthSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Health Information',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _commonHealthConditions.map((condition) {
            final isSelected = _healthConditions.contains(condition);
            return FilterChip(
              label: Text(condition),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _healthConditions.add(condition);
                  } else {
                    _healthConditions.remove(condition);
                  }
                });
              },
            );
          }).toList(),
        ),
        SizedBox(height: 16),
        Text(
          'Available Equipment',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: Equipment.values.map((equipment) {
            final equipmentName = equipment.toString().split('.').last;
            final isSelected = _availableEquipment.contains(equipmentName);
            return FilterChip(
              label: Text(equipmentName.capitalize()),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _availableEquipment.add(equipmentName);
                  } else {
                    _availableEquipment.remove(equipmentName);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAvailabilitySection() {
    return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
        Text(
          'Time Availability',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
                Row(
                  children: [
            Expanded(
              child: _buildNumberField(
                label: 'Days per Week',
                value: _timeAvailability.daysPerWeek.toDouble(),
                onChanged: (value) => setState(() {
                  _timeAvailability = TimeAvailability(
                    daysPerWeek: value.toInt(),
                    minutesPerSession: _timeAvailability.minutesPerSession,
                  );
                }),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildNumberField(
                label: 'Minutes per Session',
                value: _timeAvailability.minutesPerSession.toDouble(),
                onChanged: (value) => setState(() {
                  _timeAvailability = TimeAvailability(
                    daysPerWeek: _timeAvailability.daysPerWeek,
                    minutesPerSession: value.toInt(),
                  );
                }),
              ),
                    ),
                  ],
                ),
      ],
    );
  }

  Widget _buildNumberField({
    required String label,
    required double value,
    required Function(double) onChanged,
  }) {
    return TextFormField(
      initialValue: value.toString(),
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      onChanged: (value) {
        if (value.isNotEmpty) {
          onChanged(double.parse(value));
        }
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a value';
        }
        return null;
      },
    );
  }

  Widget _buildGoalsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fitness Goals',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        ..._goals.map((goal) => _buildGoalCard(goal)).toList(),
        SizedBox(height: 16),
        Row(
          children: [
            ElevatedButton(
              onPressed: _showAddGoalDialog,
              child: Text('+ Add Goal'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFE91E63),
                padding: EdgeInsets.symmetric(vertical: 16),
                minimumSize: Size(120, 48),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: _showAddGoalWithAIDialog,
                child: Text('Add Goal with AI'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF6B2D5C),
                  padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
      ],
    );
  }

  Widget _buildGoalCard(FitnessGoal goal) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                  _formatEnum(goal.type.toString()),
                  style: TextStyle(
                    fontSize: 18,
                      fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    setState(() {
                      _goals.remove(goal);
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 8),
            Text('Target: ${goal.targetValue} ${_getUnitForGoal(goal.type)}'),
            Text('Muscle Group: ${goal.muscleGroup}'),
            Text(
              'Target Date: ${goal.targetDate.toString().split(' ')[0]}',
            ),
          ],
        ),
      ),
    );
  }

  String _getUnitForGoal(GoalType type) {
    switch (type) {
      case GoalType.weightLoss:
      case GoalType.weightGain:
        return 'kg';
      case GoalType.muscleMass:
        return 'cm';
      case GoalType.strength:
        return 'kg (1RM)';
      case GoalType.endurance:
        return 'minutes';
      case GoalType.flexibility:
        return 'cm';
      case GoalType.generalFitness:
        return '';
    }
  }

  String _getGoalEmoji(GoalType type) {
    switch (type) {
      case GoalType.weightLoss:
        return '⚖️';
      case GoalType.weightGain:
        return '💪';
      case GoalType.muscleMass:
        return '🏋️';
      case GoalType.strength:
        return '🔨';
      case GoalType.endurance:
        return '🏃';
      case GoalType.flexibility:
        return '🧘';
      case GoalType.generalFitness:
        return '🎯';
    }
  }

  String _formatEnum(String enumString) {
    return enumString.split('.').last.replaceAllMapped(
          RegExp(r'([A-Z])'),
          (match) => ' ${match.group(1)}',
        ).trim().capitalize();
  }

  void _showAddGoalDialog() {
    GoalType _type = GoalType.weightLoss;
    double _targetValue = 0;
    String _muscleGroup = MuscleGroup.fullBody.toString().split('.').last;
    DateTime _targetDate = DateTime.now().add(Duration(days: 90));

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Add New Goal'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<GoalType>(
                      value: _type,
                      decoration: InputDecoration(
                        labelText: 'Goal Type',
                        border: OutlineInputBorder(),
                      ),
                      items: GoalType.values.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(_formatEnum(type.toString())),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _type = value!;
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Target Value',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          _targetValue = double.parse(value);
                        }
                      },
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _muscleGroup,
                      decoration: InputDecoration(
                        labelText: 'Muscle Group',
                        border: OutlineInputBorder(),
                      ),
                      items: MuscleGroup.values.map((group) {
                        return DropdownMenuItem(
                          value: group.toString().split('.').last,
                          child: Text(_formatEnum(group.toString())),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _muscleGroup = value!;
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    ListTile(
                      title: Text('Target Date'),
                      subtitle: Text(_targetDate.toString().split(' ')[0]),
                      trailing: Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _targetDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(Duration(days: 365 * 2)),
                        );
                        if (date != null) {
                          setState(() {
                            _targetDate = date;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _goals.add(FitnessGoal(
                        type: _type,
                        targetValue: _targetValue,
                        muscleGroup: _muscleGroup,
                        targetDate: _targetDate,
                      ));
                    });
                    Navigator.pop(context);
                  },
                  child: Text('Add'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFE91E63),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddGoalWithAIDialog() {
    GoalType _type = GoalType.weightLoss;
    double _targetValue = 0;
    String _muscleGroup = MuscleGroup.fullBody.toString().split('.').last;
    DateTime _targetDate = DateTime.now().add(Duration(days: 90));
    String _aiDescription = '';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Add New Goal with AI'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Describe your goal to AI',
                        hintText: 'Example: I want to lose weight and build muscle, focusing on upper body. I can train 3 times a week.',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        _aiDescription = value;
                      },
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<GoalType>(
                      value: _type,
                      decoration: InputDecoration(
                        labelText: 'Goal Type',
                        border: OutlineInputBorder(),
                      ),
                      items: GoalType.values.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(_formatEnum(type.toString())),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _type = value!;
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Target Value',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          _targetValue = double.parse(value);
                        }
                      },
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _muscleGroup,
                      decoration: InputDecoration(
                        labelText: 'Muscle Group',
                        border: OutlineInputBorder(),
                      ),
                      items: MuscleGroup.values.map((group) {
                        return DropdownMenuItem(
                          value: group.toString().split('.').last,
                          child: Text(_formatEnum(group.toString())),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _muscleGroup = value!;
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    ListTile(
                      title: Text('Target Date'),
                      subtitle: Text(_targetDate.toString().split(' ')[0]),
                      trailing: Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _targetDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(Duration(days: 365 * 2)),
                        );
                        if (date != null) {
                          setState(() {
                            _targetDate = date;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // TODO: Process AI description when API key is available
                    setState(() {
                      _goals.add(FitnessGoal(
                        type: _type,
                        targetValue: _targetValue,
                        muscleGroup: _muscleGroup,
                        targetDate: _targetDate,
                      ));
                    });
                    Navigator.pop(context);
                  },
                  child: Text('Add'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFE91E63),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  UserProfile _getCurrentUserProfile() {
    return UserProfile(
      height: _height,
      weight: _weight,
      age: _age,
      gender: _gender,
      activityLevel: _activityLevel,
      goals: _goals,
      healthConditions: _healthConditions,
      availableEquipment: _availableEquipment,
      timeAvailability: _timeAvailability,
      fitnessLevel: _fitnessLevel,
      preferences: _preferences,
    );
  }

  void _generateAIResponse(String userMessage) {
    Future.delayed(Duration(seconds: 1), () {
      String response = '';
      final lowerMessage = userMessage.toLowerCase();
      final profile = _getCurrentUserProfile();

      if (lowerMessage.contains('recommend') || lowerMessage.contains('suggest')) {
        response = _generateWorkoutRecommendation(profile);
      } else if (lowerMessage.contains('change') || lowerMessage.contains('modify')) {
        response = _generateModificationResponse(profile, lowerMessage);
      } else if (lowerMessage.contains('explain') || lowerMessage.contains('how to')) {
        response = _generateExerciseExplanation(lowerMessage);
      } else if (lowerMessage.contains('progress') || lowerMessage.contains('track')) {
        response = _generateProgressTrackingResponse(profile);
      } else {
        response = _generateGeneralResponse(profile);
      }

      setState(() {
        _messages.add(Message(
          text: response,
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
      _scrollToBottom();
    });
  }

  String _generateWorkoutRecommendation(UserProfile profile) {
    String recommendation = 'Based on your profile, here\'s a personalized workout plan:\n\n';
    
    // Weekly schedule
    recommendation += '📅 Weekly Schedule:\n';
    for (int i = 0; i < profile.timeAvailability.daysPerWeek; i++) {
      recommendation += '• Day ${i + 1}: ${_generateDayWorkout(profile, i)}\n';
    }
    
    // Intensity guidelines
    recommendation += '\n💪 Intensity Guidelines:\n';
    recommendation += _getIntensityGuidelines(profile.fitnessLevel);
    
    // Equipment usage
    if (profile.availableEquipment.isNotEmpty) {
      recommendation += '\n🔧 Equipment Focus:\n';
      recommendation += '• ${profile.availableEquipment.join(", ")}\n';
    }
    
    // Health considerations
    if (profile.healthConditions.isNotEmpty) {
      recommendation += '\n⚕️ Modifications for Your Health:\n';
      for (var condition in profile.healthConditions) {
        recommendation += '• ${_getHealthModification(condition)}\n';
      }
    }
    
    recommendation += '\nWould you like me to explain any of these exercises in detail?';
    return recommendation;
  }

  String _generateDayWorkout(UserProfile profile, int dayIndex) {
    final workouts = [
      'Full Body Strength',
      'Upper Body Focus',
      'Lower Body Power',
      'Core and Cardio',
      'Mobility and Recovery'
    ];
    return workouts[dayIndex % workouts.length];
  }

  String _getIntensityGuidelines(FitnessLevel level) {
    switch (level) {
      case FitnessLevel.beginner:
        return '• Start with 2-3 sets\n• 12-15 reps\n• 60-90 sec rest';
      case FitnessLevel.intermediate:
        return '• 3-4 sets\n• 8-12 reps\n• 45-60 sec rest';
      case FitnessLevel.advanced:
        return '• 4-5 sets\n• 6-12 reps\n• 30-45 sec rest';
    }
  }

  String _getHealthModification(String condition) {
    switch (condition) {
      case 'Back Pain':
        return 'Focus on core stability, avoid heavy loading';
      case 'Knee Issues':
        return 'Low-impact exercises, emphasis on form';
      case 'Shoulder Pain':
        return 'Modified push movements, band work';
      default:
        return 'Consult with healthcare provider for specific modifications';
    }
  }

  String _generateModificationResponse(UserProfile profile, String message) {
    if (message.contains('intensity')) {
      return 'I can adjust the intensity of your workouts. Would you like to:\n\n'
          '• Increase/decrease sets and reps\n'
          '• Modify rest periods\n'
          '• Change exercise difficulty\n\n'
          'Let me know your preference, and I\'ll update your plan accordingly.';
    } else if (message.contains('time')) {
      return 'I can optimize your workouts for different time constraints. Current schedule: '
          '${profile.timeAvailability.daysPerWeek}x per week, '
          '${profile.timeAvailability.minutesPerSession} mins/session.\n\n'
          'Would you like to:\n'
          '• Adjust workout duration\n'
          '• Change weekly frequency\n'
          '• Split workouts differently';
    } else {
      return 'I can help modify your plan. What specific aspect would you like to change?\n\n'
          '• Exercise selection\n'
          '• Workout intensity\n'
          '• Schedule/timing\n'
          '• Equipment usage';
    }
  }

  String _generateExerciseExplanation(String message) {
    // Add exercise explanations based on common queries
    return 'Here\'s a detailed breakdown of the exercise:\n\n'
           '1. Starting position\n'
           '2. Movement pattern\n'
           '3. Breathing technique\n'
           '4. Common mistakes to avoid\n'
           '5. Variations and progressions\n\n'
           'Would you like me to explain another exercise?';
  }

  String _generateProgressTrackingResponse(UserProfile profile) {
    return 'Based on your goals, here\'s what you should track:\n\n'
           '📊 Weekly Measurements:\n'
           '• Weight: ${profile.weight} kg\n'
           '• Body measurements\n'
           '• Progress photos\n\n'
           '💪 Workout Tracking:\n'
           '• Exercise weights/reps\n'
           '• Workout completion\n'
           '• Energy levels\n\n'
           'Would you like me to set up specific tracking reminders?';
  }

  String _generateGeneralResponse(UserProfile profile) {
    return 'I\'m here to help optimize your fitness journey. I can assist with:\n\n'
           '• Workout recommendations\n'
           '• Exercise technique\n'
           '• Plan modifications\n'
           '• Progress tracking\n'
           '• Recovery strategies\n\n'
           'What specific aspect would you like to discuss?';
  }

  Widget _buildChatInterface() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final message = _messages[index];
              return _buildMessageBubble(message);
            },
          ),
        ),
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            boxShadow: [
              BoxShadow(
                offset: Offset(0, -2),
                blurRadius: 4,
                color: Colors.black12,
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Ask me anything about your workout plan...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: _sendMessage,
                  child: Icon(Icons.send),
                  mini: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(Message message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: message.isUser ? Theme.of(context).primaryColor : Colors.grey[800],
          borderRadius: BorderRadius.circular(16),
        ),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(height: 4),
            Text(
              '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
            ),
          ),
        ],
        ),
      ),
    );
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      _messages.add(Message(
        text: _messageController.text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
    });

    // Simulate AI response
    _generateAIResponse(_messageController.text);
    _messageController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      final profile = UserProfile(
        height: _height,
        weight: _weight,
        age: _age,
        gender: _gender,
        activityLevel: _activityLevel,
        goals: _goals,
        healthConditions: _healthConditions,
        availableEquipment: _availableEquipment,
        timeAvailability: _timeAvailability,
        fitnessLevel: _fitnessLevel,
        preferences: _preferences,
      );

      // Generate workout plan using provider
      final workoutProvider = Provider.of<WorkoutProvider>(context, listen: false);
      workoutProvider.generateWorkoutPlan(profile);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Training plan generated and added to your schedule!'),
          backgroundColor: Color(0xFFE91E63),
          action: SnackBarAction(
            label: 'View Plan',
            textColor: Colors.white,
            onPressed: () {
              // Navigate to workout tab
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => MainNavigationScreen(initialIndex: 0),
                ),
              );
            },
          ),
        ),
      );
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
} 
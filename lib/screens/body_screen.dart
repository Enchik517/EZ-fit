import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/body_measurement.dart';
import '../providers/workout_provider.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class BodyScreen extends StatefulWidget {
  const BodyScreen({Key? key}) : super(key: key);

  @override
  State<BodyScreen> createState() => _BodyScreenState();
}

class _BodyScreenState extends State<BodyScreen> {
  String _selectedMeasurement = 'Weight';
  int _selectedTimeRange = 30; // days
  bool _showChart = true;
  List<dynamic> exercises = [];
  List<dynamic> filteredExercises = [];
  String selectedDifficulty = 'All';
  String selectedMuscleGroup = 'All';
  String selectedEquipment = 'All';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadExercises();
  }

  Future<void> loadExercises() async {
    try {
      final String jsonString = await rootBundle.loadString('exercise.json');
      setState(() {
        exercises = json.decode(jsonString);
        filteredExercises = exercises;
        isLoading = false;
      });
    } catch (e) {
      //      setState(() {
        isLoading = false;
      });
    }
  }

  void filterExercises() {
    setState(() {
      filteredExercises = exercises.where((exercise) {
        bool matchesDifficulty = selectedDifficulty == 'All' || 
                                exercise['difficultyLevel'] == selectedDifficulty;
        bool matchesMuscle = selectedMuscleGroup == 'All' || 
                            exercise['muscleGroup'].toString().contains(selectedMuscleGroup);
        bool matchesEquipment = selectedEquipment == 'All' || 
                               exercise['equipment'].toString().contains(selectedEquipment);
        return matchesDifficulty && matchesMuscle && matchesEquipment;
      }).toList();

      // Используем AI для создания оптимальной тренировки из отфильтрованных упражнений
      if (filteredExercises.length > 10) {
        // Выбираем случайные 5-10 упражнений для тренировки
        filteredExercises.shuffle();
        filteredExercises = filteredExercises.take(5 + (DateTime.now().millisecond % 6)).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Body Measurements'),
        actions: [
          IconButton(
            icon: Icon(_showChart ? Icons.list : Icons.show_chart),
            onPressed: () => setState(() => _showChart = !_showChart),
          ),
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _showAddMeasurementDialog(context),
          ),
        ],
      ),
      body: Consumer<WorkoutProvider>(
        builder: (context, provider, child) {
          final latestMeasurement = provider.getLatestMeasurement();
          final measurements = provider.getMeasurementHistory(_selectedMeasurement, days: _selectedTimeRange);

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          FilterChip(
                            label: Text('Beginner'),
                            selected: selectedDifficulty == 'Beginner',
                            onSelected: (selected) {
                              setState(() {
                                selectedDifficulty = selected ? 'Beginner' : 'All';
                                filterExercises();
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            label: Text('Intermediate'),
                            selected: selectedDifficulty == 'Intermediate',
                            onSelected: (selected) {
                              setState(() {
                                selectedDifficulty = selected ? 'Intermediate' : 'All';
                                filterExercises();
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            label: Text('Advanced'),
                            selected: selectedDifficulty == 'Advanced',
                            onSelected: (selected) {
                              setState(() {
                                selectedDifficulty = selected ? 'Advanced' : 'All';
                                filterExercises();
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          FilterChip(
                            label: Text('Chest'),
                            selected: selectedMuscleGroup == 'Chest',
                            onSelected: (selected) {
                              setState(() {
                                selectedMuscleGroup = selected ? 'Chest' : 'All';
                                filterExercises();
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            label: Text('Back'),
                            selected: selectedMuscleGroup == 'Back',
                            onSelected: (selected) {
                              setState(() {
                                selectedMuscleGroup = selected ? 'Back' : 'All';
                                filterExercises();
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            label: Text('Legs'),
                            selected: selectedMuscleGroup == 'Legs',
                            onSelected: (selected) {
                              setState(() {
                                selectedMuscleGroup = selected ? 'Legs' : 'All';
                                filterExercises();
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            label: Text('Core'),
                            selected: selectedMuscleGroup == 'Core',
                            onSelected: (selected) {
                              setState(() {
                                selectedMuscleGroup = selected ? 'Core' : 'All';
                                filterExercises();
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (_showChart) _buildTimeRangeSelector(),
              if (_showChart && measurements['values']!.isNotEmpty)
                Container(
                  height: 300,
                  padding: EdgeInsets.all(16),
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: true),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                              return Text('${date.day}/${date.month}');
                            },
                          ),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: true),
                      lineBarsData: [
                        LineChartBarData(
                          spots: List.generate(
                            measurements['dates']!.length,
                            (index) => FlSpot(
                              measurements['dates']![index],
                              measurements['values']![index],
                            ),
                          ),
                          isCurved: true,
                          color: Theme.of(context).primaryColor,
                          barWidth: 3,
                          dotData: FlDotData(show: true),
                        ),
                      ],
                    ),
                  ),
                ),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        itemCount: filteredExercises.length,
                        itemBuilder: (context, index) {
                          final exercise = filteredExercises[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: ListTile(
                              title: Text(exercise['name']),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(exercise['description']),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Muscle Groups: ${exercise['muscleGroup']}',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.secondary,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Chip(
                                label: Text(exercise['difficultyLevel']),
                                backgroundColor: _getDifficultyColor(exercise['difficultyLevel']),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMeasurementSelector() {
    return Container(
      padding: EdgeInsets.all(16),
      child: DropdownButtonFormField<String>(
        value: _selectedMeasurement,
        decoration: InputDecoration(
          labelText: 'Measurement',
          border: OutlineInputBorder(),
        ),
        items: ['Weight', ...BodyMeasurement.defaultMeasurements].map((name) {
          return DropdownMenuItem(
            value: name,
            child: Text(name),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            setState(() {
              _selectedMeasurement = value;
            });
          }
        },
      ),
    );
  }

  Widget _buildTimeRangeSelector() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonFormField<int>(
        value: _selectedTimeRange,
        decoration: InputDecoration(
          labelText: 'Time Range',
          border: OutlineInputBorder(),
        ),
        items: [7, 30, 90, 180, 365].map((days) {
          return DropdownMenuItem(
            value: days,
            child: Text('$days days'),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            setState(() {
              _selectedTimeRange = value;
            });
          }
        },
      ),
    );
  }

  void _showAddMeasurementDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    double? weight;
    Map<String, double> measurements = {};

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Measurement'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Weight (kg)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your weight';
                    }
                    final number = double.tryParse(value);
                    if (number == null || number <= 0) {
                      return 'Please enter a valid weight';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    weight = double.tryParse(value ?? '');
                  },
                ),
                SizedBox(height: 16),
                ...BodyMeasurement.defaultMeasurements.map((name) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: TextFormField(
                      decoration: InputDecoration(
                        labelText: '$name (cm)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onSaved: (value) {
                        final number = double.tryParse(value ?? '');
                        if (number != null) {
                          measurements[name] = number;
                        }
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                formKey.currentState?.save();
                if (weight != null) {
                  final measurement = BodyMeasurement(
                    date: DateTime.now(),
                    weight: weight!,
                    measurements: measurements,
                  );
                  context.read<WorkoutProvider>().addBodyMeasurement(measurement);
                  Navigator.pop(context);
                }
              }
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'Beginner':
        return Colors.green.withOpacity(0.2);
      case 'Intermediate':
        return Colors.orange.withOpacity(0.2);
      case 'Advanced':
        return Colors.red.withOpacity(0.2);
      default:
        return Colors.grey.withOpacity(0.2);
    }
  }
} 
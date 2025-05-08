import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/exercise.dart';
import '../providers/workout_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class MyStatsScreen extends StatefulWidget {
  const MyStatsScreen({Key? key}) : super(key: key);

  @override
  State<MyStatsScreen> createState() => _MyStatsScreenState();
}

class _MyStatsScreenState extends State<MyStatsScreen> with SingleTickerProviderStateMixin {
  // Главные группы мышц, которые отслеживаем
  final List<String> _muscleGroups = ['chest', 'back', 'arms', 'shoulders', 'abs', 'legs'];
  
  // Данные о тренировках мышц
  Map<String, int> _muscleTrainingCounts = {};
  
  // Данные о весах для каждой группы мышц
  Map<String, List<MuscleWeightData>> _muscleWeightData = {};
  Map<String, double> _maxWeightByMuscle = {};
  Map<String, double> _averageWeightByMuscle = {};
  
  // Данные о выполненных тренировках
  List<Map<String, dynamic>> _recentWorkouts = [];
  Map<String, List<String>> _workoutsByMuscle = {};
  
  bool _isLoading = true;
  int _daysSinceLastWorkout = 0;
  int _totalWorkouts = 0;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _muscleGroups.forEach((muscle) {
      _muscleTrainingCounts[muscle] = 0;
      _workoutsByMuscle[muscle] = [];
      _muscleWeightData[muscle] = [];
      _maxWeightByMuscle[muscle] = 0;
      _averageWeightByMuscle[muscle] = 0;
    });
    
    // Загружаем данные при инициализации
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadWorkoutData();
    });
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Слушаем изменения в провайдере тренировок для автоматического обновления
    final workoutProvider = Provider.of<WorkoutProvider>(context, listen: false);
    workoutProvider.addListener(_onWorkoutUpdated);
  }
  
  @override
  void dispose() {
    // Удаляем слушатель при закрытии экрана
    final workoutProvider = Provider.of<WorkoutProvider>(context, listen: false);
    workoutProvider.removeListener(_onWorkoutUpdated);
    
    _tabController.dispose();
    super.dispose();
  }
  
  // Вызывается при изменении данных тренировки
  void _onWorkoutUpdated() {
    if (mounted) {
      _loadWorkoutData();
    }
  }

  Future<void> _loadWorkoutData() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      
      //      
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }
      
      // Получаем логи тренировок с расширенной информацией
      final workoutLogs = await supabase
          .from('workout_logs')
          .select('*, workout:workout_id(*)')
          .eq('user_id', userId)
          .order('workout_date', ascending: false)
          .limit(20); // Ограничиваем запрос для производительности
          
      //          
      // Сохраняем последние тренировки для отображения
      _recentWorkouts = workoutLogs.length > 5 
          ? workoutLogs.sublist(0, 5) 
          : List<Map<String, dynamic>>.from(workoutLogs);
      
      // Вычисляем дни с последней тренировки и общее количество тренировок
      _totalWorkouts = workoutLogs.length;
      if (workoutLogs.isNotEmpty) {
        final lastWorkoutDate = DateTime.parse(workoutLogs[0]['workout_date']);
        final now = DateTime.now();
        _daysSinceLastWorkout = now.difference(lastWorkoutDate).inDays;
      }
      
      // Инициализируем структуры данных для весов
      Map<String, List<MuscleWeightData>> muscleWeightData = {};
      Map<String, double> maxWeightByMuscle = {};
      Map<String, double> averageWeightByMuscle = {};
      
      _muscleGroups.forEach((muscle) {
        muscleWeightData[muscle] = [];
        maxWeightByMuscle[muscle] = 0;
        averageWeightByMuscle[muscle] = 0;
      });
      
      // Получаем историю упражнений с детальной информацией
      final exerciseHistory = await supabase
          .from('exercise_history')
          .select('*, exercise:exercise_id(*), workout_log_id(*), weight, reps')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(100);
      
      //      
      // Обрабатываем данные для каждого упражнения и группируем по группам мышц
      Map<String, int> muscleCounts = {};
      Map<String, List<String>> workoutsByMuscle = {};
      
      _muscleGroups.forEach((muscle) {
        muscleCounts[muscle] = 0;
        workoutsByMuscle[muscle] = [];
      });
      
      for (final record in exerciseHistory) {
        final exerciseData = record['exercise'] as Map<String, dynamic>?;
        final workoutLogData = record['workout_log_id'] as Map<String, dynamic>?;
        
        if (exerciseData == null) {
          //          continue;
        }
        
        final muscleGroup = exerciseData['muscleGroup']?.toString().toLowerCase() ?? '';
        final workoutName = workoutLogData?['workout']?['name'] ?? 'Unknown Workout';
        final exerciseName = exerciseData['name'] ?? 'Unknown Exercise';
        
        // Получаем данные о весе и повторениях
        final weight = record['weight'] is num ? (record['weight'] as num).toDouble() : 0.0;
        final reps = record['reps'] is num ? (record['reps'] as num).toInt() : 0;
        final date = DateTime.parse(record['created_at'].toString());
        
        //        
        // Проверяем и увеличиваем счетчик для соответствующей группы мышц
        String targetMuscle = _getMuscleGroupFromExercise(muscleGroup, exerciseName);
        
        if (targetMuscle.isNotEmpty) {
          muscleCounts[targetMuscle] = (muscleCounts[targetMuscle] ?? 0) + 1;
          
          // Добавляем название тренировки в список для этой группы мышц,
          // избегая дубликатов
          if (!workoutsByMuscle[targetMuscle]!.contains(workoutName)) {
            workoutsByMuscle[targetMuscle]!.add(workoutName);
          }
          
          // Сохраняем данные о весе
          if (weight > 0) {
            muscleWeightData[targetMuscle]!.add(MuscleWeightData(
              date: date,
              weight: weight,
              reps: reps,
              exerciseName: exerciseName
            ));
            
            // Обновляем максимальный вес
            if (weight > (maxWeightByMuscle[targetMuscle] ?? 0)) {
              maxWeightByMuscle[targetMuscle] = weight;
            }
          }
        }
      }
      
      // Получаем выполненные упражнения из таблицы completed_exercises
      final completedExercises = await supabase
          .from('completed_exercises')
          .select('*, exercise:exercise_id(*), workout_log:workout_log_id(*), weight, reps')
          .eq('user_id', userId)
          .order('completed_at', ascending: false)
          .limit(100);
      
      //      
      for (final record in completedExercises) {
        final exerciseData = record['exercise'] as Map<String, dynamic>?;
        final workoutLogData = record['workout_log'] as Map<String, dynamic>?;
        
        if (exerciseData == null) {
          //          continue;
        }
        
        final muscleGroup = exerciseData['muscleGroup']?.toString().toLowerCase() ?? '';
        final exerciseName = exerciseData['name'] ?? 'Unknown Exercise';
        final workoutId = workoutLogData?['workout_id'];
        
        // Получаем данные о весе и повторениях
        final weight = record['weight'] is num ? (record['weight'] as num).toDouble() : 0.0;
        final reps = record['reps'] is num ? (record['reps'] as num).toInt() : 0;
        final date = DateTime.parse(record['completed_at'].toString());
        
        // Получаем данные о тренировке, если есть workout_id
        String workoutName = 'Unknown Workout';
        if (workoutId != null) {
          try {
            final workout = await supabase
                .from('workouts')
                .select('name')
                .eq('id', workoutId)
                .single();
            workoutName = workout['name'] ?? 'Unknown Workout';
          } catch (e) {
            //          }
        }
        
        //        
        // Определяем группу мышц из названия упражнения и группы мышц
        String targetMuscle = _getMuscleGroupFromExercise(muscleGroup, exerciseName);
        
        if (targetMuscle.isNotEmpty) {
          muscleCounts[targetMuscle] = (muscleCounts[targetMuscle] ?? 0) + 1;
          
          // Добавляем название тренировки в список для этой группы мышц,
          // избегая дубликатов
          if (!workoutsByMuscle[targetMuscle]!.contains(workoutName)) {
            workoutsByMuscle[targetMuscle]!.add(workoutName);
          }
          
          // Сохраняем данные о весе
          if (weight > 0) {
            muscleWeightData[targetMuscle]!.add(MuscleWeightData(
              date: date,
              weight: weight,
              reps: reps,
              exerciseName: exerciseName
            ));
            
            // Обновляем максимальный вес
            if (weight > (maxWeightByMuscle[targetMuscle] ?? 0)) {
              maxWeightByMuscle[targetMuscle] = weight;
            }
          }
        }
      }
      
      // Вычисляем средний вес для каждой группы мышц
      _muscleGroups.forEach((muscle) {
        if (muscleWeightData[muscle]!.isNotEmpty) {
          double totalWeight = 0;
          for (var data in muscleWeightData[muscle]!) {
            totalWeight += data.weight;
          }
          averageWeightByMuscle[muscle] = totalWeight / muscleWeightData[muscle]!.length;
        }
      });
      
      // Проверим загруженные данные
      _muscleGroups.forEach((muscle) {
        //      });
      
      if (mounted) {
        setState(() {
          _muscleTrainingCounts = muscleCounts;
          _workoutsByMuscle = workoutsByMuscle;
          _muscleWeightData = muscleWeightData;
          _maxWeightByMuscle = maxWeightByMuscle;
          _averageWeightByMuscle = averageWeightByMuscle;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      //      //      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  // Вспомогательный метод для определения группы мышц из названия упражнения и группы мышц
  String _getMuscleGroupFromExercise(String muscleGroup, String exerciseName) {
    final muscleGroupLower = muscleGroup.toLowerCase();
    final exerciseNameLower = exerciseName.toLowerCase();
    
    // Сначала проверяем по muscleGroup
    if (muscleGroupLower.contains('chest') || muscleGroupLower.contains('pec')) {
      return 'chest';
    } else if (muscleGroupLower.contains('back') || muscleGroupLower.contains('lat') || 
              muscleGroupLower.contains('trap') || muscleGroupLower.contains('rhomboid')) {
      return 'back';
    } else if (muscleGroupLower.contains('arm') || muscleGroupLower.contains('bicep') || 
              muscleGroupLower.contains('tricep')) {
      return 'arms';
    } else if (muscleGroupLower.contains('ab') || muscleGroupLower.contains('core') || 
              muscleGroupLower.contains('oblique')) {
      return 'abs';
    } else if (muscleGroupLower.contains('leg') || muscleGroupLower.contains('quad') || 
              muscleGroupLower.contains('hamstring') || muscleGroupLower.contains('calf') || 
              muscleGroupLower.contains('glute')) {
      return 'legs';
    } else if (muscleGroupLower.contains('shoulder') || muscleGroupLower.contains('delt')) {
      return 'shoulders';
    }
    
    // Если не нашли по muscleGroup, проверяем по названию упражнения
    if (exerciseNameLower.contains('bench') || exerciseNameLower.contains('chest') || 
        exerciseNameLower.contains('pec') || exerciseNameLower.contains('fly')) {
      return 'chest';
    } else if (exerciseNameLower.contains('row') || exerciseNameLower.contains('pull') || 
              exerciseNameLower.contains('deadlift') || exerciseNameLower.contains('lat') || 
              exerciseNameLower.contains('back')) {
      return 'back';
    } else if (exerciseNameLower.contains('curl') || exerciseNameLower.contains('extension') || 
              exerciseNameLower.contains('bicep') || exerciseNameLower.contains('tricep') || 
              exerciseNameLower.contains('arm')) {
      return 'arms';
    } else if (exerciseNameLower.contains('crunch') || exerciseNameLower.contains('sit') || 
              exerciseNameLower.contains('ab') || exerciseNameLower.contains('plank')) {
      return 'abs';
    } else if (exerciseNameLower.contains('squat') || exerciseNameLower.contains('leg') || 
              exerciseNameLower.contains('lunge') || exerciseNameLower.contains('calf') || 
              exerciseNameLower.contains('quad') || exerciseNameLower.contains('hamstring')) {
      return 'legs';
    } else if (exerciseNameLower.contains('shoulder') || exerciseNameLower.contains('press') || 
              exerciseNameLower.contains('military') || exerciseNameLower.contains('delt') || 
              exerciseNameLower.contains('raise')) {
      return 'shoulders';
    }
    
    // Если не смогли определить группу мышц
    //    return '';
  }
  
  // Получаем отображаемое имя группы мышц
  String _getMuscleDisplayName(String muscle) {
    switch (muscle) {
      case 'chest': return 'Chest';
      case 'back': return 'Back';
      case 'arms': return 'Arms';
      case 'shoulders': return 'Shoulders';
      case 'abs': return 'Abs';
      case 'legs': return 'Legs';
      default: return muscle;
    }
  }
  
  // Получаем цвет для группы мышц
  Color _getMuscleColor(int count) {
    if (count == 0) return Colors.grey.shade300;
    if (count < 5) return Colors.blue.shade300;
    if (count < 10) return Colors.blue.shade600;
    if (count < 20) return Colors.orange.shade300;
    if (count < 30) return Colors.orange.shade600;
    return Colors.red.shade500;
  }

  void _showMuscleStatsDialog(String muscle) {
    final count = _muscleTrainingCounts[muscle] ?? 0;
    final displayName = _getMuscleDisplayName(muscle);
    final workouts = _workoutsByMuscle[muscle] ?? [];
    final maxWeight = _maxWeightByMuscle[muscle] ?? 0;
    final avgWeight = _averageWeightByMuscle[muscle] ?? 0;
    final weightData = _muscleWeightData[muscle] ?? [];
    
    // Сортируем данные по весу (убывание) и берем топ 5
    weightData.sort((a, b) => b.weight.compareTo(a.weight));
    final topWeightData = weightData.take(5).toList();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '$displayName Stats',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatItem(label: 'Total exercises', value: count.toString()),
            if (maxWeight > 0) ...[
              const SizedBox(height: 8),
              _StatItem(
                label: 'Max weight', 
                value: '${maxWeight.toStringAsFixed(1)} kg',
              ),
            ],
            if (avgWeight > 0) ...[
              const SizedBox(height: 8),
              _StatItem(
                label: 'Average weight', 
                value: '${avgWeight.toStringAsFixed(1)} kg',
              ),
            ],
            const SizedBox(height: 16),
            Text(
              count == 0 
                  ? 'You haven\'t trained this muscle group yet.' 
                  : count < 10 
                      ? 'This muscle group needs more training.'
                      : 'This muscle group is well-trained!',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: _getMuscleColor(count)
              ),
            ),
            if (topWeightData.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                'Top weight exercises:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 8),
              ...topWeightData.map((data) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(
                        children: [
                          Icon(Icons.fitness_center, 
                            size: 16, 
                            color: _getMuscleColor(count),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              data.exerciseName,
                              style: const TextStyle(
                                color: Colors.white70
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${data.weight.toStringAsFixed(1)} kg × ${data.reps}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getMuscleColor(count),
                      ),
                    ),
                  ],
                ),
              )),
            ],
            if (workouts.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                'Trained in workouts:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 8),
              ...workouts.map((workout) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(Icons.fitness_center, 
                      size: 16, 
                      color: _getMuscleColor(count),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        workout,
                        style: const TextStyle(
                          color: Colors.white70
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )).take(5), // Показываем только первые 5 тренировок
              if (workouts.length > 5)
                const Text('...and more', 
                  style: TextStyle(
                    color: Colors.white54,
                    fontStyle: FontStyle.italic,
                    fontSize: 12,
                  ),
                ),
            ],
          ],
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A), // Dark background
      appBar: AppBar(
        title: const Text('My Stats', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFF222222), // Dark app bar
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadWorkoutData,
            tooltip: 'Refresh data',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).primaryColor,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.person), text: 'Body Map'),
            Tab(icon: Icon(Icons.bar_chart), text: 'Progress'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Body Map View
                BodyMapView(
                  muscleTrainingCounts: _muscleTrainingCounts,
                  onMuscleTap: _showMuscleStatsDialog,
                  isLoading: _isLoading,
                ),
                // Tab 2: Progress View
                ProgressView(
                  muscleTrainingCounts: _muscleTrainingCounts,
                  maxWeightByMuscle: _maxWeightByMuscle,
                  averageWeightByMuscle: _averageWeightByMuscle,
                  onMuscleTap: _showMuscleStatsDialog,
                  recentWorkouts: _recentWorkouts,
                ),
              ],
            ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  
  const _StatItem({Key? key, required this.label, required this.value}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white70,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class BodyMapView extends StatelessWidget {
  final Map<String, int> muscleTrainingCounts;
  final Function(String) onMuscleTap;
  final bool isLoading;

  const BodyMapView({
    Key? key,
    required this.muscleTrainingCounts,
    required this.onMuscleTap,
    required this.isLoading,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        if (isLoading)
          const Center(
            child: CircularProgressIndicator(),
          )
        else
          InteractiveBodyMap(
            chestColor: _getMuscleColor(muscleTrainingCounts['chest'] ?? 0),
            backColor: _getMuscleColor(muscleTrainingCounts['back'] ?? 0),
            armsColor: _getMuscleColor(muscleTrainingCounts['arms'] ?? 0),
            shouldersColor: _getMuscleColor(muscleTrainingCounts['shoulders'] ?? 0),
            absColor: _getMuscleColor(muscleTrainingCounts['abs'] ?? 0),
            legsColor: _getMuscleColor(muscleTrainingCounts['legs'] ?? 0),
            onMuscleTap: onMuscleTap,
          ),
        
        const SizedBox(height: 24),
        
        // Add training level legend
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Training Levels',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _TrainingLevelIndicator(
                    color: Colors.grey.shade300,
                    label: 'Not Trained',
                    labelColor: Colors.white70,
                  ),
                  _TrainingLevelIndicator(
                    color: Colors.blue.shade300,
                    label: 'Beginner',
                    labelColor: Colors.white70,
                  ),
                  _TrainingLevelIndicator(
                    color: Colors.blue.shade600,
                    label: 'Intermediate',
                    labelColor: Colors.white70,
                  ),
                  _TrainingLevelIndicator(
                    color: Colors.orange.shade300,
                    label: 'Advanced',
                    labelColor: Colors.white70,
                  ),
                  _TrainingLevelIndicator(
                    color: Colors.orange.shade600,
                    label: 'Expert',
                    labelColor: Colors.white70,
                  ),
                  _TrainingLevelIndicator(
                    color: Colors.red.shade500,
                    label: 'Master',
                    labelColor: Colors.white70,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Color _getMuscleColor(int count) {
    if (count == 0) return Colors.grey.shade300;
    if (count < 5) return Colors.blue.shade300;
    if (count < 10) return Colors.blue.shade600;
    if (count < 20) return Colors.orange.shade300;
    if (count < 30) return Colors.orange.shade600;
    return Colors.red.shade500;
  }
}

class _TrainingLevelIndicator extends StatelessWidget {
  final Color color;
  final String label;
  final Color labelColor;

  const _TrainingLevelIndicator({
    Key? key,
    required this.color,
    required this.label,
    this.labelColor = Colors.black87,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: labelColor),
        ),
      ],
    );
  }
}

class InteractiveBodyMap extends StatelessWidget {
  final Color chestColor;
  final Color backColor;
  final Color armsColor;
  final Color shouldersColor;
  final Color absColor;
  final Color legsColor;
  final Function(String) onMuscleTap;

  const InteractiveBodyMap({
    Key? key,
    required this.chestColor,
    required this.backColor,
    required this.armsColor,
    required this.shouldersColor,
    required this.absColor,
    required this.legsColor,
    required this.onMuscleTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 400,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Front view
          Column(
            children: [
              const Text(
                'Front',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70),
              ),
              const SizedBox(height: 10),
              Stack(
                alignment: Alignment.center,
                children: [
                  // Body outline
                  Container(
                    width: 140,
                    height: 350,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: const Color(0xFF2A2A2A),
                    ),
                    child: CustomPaint(
                      painter: BodyOutlinePainter(isFront: true),
                      size: const Size(140, 350),
                    ),
                  ),
                  
                  // Muscles - chest
                  Positioned(
                    top: 100,
                    child: _MuscleHitbox(
                      color: chestColor,
                      width: 100,
                      height: 40,
                      onTap: () => onMuscleTap('chest'),
                    ),
                  ),
                  
                  // Muscles - abs
                  Positioned(
                    top: 150,
                    child: _MuscleHitbox(
                      color: absColor,
                      width: 60,
                      height: 80,
                      onTap: () => onMuscleTap('abs'),
                    ),
                  ),

                  // Muscles - arms (left)
                  Positioned(
                    top: 120,
                    left: 30,
                    child: _MuscleHitbox(
                      color: armsColor,
                      width: 30,
                      height: 80,
                      onTap: () => onMuscleTap('arms'),
                    ),
                  ),

                  // Muscles - arms (right)
                  Positioned(
                    top: 120,
                    right: 30,
                    child: _MuscleHitbox(
                      color: armsColor,
                      width: 30,
                      height: 80,
                      onTap: () => onMuscleTap('arms'),
                    ),
                  ),

                  // Muscles - shoulders (left)
                  Positioned(
                    top: 90,
                    left: 60,
                    child: _MuscleHitbox(
                      color: shouldersColor,
                      width: 30,
                      height: 30,
                      borderRadius: 15,
                      onTap: () => onMuscleTap('shoulders'),
                    ),
                  ),
                  
                  // Muscles - shoulders (right)
                  Positioned(
                    top: 90,
                    right: 60,
                    child: _MuscleHitbox(
                      color: shouldersColor,
                      width: 30,
                      height: 30,
                      borderRadius: 15,
                      onTap: () => onMuscleTap('shoulders'),
                    ),
                  ),
                  
                  // Muscles - legs
                  Positioned(
                    bottom: 30,
                    child: _MuscleHitbox(
                      color: legsColor,
                      width: 120,
                      height: 120,
                      onTap: () => onMuscleTap('legs'),
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          // Back view
          Column(
            children: [
              const Text(
                'Back',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70),
              ),
              const SizedBox(height: 10),
              Stack(
                alignment: Alignment.center,
                children: [
                  // Body outline
                  Container(
                    width: 140,
                    height: 350,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: const Color(0xFF2A2A2A),
                    ),
                    child: CustomPaint(
                      painter: BodyOutlinePainter(isFront: false),
                      size: const Size(140, 350),
                    ),
                  ),
                  
                  // Muscles - back
                  Positioned(
                    top: 120,
                    child: _MuscleHitbox(
                      color: backColor,
                      width: 100,
                      height: 80,
                      onTap: () => onMuscleTap('back'),
                    ),
                  ),
                  
                  // Muscles - shoulders (left)
                  Positioned(
                    top: 90,
                    left: 60,
                    child: _MuscleHitbox(
                      color: shouldersColor,
                      width: 30,
                      height: 30,
                      borderRadius: 15,
                      onTap: () => onMuscleTap('shoulders'),
                    ),
                  ),
                  
                  // Muscles - shoulders (right)
                  Positioned(
                    top: 90,
                    right: 60,
                    child: _MuscleHitbox(
                      color: shouldersColor,
                      width: 30,
                      height: 30,
                      borderRadius: 15,
                      onTap: () => onMuscleTap('shoulders'),
                    ),
                  ),
                  
                  // Muscles - arms (left)
                  Positioned(
                    top: 120,
                    left: 30,
                    child: _MuscleHitbox(
                      color: armsColor,
                      width: 30,
                      height: 80,
                      onTap: () => onMuscleTap('arms'),
                    ),
                  ),
                  
                  // Muscles - arms (right)
                  Positioned(
                    top: 120,
                    right: 30,
                    child: _MuscleHitbox(
                      color: armsColor,
                      width: 30,
                      height: 80,
                      onTap: () => onMuscleTap('arms'),
                    ),
                  ),
                  
                  // Muscles - legs
                  Positioned(
                    bottom: 30,
                    child: _MuscleHitbox(
                      color: legsColor,
                      width: 120,
                      height: 120,
                      onTap: () => onMuscleTap('legs'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class BodyOutlinePainter extends CustomPainter {
  final bool isFront;
  
  BodyOutlinePainter({required this.isFront});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white54
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
      
    final width = size.width;
    final height = size.height;
    
    final centerX = width / 2;
    
    final path = Path();
    
    if (isFront) {
      // Голова
      path.addOval(Rect.fromCenter(
        center: Offset(centerX, 40),
        width: 50,
        height: 50,
      ));
      
      // Тело
      path.moveTo(centerX - 25, 65);
      path.lineTo(centerX - 40, 130);
      path.lineTo(centerX - 30, 240);
      path.lineTo(centerX - 20, 250);
      
      path.lineTo(centerX - 25, height - 20);
      path.lineTo(centerX + 25, height - 20);
      
      path.lineTo(centerX + 20, 250);
      path.lineTo(centerX + 30, 240);
      path.lineTo(centerX + 40, 130);
      path.lineTo(centerX + 25, 65);
      path.close();
      
      // Руки
      // Левая рука
      path.moveTo(centerX - 40, 130);
      path.lineTo(centerX - 60, 200);
      
      // Правая рука
      path.moveTo(centerX + 40, 130);
      path.lineTo(centerX + 60, 200);
      
    } else {
      // Голова
      path.addOval(Rect.fromCenter(
        center: Offset(centerX, 40),
        width: 50,
        height: 50,
      ));
      
      // Тело (вид сзади)
      path.moveTo(centerX - 25, 65);
      path.lineTo(centerX - 40, 130);
      path.lineTo(centerX - 30, 240);
      path.lineTo(centerX - 20, 250);
      
      path.lineTo(centerX - 25, height - 20);
      path.lineTo(centerX + 25, height - 20);
      
      path.lineTo(centerX + 20, 250);
      path.lineTo(centerX + 30, 240);
      path.lineTo(centerX + 40, 130);
      path.lineTo(centerX + 25, 65);
      path.close();
      
      // Руки
      // Левая рука
      path.moveTo(centerX - 40, 130);
      path.lineTo(centerX - 60, 200);
      
      // Правая рука
      path.moveTo(centerX + 40, 130);
      path.lineTo(centerX + 60, 200);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(BodyOutlinePainter oldDelegate) => 
    oldDelegate.isFront != isFront;
}

class _MuscleHitbox extends StatelessWidget {
  final Color color;
  final double width;
  final double height;
  final double borderRadius;
  final VoidCallback onTap;

  const _MuscleHitbox({
    Key? key,
    required this.color,
    required this.width,
    required this.height,
    this.borderRadius = 8,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color.withOpacity(0.7),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class ProgressView extends StatelessWidget {
  final Map<String, int> muscleTrainingCounts;
  final Function(String) onMuscleTap;
  final List<Map<String, dynamic>> recentWorkouts;
  final Map<String, double> maxWeightByMuscle;
  final Map<String, double> averageWeightByMuscle;

  const ProgressView({
    Key? key,
    required this.muscleTrainingCounts,
    required this.onMuscleTap,
    this.recentWorkouts = const [],
    this.maxWeightByMuscle = const {},
    this.averageWeightByMuscle = const {},
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Сортируем мышцы по количеству тренировок (убыванию)
    final sortedMuscles = muscleTrainingCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Recent Workouts Section
        if (recentWorkouts.isNotEmpty) ...[
          const Text(
            'Recent Workouts',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          ...recentWorkouts.map((workout) => _RecentWorkoutCard(workout: workout)),
          const Divider(
            color: Color(0xFF3D3D3D),
            height: 40,
            thickness: 1,
          ),
        ],
        
        const Text(
          'Muscle Group Activity',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        ...sortedMuscles.map((entry) => _MuscleProgressCard(
          muscleKey: entry.key,
          muscleName: _getMuscleDisplayName(entry.key),
          count: entry.value,
          maxWeight: maxWeightByMuscle[entry.key] ?? 0,
          avgWeight: averageWeightByMuscle[entry.key] ?? 0,
          onTap: () => onMuscleTap(entry.key),
        )),
      ],
    );
  }
  
  String _getMuscleDisplayName(String muscle) {
    switch (muscle) {
      case 'chest': return 'Chest';
      case 'back': return 'Back';
      case 'arms': return 'Arms';
      case 'shoulders': return 'Shoulders';
      case 'abs': return 'Abs';
      case 'legs': return 'Legs';
      default: return muscle.substring(0, 1).toUpperCase() + muscle.substring(1);
    }
  }
}

class _RecentWorkoutCard extends StatelessWidget {
  final Map<String, dynamic> workout;
  
  const _RecentWorkoutCard({
    Key? key,
    required this.workout,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    // Extract workout data
    final workoutData = workout['workout'] as Map<String, dynamic>?;
    final workoutName = workoutData?['name'] ?? 'Unnamed Workout';
    final workoutDate = DateTime.parse(workout['workout_date'].toString());
    final formattedDate = DateFormat('yyyy-MM-dd').format(workoutDate);
    final exerciseCount = workout['exercises_completed'] ?? 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    workoutName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$exerciseCount exercises',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(width: 4),
                Text(
                  formattedDate,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade400,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.play_arrow_rounded,
                  color: Theme.of(context).primaryColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MuscleProgressCard extends StatelessWidget {
  final String muscleKey;
  final String muscleName;
  final int count;
  final VoidCallback onTap;
  final double maxWeight;
  final double avgWeight;
  
  const _MuscleProgressCard({
    Key? key,
    required this.muscleKey,
    required this.muscleName,
    required this.count,
    required this.onTap,
    this.maxWeight = 0,
    this.avgWeight = 0,
  }) : super(key: key);
  
  Color _getProgressColor() {
    if (count == 0) return Colors.grey;
    if (count < 5) return Colors.blue.shade300;
    if (count < 10) return Colors.blue.shade600;
    if (count < 20) return Colors.orange.shade300;
    if (count < 30) return Colors.orange.shade600;
    return Colors.red.shade500;
  }
  
  String _getStatusText() {
    if (count == 0) return "Not trained";
    if (count < 5) return "Beginner";
    if (count < 10) return "Intermediate";
    if (count < 20) return "Advanced";
    if (count < 30) return "Expert";
    return "Master";
  }
  
  IconData _getMuscleIcon() {
    switch (muscleKey) {
      case 'chest': return Icons.fitness_center;
      case 'back': return Icons.drag_handle;
      case 'arms': return Icons.front_hand;
      case 'shoulders': return Icons.swap_horiz;
      case 'abs': return Icons.grid_3x3;
      case 'legs': return Icons.directions_walk;
      default: return Icons.fitness_center;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _getProgressColor().withOpacity(0.2),
                    child: Icon(
                      _getMuscleIcon(),
                      color: _getProgressColor(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          muscleName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          _getStatusText(),
                          style: TextStyle(
                            color: _getProgressColor(),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getProgressColor().withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          "$count",
                          style: TextStyle(
                            color: _getProgressColor(),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (maxWeight > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          "Max: ${maxWeight.toStringAsFixed(1)} kg",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: count > 0 ? (count > 50 ? 1.0 : count / 50) : 0,
                  minHeight: 12,
                  backgroundColor: const Color(0xFF1A1A1A),
                  valueColor: AlwaysStoppedAnimation<Color>(_getProgressColor()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Модель для хранения данных о весе для мышечных групп
class MuscleWeightData {
  final DateTime date;
  final double weight;
  final int reps;
  final String exerciseName;
  
  MuscleWeightData({
    required this.date,
    required this.weight,
    required this.reps,
    required this.exerciseName,
  });
} 
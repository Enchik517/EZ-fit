import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/exercise.dart';
import '../services/exercise_rating_service.dart';

class DeveloperToolsScreen extends StatefulWidget {
  const DeveloperToolsScreen({Key? key}) : super(key: key);

  @override
  State<DeveloperToolsScreen> createState() => _DeveloperToolsScreenState();
}

class _DeveloperToolsScreenState extends State<DeveloperToolsScreen> {
  final ExerciseRatingService _ratingService = ExerciseRatingService();
  List<Exercise> _exercises = [];
  bool _isLoading = true;
  String _filterMuscleGroup = 'All';
  String _sortBy = 'Rating';
  bool _showOnlyFavorites = false;

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final exercises = await _ratingService.getExercisesWithRatings();
      setState(() {
        _exercises = exercises;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading exercises: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Exercise> _getFilteredExercises() {
    // Применяем фильтр по группе мышц
    List<Exercise> filtered = _filterMuscleGroup == 'All'
        ? List.from(_exercises)
        : _exercises
            .where((e) => e.muscleGroup == _filterMuscleGroup ||
                e.targetMuscleGroup == _filterMuscleGroup)
            .toList();

    // Фильтр по избранному
    if (_showOnlyFavorites) {
      filtered = filtered.where((e) => e.isFavorite).toList();
    }

    // Сортировка
    switch (_sortBy) {
      case 'Rating':
        filtered.sort((a, b) => b.calculateCurrentRating().compareTo(a.calculateCurrentRating()));
        break;
      case 'Name':
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'Usage Count':
        filtered.sort((a, b) => b.usageCount.compareTo(a.usageCount));
        break;
      case 'Last Used':
        filtered.sort((a, b) {
          if (a.lastUsed == null && b.lastUsed == null) return 0;
          if (a.lastUsed == null) return 1;
          if (b.lastUsed == null) return -1;
          return b.lastUsed!.compareTo(a.lastUsed!);
        });
        break;
    }

    return filtered;
  }

  List<String> _getUniqueMuscleGroups() {
    final Set<String> muscleGroups = {'All'};
    for (final exercise in _exercises) {
      muscleGroups.add(exercise.muscleGroup);
      muscleGroups.add(exercise.targetMuscleGroup);
    }
    return muscleGroups.toList()..sort();
  }

  Future<void> _resetExerciseRating(Exercise exercise) async {
    try {
      final updatedExercise = exercise.copyWith(
        baseRating: 50.0,
        userPreference: 0,
        usageCount: 0,
        lastUsed: null,
        isFavorite: false,
      );
      await _ratingService.updateExerciseRating(updatedExercise);
      await _loadExercises();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reset rating for ${exercise.name}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error resetting rating: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _weeklyRatingReset() async {
    try {
      await _ratingService.weeklyRatingReset();
      await _loadExercises();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Weekly rating reset completed'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error running weekly reset: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _markAsUsed(Exercise exercise) async {
    try {
      await _ratingService.markExerciseAsUsed(exercise);
      await _loadExercises();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Marked ${exercise.name} as used'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error marking as used: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updatePreference(Exercise exercise, int preference) async {
    try {
      await _ratingService.updateUserPreference(exercise, preference);
      await _loadExercises();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Updated preference for ${exercise.name}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating preference: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleFavorite(Exercise exercise) async {
    try {
      await _ratingService.toggleFavorite(exercise);
      await _loadExercises();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${exercise.name} ${exercise.isFavorite ? 'removed from' : 'added to'} favorites'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error toggling favorite: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showExerciseActions(Exercise exercise) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              exercise.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.refresh, color: Colors.white),
              title: const Text('Reset Rating', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _resetExerciseRating(exercise);
              },
            ),
            ListTile(
              leading: const Icon(Icons.fitness_center, color: Colors.white),
              title: const Text('Mark as Used', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _markAsUsed(exercise);
              },
            ),
            ListTile(
              leading: const Icon(Icons.thumb_up, color: Colors.green),
              title: const Text('Like (+1)', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _updatePreference(exercise, 1);
              },
            ),
            ListTile(
              leading: const Icon(Icons.thumb_down, color: Colors.orange),
              title: const Text('Dislike (-1)', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _updatePreference(exercise, -1);
              },
            ),
            ListTile(
              leading: const Icon(Icons.star, color: Colors.amber),
              title: Text(
                exercise.isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _toggleFavorite(exercise);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredExercises = _getFilteredExercises();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Developer Tools'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadExercises,
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Weekly Rating Reset'),
                  content: const Text(
                      'This will simulate the weekly rating reset process. Continue?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _weeklyRatingReset();
                      },
                      child: const Text('Run Reset'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Фильтры и сортировка
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Filters & Sorting',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              // Dropdown для фильтрации по группе мышц
                              Expanded(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: _filterMuscleGroup,
                                  hint: const Text('Muscle Group'),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        _filterMuscleGroup = value;
                                      });
                                    }
                                  },
                                  items: _getUniqueMuscleGroups()
                                      .map((muscleGroup) => DropdownMenuItem<String>(
                                            value: muscleGroup,
                                            child: Text(muscleGroup),
                                          ))
                                      .toList(),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Dropdown для сортировки
                              Expanded(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: _sortBy,
                                  hint: const Text('Sort By'),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        _sortBy = value;
                                      });
                                    }
                                  },
                                  items: const [
                                    DropdownMenuItem(value: 'Rating', child: Text('Rating')),
                                    DropdownMenuItem(value: 'Name', child: Text('Name')),
                                    DropdownMenuItem(
                                        value: 'Usage Count', child: Text('Usage Count')),
                                    DropdownMenuItem(
                                        value: 'Last Used', child: Text('Last Used')),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          // Checkbox для показа только избранных
                          Row(
                            children: [
                              Checkbox(
                                value: _showOnlyFavorites,
                                onChanged: (value) {
                                  setState(() {
                                    _showOnlyFavorites = value ?? false;
                                  });
                                },
                              ),
                              const Text('Show only favorites'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Статистика
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatCard(
                        title: 'Total Exercises',
                        value: _exercises.length.toString(),
                        icon: Icons.fitness_center,
                        color: Colors.blue,
                      ),
                      _buildStatCard(
                        title: 'Favorites',
                        value: _exercises.where((e) => e.isFavorite).length.toString(),
                        icon: Icons.star,
                        color: Colors.amber,
                      ),
                      _buildStatCard(
                        title: 'Used Exercises',
                        value: _exercises.where((e) => e.usageCount > 0).length.toString(),
                        icon: Icons.history,
                        color: Colors.green,
                      ),
                    ],
                  ),
                ),
                // Список упражнений
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredExercises.length,
                    itemBuilder: (context, index) {
                      final exercise = filteredExercises[index];
                      return _buildExerciseCard(exercise);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseCard(Exercise exercise) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final currentRating = exercise.calculateCurrentRating();
    
    Color ratingColor;
    if (currentRating < 30) {
      ratingColor = Colors.blue.shade400;
    } else if (currentRating < 50) {
      ratingColor = Colors.green.shade400;
    } else if (currentRating < 70) {
      ratingColor = Colors.amber.shade400;
    } else {
      ratingColor = Colors.red.shade400;
    }

    String preferenceText;
    IconData preferenceIcon;
    Color preferenceColor;
    
    if (exercise.userPreference > 0) {
      preferenceText = 'Liked';
      preferenceIcon = Icons.thumb_up;
      preferenceColor = Colors.green;
    } else if (exercise.userPreference < 0) {
      preferenceText = 'Disliked';
      preferenceIcon = Icons.thumb_down;
      preferenceColor = Colors.orange;
    } else {
      preferenceText = 'Neutral';
      preferenceIcon = Icons.remove_circle_outline;
      preferenceColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: () => _showExerciseActions(exercise),
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
                      exercise.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (exercise.isFavorite)
                    const Icon(Icons.star, color: Colors.amber, size: 20),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Muscle: ${exercise.muscleGroup}'),
                        Text('Equipment: ${exercise.equipment}'),
                        Text('Difficulty: ${exercise.difficultyLevel}'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(preferenceIcon, size: 16, color: preferenceColor),
                            const SizedBox(width: 4),
                            Text(preferenceText, style: TextStyle(color: preferenceColor)),
                          ],
                        ),
                        Text('Used: ${exercise.usageCount} times'),
                        if (exercise.lastUsed != null)
                          Text('Last used: ${dateFormat.format(exercise.lastUsed!)}'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Current Rating:'),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: currentRating / 100,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(ratingColor),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    currentRating.toStringAsFixed(1),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: ratingColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/exercise.dart';
import '../models/workout_log.dart';

class ExerciseHistoryScreen extends StatefulWidget {
  final Exercise exercise;

  const ExerciseHistoryScreen({
    Key? key,
    required this.exercise,
  }) : super(key: key);

  @override
  State<ExerciseHistoryScreen> createState() => _ExerciseHistoryScreenState();
}

class _ExerciseHistoryScreenState extends State<ExerciseHistoryScreen> {
  final _supabase = Supabase.instance.client;
  List<ExerciseHistoryEntry> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExerciseHistory();
  }

  Future<void> _loadExerciseHistory() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await _supabase
          .from('exercise_history')
          .select()
          .eq('user_id', userId)
          .eq('exercise_name', widget.exercise.name)
          .order('completed_at', ascending: false);

      setState(() {
        _history = (response as List)
            .map((record) => ExerciseHistoryEntry.fromJson(record))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      //      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          'Exercise History',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? Center(
                  child: Text(
                    'No history yet',
                    style: TextStyle(color: Colors.white),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: _history.length,
                  itemBuilder: (context, index) {
                    final entry = _history[index];
                    return Container(
                      margin: EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Color(0xFF252527),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.formattedDate,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 8),
                            ...entry.sets.map((set) => Padding(
                                  padding: EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    'Set ${set.setNumber}: ${set.reps} reps × ${set.weight} kg',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 14,
                                    ),
                                  ),
                                )),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class ExerciseHistoryEntry {
  final DateTime completedAt;
  final List<ExerciseSet> sets;

  ExerciseHistoryEntry({
    required this.completedAt,
    required this.sets,
  });

  String get formattedDate {
    return '${completedAt.day}/${completedAt.month}/${completedAt.year}';
  }

  factory ExerciseHistoryEntry.fromJson(Map<String, dynamic> json) {
    return ExerciseHistoryEntry(
      completedAt: DateTime.parse(json['completed_at']),
      sets: (json['sets'] as List)
          .map((set) => ExerciseSet.fromJson(set))
          .toList(),
    );
  }
}

class ExerciseSet {
  final int setNumber;
  final int reps;
  final double weight;

  ExerciseSet({
    required this.setNumber,
    required this.reps,
    required this.weight,
  });

  factory ExerciseSet.fromJson(Map<String, dynamic> json) {
    return ExerciseSet(
      setNumber: json['set_number'],
      reps: json['reps'],
      weight: json['weight'].toDouble(),
    );
  }
}

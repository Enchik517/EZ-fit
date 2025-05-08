import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class WorkoutDiagnosticsScreen extends StatefulWidget {
  const WorkoutDiagnosticsScreen({Key? key}) : super(key: key);

  @override
  _WorkoutDiagnosticsScreenState createState() =>
      _WorkoutDiagnosticsScreenState();
}

class _WorkoutDiagnosticsScreenState extends State<WorkoutDiagnosticsScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoading = false;
  List<Map<String, dynamic>> _workoutHistory = [];
  List<Map<String, dynamic>> _favoriteWorkouts = [];
  List<Map<String, dynamic>> _debugLogs = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _fetchWorkoutHistory();
      await _fetchFavoriteWorkouts();
      await _fetchDebugLogs();
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      if (kDebugMode) debugPrint('Failed to load diagnostic data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchWorkoutHistory() async {
    try {
      final response = await _supabase
          .from('workout_history')
          .select()
          .order('created_at', ascending: false);
      setState(() {
        _workoutHistory = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Failed to fetch workout history: $e');
      rethrow;
    }
  }

  Future<void> _fetchFavoriteWorkouts() async {
    try {
      final response = await _supabase
          .from('favorite_workouts')
          .select()
          .order('created_at', ascending: false);
      setState(() {
        _favoriteWorkouts = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Failed to fetch favorite workouts: $e');
      rethrow;
    }
  }

  Future<void> _fetchDebugLogs() async {
    try {
      final response = await _supabase
          .from('debug_logs')
          .select()
          .or('action.eq.workout_history_add,action.eq.favorite_workout_toggle,action.eq.error')
          .order('created_at', ascending: false)
          .limit(100);

      setState(() {
        _debugLogs = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Failed to fetch debug logs: $e');
      // Don't rethrow as this is not critical
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Diagnostics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : DefaultTabController(
                  length: 3,
                  child: Column(
                    children: [
                      const TabBar(
                        tabs: [
                          Tab(text: 'History'),
                          Tab(text: 'Favorites'),
                          Tab(text: 'Logs'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildWorkoutHistory(),
                            _buildFavoriteWorkouts(),
                            _buildDebugLogs(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildWorkoutHistory() {
    if (_workoutHistory.isEmpty) {
      return const Center(
        child: Text('No workout history found'),
      );
    }

    return ListView.builder(
      itemCount: _workoutHistory.length,
      itemBuilder: (context, index) {
        final item = _workoutHistory[index];
        return ListTile(
          title: Text(item['workout_name'] ?? 'Unknown Workout'),
          subtitle: Text('Created: ${_formatDate(item['created_at'])}'),
          trailing: Text('ID: ${_shortenId(item['workout_id'])}'),
          onTap: () => _showItemDetails(item, 'Workout History'),
        );
      },
    );
  }

  Widget _buildFavoriteWorkouts() {
    if (_favoriteWorkouts.isEmpty) {
      return const Center(
        child: Text('No favorite workouts found'),
      );
    }

    return ListView.builder(
      itemCount: _favoriteWorkouts.length,
      itemBuilder: (context, index) {
        final item = _favoriteWorkouts[index];
        return ListTile(
          title: Text(item['workout_name'] ?? 'Unknown Workout'),
          subtitle: Text('Added: ${_formatDate(item['created_at'])}'),
          trailing: Text('ID: ${_shortenId(item['workout_id'])}'),
          onTap: () => _showItemDetails(item, 'Favorite Workout'),
        );
      },
    );
  }

  Widget _buildDebugLogs() {
    if (_debugLogs.isEmpty) {
      return const Center(
        child: Text('No debug logs found'),
      );
    }

    return ListView.builder(
      itemCount: _debugLogs.length,
      itemBuilder: (context, index) {
        final log = _debugLogs[index];
        return ListTile(
          title: Text(log['action'] ?? 'Unknown Action'),
          subtitle:
              Text('${_formatDate(log['created_at'])}\n${log['details']}'),
          trailing: const Icon(Icons.info_outline),
        );
      },
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Unknown date';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
    } catch (e) {
      return dateStr;
    }
  }

  String _shortenId(String? id) {
    if (id == null) return 'N/A';
    return id.length > 8 ? '${id.substring(0, 8)}...' : id;
  }

  void _showItemDetails(Map<String, dynamic> item, String type) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$type Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: item.entries.map((entry) {
              final value = entry.value is Map || entry.value is List
                  ? const Text('[Complex object]',
                      style: TextStyle(fontStyle: FontStyle.italic))
                  : Text('${entry.value}');

              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${entry.key}:',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    value,
                    const Divider(),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

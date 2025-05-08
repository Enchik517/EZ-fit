import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/workout_provider.dart';

class StreakScreen extends StatelessWidget {
  const StreakScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final workoutProvider = Provider.of<WorkoutProvider>(context);
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Progress & Achievements',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Streak Circle
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFF9800),
                      Color(0xFFFF5722),
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${workoutProvider.workoutStreak}',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'DAY STREAK',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 32),

              // Statistics Section
              Text(
                'Statistics',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.fitness_center,
                      value: '${workoutProvider.totalWorkouts}',
                      label: 'Total\nWorkouts',
                      gradient: [Color(0xFF1A237E), Color(0xFF0D47A1)],
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.timer,
                      value: '${workoutProvider.totalHours.toStringAsFixed(1)}h',
                      label: 'Average\nDuration',
                      gradient: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 32),

              // Achievements Section
              Text(
                'Achievements',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              _buildAchievementCard(
                icon: Icons.star,
                title: 'First Steps',
                description: 'Complete your first workout',
                isUnlocked: workoutProvider.totalWorkouts > 0,
              ),
              SizedBox(height: 12),
              _buildAchievementCard(
                icon: Icons.local_fire_department,
                title: 'On Fire',
                description: 'Maintain a 7-day streak',
                isUnlocked: workoutProvider.workoutStreak >= 7,
              ),
              SizedBox(height: 12),
              _buildAchievementCard(
                icon: Icons.fitness_center,
                title: 'Dedicated',
                description: 'Complete 10 workouts',
                isUnlocked: workoutProvider.totalWorkouts >= 10,
              ),
              SizedBox(height: 12),
              _buildAchievementCard(
                icon: Icons.timer,
                title: 'Time Master',
                description: 'Accumulate 10 hours of training',
                isUnlocked: workoutProvider.totalHours >= 10,
              ),
              SizedBox(height: 12),
              _buildAchievementCard(
                icon: Icons.whatshot,
                title: 'Unstoppable',
                description: 'Maintain a 30-day streak',
                isUnlocked: workoutProvider.workoutStreak >= 30,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required List<Color> gradient,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementCard({
    required IconData icon,
    required String title,
    required String description,
    required bool isUnlocked,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF252527),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnlocked ? Colors.amber : Colors.grey[800]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isUnlocked ? Colors.amber : Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: isUnlocked ? Colors.black : Colors.grey,
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isUnlocked ? Colors.amber : Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (isUnlocked)
            Icon(
              Icons.check_circle,
              color: Colors.amber,
              size: 24,
            ),
        ],
      ),
    );
  }
} 
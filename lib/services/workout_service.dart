import '../models/workout.dart';
import '../models/exercise.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

class WorkoutService {
  static final _uuid = Uuid();

  static final List<Workout> workouts = [
    // Beginner workouts
    Workout(
      id: _uuid.v4(),
      name: 'Beginner Workout',
      description: 'Full-body strength (basic movements, bodyweight)',
      focus: 'Full-body strength',
      exercises: [
        Exercise.basic(
            name: 'Bodyweight Squats',
            sets: '3',
            reps: '12',
            targetMuscleGroup: 'Legs',
            equipment: 'none',
            difficulty: 'Beginner'),
        Exercise.basic(
            name: 'Incline Push-ups',
            sets: '3',
            reps: '10',
            targetMuscleGroup: 'Chest',
            equipment: 'none',
            difficulty: 'Beginner'),
        Exercise.basic(
            name: 'Bent-over Dumbbell Rows',
            sets: '3',
            reps: '8',
            targetMuscleGroup: 'Back',
            equipment: 'dumbbells',
            difficulty: 'Beginner'),
        Exercise.basic(
            name: 'Standing Overhead Dumbbell Press',
            sets: '3',
            reps: '10',
            targetMuscleGroup: 'Shoulders',
            equipment: 'dumbbells',
            difficulty: 'Beginner'),
        Exercise.basic(
            name: 'Plank Hold',
            sets: '3',
            reps: '20 seconds',
            targetMuscleGroup: 'Core',
            equipment: 'none',
            difficulty: 'Beginner'),
      ],
      difficulty: 'beginner',
      equipment: ['none', 'dumbbells'],
      targetMuscles: ['Full Body'],
      warmUp: 'Light cardio and dynamic stretching',
      coolDown: 'Static stretching and mobility work',
      duration: 30,
    ),
    Workout(
      id: _uuid.v4(),
      name: 'Beginner Bodyweight Full-Body',
      description: 'Basic functional movements (no equipment)',
      focus: 'Full-body basics',
      exercises: [
        Exercise.basic(
            name: 'Chair/Box Squats',
            sets: '3',
            reps: '10',
            targetMuscleGroup: 'Legs',
            equipment: 'none',
            difficulty: 'Beginner'),
        Exercise.basic(
            name: 'Knee Push-ups',
            sets: '3',
            reps: '8',
            targetMuscleGroup: 'Chest',
            equipment: 'none',
            difficulty: 'Beginner'),
        Exercise.basic(
            name: 'Glute Bridge',
            sets: '3',
            reps: '12',
            targetMuscleGroup: 'Glutes',
            equipment: 'none',
            difficulty: 'Beginner'),
        Exercise.basic(
            name: 'Bird Dog',
            sets: '3',
            reps: '8 per side',
            targetMuscleGroup: 'Core',
            equipment: 'none',
            difficulty: 'Beginner'),
        Exercise.basic(
            name: 'Standing Calf Raises',
            sets: '3',
            reps: '10',
            targetMuscleGroup: 'Calves',
            equipment: 'none',
            difficulty: 'Beginner'),
      ],
      difficulty: 'beginner',
      equipment: ['none'],
      targetMuscles: ['Full Body'],
      warmUp:
          '5 minutes of arm circles, hip rotations, light marching in place',
      coolDown: 'Static stretches for the entire body (5 minutes)',
      duration: 30,
    ),

    // Intermediate workouts
    Workout(
      id: _uuid.v4(),
      name: 'Intermediate Workout',
      description: 'Upper body and core',
      focus: 'Upper body strength',
      exercises: [
        Exercise.basic(
            name: 'Pull-ups',
            sets: '3',
            reps: '6',
            targetMuscleGroup: 'Back',
            equipment: 'pull-up bar',
            difficulty: 'Beginner'),
        Exercise.basic(
            name: 'Dumbbell Bench Press',
            sets: '3',
            reps: '10',
            targetMuscleGroup: 'Chest',
            equipment: 'dumbbells',
            difficulty: 'Beginner'),
        Exercise.basic(
            name: 'Dumbbell Lateral Raises',
            sets: '3',
            reps: '10',
            targetMuscleGroup: 'Shoulders',
            equipment: 'dumbbells',
            difficulty: 'Beginner'),
        Exercise.basic(
            name: 'Hanging Leg Raises',
            sets: '3',
            reps: '12',
            targetMuscleGroup: 'Core',
            equipment: 'pull-up bar',
            difficulty: 'Beginner'),
        Exercise.basic(
            name: 'Plank Shoulder Taps',
            sets: '3',
            reps: '15 per side',
            targetMuscleGroup: 'Core',
            equipment: 'none',
            difficulty: 'Beginner'),
      ],
      difficulty: 'intermediate',
      equipment: ['bench', 'dumbbells', 'pull-up bar'],
      targetMuscles: ['Upper Body', 'Core'],
      warmUp: 'Arm circles and torso twists',
      coolDown: 'Cat-Cow stretch, Child\'s Pose',
      duration: 30,
    ),

    // Advanced workouts
    Workout(
      id: _uuid.v4(),
      name: 'Advanced Workout',
      description: 'Lower body and explosive power',
      focus: 'Lower body power',
      exercises: [
        Exercise.basic(
            name: 'Barbell Back Squats',
            sets: '4',
            reps: '8',
            targetMuscleGroup: 'Legs',
            equipment: 'barbell',
            difficulty: 'Beginner'),
        Exercise.basic(
            name: 'Romanian Deadlifts',
            sets: '4',
            reps: '10',
            targetMuscleGroup: 'Hamstrings',
            equipment: 'barbell',
            difficulty: 'Beginner'),
        Exercise.basic(
            name: 'Bulgarian Split Squats',
            sets: '3',
            reps: '12 per leg',
            targetMuscleGroup: 'Quads',
            equipment: 'dumbbells',
            difficulty: 'Beginner'),
        Exercise.basic(
            name: 'Weighted Side Plank',
            sets: '3',
            reps: '15 seconds per side',
            targetMuscleGroup: 'Core',
            equipment: 'dumbbells',
            difficulty: 'Beginner'),
        Exercise.basic(
            name: 'Box Jumps',
            sets: '4',
            reps: '8',
            targetMuscleGroup: 'Legs',
            equipment: 'box',
            difficulty: 'Beginner'),
      ],
      difficulty: 'advanced',
      equipment: ['barbell', 'rack', 'dumbbells', 'box'],
      targetMuscles: ['Lower Body', 'Core'],
      warmUp: '10 bodyweight squats, lunges, high knees',
      coolDown: 'Foam rolling for legs',
      duration: 40,
    ),

    // Gender-specific workouts
    Workout(
      id: _uuid.v4(),
      name: 'Female Workout',
      description: 'Lower body and core (targeting glutes and stability)',
      focus: 'Glute and core focus',
      exercises: [
        Exercise.basic(
            name: 'Hip Thrusts',
            sets: '3',
            reps: '15',
            targetMuscleGroup: 'Glutes',
            equipment: 'barbell',
            difficulty: 'Beginner'),
        Exercise.basic(
            name: 'Side-lying Leg Lifts',
            sets: '3',
            reps: '15 per side',
            targetMuscleGroup: 'Glutes',
            equipment: 'none',
            difficulty: 'Beginner'),
        Exercise.basic(
            name: 'Deadlifts',
            sets: '4',
            reps: '8',
            targetMuscleGroup: 'Hamstrings',
            equipment: 'barbell',
            difficulty: 'Beginner'),
        Exercise.basic(
            name: 'Russian Twists',
            sets: '3',
            reps: '20',
            targetMuscleGroup: 'Core',
            equipment: 'dumbbells',
            difficulty: 'Beginner'),
        Exercise.basic(
            name: 'Step-ups',
            sets: '3',
            reps: '10 per leg',
            targetMuscleGroup: 'Legs',
            equipment: 'dumbbells',
            difficulty: 'Beginner'),
      ],
      difficulty: 'intermediate',
      equipment: ['barbell', 'dumbbells', 'bench'],
      targetMuscles: ['Lower Body', 'Core'],
      warmUp: 'Side lunges, hip bridges',
      coolDown: 'Pigeon stretch, hamstring stretch',
      duration: 30,
    ),

    // Male Workout
    Workout(
      id: _uuid.v4(),
      name: 'Male Workout',
      description: 'An upper body focused strength workout',
      focus: 'Upper body and strength',
      exercises: [
        Exercise.basic(
            name: 'Bench Press',
            description: 'Classic chest compound movement',
            equipment: 'barbell, bench',
            sets: '4',
            reps: '6',
            targetMuscleGroup: 'chest',
            difficulty: 'Beginner'),
        Exercise.basic(
            name: 'Burpees',
            description: 'Full body conditioning exercise',
            equipment: 'none',
            sets: '3',
            reps: '10',
            targetMuscleGroup: 'full body',
            difficulty: 'Intermediate'),
      ],
      warmUp: 'Jumping jacks, dynamic stretches',
      coolDown: 'Relaxation stretches',
      difficulty: 'Beginner',
      equipment: ['None (Bodyweight Only)'],
      targetMuscles: ['Full Body'],
      duration: 30,
    ),

    // Arms Workout
    Workout(
      id: _uuid.v4(),
      name: 'Arms Workout',
      description: 'Focused on biceps and triceps',
      focus: 'Arms strength',
      exercises: [
        Exercise.basic(
            name: 'Dumbbell Bicep Curls',
            description: 'Basic bicep curl movement',
            equipment: 'dumbbells',
            sets: '3',
            reps: '12',
            targetMuscleGroup: 'biceps',
            difficulty: 'Beginner'),
        Exercise.basic(
            name: 'Tricep Dips',
            description: 'Bodyweight tricep exercise',
            equipment: 'bench',
            sets: '3',
            reps: '10',
            targetMuscleGroup: 'triceps',
            difficulty: 'Intermediate'),
        Exercise.basic(
            name: 'Hammer Curls',
            description: 'Bicep curl variation',
            equipment: 'dumbbells',
            sets: '3',
            reps: '10',
            targetMuscleGroup: 'biceps',
            difficulty: 'Beginner'),
        Exercise.basic(
            name: 'Overhead Tricep Extensions',
            description: 'Isolation tricep exercise',
            equipment: 'dumbbells',
            sets: '3',
            reps: '12',
            targetMuscleGroup: 'triceps',
            difficulty: 'Beginner'),
        Exercise.basic(
            name: 'Plank-to-Push-ups',
            description: 'Compound movement for arms and core',
            equipment: 'none',
            sets: '3',
            reps: '10',
            targetMuscleGroup: 'arms',
            difficulty: 'Intermediate'),
      ],
      warmUp: 'Arm circles, light dumbbell curls',
      coolDown: 'Stretch biceps and triceps',
      difficulty: 'Beginner',
      equipment: ['dumbbells', 'bench'],
      targetMuscles: ['Arms'],
      duration: 30,
    ),

    // Legs Workout
    Workout(
      id: _uuid.v4(),
      name: 'Legs Workout',
      description: 'Focus on lower body strength',
      focus: 'Legs strength',
      exercises: [
        Exercise.basic(
            name: 'Goblet Squats',
            description: 'Squat variation with dumbbell',
            equipment: 'dumbbells',
            sets: '3',
            reps: '12',
            targetMuscleGroup: 'legs',
            difficulty: 'Intermediate'),
        Exercise.basic(
            name: 'Romanian Deadlifts',
            description: 'Hamstring focused deadlift',
            equipment: 'dumbbells',
            sets: '4',
            reps: '10',
            targetMuscleGroup: 'hamstrings',
            difficulty: 'Intermediate'),
        Exercise.basic(
            name: 'Bulgarian Split Squats',
            description: 'Unilateral leg exercise',
            equipment: 'dumbbells',
            sets: '3',
            reps: '12 per leg',
            targetMuscleGroup: 'legs',
            difficulty: 'Intermediate'),
        Exercise.basic(
            name: 'Calf Raises',
            description: 'Isolation for calves',
            equipment: 'none',
            sets: '3',
            reps: '15',
            targetMuscleGroup: 'calves',
            difficulty: 'Beginner'),
        Exercise.basic(
            name: 'Jump Squats',
            description: 'Explosive leg movement',
            equipment: 'none',
            sets: '3',
            reps: '10',
            targetMuscleGroup: 'legs',
            difficulty: 'Intermediate'),
      ],
      warmUp: 'Bodyweight squats, walking lunges',
      coolDown: 'Stretch quads, hamstrings, and calves',
      difficulty: 'Intermediate',
      equipment: ['dumbbells', 'bench'],
      targetMuscles: ['Legs'],
      duration: 30,
    ),

    // Dumbbells Only Workout
    Workout(
      id: _uuid.v4(),
      name: 'Dumbbells Only Workout',
      description: 'Full-body workout using only dumbbells',
      focus: 'Full-body strength',
      exercises: [
        Exercise.basic(
            name: 'Dumbbell Deadlifts',
            description: 'Full body compound movement',
            equipment: 'dumbbells',
            sets: '4',
            reps: '10',
            targetMuscleGroup: 'full body',
            difficulty: 'Intermediate'),
        Exercise.basic(
            name: 'Dumbbell Bench Press',
            description: 'Chest press with dumbbells',
            equipment: 'dumbbells',
            sets: '3',
            reps: '12',
            targetMuscleGroup: 'chest',
            difficulty: 'Intermediate'),
        Exercise.basic(
            name: 'Dumbbell Rows',
            description: 'Back exercise with dumbbells',
            equipment: 'dumbbells',
            sets: '3',
            reps: '12',
            targetMuscleGroup: 'back',
            difficulty: 'Intermediate'),
        Exercise.basic(
            name: 'Dumbbell Shoulder Press',
            description: 'Overhead press with dumbbells',
            equipment: 'dumbbells',
            sets: '3',
            reps: '10',
            targetMuscleGroup: 'shoulders',
            difficulty: 'Intermediate'),
        Exercise.basic(
            name: 'Dumbbell Side Plank Raise',
            description: 'Core exercise with weight',
            equipment: 'dumbbells',
            sets: '3',
            reps: '10 per side',
            targetMuscleGroup: 'core',
            difficulty: 'Intermediate'),
      ],
      warmUp: 'Dumbbell swings, arm circles',
      coolDown: 'Full-body stretch',
      difficulty: 'Intermediate',
      equipment: ['dumbbells'],
      targetMuscles: ['Full Body'],
      duration: 30,
    ),

    // Bodyweight Only Workout
    Workout(
      id: _uuid.v4(),
      name: 'Bodyweight Only Workout',
      description: 'Functional strength using only bodyweight',
      focus: 'Functional strength',
      exercises: [
        Exercise.basic(
            name: 'Push-ups',
            description: 'Basic push-up movement',
            equipment: 'none',
            sets: '3',
            reps: '15',
            targetMuscleGroup: 'chest',
            difficulty: 'Beginner'),
        Exercise.basic(
            name: 'Bodyweight Squats',
            description: 'Basic squat movement',
            equipment: 'none',
            sets: '3',
            reps: '12',
            targetMuscleGroup: 'legs',
            difficulty: 'Beginner'),
        Exercise.basic(
            name: 'Glute Bridges',
            description: 'Hip extension exercise',
            equipment: 'none',
            sets: '3',
            reps: '15',
            targetMuscleGroup: 'glutes',
            difficulty: 'Beginner'),
        Exercise.basic(
            name: 'Plank Hold',
            description: 'Static core exercise',
            equipment: 'none',
            sets: '3',
            reps: '30 seconds',
            targetMuscleGroup: 'core',
            difficulty: 'Beginner'),
        Exercise.basic(
            name: 'Burpees',
            description: 'Full body conditioning',
            equipment: 'none',
            sets: '3',
            reps: '10',
            targetMuscleGroup: 'full body',
            difficulty: 'Intermediate'),
      ],
      warmUp: 'Jumping jacks, dynamic stretches',
      coolDown: 'Relaxation stretches',
      difficulty: 'Beginner',
      equipment: ['none'],
      targetMuscles: ['Full Body'],
      duration: 30,
    ),

    // Pull-up Bar Workout
    Workout(
      id: _uuid.v4(),
      name: 'Pull-up Bar Workout',
      description: 'An upper body workout focused on the pull-up bar',
      focus: 'Upper body strength',
      exercises: [
        Exercise.basic(
            name: 'Pull-ups',
            description: 'Basic pull-up movement',
            equipment: 'pull-up bar',
            sets: '3',
            reps: '10',
            targetMuscleGroup: 'back',
            difficulty: 'Advanced'),
        Exercise.basic(
            name: 'Hanging Leg Raises',
            description: 'Core exercise while hanging',
            equipment: 'pull-up bar',
            sets: '3',
            reps: '12',
            targetMuscleGroup: 'core',
            difficulty: 'Intermediate'),
        Exercise.basic(
            name: 'Chin-ups',
            description: 'Underhand grip pull-up variation',
            equipment: 'pull-up bar',
            sets: '3',
            reps: '8',
            targetMuscleGroup: 'biceps',
            difficulty: 'Advanced'),
        Exercise.basic(
            name: 'Hanging Shrugs',
            description: 'Upper back exercise',
            equipment: 'pull-up bar',
            sets: '3',
            reps: '15',
            targetMuscleGroup: 'shoulders',
            difficulty: 'Intermediate'),
        Exercise.basic(
            name: 'Toes-to-Bar',
            description: 'Advanced core exercise',
            equipment: 'pull-up bar',
            sets: '3',
            reps: '10',
            targetMuscleGroup: 'core',
            difficulty: 'Advanced'),
      ],
      warmUp: 'Light stretching for shoulders and arms',
      coolDown: 'Stretch shoulders and lats',
      difficulty: 'Advanced',
      equipment: ['Pull-up Bar'],
      targetMuscles: ['Upper Body', 'Core'],
      duration: 30,
    ),

    // New workouts
    Workout(
      id: _uuid.v4(),
      name: 'Beginner HIIT Bodyweight Blast',
      description:
          'High-intensity intervals for full-body conditioning (no equipment)',
      focus: 'HIIT full-body conditioning',
      exercises: [
        Exercise.basic(
            name: 'Squat Jumps',
            sets: '4',
            reps: '20s work, 10s rest',
            targetMuscleGroup: 'Legs/Glutes',
            equipment: 'none',
            difficulty: 'Beginner'),
        Exercise.basic(
            name: 'Push-ups',
            targetMuscleGroup: 'Chest',
            equipment: 'none',
            sets: '3',
            reps: '10',
            difficulty: 'Beginner'),
        Exercise.basic(
            name: 'Mountain Climbers',
            sets: '4',
            reps: '20s work, 10s rest',
            targetMuscleGroup: 'Core/Shoulders',
            equipment: 'none',
            difficulty: 'Beginner'),
        Exercise.basic(
            name: 'Plank Shoulder Taps',
            sets: '4',
            reps: '20s work, 10s rest',
            targetMuscleGroup: 'Core',
            equipment: 'none',
            difficulty: 'Beginner'),
      ],
      difficulty: 'beginner',
      equipment: ['none'],
      targetMuscles: ['Full Body'],
      warmUp:
          'Light jogging in place (1 minute), Arm circles (30 seconds each direction), Hip rotations (30 seconds each side)',
      coolDown:
          'Child\'s Pose (30 seconds), Standing Quad Stretch (30 seconds each leg), Overhead Triceps Stretch (30 seconds each arm)',
      duration: 30,
    ),

    Workout(
      id: _uuid.v4(),
      name: 'Intermediate Full-Body Dumbbell Circuit',
      description: 'Strength and endurance using only dumbbells',
      focus: 'Full-body strength and endurance',
      exercises: [
        Exercise.basic(
            name: 'Dumbbell Front Squats',
            sets: '3',
            reps: '12',
            targetMuscleGroup: 'Legs',
            equipment: 'dumbbells',
            difficulty: 'Beginner'),
        Exercise.basic(
            name: 'Dumbbell Bent-over Rows',
            sets: '3',
            reps: '10 per side',
            targetMuscleGroup: 'Back',
            equipment: 'dumbbells',
            difficulty: 'Beginner'),
        Exercise.basic(
            name: 'Dumbbell Reverse Lunges',
            sets: '3',
            reps: '8 each leg',
            targetMuscleGroup: 'Legs/Glutes',
            equipment: 'dumbbells',
            difficulty: 'Beginner'),
        Exercise.basic(
            name: 'Dumbbell Push Press',
            sets: '3',
            reps: '10',
            targetMuscleGroup: 'Shoulders',
            equipment: 'dumbbells',
            difficulty: 'Beginner'),
        Exercise.basic(
            name: 'Plank with Single-Arm Row',
            sets: '3',
            reps: '6 each arm',
            targetMuscleGroup: 'Core/Back',
            equipment: 'dumbbells',
            difficulty: 'Beginner'),
      ],
      difficulty: 'intermediate',
      equipment: ['dumbbells'],
      targetMuscles: ['Full Body'],
      warmUp:
          'Jumping jacks (1 minute), Hip hinges (10 reps), Shoulder circles (30 seconds each direction)',
      coolDown:
          'Downward Dog (30 seconds), Cobra Pose (30 seconds), Standing Hamstring Stretch (30 seconds each side)',
      duration: 30,
    ),

    Workout(
      id: _uuid.v4(),
      name: 'Advanced Barbell Complex',
      description: 'Explosive strength and metabolic conditioning',
      focus: 'Complex/Metabolic conditioning',
      exercises: [
        Exercise.basic(
            name: 'Barbell Power Cleans',
            sets: '4',
            reps: '5',
            targetMuscleGroup: 'Full Body',
            equipment: 'barbell',
            difficulty: 'Beginner'),
        Exercise.basic(
            name: 'Barbell Front Squats',
            sets: '4',
            reps: '5',
            targetMuscleGroup: 'Quads/Core',
            equipment: 'barbell',
            difficulty: 'Beginner'),
        Exercise.basic(
            name: 'Barbell Overhead Press',
            sets: '4',
            reps: '5',
            targetMuscleGroup: 'Shoulders/Arms',
            equipment: 'barbell',
            difficulty: 'Beginner'),
        Exercise.basic(
            name: 'Barbell Back Squats',
            sets: '4',
            reps: '5',
            targetMuscleGroup: 'Legs',
            equipment: 'barbell',
            difficulty: 'Beginner'),
        Exercise.basic(
            name: 'Barbell Bent-over Rows',
            sets: '4',
            reps: '5',
            targetMuscleGroup: 'Back',
            equipment: 'barbell',
            difficulty: 'Beginner'),
      ],
      difficulty: 'advanced',
      equipment: ['barbell'],
      targetMuscles: ['Full Body'],
      warmUp:
          'Light barbell good mornings (10 reps), Bodyweight squats (10 reps), Arm swings (30 seconds)',
      coolDown:
          'Foam roll major muscle groups (2-3 minutes), Deep hamstring and quad stretches (30 seconds each side)',
      duration: 40,
    ),

    Workout(
      id: _uuid.v4(),
      name: 'Female Full-Body Circuit',
      description: 'Toning glutes, legs, and core with moderate equipment',
      focus: 'Glutes & Core emphasis',
      exercises: [
        Exercise.basic(
            name: 'Dumbbell Sumo Squats',
            sets: '3',
            reps: '12',
            targetMuscleGroup: 'Glutes/Inner Thighs',
            equipment: 'dumbbells',
            difficulty: 'Beginner'),
        Exercise.basic(
            name: 'Walking Lunges',
            sets: '3',
            reps: '12',
            targetMuscleGroup: 'Legs/Glutes',
            equipment: 'dumbbells',
            difficulty: 'Beginner'),
        Exercise.basic(
            name: 'Seated Dumbbell Shoulder Press',
            sets: '3',
            reps: '12',
            targetMuscleGroup: 'Shoulders',
            equipment: 'dumbbells',
            difficulty: 'Beginner'),
        Exercise.basic(
            name: 'Side Plank Hip Lifts',
            sets: '3',
            reps: '10 each side',
            targetMuscleGroup: 'Obliques/Core',
            equipment: 'none',
            difficulty: 'Beginner'),
        Exercise.basic(
            name: 'Leg Raises',
            sets: '3',
            reps: '12',
            targetMuscleGroup: 'Core',
            equipment: 'bench',
            difficulty: 'Beginner'),
      ],
      difficulty: 'intermediate',
      equipment: ['dumbbells', 'bench'],
      targetMuscles: ['Full Body', 'Glutes', 'Core'],
      warmUp:
          'Hip bridges (10 reps), Lateral leg swings (10 each leg), Shoulder rolls (30 seconds)',
      coolDown:
          'Pigeon stretch (30 seconds each leg), Figure-four glute stretch (30 seconds each leg), Standing calf stretch (30 seconds each leg)',
      duration: 30,
    ),

    Workout(
      id: _uuid.v4(),
      name: 'Male Push-Day Emphasis',
      description: 'Chest, shoulders, triceps, and core strength',
      focus: 'Upper body push muscles',
      exercises: [
        Exercise.basic(
            name: 'Barbell Bench Press',
            sets: '4',
            reps: '8-10',
            targetMuscleGroup: 'Chest',
            equipment: 'barbell',
            difficulty: 'Beginner'),
        Exercise.basic(
            name: 'Incline Dumbbell Press',
            sets: '4',
            reps: '8-10',
            targetMuscleGroup: 'Upper Chest',
            equipment: 'dumbbells',
            difficulty: 'Beginner'),
        Exercise.basic(
            name: 'Standing Barbell Shoulder Press',
            sets: '4',
            reps: '8-10',
            targetMuscleGroup: 'Shoulders',
            equipment: 'barbell',
            difficulty: 'Beginner'),
        Exercise.basic(
            name: 'Cable or Dumbbell Tricep Extensions',
            sets: '4',
            reps: '8-10',
            targetMuscleGroup: 'Triceps',
            equipment: 'dumbbells',
            difficulty: 'Beginner'),
        Exercise.basic(
            name: 'Plank-to-Push-up',
            sets: '3',
            reps: '8',
            targetMuscleGroup: 'Core/Arms',
            equipment: 'none',
            difficulty: 'Beginner'),
      ],
      difficulty: 'intermediate',
      equipment: ['barbell', 'dumbbells'],
      targetMuscles: ['Upper Body', 'Core'],
      warmUp:
          'Light band shoulder external rotations (10 reps each arm), Push-ups (5-10 reps), Dynamic chest stretch (arm swings, 30 seconds)',
      coolDown:
          'Chest doorway stretch (30 seconds each side), Triceps stretch overhead (30 seconds each arm), Neck rolls (15 seconds each direction)',
      duration: 30,
    ),

    Workout(
      id: _uuid.v4(),
      name: 'Arms & Shoulder Superset',
      description: 'Upper-arm development and shoulder definition',
      focus: 'Arms and shoulders',
      exercises: [
        Exercise.basic(
            name: 'Standing Dumbbell Bicep Curls',
            sets: '3',
            reps: '10',
            targetMuscleGroup: 'Biceps',
            equipment: 'dumbbells',
            difficulty: 'Beginner'),
        Exercise.basic(
            name: 'Seated Overhead Tricep Extensions',
            sets: '3',
            reps: '10',
            targetMuscleGroup: 'Triceps',
            equipment: 'dumbbells',
            difficulty: 'Beginner'),
        Exercise.basic(
            name: 'Hammer Curls',
            sets: '3',
            reps: '10',
            targetMuscleGroup: 'Biceps',
            equipment: 'dumbbells',
            difficulty: 'Beginner'),
        Exercise.basic(
            name: 'Tricep Dips',
            sets: '3',
            reps: '10',
            targetMuscleGroup: 'Triceps',
            equipment: 'bench',
            difficulty: 'Beginner'),
        Exercise.basic(
            name: 'Dumbbell Lateral Raises',
            sets: '3',
            reps: '12',
            targetMuscleGroup: 'Shoulders',
            equipment: 'dumbbells',
            difficulty: 'Beginner'),
        Exercise.basic(
            name: 'Front Raises',
            sets: '3',
            reps: '12',
            targetMuscleGroup: 'Shoulders',
            equipment: 'dumbbells',
            difficulty: 'Beginner'),
      ],
      difficulty: 'intermediate',
      equipment: ['dumbbells', 'bench'],
      targetMuscles: ['Arms', 'Shoulders'],
      warmUp:
          'Arm circles (30 seconds each direction), Light dumbbell curls (8 reps), Light overhead triceps extensions (8 reps)',
      coolDown:
          'Bicep wall stretch (30 seconds each side), Overhead triceps stretch (30 seconds each arm), Shoulder cross-body stretch (30 seconds each arm)',
      duration: 30,
    ),

    Workout(
      id: _uuid.v4(),
      name: 'Lower Body Builder',
      description: 'Strengthening posterior chain (glutes, hamstrings)',
      focus: 'Hamstring and glute strength',
      exercises: [
        Exercise.basic(
            name: 'Barbell Romanian Deadlifts',
            sets: '4',
            reps: '10-12',
            targetMuscleGroup: 'Hamstrings/Glutes',
            equipment: 'barbell',
            difficulty: 'Beginner'),
        Exercise.basic(
            name: 'Reverse Dumbbell Lunges',
            sets: '4',
            reps: '10-12',
            targetMuscleGroup: 'Glutes/Quads',
            equipment: 'dumbbells',
            difficulty: 'Beginner'),
        Exercise.basic(
            name: 'Single-Leg Dumbbell Deadlifts',
            sets: '4',
            reps: '10-12',
            targetMuscleGroup: 'Hamstrings',
            equipment: 'dumbbells',
            difficulty: 'Beginner'),
        Exercise.basic(
            name: 'Hip Thrusts',
            sets: '4',
            reps: '10-12',
            targetMuscleGroup: 'Glutes',
            equipment: 'barbell',
            difficulty: 'Beginner'),
        Exercise.basic(
            name: 'Swiss Ball Hamstring Curls',
            sets: '4',
            reps: '10-12',
            targetMuscleGroup: 'Hamstrings',
            equipment: 'swiss ball',
            difficulty: 'Beginner'),
      ],
      difficulty: 'intermediate',
      equipment: ['barbell', 'dumbbells', 'swiss ball'],
      targetMuscles: ['Legs', 'Hamstrings', 'Glutes'],
      warmUp:
          'Glute activation with mini-band (lateral walks, 10 steps each way), Bodyweight hip hinges (10 reps)',
      coolDown:
          'Seated hamstring stretch (30 seconds each leg), Standing quadriceps stretch (30 seconds each leg), Hip flexor stretch (30 seconds each leg)',
      duration: 30,
    ),

    Workout(
      id: _uuid.v4(),
      name: 'Low-Impact Core & Stability',
      description:
          'Strengthening core and improving balance, minimal joint stress',
      focus: 'Core and stability',
      exercises: [
        Exercise.basic(
            name: 'Dead Bug',
            sets: '3',
            reps: '10-12',
            targetMuscleGroup: 'Core',
            equipment: 'none',
            difficulty: 'Beginner'),
        Exercise.basic(
            name: 'Side Plank',
            sets: '3',
            reps: '30 seconds each side',
            targetMuscleGroup: 'Obliques/Torso',
            equipment: 'none',
            difficulty: 'Beginner'),
        Exercise.basic(
            name: 'Glute Bridge March',
            sets: '3',
            reps: '10-12',
            targetMuscleGroup: 'Glutes/Core',
            equipment: 'none',
            difficulty: 'Beginner'),
        Exercise.basic(
            name: 'Standing Single-Leg Balance',
            sets: '3',
            reps: '30 seconds each leg',
            targetMuscleGroup: 'Stability',
            equipment: 'none',
            difficulty: 'Beginner'),
        Exercise.basic(
            name: 'Modified Superman',
            sets: '3',
            reps: '10-12',
            targetMuscleGroup: 'Lower Back/Glutes',
            equipment: 'none',
            difficulty: 'Beginner'),
      ],
      difficulty: 'beginner',
      equipment: ['none'],
      targetMuscles: ['Core', 'Stability'],
      warmUp:
          'Cat-Camel (5 reps), Bird Dog (5 reps each side), Hip circles (5 reps each direction)',
      coolDown:
          'Knees to chest stretch (30 seconds), Supine twist (30 seconds each side), Child\'s Pose (30 seconds)',
      duration: 30,
    ),
  ];

  static bool _initialized = false;

  static void initialize() {
    if (_initialized) return;
    print('Initializing WorkoutService');
    print('Number of workouts: ${workouts.length}');
    _initialized = true;
  }

  static List<Workout> getWorkouts() {
    if (!_initialized) initialize();
    return workouts;
  }

  static List<Workout> getWorkoutsByDifficulty(String difficulty) {
    if (!_initialized) initialize();
    return workouts
        .where((workout) =>
            workout.difficulty.toLowerCase() == difficulty.toLowerCase())
        .toList();
  }

  static List<Workout> getWorkoutsByEquipment(String equipment) {
    if (!_initialized) initialize();
    return workouts
        .where((workout) => workout.equipment.contains(equipment.toLowerCase()))
        .toList();
  }

  static List<Workout> getWorkoutsByMuscleGroup(String muscleGroup) {
    if (!_initialized) initialize();
    return workouts
        .where((workout) => workout.targetMuscles.any((muscle) =>
            muscle.toLowerCase().contains(muscleGroup.toLowerCase())))
        .toList();
  }

  static List<Workout> getWorkoutsByGender(String gender) {
    return workouts;
  }

  static List<Workout> filterWorkouts({
    String? difficulty,
    List<String>? equipment,
    String? muscleGroup,
    String? gender,
  }) {
    return workouts.where((workout) {
      bool difficultyMatch = difficulty == null ||
          difficulty.isEmpty ||
          workout.difficulty.toLowerCase() == difficulty.toLowerCase();

      bool equipmentMatch = equipment == null ||
          equipment.isEmpty ||
          workout.equipment.any((e) => equipment.contains(e));

      bool muscleMatch = muscleGroup == null ||
          muscleGroup.isEmpty ||
          workout.targetMuscles
              .any((m) => m.toLowerCase() == muscleGroup.toLowerCase());

      return difficultyMatch && equipmentMatch && muscleMatch;
    }).toList();
  }

  static List<Map<String, dynamic>> exercises = [];
  static List<Exercise> exerciseObjects = [];

  static Future<void> loadExercises() async {
    try {
      print('🚀 Начинаем загрузку упражнений из JSON...');

      final String jsonString =
          await rootBundle.loadString('assets/exercise.json');

      print('📄 Загружен JSON строка длиной: ${jsonString.length}');

      // Проверка на пустую строку
      if (jsonString.isEmpty || jsonString.trim().isEmpty) {
        print(
            '⚠️ Получена пустая JSON строка, пробуем загрузить из корневой директории');

        try {
          // Пробуем загрузить из корневой директории
          final rootJsonString = await rootBundle.loadString('exercise.json');
          if (rootJsonString.isNotEmpty && rootJsonString.trim().isNotEmpty) {
            print(
                '✅ Успешно загружен JSON из корневой директории, длина: ${rootJsonString.length}');
            final List<dynamic> decoded = json.decode(rootJsonString);
            exercises = List<Map<String, dynamic>>.from(decoded);
          } else {
            print('❌ JSON файл в корневой директории тоже пуст');
            exercises = [];
            exerciseObjects = [];
            return;
          }
        } catch (e) {
          print('❌ Ошибка при попытке загрузки из корневой директории: $e');
          exercises = [];
          exerciseObjects = [];
          return;
        }
      } else {
        // Безопасный вывод части строки только если она не пустая
        if (jsonString.length > 10) {
          print(
              '📄 Начало JSON: ${jsonString.substring(0, min(100, jsonString.length))}...');
        }

        final List<dynamic> decoded = json.decode(jsonString);
        print('📊 Декодировано ${decoded.length} упражнений из JSON');

        exercises = List<Map<String, dynamic>>.from(decoded);
      }

      // Исправляем URL с [project-ref] на efctwzpqpukhpqvpirrt
      for (var exercise in exercises) {
        if (exercise['videoUrl'] != null &&
            exercise['videoUrl'].toString().contains('[project-ref]')) {
          exercise['videoUrl'] = exercise['videoUrl']
              .toString()
              .replaceAll('[project-ref]', 'efctwzpqpukhpqvpirrt');
          print(
              '🔄 Исправлен URL для ${exercise['name']}: ${exercise['videoUrl']}');
        }
      }

      // Создаем объекты Exercise из JSON
      exerciseObjects =
          exercises.map((json) => Exercise.fromJson(json)).toList();
      print('📊 Создано ${exerciseObjects.length} объектов Exercise');

      // Проверяем наличие и структуру конкретных упражнений
      print('🔍 Поиск конкретных упражнений для проверки...');

      // Ищем Dumbbell Lateral Raise в JSON
      final lateralRaise = exercises.firstWhere(
        (e) => e['name'] == 'Dumbbell Lateral Raise',
        orElse: () => {'name': 'Not found', 'videoUrl': 'null'},
      );

      print(
          '✅ Dumbbell Lateral Raise найдено в JSON: ${lateralRaise['name'] != 'Not found'}');
      print(
          '📺 Dumbbell Lateral Raise videoUrl в JSON: ${lateralRaise['videoUrl']}');

      // Также проверяем объект Exercise
      final lateralRaiseObj = exerciseObjects.firstWhere(
        (e) => e.name == 'Dumbbell Lateral Raise',
        orElse: () => Exercise(
          name: 'Not found',
          description: 'Not found',
          muscleGroup: 'Not found',
          equipment: 'Not found',
          difficultyLevel: 'Not found',
          targetMuscleGroup: 'Not found',
        ),
      );

      print('✅ Dumbbell Lateral Raise объект Exercise: $lateralRaiseObj');
      print('📺 videoUrl в объекте: ${lateralRaiseObj.videoUrl}');

      // Проверяем структуру нескольких случайных упражнений
      if (exercises.length > 10) {
        final randomIndex = (Random().nextDouble() * exercises.length).floor();
        final randomExercise = exercises[randomIndex];
        final randomExerciseObj = exerciseObjects[randomIndex];

        print(
            '🎲 Случайное упражнение #$randomIndex: ${randomExercise['name']}');
        print(
            '📺 Случайное упражнение videoUrl в JSON: ${randomExercise['videoUrl']}');
        print(
            '📺 Случайное упражнение videoUrl в объекте: ${randomExerciseObj.videoUrl}');
      }

      // Проверяем общую структуру данных
      print(
          '🔢 Количество упражнений с videoUrl в JSON: ${exercises.where((e) => e['videoUrl'] != null).length}');
      print(
          '🔢 Количество упражнений с videoUrl в объектах: ${exerciseObjects.where((e) => e.videoUrl != null).length}');

      print('✅ Успешно загружено ${exercises.length} упражнений');
    } catch (e, stackTrace) {
      print('❌ Ошибка при загрузке упражнений: $e');
      print('❌ Стек вызовов: $stackTrace');
      exercises = [];
      exerciseObjects = [];
    }
  }

  // Добавляем метод для получения объекта Exercise по имени
  static Exercise? getExerciseByName(String name) {
    try {
      final exercise = exerciseObjects.firstWhere(
        (e) => e.name == name,
        orElse: () => Exercise(
          name: 'Not found',
          description: 'Not found',
          muscleGroup: 'Not found',
          equipment: 'Not found',
          difficultyLevel: 'Not found',
          targetMuscleGroup: 'Not found',
        ),
      );

      // Проверяем наличие [project-ref] в URL и исправляем его
      if (exercise.videoUrl != null &&
          exercise.videoUrl!.contains('[project-ref]')) {
        final correctedExercise = exercise.copyWith(
            videoUrl: exercise.videoUrl!
                .replaceAll('[project-ref]', 'efctwzpqpukhpqvpirrt'));
        print(
            '🔄 Исправлен URL для ${exercise.name}: ${correctedExercise.videoUrl}');
        return correctedExercise;
      }

      // Если videoUrl равен null или пустой, попробуем сгенерировать URL
      if (exercise.videoUrl == null || exercise.videoUrl!.isEmpty) {
        final generatedUrl = generateVideoUrl(exercise.name);
        print('🔄 Сгенерирован URL для ${exercise.name}: $generatedUrl');
        return exercise.copyWith(videoUrl: generatedUrl);
      }

      return exercise;
    } catch (e) {
      print('❌ Ошибка при поиске упражнения $name: $e');
      return null;
    }
  }

  // Метод для генерации правильного URL видео на основе имени упражнения
  static String generateVideoUrl(String exerciseName) {
    // Преобразуем имя в slug для URL
    final slug = exerciseName.toLowerCase().replaceAll(' ', '-');

    // Проверяем тире в конце и удаляем если есть
    final videoSlug =
        slug.endsWith('-') ? slug.substring(0, slug.length - 1) : slug;

    return 'https://efctwzpqpukhpqvpirrt.supabase.co/storage/v1/object/public/videos/$videoSlug.mp4';
  }

  // Метод для проверки доступности видео
  static Future<bool> checkVideoAvailability(String url) async {
    try {
      if (url.contains('[project-ref]')) {
        url = url.replaceAll('[project-ref]', 'efctwzpqpukhpqvpirrt');
      }

      print('🔍 Проверка доступности видео: $url');

      // Проверка на YouTube ссылку
      if (url.contains('youtube.com') || url.contains('youtu.be')) {
        return true; // Для YouTube не проверяем
      }

      // Используем HEAD запрос для проверки доступности
      final response = await http.head(Uri.parse(url)).timeout(
            Duration(seconds: 5),
            onTimeout: () => http.Response('Error', 408),
          );

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      print('❌ Ошибка при проверке доступности видео: $e');
      return false;
    }
  }

  // Метод для получения списка всех упражнений как объектов Exercise
  static List<Exercise> getAllExercises() {
    return List<Exercise>.from(exerciseObjects);
  }
}

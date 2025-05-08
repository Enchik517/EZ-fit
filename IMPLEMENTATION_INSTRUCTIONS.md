# Workout Persistence Diagnostic System

This package provides a comprehensive diagnostic system to address issues with workout persistence in the Fitbod application.

## Files Created

1. **debug_logs.sql**: SQL for creating debug logging tables and triggers
2. **fix_duplicates.sql**: SQL stored procedures to fix duplicate entries
3. **lib/services/debug_logger.dart**: Debug logging service
4. **lib/screens/workout_diagnostics_screen.dart**: Diagnostic UI
5. **lib/patches/workout_provider_patch.dart**: Improved workout persistence methods

## Implementation Steps

### 1. Set Up Database Tables

Run the following SQL scripts in your Supabase SQL Editor:

1. First, run `debug_logs.sql` to create the debug logs table
2. Then run `fix_duplicates.sql` to create the stored procedures

### 2. Add Routes to Your App

In your `lib/main.dart` file, add the diagnostics screen route:

```dart
import 'lib/screens/workout_diagnostics_screen.dart';

// In your routes map:
routes: {
  // ... existing routes
  '/workout-diagnostics': (context) => const WorkoutDiagnosticsScreen(),
},
```

### 3. Wrap Your Main App With the Debug Overlay

In your `lib/main.dart` file, wrap your main app with the WorkoutDebugOverlay:

```dart
import 'lib/patches/workout_provider_patch.dart';

// In your build method:
@override
Widget build(BuildContext context) {
  return MaterialApp(
    // ... existing properties
    home: WorkoutDebugOverlay(
      child: YourMainScreen(),
    ),
    // ... existing properties
  );
}
```

### 4. Patch Workout Provider Methods

Replace calls to the original methods with the patched versions:

1. Find where `saveWorkout` is called and replace it with:
   ```dart
   // Import the patch
   import 'patches/workout_provider_patch.dart';
   
   // Replace
   await workoutProvider.saveWorkout(workout);
   
   // With
   await workoutProvider.saveWorkoutToHistoryWithLogging(workout);
   ```

2. Find where toggling favorites is implemented and replace with:
   ```dart
   await workoutProvider.toggleFavoriteWithLogging(workout);
   ```

### 5. Add Verification in Profile Screen

Add a method to verify workout data in your profile screen:

```dart
import '../patches/workout_provider_patch.dart';

Future<void> _verifyWorkoutData() async {
  final workoutProvider = Provider.of<WorkoutProvider>(context, listen: false);
  final result = await workoutProvider.verifyWorkoutData();
  
  if (result['success']) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(
        'Workout History: ${result['history_count']}, Favorites: ${result['favorites_count']}'
      )),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: ${result['error']}'))
    );
  }
}

// Add button to profile screen:
ListTile(
  leading: Icon(Icons.verified),
  title: Text('Verify Workout Data'),
  onTap: _verifyWorkoutData,
),
```

## Debugging Process

1. Run the app
2. Use the debug FAB button to access diagnostics
3. Check for any errors in the debug logs
4. Use the "Fix Duplicates" button if duplicates are detected
5. Check workout history and favorites counts

## Common Issues

1. **Missing Tables**: Ensure the SQL scripts have been run successfully
2. **Duplicate Entries**: Use the diagnostic tool to fix duplicates
3. **Data Not Persisting**: Check for errors in Debug Logs tab
4. **Workout IDs**: Ensure workouts have unique IDs before saving 
import 'package:flutter/material.dart';

class NotificationSettingsScreen extends StatefulWidget {
  @override
  _NotificationSettingsScreenState createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool workoutReminders = true;
  bool progressUpdates = true;
  bool achievementAlerts = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notification Settings'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: Text('Workout Reminders'),
            subtitle: Text('Get notified about upcoming workouts'),
            value: workoutReminders,
            onChanged: (value) => setState(() => workoutReminders = value),
          ),
          Divider(),
          SwitchListTile(
            title: Text('Progress Updates'),
            subtitle: Text('Receive weekly progress summaries'),
            value: progressUpdates,
            onChanged: (value) => setState(() => progressUpdates = value),
          ),
          Divider(),
          SwitchListTile(
            title: Text('Achievement Alerts'),
            subtitle: Text('Get notified when you reach fitness goals'),
            value: achievementAlerts,
            onChanged: (value) => setState(() => achievementAlerts = value),
          ),
        ],
      ),
    );
  }
} 
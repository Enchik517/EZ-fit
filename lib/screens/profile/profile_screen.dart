import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../onboarding/onboarding_screen.dart';
import '../../providers/survey_provider.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  final bool isFromProfile;

  const ProfileScreen({
    super.key,
    this.isFromProfile = false,
  });

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Загружаем данные опроса при инициализации
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        context.read<SurveyProvider>().loadSurveyData(userId);
        // Запрашиваем обновление профиля при открытии экрана
        context.read<AuthProvider>().loadUserProfile();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userProfile = authProvider.userProfile;
    final user = Supabase.instance.client.auth.currentUser;
    final createdAt = user?.createdAt != null
        ? DateTime.parse(user!.createdAt!)
        : DateTime.now();

    // Получаем имя пользователя из метаданных Supabase
    String? userName;
    if (user != null && user.userMetadata != null) {
      final metadata = user.userMetadata!;

      // Пробуем разные варианты названий полей с именем
      if (metadata.containsKey('full_name')) {
        userName = metadata['full_name'] as String?;
      } else if (metadata.containsKey('name')) {
        userName = metadata['name'] as String?;
      } else if (metadata.containsKey('user_name')) {
        userName = metadata['user_name'] as String?;
      } else if (metadata.containsKey('display_name')) {
        userName = metadata['display_name'] as String?;
      }

      //    }

    // Выводим отладочную информацию
    //    //    //
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () async {
              // Обновляем профиль и принудительно загружаем данные из Google/Apple
              final authProvider =
                  Provider.of<AuthProvider>(context, listen: false);
              final user = Supabase.instance.client.auth.currentUser;

              if (user != null &&
                  user.userMetadata != null &&
                  authProvider.userProfile != null) {
                final metadata = user.userMetadata!;
                String? name;

                // Пробуем получить имя из разных полей метаданных
                if (metadata.containsKey('full_name')) {
                  name = metadata['full_name'] as String?;
                } else if (metadata.containsKey('name')) {
                  name = metadata['name'] as String?;
                } else if (metadata.containsKey('user_name')) {
                  name = metadata['user_name'] as String?;
                } else if (metadata.containsKey('display_name')) {
                  name = metadata['display_name'] as String?;
                }

                // Если нашли имя, обновляем профиль
                if (name != null && name.isNotEmpty) {
                  //                  final updatedProfile = authProvider.userProfile!.copyWith(
                    fullName: name,
                  );
                  await authProvider.saveUserProfile(updatedProfile);
                } else {
                  // Как запасной вариант, используем пустое имя для запуска стандартной логики
                  if (authProvider.userProfile!.fullName == "User") {
                    final updatedProfile = authProvider.userProfile!.copyWith(
                      fullName:
                          "", // Специально устанавливаем пустое имя, чтобы сработало условие обновления
                    );
                    await authProvider.saveUserProfile(updatedProfile);
                  }
                }
              }

              await authProvider.loadUserProfile();
              setState(() {}); // Обновляем экран
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Профиль обновлен')),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OnboardingScreen(isFromProfile: true),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info Card
            Card(
              margin: EdgeInsets.all(16),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Theme.of(context).primaryColor,
                          backgroundImage: userProfile?.avatarUrl != null
                              ? NetworkImage(userProfile!.avatarUrl!)
                              : null,
                          child: (userProfile?.avatarUrl == null)
                              ? Text(
                                  userProfile?.fullName
                                          ?.substring(0, 1)
                                          .toUpperCase() ??
                                      user?.email
                                          ?.substring(0, 1)
                                          .toUpperCase() ??
                                      'U',
                                  style: TextStyle(
                                    fontSize: 24,
                                    color: Colors.white,
                                  ),
                                )
                              : null,
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userName ?? // Имя из метаданных
                                    userProfile?.fullName ?? // Имя из профиля
                                    user?.email
                                        ?.split('@')
                                        .first ?? // Email как запасной вариант
                                    'Требуется имя',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Member since ${createdAt.year}',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Fitness Profile Card
            Consumer<SurveyProvider>(
              builder: (context, surveyProvider, child) {
                final surveyState = surveyProvider.state;

                return Card(
                  margin: EdgeInsets.all(16),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fitness Profile',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16),
                        _buildInfoRow(
                            'Age', surveyState.age?.toString() ?? 'Not set'),
                        _buildInfoRow(
                            'Height',
                            surveyState.height != null
                                ? '${surveyState.height} cm'
                                : 'Not set'),
                        _buildInfoRow(
                            'Weight',
                            surveyState.weight != null
                                ? '${surveyState.weight.toInt()} kg'
                                : 'Not set'),
                        _buildInfoRow('Fitness Level',
                            surveyState.fitnessLevel ?? 'Not specified'),
                        _buildInfoRow('Weekly Workouts',
                            '${surveyState.weeklyWorkouts ?? 0}'),
                        _buildInfoRow('Workout Duration',
                            '${surveyState.workoutDuration ?? 0} min'),
                        SizedBox(height: 16),
                        Text(
                          'Goals',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: surveyState.selectedGoals
                                  ?.map((goal) => Chip(
                                        label: Text(goal),
                                        backgroundColor: Theme.of(context)
                                            .colorScheme
                                            .primaryContainer,
                                      ))
                                  .toList() ??
                              [],
                        ),
                        if (surveyState.injuries?.isNotEmpty ?? false) ...[
                          SizedBox(height: 16),
                          Text(
                            'Injuries/Limitations',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(surveyState.injuries?.join(", ") ?? ''),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey),
          ),
          Text(value),
        ],
      ),
    );
  }
}

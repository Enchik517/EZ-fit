import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:ui'; // Для ImageFilter
import '../models/user_profile.dart';
import '../providers/auth_provider.dart';
import '../providers/survey_provider.dart';
import 'developer_tools_screen.dart';
import 'login_screen.dart';
import '../main.dart'; // Для navigatorKey

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userProfile = authProvider.userProfile;
    final isLoading = authProvider.isLoading;
    final user = Supabase.instance.client.auth.currentUser;

    // Выводим отладочную информацию
    debugPrint('ProfileScreen build: isLoading = $isLoading');
    debugPrint('ProfileScreen build: userProfile = $userProfile');
    debugPrint('ProfileScreen build: user = ${user?.id}');

    if (userProfile == null && !isLoading) {
      debugPrint(
          'Профиль отсутствует, но загрузка не активна - пробуем загрузить снова');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        authProvider.loadUserProfile();
      });
    }

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

      debugPrint('Supabase user metadata: $metadata');
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Profile'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () async {
              // Обновляем профиль, получая данные из метаданных
              final authProvider =
                  Provider.of<AuthProvider>(context, listen: false);

              if (user != null &&
                  user.userMetadata != null &&
                  userProfile != null) {
                final metadata = user.userMetadata!;
                String? name;

                // Пробуем получить имя из метаданных
                if (metadata.containsKey('full_name')) {
                  name = metadata['full_name'] as String?;
                } else if (metadata.containsKey('name')) {
                  name = metadata['name'] as String?;
                } else if (metadata.containsKey('user_name')) {
                  name = metadata['user_name'] as String?;
                } else if (metadata.containsKey('display_name')) {
                  name = metadata['display_name'] as String?;
                }

                // Если есть имя, обновляем профиль
                if (name != null && name.isNotEmpty) {
                  final updatedProfile = userProfile.copyWith(
                    fullName: name,
                    name: userProfile.name, // Сохраняем старое имя пользователя
                  );
                  await authProvider.saveUserProfile(updatedProfile);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Profile updated')),
                  );
                }
              }

              // Обновляем профиль
              await authProvider.loadUserProfile();
            },
          ),
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              // Добавить навигацию к экрану редактирования профиля
            },
          ),
        ],
      ),
      body: userProfile == null
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Аватар и основная информация
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.blue,
                          backgroundImage: userProfile.avatarUrl != null
                              ? NetworkImage(userProfile.avatarUrl!)
                              : null,
                          child: userProfile.avatarUrl == null
                              ? Text(
                                  userProfile.fullName?[0].toUpperCase() ??
                                      userProfile.name?[0].toUpperCase() ??
                                      'A',
                                  style: TextStyle(fontSize: 32),
                                )
                              : null,
                        ),
                        SizedBox(height: 16),
                        Text(
                          userName ?? // Имя из метаданных Supabase
                              userProfile.fullName ?? // Полное имя из профиля
                              userProfile.name ?? // Имя пользователя из профиля
                              (user?.email?.split('@').first ??
                                  'Name required'),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 32),

                  // Физическая информация
                  _buildSection(
                    'Physical Information',
                    [
                      _buildInfoRow('Age',
                          '${_calculateAge(userProfile.birthDate)} years'),
                      _buildInfoRow('Weight',
                          '${userProfile.weight != null ? userProfile.weight!.toInt() : "Not set"} kg'),
                      _buildInfoRow(
                          'Height', '${userProfile.height ?? "Not set"} cm'),
                      _buildInfoRow('Gender', userProfile.gender ?? "Not set"),
                    ],
                  ),

                  // Фитнес информация
                  _buildSection(
                    'Fitness Information',
                    [
                      _buildInfoRow(
                          'Level', userProfile.fitnessLevel ?? "Not set"),
                      _buildInfoRow('Goals', userProfile.goals.join(", ")),
                      _buildInfoRow(
                          'Weekly Workouts', userProfile.weeklyWorkouts),
                      _buildInfoRow(
                          'Workout Duration', userProfile.workoutDuration),
                    ],
                  ),

                  // Статистика
                  _buildSection(
                    'Statistics',
                    [
                      _buildInfoRow(
                          'Total Workouts', '${userProfile.totalWorkouts}'),
                      _buildInfoRow('Total Sets', '${userProfile.totalSets}'),
                      _buildInfoRow('Total Hours', '${userProfile.totalHours}'),
                      _buildInfoRow(
                          'Current Streak', '${userProfile.workoutStreak}'),
                    ],
                  ),

                  // Настройки аккаунта
                  _buildSection(
                    'Account Settings',
                    [
                      // Кнопка выхода из аккаунта
                      Container(
                        margin: EdgeInsets.only(top: 16),
                        child: ElevatedButton(
                          onPressed: () => _handleSignOut(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[800],
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            minimumSize: Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Sign Out',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      // Кнопка удаления аккаунта
                      Container(
                        margin: EdgeInsets.only(top: 16),
                        child: ElevatedButton(
                          onPressed: () => _deleteAccount(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[900],
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            minimumSize: Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Delete Account',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        ...children,
        SizedBox(height: 32),
      ],
    );
  }

  Widget _buildInfoRow(String label, dynamic value) {
    String displayValue = '';

    if (value is String?) {
      if (value == null) {
        displayValue = 'Not set';
      } else {
        // Форматирование для fitnessLevel
        if (label == 'Level' && value.contains('BodyFatLevel.')) {
          String levelStr = value.replaceAll('BodyFatLevel.', '');
          switch (levelStr) {
            case 'level1':
              displayValue = '10-13%';
            case 'level2':
              displayValue = '14-17%';
            case 'level3':
              displayValue = '18-23%';
            case 'level4':
              displayValue = '24-28%';
            case 'level5':
              displayValue = '29-33%';
            case 'level6':
              displayValue = '34-37%';
            case 'level7':
              displayValue = '38-42%';
            case 'level8':
              displayValue = '43-49%';
            case 'level9':
              displayValue = '50%+';
            default:
              displayValue = levelStr;
          }
        }
        // Форматирование для weeklyWorkouts
        else if (label == 'Weekly Workouts' &&
            value.contains('WorkoutFrequency.')) {
          String freqStr = value.replaceAll('WorkoutFrequency.', '');
          switch (freqStr) {
            case 'none':
              displayValue = '0 sessions / week';
            case 'low':
              displayValue = '1-3 sessions / week';
            case 'medium':
              displayValue = '4-6 sessions / week';
            case 'high':
              displayValue = '7+ sessions / week';
            default:
              displayValue = freqStr;
          }
        } else {
          // Проверяем и заменяем русские строки на английские
          if (value == 'Начинающий') {
            displayValue = 'Beginner';
          } else if (value.contains('Общее улучшение физической формы')) {
            displayValue = 'General physical fitness improvement';
          } else if (value == '3-4 раза в неделю') {
            displayValue = '3-4 times a week';
          } else if (value == '30-45 минут') {
            displayValue = '30-45 minutes';
          } else if (value == 'Not set' || value == 'Не указано') {
            displayValue = 'Not set';
          } else {
            displayValue = value;
          }
        }
      }
    } else {
      displayValue = value?.toString() ?? 'Not set';
    }

    return Container(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          Text(
            displayValue,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  int _calculateAge(DateTime? birthDate) {
    if (birthDate == null) return 0;
    DateTime now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  void _deleteAccount(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Account'),
        content: Text(
          'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              // Закрываем диалог
              Navigator.pop(context);

              try {
                // Показываем индикатор загрузки
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => WillPopScope(
                    onWillPop: () async => false,
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                );

                // Используем AuthProvider для удаления аккаунта
                final authProvider =
                    Provider.of<AuthProvider>(context, listen: false);
                await authProvider.deleteAccount();

                // Поскольку удаление аккаунта обрабатывает navigatorKey,
                // дальнейшее управление навигацией не требуется
              } catch (e) {
                // Закрываем диалог загрузки
                Navigator.pop(context);

                // Показываем ошибку
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting account: $e')),
                );
              }
            },
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Обработчик выхода из аккаунта
  void _handleSignOut(BuildContext context) async {
    // Показываем диалог подтверждения
    final shouldSignOut = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: Text(
              'Sign Out',
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              'Are you sure you want to sign out?',
              style: TextStyle(color: Colors.white),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false), // Отмена
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.blue),
                ),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.of(context).pop(true), // Подтверждение
                child: Text(
                  'Sign Out',
                  style: TextStyle(color: Colors.blue),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldSignOut) return;

    // Получаем AuthProvider
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Создаем стильный индикатор загрузки
    final loadingOverlay = OverlayEntry(
      builder: (context) => Container(
        color: Colors.black.withOpacity(0.85),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Center(
            child: Container(
              width: 220,
              padding: EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF202020),
                    Color(0xFF2A2A2A),
                    Color(0xFF323232),
                  ],
                ),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 30,
                    spreadRadius: 2,
                  )
                ],
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 0.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Анимированный индикатор загрузки
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 1,
                        )
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Фоновый круг
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withOpacity(0.3),
                          ),
                        ),
                        // Иконка
                        ShaderMask(
                          shaderCallback: (Rect bounds) {
                            return LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.8),
                                Colors.white.withOpacity(0.4),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ).createShader(bounds);
                          },
                          child: Icon(
                            Icons.logout_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        // Прогресс-индикатор
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.primary,
                            ),
                            strokeWidth: 3,
                            backgroundColor: Colors.black.withOpacity(0.2),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 28),
                  // Текстовая информация без подчеркивания
                  Text(
                    'Signing Out',
                    semanticsLabel: 'Signing Out',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  SizedBox(height: 12),
                  // Подтекст
                  Text(
                    'Please wait a moment...',
                    semanticsLabel: 'Please wait a moment',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      decoration: TextDecoration.none,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    // Показываем индикатор загрузки
    Overlay.of(context).insert(loadingOverlay);

    try {
      // Выполняем выход
      await authProvider.signOut();

      // Проверяем, действительно ли вышли
      final supabase = Supabase.instance.client;
      final currentUser = supabase.auth.currentUser;
      if (currentUser != null) {
        print('Warning: User still logged in after signOut');
        // Попробуем еще раз выйти
        await supabase.auth.signOut();
      }

      // Закрываем индикатор и возвращаемся на экран входа
      loadingOverlay.remove();

      if (context.mounted) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/auth', (route) => false);

        // Используем Future.delayed, чтобы сообщение появилось после завершения навигации
        Future.delayed(Duration(milliseconds: 300), () {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 6,
                duration: Duration(seconds: 3),
                content: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.logout_rounded,
                          color: Colors.white, size: 22),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "See you soon!",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "You have successfully logged out",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                              letterSpacing: 0.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                backgroundColor: Color(0xFF3949AB),
              ),
            );
          }
        });
      }
    } catch (e) {
      // Закрываем индикатор загрузки
      loadingOverlay.remove();

      if (context.mounted) {
        // Показываем сообщение об ошибке
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error signing out: ${e.toString()}'),
          backgroundColor: Colors.red,
        ));

        // Всё равно перенаправляем на экран входа
        Future.delayed(Duration(milliseconds: 500), () {
          if (context.mounted) {
            Navigator.of(context)
                .pushNamedAndRemoveUntil('/auth', (route) => false);
          }
        });
      }
    }
  }
}

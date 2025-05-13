import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/workout.dart';
import '../providers/workout_provider.dart';
import 'workout_details_screen.dart';
import 'chat_screen.dart';
import 'active_workout_screen.dart';
import 'onboarding/onboarding_screen.dart';
import '../widgets/workout_details_modal.dart';
import '../models/workout_log.dart';
import 'profile_screen.dart';
import 'dart:ui';
import 'basics_screen.dart';
import 'disclaimer_screen.dart';
import 'goals_screen.dart';
import 'registration_flow.dart';
import 'goals_flow_screen.dart';
import 'home_screen.dart';
import 'workout_category_screen.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import '../patches/favorite_patch.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/subscription_provider.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({Key? key}) : super(key: key);

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _refreshData();

    // Автоматически создаем тестовую тренировку, если нет избранных
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndCreateTestWorkout();
    });

    // Добавляем обработчик для отслеживания изменения вкладок
    _tabController.addListener(() {
      if (_tabController.index == 1) {
        // Вкладка "Избранное"
        print('👍 Переключились на вкладку "Избранное"');

        // Синхронизируем избранное при переключении на эту вкладку
        FavoritePatch.syncFavorites(context);

        final workoutProvider =
            Provider.of<WorkoutProvider>(context, listen: false);
        final favoriteWorkouts = workoutProvider.getFavoriteWorkouts();
        print('📊 Количество избранных тренировок: ${favoriteWorkouts.length}');

        for (var workout in favoriteWorkouts) {
          print(
              '💪 ${workout.name} (id: ${workout.id}, isFavorite: ${workout.isFavorite})');
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    final workoutProvider =
        Provider.of<WorkoutProvider>(context, listen: false);

    // Загружаем логи тренировок
    await workoutProvider.loadWorkoutLogs();

    // Синхронизируем избранное
    if (_tabController.index == 1) {
      // Если сейчас активна вкладка "Избранное", обновляем статус
      await FavoritePatch.syncFavorites(context);
    }
  }

  // Метод для проверки избранных тренировок напрямую в базе данных
  Future<void> _verifyFavoritesInDatabase() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        print('❌ Ошибка: пользователь не авторизован');
        return;
      }

      print('👤 Проверка избранных тренировок для пользователя: $userId');

      // Выполняем прямой запрос к таблице favorite_workouts
      final favoritesResponse = await Supabase.instance.client
          .from('favorite_workouts')
          .select()
          .eq('user_id', userId);

      print(
          '📊 Найдено записей в БД favorite_workouts: ${favoritesResponse.length}');

      // Выводим ID для отладки
      if (favoritesResponse.isNotEmpty) {
        for (var i = 0; i < favoritesResponse.length; i++) {
          final item = favoritesResponse[i];
          print(
              '📌 Запись #${i + 1}: workout_id=${item['workout_id']}, name=${item['workout_name']}');
        }
      }
    } catch (e) {
      print('❌ Ошибка проверки избранного в БД: $e');
    }
  }

  // Проверяет наличие избранных тренировок и создает тестовую, если их нет
  Future<void> _checkAndCreateTestWorkout() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        if (kDebugMode) debugPrint('❌ Пользователь не авторизован');
        return;
      }

      // Проверяем наличие избранных тренировок
      final favorites = await Supabase.instance.client
          .from('favorite_workouts')
          .select('count')
          .eq('user_id', userId)
          .single();

      final count = favorites['count'] as int? ?? 0;

      if (kDebugMode) debugPrint('📊 Найдено избранных тренировок: $count');

      // Если тренировок нет, создаем тестовую
      if (count == 0) {
        if (kDebugMode)
          debugPrint('⚠️ Избранных тренировок нет, создаем тестовую');
        await FavoritePatch.createTestWorkout(context);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Ошибка проверки избранных тренировок: $e');
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  void _showRegistrationMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Test Registration Screens',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              _buildTestButton('Start Goals Flow (New)', () {
                Navigator.pop(context);
                _openGoalsFlow();
              }),
              SizedBox(height: 8),
              _buildTestButton('Start Full Registration Flow (Old)', () {
                Navigator.pop(context);
                RegistrationFlow.start(context);
              }),
              SizedBox(height: 8),
              _buildTestButton('Goals Screen', () {
                Navigator.pop(context);
                RegistrationFlow.startFromIndex(context, 4);
              }),
              SizedBox(height: 8),
              _buildTestButton('Equipment Screen', () {
                Navigator.pop(context);
                RegistrationFlow.startFromIndex(context, 5);
              }),
              SizedBox(height: 8),
              _buildTestButton('Schedule Screen', () {
                Navigator.pop(context);
                RegistrationFlow.startFromIndex(context, 7);
              }),
            ],
          ),
        );
      },
    );
  }

  void _openGoalsFlow() {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => GoalsFlowScreen(),
      ),
    )
        .then((userData) {
      if (userData != null) {
        print('Received user data: $userData');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Goals flow completed successfully!')),
        );
      }
    });
  }

  Widget _buildTestButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.centerLeft,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  void _toggleFavorite(Workout workout) {
    if (kDebugMode) {
      // Для отладки
      final provider = Provider.of<WorkoutProvider>(context, listen: false);

      // Посмотрим список избранных тренировок
      final favorites = provider.getFavoriteWorkouts();
      print('📝 Current favorites count: ${favorites.length}');

      // Выведем их ID для отладки
      for (var favorite in favorites) {
        print('   - Favorite workout: ${favorite.name} (ID: ${favorite.id})');
      }
    }

    // Создаем локальную копию с противоположным статусом для немедленного обновления UI
    final updatedWorkout = workout.toggleFavoriteStatus();
    final isCurrentlyFavorite = workout.isFavorite;
    final newStatus = !isCurrentlyFavorite;

    // Обновляем локальный UI немедленно
    setState(() {
      // Это вызовет перерисовку виджета с обновленным статусом
    });

    // Сначала показываем индикатор загрузки
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
            SizedBox(width: 16),
            Text(isCurrentlyFavorite
                ? 'Удаление из избранного...'
                : 'Добавление в избранное...'),
          ],
        ),
        duration: Duration(seconds: 1),
      ),
    );

    // Выполняем прямое обновление в Supabase
    _updateFavoriteStatusInDatabase(workout, newStatus).then((success) {
      if (success) {
        if (kDebugMode) {
          print('✅ Successfully toggled favorite status');
        }

        // Принудительно перезагружаем данные
        final provider = Provider.of<WorkoutProvider>(context, listen: false);

        // Загружаем тренировки и обновляем UI
        provider.loadWorkouts().then((_) {
          if (kDebugMode) {
            final newState = provider.getFavoriteWorkouts();
            print('📝 After toggle, favorites count: ${newState.length}');
          }

          // Обновляем UI в любом случае
          setState(() {
            // Перерисовываем виджет, даже если уже обновили выше
          });

          // Убеждаемся, что провайдер уведомляет всех слушателей
          provider.notifyListeners();

          // Показываем уведомление об успешном обновлении
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(newStatus
                  ? '${workout.name} добавлена в избранное'
                  : '${workout.name} удалена из избранного'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        });
      } else {
        if (kDebugMode) {
          print('❌ Failed to toggle favorite status');
        }

        // Возвращаем предыдущее состояние UI в случае ошибки
        setState(() {
          // Это отменит визуальные изменения, если запрос не удался
        });

        // Показываем ошибку
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Ошибка обновления избранного'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  // Новый метод для прямого обновления статуса в базе данных
  Future<bool> _updateFavoriteStatusInDatabase(
      Workout workout, bool newStatus) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Пользователь не авторизован');
      }

      if (newStatus) {
        // Добавление в избранное
        print('📌 Adding workout to favorites: ${workout.name}');

        // Создаем копию с правильным статусом
        final favoriteWorkout = workout.copyWith(isFavorite: true);

        // Проверяем существование записи
        final existing = await Supabase.instance.client
            .from('favorite_workouts')
            .select()
            .eq('user_id', userId)
            .eq('workout_id', workout.id)
            .maybeSingle();

        if (existing != null) {
          // Обновляем существующую запись
          await Supabase.instance.client.from('favorite_workouts').update({
            'workout_data': favoriteWorkout.toJson(),
            'updated_at': DateTime.now().toIso8601String(),
          }).eq('id', existing['id']);

          print('✅ Updated existing record in favorite_workouts');
        } else {
          // Создаем новую запись
          await Supabase.instance.client.from('favorite_workouts').insert({
            'user_id': userId,
            'workout_id': workout.id,
            'workout_name': workout.name,
            'workout_data': favoriteWorkout.toJson(),
            'created_at': DateTime.now().toIso8601String(),
          });

          print('✅ Created new record in favorite_workouts');
        }

        // Обновляем запись в таблице workouts
        await Supabase.instance.client
            .from('workouts')
            .update({'is_favorite': true}).eq('id', workout.id);

        print('✅ Updated status in workouts table');
      } else {
        // Удаление из избранного
        print('🗑️ Removing workout from favorites: ${workout.name}');

        await Supabase.instance.client
            .from('favorite_workouts')
            .delete()
            .eq('user_id', userId)
            .eq('workout_id', workout.id);

        print('✅ Deleted record from favorite_workouts');

        // Обновляем запись в таблице workouts
        await Supabase.instance.client
            .from('workouts')
            .update({'is_favorite': false}).eq('id', workout.id);

        print('✅ Updated status in workouts table');
      }

      return true;
    } catch (e) {
      print('❌ Error updating favorite status: $e');
      return false;
    }
  }

  void _navigateToWorkoutDetails(Workout workout) {
    final subscriptionProvider =
        Provider.of<SubscriptionProvider>(context, listen: false);

    if (!subscriptionProvider.isSubscribed) {
      subscriptionProvider.showSubscription();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutDetailsScreen(workout: workout),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final workoutProvider = Provider.of<WorkoutProvider>(context);
    final workoutLogs = workoutProvider.workoutLogs;
    final isLoading = workoutProvider.isLoading;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Workouts',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () {
              // Навигация к профилю
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileScreen()),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blue,
          tabs: const [
            Tab(text: 'History'),
            Tab(text: 'Favorites'),
            Tab(text: 'Collections'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // История тренировок
          workoutLogs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.fitness_center,
                        size: 64,
                        color: Colors.grey[700],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No workout history yet',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Complete your first workout to see it here',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => const HomeScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Go to Home',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  key: _refreshIndicatorKey,
                  onRefresh: _refreshData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: workoutLogs.length,
                    itemBuilder: (context, index) {
                      final workoutLog = workoutLogs[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF252527),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        workoutLog.workoutName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${_formatDate(workoutLog.date)} • ${workoutLog.duration.inMinutes} min',
                                        style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: workoutLog.isCompleted
                                          ? Colors.green.withOpacity(0.2)
                                          : Colors.orange.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: Text(
                                      workoutLog.isCompleted
                                          ? 'Completed'
                                          : 'Partial',
                                      style: TextStyle(
                                        color: workoutLog.isCompleted
                                            ? Colors.green[300]
                                            : Colors.orange[300],
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Exercise list preview
                              Text(
                                '${workoutLog.exercises.length} exercises',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

          // Избранные тренировки
          Consumer<WorkoutProvider>(
            builder: (context, workoutProvider, child) {
              final favoriteWorkouts = workoutProvider.getFavoriteWorkouts();
              final isLoading = workoutProvider.isLoading;

              // Прямая отладка списка избранных тренировок
              if (kDebugMode) {
                print('🔍 Отладка избранных тренировок на экране:');
                print(
                    '📊 Всего тренировок в избранном: ${favoriteWorkouts.length}');

                // Выполняем прямой запрос к Supabase для проверки
                _verifyFavoritesInDatabase();
              }

              // Показываем индикатор загрузки
              if (isLoading) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.blue),
                      SizedBox(height: 16),
                      Text(
                        'Loading favorite workouts...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Если список избранного пуст
              if (favoriteWorkouts.isEmpty) {
                // Проверяем БД напрямую для отладки
                _verifyFavoritesInDatabase();

                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.favorite_border,
                        size: 64,
                        color: Colors.grey[700],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No favorite workouts yet',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Mark workouts as favorites to see them here',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              // Показываем список избранных тренировок
              return RefreshIndicator(
                onRefresh: _refreshData,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: favoriteWorkouts.length,
                  itemBuilder: (context, index) {
                    final workout = favoriteWorkouts[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF252527),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        onTap: () {
                          _navigateToWorkoutDetails(workout);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          workout.name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${workout.duration} min • ${workout.difficulty.toUpperCase()}',
                                          style: TextStyle(
                                            color: Colors.grey[400],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.favorite,
                                      color: Colors.red,
                                    ),
                                    onPressed: () {
                                      _toggleFavorite(workout);
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '${workout.exercises.length} exercises • ${workout.focus.toUpperCase()}',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 14,
                                ),
                              ),
                              if (workout.targetMuscles.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: workout.targetMuscles.map((muscle) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      child: Text(
                                        muscle,
                                        style: TextStyle(
                                          color: Colors.blue[300],
                                          fontSize: 12,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),

          // Коллекции
          GridView.count(
            crossAxisCount: 2,
            padding: const EdgeInsets.all(16),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: [
              _buildWorkoutCategory(
                'Express Workouts',
                '15-minute workouts to fit in your day',
                Icons.timer,
              ),
              _buildWorkoutCategory(
                'HIIT',
                'High-intensity workouts aimed at weight loss',
                Icons.local_fire_department,
              ),
              _buildWorkoutCategory(
                'Home Vibe',
                'Workouts without equipment',
                Icons.home,
              ),
              _buildWorkoutCategory(
                'Peaches 🍑',
                'Get those glutes',
                Icons.fitness_center,
              ),
              _buildWorkoutCategory(
                'Strength',
                'Train for strength',
                Icons.fitness_center,
              ),
              _buildWorkoutCategory(
                'Full Body',
                'Overall health',
                Icons.accessibility_new,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutCategory(
      String title, String description, IconData icon) {
    return InkWell(
      onTap: () {
        // Переход на экран категории тренировок
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WorkoutCategoryScreen(
              categoryName: title,
              categoryDescription: description,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF252527),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

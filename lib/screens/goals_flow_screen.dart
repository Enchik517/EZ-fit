import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/auth_provider.dart';
import 'birth_date_screen.dart';
import 'height_screen.dart';
import 'weight_screen.dart';
import 'weight_trend_screen.dart';
import 'body_fat_screen.dart';
import 'workout_frequency_screen.dart';
import 'workout_duration_screen.dart';
import 'target_body_screen.dart';
import 'focus_screen.dart';
import 'progress_projection_screen.dart';
import 'injuries_screen.dart';
import 'weight_prediction_screen.dart';
import 'weight_loss_comparison_screen.dart';
import 'plan_generating_screen.dart';
import 'plan_ready_screen.dart';
import 'target_waist_size_screen.dart';
import 'package:superwallkit_flutter/superwallkit_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'disclaimer_screen.dart';

class GoalsFlowScreen extends StatefulWidget {
  const GoalsFlowScreen({Key? key}) : super(key: key);

  @override
  State<GoalsFlowScreen> createState() => _GoalsFlowScreenState();
}

class _GoalsFlowScreenState extends State<GoalsFlowScreen> {
  final Map<String, dynamic> _userData = {};
  int _currentPage = 0;
  final PageController _pageController = PageController();
  bool _isChecking = true;
  bool _paywallShown = false;

  @override
  void initState() {
    super.initState();
    _initializeUserData();
    _checkSurveyCompletionStatus();
  }

  void _initializeUserData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final profile = authProvider.userProfile;

    if (profile != null) {
      _userData['gender'] = profile.gender;
      _userData['birthDate'] = profile.birthDate;
      _userData['height'] = profile.height;
      _userData['weight'] = profile.weight;
      _userData['fitnessLevel'] = profile.fitnessLevel;
      _userData['goals'] = profile.goals;
      _userData['weeklyWorkouts'] = profile.weeklyWorkouts;
    }
  }

  // Проверка статуса завершения опроса
  Future<void> _checkSurveyCompletionStatus() async {
    try {
      setState(() {
        _isChecking = true;
      });

      print('GoalsFlowScreen: _checkSurveyCompletionStatus начало проверки');

      // Получаем AuthProvider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Выполняем полную проверку базы данных
      final hasCompletedSurvey =
          await authProvider.forceCheckSurveyCompletionInDatabase();

      print(
          'GoalsFlowScreen: hasCompletedSurvey из базы = $hasCompletedSurvey');

      if (hasCompletedSurvey) {
        // Если опрос завершен, переходим на главный экран
        print('GoalsFlowScreen: опрос уже пройден, переходим на главный экран');
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/main');
        }
      } else {
        print(
            'GoalsFlowScreen: опрос НЕ пройден, отображаем экраны ввода данных');
        if (mounted) {
          setState(() {
            _isChecking = false;
          });
        }
      }
    } catch (e) {
      print('GoalsFlowScreen: ошибка при проверке статуса опроса - $e');
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  // Список заголовков для всех экранов
  final List<String> _titles = [
    'Gender', // 0
    'Date of Birth', // 1
    'Height', // 2
    'Weight', // 3
    'Recent Weight Trend', // 4
    'Body Fat', // 5
    'Waist Size', // 6
    'Workout Frequency', // 7
    'Goals Selection', // 8
    'Target Weight', // 9
    'Target Body Fat', // 10
    'Target Waist Size', // 11 - Новый экран для ввода желаемого размера талии
    'Progress Projection', // 12
    'Body Focus', // 13
    'Injuries', // 14
    'Weight Prediction', // 15
    'Weight Loss Comparison', // 16
    'Plan Generating', // 17
    'Plan Ready', // 18
    'Paywall', // 19
  ];

  void _goToNextScreen() {
    // Добавляем отладочное сообщение
    print(
        'Переход на следующий экран: ${_currentPage + 1} из ${_titles.length - 1}');

    if (_currentPage < _titles.length - 1) {
      setState(() {
        _currentPage++;
      });
    } else {
      // Завершаем опрос и сохраняем данные
      _saveUserData();
    }
  }

  void _goToPreviousScreen() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
      });
    } else {
      // Если мы на первом экране и нажата кнопка назад, возвращаемся на экран аутентификации
      print(
          'GoalsFlowScreen: Возврат на экран аутентификации при нажатии "назад" с первого экрана опроса');
      Navigator.of(context).pushReplacementNamed('/auth');
    }
  }

  void _updateUserData(String key, dynamic value) {
    setState(() {
      _userData[key] = value;
      if (key == 'isMetric') {
        // Обновляем настройки метрической системы
      }
    });
  }

  // Метод для сохранения данных пользователя и возврата к предыдущему экрану
  void _saveUserData() async {
    try {
      print('GoalsFlowScreen: _saveUserData - начинаем сохранение данных');

      // Получаем AuthProvider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Убедимся, что в _userData всегда есть hasCompletedSurvey = true
      _userData['hasCompletedSurvey'] = true;

      print(
          'GoalsFlowScreen: _saveUserData - данные для сохранения: ${_userData.toString()}');

      // Обновляем профиль пользователя данными из опроса
      if (authProvider.userProfile != null) {
        print(
            'GoalsFlowScreen: _saveUserData - обновляем существующий профиль');

        // Безопасно получаем данные из _userData
        final gender = _userData['gender'];
        final birthDate = _userData['birthDate'];
        final height = _userData['height'];
        final weight = _userData['weight'];
        final bodyFatLevel = _userData['bodyFatLevel'];
        final selectedGoals = _userData['selectedGoals'];
        final workoutFrequency = _userData['workoutFrequency'];

        final updatedProfile = authProvider.userProfile!.copyWith(
          // Обновляем основные данные профиля из _userData с безопасными проверками
          gender: gender is String ? gender : authProvider.userProfile!.gender,
          birthDate: birthDate is DateTime
              ? birthDate
              : authProvider.userProfile!.birthDate,
          height: height is double ? height : authProvider.userProfile!.height,
          weight: weight is double ? weight : authProvider.userProfile!.weight,
          fitnessLevel: bodyFatLevel != null
              ? bodyFatLevel.toString()
              : authProvider.userProfile!.fitnessLevel,
          goals: selectedGoals is List
              ? List<String>.from(selectedGoals)
              : authProvider.userProfile!.goals,
          weeklyWorkouts: workoutFrequency != null
              ? workoutFrequency.toString()
              : authProvider.userProfile!.weeklyWorkouts,
          hasCompletedSurvey: true, // Помечаем, что опрос пройден
        );

        // Сначала обновляем напрямую в базе
        await Supabase.instance.client.from('user_profiles').update(
            {'has_completed_survey': true}).eq('id', authProvider.user!.id);

        print(
            'GoalsFlowScreen: _saveUserData - обновили has_completed_survey=true напрямую в базе');

        // Сохраняем обновленный профиль
        await authProvider.saveUserProfile(updatedProfile);

        print(
            'GoalsFlowScreen: _saveUserData - профиль сохранен через AuthProvider');
        print(
            'hasCompletedSurvey set to: ${updatedProfile.hasCompletedSurvey}');

        // Также сохраняем флаг в метаданных пользователя
        await authProvider.updateSurveyCompletionFlag(true);
        print('GoalsFlowScreen: _saveUserData - флаг обновлен в метаданных');

        // Повторная проверка базы данных
        final response = await Supabase.instance.client
            .from('user_profiles')
            .select('has_completed_survey')
            .eq('id', authProvider.user!.id)
            .single();

        print(
            'GoalsFlowScreen: _saveUserData - после всех обновлений has_completed_survey в базе = ${response['has_completed_survey']}');

        // Принудительно перезагружаем профиль
        await authProvider.loadUserProfile();
        print(
            'GoalsFlowScreen: _saveUserData - профиль перезагружен, hasCompletedSurvey = ${authProvider.userProfile?.hasCompletedSurvey}');
      } else {
        print(
            'GoalsFlowScreen: _saveUserData - ОШИБКА: профиль пользователя не найден');
      }

      // Вместо возврата данных перенаправляем на главный экран
      print('GoalsFlowScreen: _saveUserData - перенаправляем на главный экран');
      Navigator.of(context).pushReplacementNamed('/main');
    } catch (e) {
      // В случае ошибки все равно перенаправляем на главный экран
      print('GoalsFlowScreen: _saveUserData - ОШИБКА при сохранении: $e');
      // Убедимся, что в возвращаемых данных всегда есть hasCompletedSurvey = true
      _userData['hasCompletedSurvey'] = true;
      Navigator.of(context).pushReplacementNamed('/main');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Показываем индикатор загрузки, пока проверяем статус опроса
    if (_isChecking) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Loading data...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        _goToPreviousScreen();
        return false;
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF170B0C),
                Colors.black,
              ],
            ),
          ),
          child: Column(
            children: [
              AppBar(
                backgroundColor: Colors.transparent,
                title: Text(''),
                leading: IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: _goToPreviousScreen,
                ),
                elevation: 0,
              ),
              Container(
                width: double.infinity,
                height: 1,
                color: Colors.white.withOpacity(0.1),
                margin: EdgeInsets.only(bottom: 24),
                child: FractionallySizedBox(
                  widthFactor: (_currentPage + 1) / _titles.length,
                  child: Container(
                    color: Colors.white,
                  ),
                ),
              ),
              Expanded(
                child: _buildCurrentScreen(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentScreen() {
    //// Отладка
    switch (_currentPage) {
      case 0:
        return _GenderSelectionContent(
          onSelect: (gender) {
            _updateUserData('gender', gender);
            _goToNextScreen();
          },
        );
      case 1:
        return BirthDateScreen(
          onSelect: (date) {
            _updateUserData('birthDate', date);
            _goToNextScreen();
          },
        );
      case 2:
        return HeightScreen(
          onSelect: (height) {
            _updateUserData('height', height);
            _goToNextScreen();
          },
        );
      case 3:
        // Безопасно обрабатываем значения с проверкой на null
        final height = _userData['height'];
        final isMetric = _userData['isMetric'];
        return WeightScreen(
          onSelect: (weight) {
            _updateUserData('weight', weight);
            _goToNextScreen();
          },
          height: height is double
              ? height
              : 170.0, // Среднее значение роста, если null
          isMetric: isMetric is bool ? isMetric : true,
          onUnitChanged: (isMetric) {
            _updateUserData('isMetric', isMetric);
          },
        );
      case 4:
        return WeightTrendScreen(
          onSelect: (trend) {
            _updateUserData('weightTrend', trend);
            _goToNextScreen();
          },
        );
      case 5:
        // Безопасно обрабатываем gender для параметра isMale
        final gender = _userData['gender'];
        return BodyFatScreen(
          onSelect: (bodyFatLevel) {
            _updateUserData('bodyFatLevel', bodyFatLevel);
            _goToNextScreen();
          },
          isMale:
              gender is String ? gender == 'Male' : true, // По умолчанию true
        );
      case 6:
        return WaistSizeScreen(
          onSelect: (waistSize) {
            _updateUserData('waistSize', waistSize);
            _goToNextScreen();
          },
          isMetric: _userData['isMetric'] is bool
              ? _userData['isMetric'] as bool
              : true,
          onUnitChanged: (isMetric) {
            _updateUserData('isMetric', isMetric);
          },
        );
      case 7:
        return WorkoutFrequencyScreen(
          onSelect: (frequency) {
            _updateUserData('workoutFrequency', frequency);
            _goToNextScreen();
          },
        );
      case 8:
        return _GoalSelectionContent(
          onContinue: (selectedGoals) {
            _updateUserData('selectedGoals', selectedGoals);
            _goToNextScreen();
          },
        );
      case 9:
        return TargetWeightScreen(
          onSelect: (data) {
            _updateUserData('targetWeight', data['targetWeight']);
            _updateUserData('goalRate', data['goalRate']);
            _updateUserData('weeklyRateLbs', data['weeklyRateLbs']);
            _updateUserData('weeklyRateBwPercent', data['weeklyRateBwPercent']);
            _updateUserData('monthlyRateLbs', data['monthlyRateLbs']);
            _updateUserData(
                'monthlyRateBwPercent', data['monthlyRateBwPercent']);
            _updateUserData('rateLabel', data['rateLabel']);
            _goToNextScreen();
          },
          currentWeight: _userData['weight'] is double
              ? _userData['weight'] as double
              : 70.0,
          isMetric: _userData['isMetric'] is bool
              ? _userData['isMetric'] as bool
              : true,
          onUnitChanged: (isMetric) {
            _updateUserData('isMetric', isMetric);
          },
        );
      case 10:
        return TargetBodyScreen(
          onSelect: (bodyFatRange) {
            _updateUserData('targetBodyFat', bodyFatRange);
            _goToNextScreen();
          },
          isMale: _userData['gender'] is String
              ? _userData['gender'] == 'Male'
              : true,
        );
      case 11:
        return TargetWaistSizeScreen(
          onSelect: (targetWaistSize) {
            _updateUserData('targetWaistSize', targetWaistSize);
            _goToNextScreen();
          },
          currentWaistSize: _userData['waistSize'] is double
              ? _userData['waistSize'] as double
              : 80.0,
          isMetric: _userData['isMetric'] is bool
              ? _userData['isMetric'] as bool
              : true,
          onUnitChanged: (isMetric) {
            _updateUserData('isMetric', isMetric);
          },
        );
      case 12:
        return ProgressProjectionScreen(
          onNext: () {
            _goToNextScreen();
          },
          gender: _userData['gender'] is String
              ? _userData['gender'] as String
              : 'Male',
          age: _getUserAge(),
          currentWeight: _userData['weight'] is double
              ? _userData['weight'] as double
              : null,
          targetWeight: _userData['targetWeight'] is double
              ? _userData['targetWeight'] as double
              : null,
          height: _userData['height'] is double
              ? _userData['height'] as double
              : null,
          bodyFatRange: _userData['targetBodyFat'] is String
              ? _userData['targetBodyFat'] as String
              : null,
        );
      case 13:
        return FocusScreen(
          onSelect: (focusAreas) {
            _updateUserData('focusAreas', focusAreas);
            _goToNextScreen();
          },
        );
      case 14:
        return InjuriesScreen(
          onSelect: (injuries, notes) {
            _updateUserData('injuries', injuries);
            if (notes != null) {
              _updateUserData('injuryNotes', notes);
            }
            _goToNextScreen();
          },
          gender: _userData['gender'] ?? 'Male',
        );
      case 15:
        return WeightPredictionScreen(
          onNext: () {
            _goToNextScreen();
          },
          currentWeight: _userData['weight'] is double
              ? _userData['weight'] as double
              : 70.0,
          targetWeight: _userData['targetWeight'] is double
              ? _userData['targetWeight'] as double
              : null,
          weightTrend: _userData['weightTrend'],
          workoutFrequency: _userData['workoutFrequency'] is int
              ? _userData['workoutFrequency'] as int
              : null,
          isMetric: _userData['isMetric'] is bool
              ? _userData['isMetric'] as bool
              : true,
        );
      case 16:
        return WeightLossComparisonScreen(
          onNext: () {
            _goToNextScreen();
          },
          gender: _userData['gender'] is String
              ? _userData['gender'] as String
              : 'Male',
          weight: _userData['weight'] is double
              ? _userData['weight'] as double
              : null,
          bodyFat: _getBodyFatValueFromLevel(),
          waistSize: _userData['waistSize'] is double
              ? _userData['waistSize'] as double
              : null,
          targetWeight: _userData['targetWeight'] is double
              ? _userData['targetWeight'] as double
              : null,
          targetBodyFat: _getTargetBodyFatValue(),
          targetWaistSize: _userData['targetWaistSize'] is double
              ? _userData['targetWaistSize'] as double
              : _calculateTargetWaistSize(),
        );
      case 17:
        return PlanGeneratingScreen(
          onNext: () {
            _goToNextScreen();
          },
        );
      case 18:
        return PlanReadyScreen(
          onGetPlan: () {
            _goToNextScreen();
          },
          gender: _userData['gender'] is String
              ? _userData['gender'] as String
              : 'Male',
          currentWeight: _userData['weight'] is double
              ? _userData['weight'] as double
              : null,
          targetWeight: _userData['targetWeight'] is double
              ? _userData['targetWeight'] as double
              : null,
          focusAreas: _userData['focusAreas'] is List
              ? List<String>.from(_userData['focusAreas'])
              : null,
        );
      case 19:
        // Переходим на экран с возможностью пропуска paywall
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          // Проверяем, что paywall еще не был показан
          if (_paywallShown) {
            debugPrint('GoalsFlowScreen: paywall уже показан, пропускаем');
            return;
          }

          // Помечаем, что paywall будет показан (важно сделать это сразу)
          setState(() {
            _paywallShown = true;
          });

          debugPrint(
              'GoalsFlowScreen: начинаем показ paywall и сохранение данных опроса');

          try {
            // Получаем AuthProvider и сохраняем данные профиля
            final authProvider =
                Provider.of<AuthProvider>(context, listen: false);

            // Обновляем профиль пользователя данными из опроса
            if (authProvider.userProfile != null) {
              // Получаем текущий пол или используем мужской по умолчанию
              final gender = _userData['gender'];
              final genderValue = gender is String ? gender : 'male';

              // Обновляем профиль, устанавливая флаг hasCompletedSurvey в true и сохраняя данные опроса
              final updatedProfile = authProvider.userProfile!.copyWith(
                gender: genderValue,
                birthDate: _userData['birthDate'] is DateTime
                    ? _userData['birthDate'] as DateTime
                    : authProvider.userProfile!.birthDate,
                height: _userData['height'] is double
                    ? _userData['height'] as double
                    : authProvider.userProfile!.height,
                weight: _userData['weight'] is double
                    ? _userData['weight'] as double
                    : authProvider.userProfile!.weight,
                fitnessLevel: _userData['bodyFatLevel'] is String
                    ? _userData['bodyFatLevel'] as String
                    : authProvider.userProfile!.fitnessLevel,
                goals: _userData['selectedGoals'] is List
                    ? List<String>.from(_userData['selectedGoals'] as List)
                    : authProvider.userProfile!.goals,
                weeklyWorkouts: _userData['workoutFrequency'] != null
                    ? _userData['workoutFrequency'].toString()
                    : authProvider.userProfile!.weeklyWorkouts,
                hasCompletedSurvey: true,
              );

              // 1. Принудительно сразу обновляем в базе данных
              await Supabase.instance.client.from('user_profiles').update({
                'has_completed_survey': true,
                'gender': genderValue
              }).eq('id', authProvider.user!.id);

              debugPrint(
                  'GoalsFlowScreen: обновили has_completed_survey=true в базе данных');

              // 2. Сохраняем обновленный профиль через AuthProvider
              await authProvider.saveUserProfile(updatedProfile);

              debugPrint(
                  'GoalsFlowScreen: сохранили профиль через AuthProvider');

              // 3. Также обновляем метаданные пользователя
              await authProvider.updateSurveyCompletionFlag(true);

              debugPrint('GoalsFlowScreen: обновили метаданные пользователя');
            }

            // Показываем экран подписки - делаем это после сохранения всех данных
            if (mounted) {
              final subscriptionProvider =
                  Provider.of<SubscriptionProvider>(context, listen: false);

              debugPrint('GoalsFlowScreen: вызываем показ экрана подписки');
              subscriptionProvider.showSubscription();

              // После показа paywall и успешной подписки переходим к DisclaimerScreen
              // Увеличиваем задержку для более стабильной работы
              Future.delayed(Duration(seconds: 3), () {
                if (mounted) {
                  debugPrint(
                      'GoalsFlowScreen: Показываем DisclaimerScreen после paywall');
                  // Перенаправляем на экран дисклеймера
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => DisclaimerScreen(
                        onAccept: () {
                          // После принятия дисклеймера переходим на главный экран
                          Navigator.of(context).pushReplacementNamed('/main');
                        },
                      ),
                    ),
                  );
                }
              });
            }
          } catch (e) {
            debugPrint(
                'GoalsFlowScreen: Ошибка при обновлении профиля или показе paywall: $e');
            // В случае ошибки сбрасываем флаг, чтобы можно было повторить попытку
            setState(() {
              _paywallShown = false;
            });
          }
        });

        // Показываем индикатор загрузки, пока не перейдем на экран Superwall
        return Container(
          color: Colors.black,
          child: Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          ),
        );
      default:
        //// Отладка
        return _buildPlaceholderScreen(_titles[_currentPage]);
    }
  }

  Widget _buildPlaceholderScreen(String title) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            title,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: Text(
              'Screen under development',
              style: GoogleFonts.inter(color: Colors.white70),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _goToNextScreen,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
              child: Text(
                'Continue',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  int? _getUserAge() {
    if (_userData['birthDate'] is DateTime) {
      final birthDate = _userData['birthDate'] as DateTime;
      final now = DateTime.now();
      int age = now.year - birthDate.year;
      if (now.month < birthDate.month ||
          (now.month == birthDate.month && now.day < birthDate.day)) {
        age--;
      }
      return age;
    }
    return null;
  }

  double? _getTargetBodyFatValue() {
    // Получаем целевой диапазон процента жира
    if (_userData['targetBodyFat'] is String) {
      final String range = _userData['targetBodyFat'] as String;
      // Берем среднее значение из диапазона
      final parts = range.split('-');
      if (parts.length == 2) {
        final double? start = double.tryParse(parts[0].replaceAll('%', ''));
        final double? end = double.tryParse(parts[1].replaceAll('%', ''));
        if (start != null && end != null) {
          return (start + end) / 2; // Среднее значение диапазона
        }
      } else if (range.contains('+')) {
        // Для диапазонов типа "50%+"
        final double? value = double.tryParse(range.replaceAll('%+', ''));
        if (value != null) {
          return value;
        }
      }
    }
    return null;
  }

  double? _calculateTargetWaistSize() {
    // Расчет целевого размера талии на основе процентного соотношения от текущего
    // до целевого веса, если пользователь не ввел конкретное значение
    if (_userData['waistSize'] is double &&
        _userData['weight'] is double &&
        _userData['targetWeight'] is double) {
      final double currentWaist = _userData['waistSize'] as double;
      final double currentWeight = _userData['weight'] as double;
      final double targetWeight = _userData['targetWeight'] as double;

      if (currentWeight > 0) {
        // Предполагаем, что талия уменьшается пропорционально весу
        final double ratio = targetWeight / currentWeight;
        // Применяем небольшую коррекцию (талия уменьшается медленнее, чем вес)
        final double correctedRatio = 0.7 * (1 - ratio) + ratio;
        return currentWaist * correctedRatio;
      }
    }
    return null;
  }

  double? _getBodyFatValueFromLevel() {
    if (_userData['bodyFatLevel'] != null) {
      final bodyFatLevel = _userData['bodyFatLevel'];

      if (bodyFatLevel.toString().contains('level')) {
        // Обработка значения как enum
        String levelStr = bodyFatLevel.toString();
        if (levelStr.contains('level1')) return 11.5; // 10-13%
        if (levelStr.contains('level2')) return 15.5; // 14-17%
        if (levelStr.contains('level3')) return 20.5; // 18-23%
        if (levelStr.contains('level4')) return 26.0; // 24-28%
        if (levelStr.contains('level5')) return 31.0; // 29-33%
        if (levelStr.contains('level6')) return 35.5; // 34-37%
        if (levelStr.contains('level7')) return 40.0; // 38-42%
        if (levelStr.contains('level8')) return 46.0; // 43-49%
        if (levelStr.contains('level9')) return 52.0; // 50%+
      } else if (bodyFatLevel is int) {
        // Если bodyFatLevel сохранен как индекс
        switch (bodyFatLevel) {
          case 0:
            return 11.5; // 10-13%
          case 1:
            return 15.5; // 14-17%
          case 2:
            return 20.5; // 18-23%
          case 3:
            return 26.0; // 24-28%
          case 4:
            return 31.0; // 29-33%
          case 5:
            return 35.5; // 34-37%
          case 6:
            return 40.0; // 38-42%
          case 7:
            return 46.0; // 43-49%
          case 8:
            return 52.0; // 50%+
        }
      } else if (bodyFatLevel is String) {
        // Если bodyFatLevel сохранен как строка диапазона
        return _getBodyFatValueFromRange(bodyFatLevel);
      }
    }
    // Значения по умолчанию
    return _userData['gender'] is String && _userData['gender'] == 'Female'
        ? 35.0
        : 24.0;
  }

  double? _getBodyFatValueFromRange(String range) {
    final parts = range.split('-');
    if (parts.length == 2) {
      final double? start = double.tryParse(parts[0].replaceAll('%', ''));
      final double? end = double.tryParse(parts[1].replaceAll('%', ''));
      if (start != null && end != null) {
        return (start + end) / 2; // Среднее значение диапазона
      }
    } else if (range.contains('+')) {
      // Для диапазонов типа "50%+"
      final double? value = double.tryParse(range.replaceAll('%+', ''));
      if (value != null) {
        return value;
      }
    }
    return null;
  }
}

// Новый экран выбора пола (первый экран)
class _GenderSelectionContent extends StatefulWidget {
  final Function(String) onSelect;

  const _GenderSelectionContent({Key? key, required this.onSelect})
      : super(key: key);

  @override
  State<_GenderSelectionContent> createState() =>
      _GenderSelectionContentState();
}

class _GenderSelectionContentState extends State<_GenderSelectionContent> {
  String? _selectedGender;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress Indicator at top
        Container(
          width: double.infinity,
          height: 4,
          margin: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            widthFactor: 0.05, // 5% progress
            alignment: Alignment.centerLeft,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Text(
            'What is your sex?',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
        ),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                // Male Button
                _buildGenderButton(
                  label: 'Male',
                  icon: Icons.male,
                  isSelected: _selectedGender == 'Male',
                  onTap: () => setState(() => _selectedGender = 'Male'),
                ),
                SizedBox(height: 16),
                // Female Button
                _buildGenderButton(
                  label: 'Female',
                  icon: Icons.female,
                  isSelected: _selectedGender == 'Female',
                  onTap: () => setState(() => _selectedGender = 'Female'),
                ),
              ],
            ),
          ),
        ),

        // Next Button at bottom
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _selectedGender != null
                  ? () => widget.onSelect(_selectedGender!)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                disabledBackgroundColor: Colors.grey[700],
                disabledForegroundColor: Colors.grey[500],
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Next',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderButton(
      {required String label,
      required IconData icon,
      required bool isSelected,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? Colors.white : Colors.black,
            ),
            SizedBox(width: 16),
            Text(
              label,
              style: GoogleFonts.inter(
                color: isSelected ? Colors.white : Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalSelectionContent extends StatefulWidget {
  final Function(List<String>) onContinue;

  const _GoalSelectionContent({Key? key, required this.onContinue})
      : super(key: key);

  @override
  State<_GoalSelectionContent> createState() => _GoalSelectionContentState();
}

class _GoalSelectionContentState extends State<_GoalSelectionContent> {
  final Map<String, bool> _selectedGoals = {
    'Lose weight': false,
    'Gain Muscle': false,
    'Look more toned': false,
    'Stay in shape': false,
  };

  bool get _hasSelectedGoals =>
      _selectedGoals.values.any((selected) => selected);

  List<String> get _selectedGoalsList => _selectedGoals.entries
      .where((entry) => entry.value)
      .map((entry) => entry.key)
      .toList();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Text(
            'What is your main goal?',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: _selectedGoals.keys.map((goal) {
                bool isSelected = _selectedGoals[goal] ?? false;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedGoals[goal] = !isSelected;
                      });
                    },
                    child: Container(
                      width: double.infinity,
                      padding:
                          EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isSelected ? Colors.blue : Colors.grey,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: isSelected
                                ? Icon(
                                    Icons.check,
                                    size: 18,
                                    color: Colors.blue,
                                  )
                                : null,
                          ),
                          SizedBox(width: 12),
                          Text(
                            goal,
                            style: GoogleFonts.inter(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _hasSelectedGoals
                  ? () => widget.onContinue(_selectedGoalsList)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                disabledBackgroundColor: Colors.grey[700],
                disabledForegroundColor: Colors.grey[500],
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Next',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Добавляю класс TargetWeightScreen
class TargetWeightScreen extends StatefulWidget {
  final Function(Map<String, dynamic>) onSelect;
  final double currentWeight;
  final bool isMetric;
  final Function(bool) onUnitChanged;

  const TargetWeightScreen({
    Key? key,
    required this.onSelect,
    required this.currentWeight,
    required this.isMetric,
    required this.onUnitChanged,
  }) : super(key: key);

  @override
  State<TargetWeightScreen> createState() => _TargetWeightScreenState();
}

class _TargetWeightScreenState extends State<TargetWeightScreen> {
  late double _targetWeight;
  late bool _isMetric;
  double _rateValue = 0.5; // Standard (middle of slider)

  // Добавляем параметры для расчета потери/набора веса
  // Базовые значения при _rateValue = 0.5
  double _weeklyLossLbs = 0.9;
  double _weeklyLossBwPercent = 0.5;
  double _monthlyLossLbs = 3.6;
  double _monthlyLossBwPercent = 2.0;

  @override
  void initState() {
    super.initState();
    _isMetric = widget.isMetric;
    _targetWeight = widget.currentWeight;
    _updateRateValues(); // Инициализация начальных значений
  }

  double get _targetWeightKg =>
      _isMetric ? _targetWeight : _targetWeight * 0.453592;
  double get _targetWeightLbs =>
      _isMetric ? _targetWeight / 0.453592 : _targetWeight;

  // Метод для обновления значений при изменении ползунка
  void _updateRateValues() {
    // Используем _rateValue (0.0 до 1.0) для расчета значений
    // Предполагаем, что минимум 0.3 фунта в неделю, максимум 1.5 фунта
    _weeklyLossLbs = 0.3 + (1.2 * _rateValue);
    _weeklyLossBwPercent = 0.2 + (0.6 * _rateValue);

    // Месячные значения (примерно 4 недели)
    _monthlyLossLbs = _weeklyLossLbs * 4;
    _monthlyLossBwPercent = _weeklyLossBwPercent * 4;
  }

  // Метод для получения текста и цвета метки в зависимости от значения _rateValue
  Map<String, dynamic> _getRateLabel() {
    if (_rateValue < 0.33) {
      return {
        'text': 'Slow & Steady',
        'color': Color(0xFF2196F3) // Blue
      };
    } else if (_rateValue < 0.66) {
      return {
        'text': 'Standard (Recommended)',
        'color': Color(0xFF4CAF50) // Green
      };
    } else {
      return {
        'text': 'Aggressive',
        'color': Color(0xFFFFA726) // Orange
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    // Получаем текст и цвет метки
    final rateLabel = _getRateLabel();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          height: 1,
          color: Colors.white,
          margin: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              children: [
                TextSpan(text: 'What is your '),
                TextSpan(
                  text: 'target',
                  style: TextStyle(
                    decoration: TextDecoration.underline,
                  ),
                ),
                TextSpan(text: ' weight?'),
              ],
            ),
          ),
        ),

        // Переключатель единиц измерения
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildUnitToggle('kg', true),
            SizedBox(width: 16),
            _buildUnitToggle('lbs', false),
          ],
        ),

        SizedBox(height: 24),

        Container(
          margin: EdgeInsets.symmetric(horizontal: 24),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Color(0xFF222222),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Weight display
              Center(
                child: Text(
                  _isMetric
                      ? '${_targetWeight.toInt()} kg'
                      : '${_targetWeightLbs.toInt()} lbs',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              SizedBox(height: 16),

              // Weight slider with min and max labels
              Container(
                height: 40,
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 18,
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade700,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      child: SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 4,
                          activeTrackColor: Color(0xFF4CAF50),
                          inactiveTrackColor: Colors.transparent,
                          thumbColor: Colors.white,
                          overlayColor: Color(0x294CAF50),
                          thumbShape: RoundSliderThumbShape(
                            enabledThumbRadius: 10,
                            elevation: 4,
                            pressedElevation: 8,
                          ),
                          overlayShape:
                              RoundSliderOverlayShape(overlayRadius: 20),
                          trackShape: CustomTrackShape(),
                        ),
                        child: Slider(
                          value: _targetWeight,
                          min: _isMetric
                              ? widget.currentWeight - 20 // кг
                              : widget.currentWeight - 45, // фунты
                          max: _isMetric
                              ? widget.currentWeight + 20 // кг
                              : widget.currentWeight + 45, // фунты
                          onChanged: (value) {
                            setState(() {
                              _targetWeight = value;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                        _isMetric
                            ? '${(_targetWeight - 20).toInt()} kg'
                            : '${(_targetWeight - 45).toInt()} lbs',
                        style: GoogleFonts.inter(
                            color: Colors.grey, fontSize: 12)),
                    Text(
                        _isMetric
                            ? '${(_targetWeight + 20).toInt()} kg'
                            : '${(_targetWeight + 45).toInt()} lbs',
                        style: GoogleFonts.inter(
                            color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),

              SizedBox(height: 32),

              // Goal rate section
              Text(
                'What is your target goal rate?',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),

              SizedBox(height: 8),

              // Rate slider with "Standard (Recommended)" label
              Center(
                child: Text(
                  rateLabel['text'],
                  style: GoogleFonts.inter(
                    color: rateLabel['color'],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              SizedBox(height: 8),

              Container(
                height: 40,
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 18,
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.grey.shade800,
                              Colors.grey.shade600
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(1.5),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      child: SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 3,
                          activeTrackColor: Colors.white,
                          inactiveTrackColor: Colors.transparent,
                          thumbColor: Colors.white,
                          overlayColor: Colors.white24,
                          thumbShape: RoundSliderThumbShape(
                            enabledThumbRadius: 8,
                            elevation: 3,
                            pressedElevation: 6,
                          ),
                          overlayShape:
                              RoundSliderOverlayShape(overlayRadius: 16),
                          trackShape: CustomTrackShape(),
                        ),
                        child: Slider(
                          value: _rateValue,
                          min: 0.0,
                          max: 1.0,
                          onChanged: (value) {
                            setState(() {
                              _rateValue = value;
                              _updateRateValues();
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Rate options
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          '−',
                          style: GoogleFonts.inter(
                              color: Colors.grey, fontSize: 14),
                        ),
                        SizedBox(width: 4),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_weeklyLossLbs.toStringAsFixed(1)}',
                              style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'lbs',
                              style: GoogleFonts.inter(
                                  color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                        SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_weeklyLossBwPercent.toStringAsFixed(1)}',
                              style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '% BW',
                              style: GoogleFonts.inter(
                                  color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Text(
                      'Per Week',
                      style:
                          GoogleFonts.inter(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        '−',
                        style:
                            GoogleFonts.inter(color: Colors.grey, fontSize: 14),
                      ),
                      SizedBox(width: 4),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_monthlyLossLbs.toStringAsFixed(1)}',
                            style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'lbs',
                            style: GoogleFonts.inter(
                                color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                      SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_monthlyLossBwPercent.toStringAsFixed(1)}',
                            style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '% BW',
                            style: GoogleFonts.inter(
                                color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Text(
                    'Per Month',
                    style: GoogleFonts.inter(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),

        Spacer(),

        // Disclaimer text
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'This app\'s workout suggestions do not constitute medical advice. Consult a healthcare professional before beginning any exercise program, especially if you have injuries or medical conditions. We are not responsible for any injuries or damages related to this information.',
            style: GoogleFonts.inter(
              color: Colors.grey,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        // Next button
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                final data = {
                  'targetWeight': _isMetric
                      ? _targetWeight
                      : _targetWeight * 0.453592, // Всегда сохраняем в кг
                  'goalRate': _rateValue,
                  'weeklyRateLbs': _weeklyLossLbs,
                  'weeklyRateBwPercent': _weeklyLossBwPercent,
                  'monthlyRateLbs': _monthlyLossLbs,
                  'monthlyRateBwPercent': _monthlyLossBwPercent,
                  'rateLabel': _getRateLabel()['text'],
                };
                widget.onSelect(data);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Next',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUnitToggle(String text, bool isMetric) {
    final bool isSelected = this._isMetric == isMetric;

    return GestureDetector(
      onTap: () {
        setState(() {
          if (this._isMetric != isMetric) {
            this._isMetric = isMetric;
            // Конвертируем значение при смене единиц измерения
            if (isMetric) {
              // Из фунтов в килограммы
              _targetWeight = _targetWeightKg;
            } else {
              // Из килограммов в фунты
              _targetWeight = _targetWeightLbs;
            }
            // Обновляем глобальную настройку
            widget.onUnitChanged(isMetric);
          }
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white24,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: GoogleFonts.inter(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// Добавляю класс TargetBodyScreen
class TargetBodyScreen extends StatefulWidget {
  final Function(String) onSelect;
  final bool isMale;

  const TargetBodyScreen({
    Key? key,
    required this.onSelect,
    required this.isMale,
  }) : super(key: key);

  @override
  State<TargetBodyScreen> createState() => _TargetBodyScreenState();
}

class _TargetBodyScreenState extends State<TargetBodyScreen> {
  String? _selectedBodyFatRange;

  final List<String> _bodyFatRanges = [
    '0-12%',
    '12-17%',
    '18-22%',
    '24-26%',
    '26-32%',
    '32-37%',
    '38-42%',
    '42-46%',
    '50%+',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Line at top
        Container(
          width: double.infinity,
          height: 1,
          color: Colors.white,
          margin: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),

        // Title
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Text(
            'What is your target body?',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // Subtitle
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Text(
            'Don\'t worry about being too precise. A visual assessment is sufficient.',
            style: GoogleFonts.inter(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ),

        // Grid of body fat options
        Expanded(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 24),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFF222222),
              borderRadius: BorderRadius.circular(12),
            ),
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.75,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: 9,
              itemBuilder: (context, index) {
                return _buildBodyFatItem(index);
              },
            ),
          ),
        ),

        // Next button
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _selectedBodyFatRange != null
                  ? () => widget.onSelect(_selectedBodyFatRange!)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                disabledBackgroundColor: Colors.grey[700],
                disabledForegroundColor: Colors.grey[500],
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Next',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBodyFatItem(int index) {
    final String range = _bodyFatRanges[index];
    final bool isSelected = _selectedBodyFatRange == range;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedBodyFatRange = range;
        });
      },
      child: Stack(
        children: [
          // Body image container
          Container(
            decoration: BoxDecoration(
              color: Color(0xFF333333),
              borderRadius: BorderRadius.circular(8),
              border:
                  isSelected ? Border.all(color: Colors.white, width: 2) : null,
            ),
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade700,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    // Здесь будет изображение тела
                    child: ClipRRect(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                      child: Image.asset(
                        _getImagePath(index),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          print('Error loading image: $error');
                          return Center(
                            child: Icon(
                              Icons.person,
                              color: Colors.grey.shade300,
                              size: 48,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    range,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Selection indicator
          if (isSelected)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.3),
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getImagePath(int index) {
    // Используем женские изображения с правильными именами файлов
    switch (index) {
      case 0:
        return 'assets/images/bodyfat_reference_corrected/01_female_10-13_bf.png';
      case 1:
        return 'assets/images/bodyfat_reference_corrected/02_female_14-17_bf.png';
      case 2:
        return 'assets/images/bodyfat_reference_corrected/03_female_18-23_bf.png';
      case 3:
        return 'assets/images/bodyfat_reference_corrected/04_female_24-28_bf.png';
      case 4:
        return 'assets/images/bodyfat_reference_corrected/04_female_24-28_bf.png'; // Используем повторно для близкого диапазона
      case 5:
        return 'assets/images/bodyfat_reference_corrected/08_female_34-37_bf.png';
      case 6:
        return 'assets/images/bodyfat_reference_corrected/06_female_38-42_bf.png';
      case 7:
        return 'assets/images/bodyfat_reference_corrected/07_female_43-46_bf.png';
      case 8:
        return 'assets/images/bodyfat_reference_corrected/09_female_47-50_bf.png';
      default:
        return 'assets/images/bodyfat_reference_corrected/01_female_10-13_bf.png';
    }
  }
}

// Add this custom track shape class at the end of the file
class CustomTrackShape extends RectangularSliderTrackShape {
  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double trackHeight = sliderTheme.trackHeight ?? 4;
    final double trackLeft = offset.dx;
    final double trackTop =
        offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }
}

// Добавляем класс для ввода размера талии
class WaistSizeScreen extends StatefulWidget {
  final Function(double) onSelect;
  final bool isMetric;
  final Function(bool) onUnitChanged;

  const WaistSizeScreen({
    Key? key,
    required this.onSelect,
    required this.isMetric,
    required this.onUnitChanged,
  }) : super(key: key);

  @override
  State<WaistSizeScreen> createState() => _WaistSizeScreenState();
}

class _WaistSizeScreenState extends State<WaistSizeScreen> {
  double _waistSize = 80.0; // Начальное значение
  late bool _isMetric; // Используем глобальную настройку

  @override
  void initState() {
    super.initState();
    _isMetric = widget.isMetric;
    _waistSize = _isMetric ? 80.0 : 31.5; // 80 см ~ 31.5 дюймов
  }

  double get _waistSizeCm => _isMetric ? _waistSize : _waistSize * 2.54;
  double get _waistSizeInches => _isMetric ? _waistSize / 2.54 : _waistSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Заголовок
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'What is your waist size?',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        SizedBox(height: 12),

        // Подсказка по измерению
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Measure around the narrowest part of your waist, usually at the belly button',
            style: GoogleFonts.inter(
              color: Colors.grey[400],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        SizedBox(height: 32),

        // Переключатель единиц измерения
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildUnitToggle('cm', true),
            SizedBox(width: 16),
            _buildUnitToggle('inches', false),
          ],
        ),

        SizedBox(height: 48),

        // Отображение текущего значения
        Center(
          child: Text(
            _isMetric
                ? '${_waistSize.round()} cm'
                : '${_waistSizeInches.round()} inches',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        SizedBox(height: 24),

        // Слайдер для выбора значения
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 8,
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.white24,
              thumbColor: Colors.white,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 12),
              overlayColor: Colors.white.withOpacity(0.2),
              overlayShape: RoundSliderOverlayShape(overlayRadius: 24),
            ),
            child: Slider(
              value: _waistSize,
              min: _isMetric ? 40.0 : 16.0, // 40 см ~ 16 дюймов
              max: _isMetric ? 200.0 : 79.0, // 200 см ~ 79 дюймов
              onChanged: (value) {
                setState(() {
                  _waistSize = value;
                });
              },
            ),
          ),
        ),

        Spacer(),

        // Кнопка Next
        Padding(
          padding: const EdgeInsets.all(24),
          child: ElevatedButton(
            onPressed: () => widget.onSelect(_isMetric
                ? _waistSize
                : _waistSize * 2.54), // Всегда возвращаем в см
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Next',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUnitToggle(String text, bool isMetric) {
    final bool isSelected = this._isMetric == isMetric;

    return GestureDetector(
      onTap: () {
        setState(() {
          if (this._isMetric != isMetric) {
            this._isMetric = isMetric;
            // Конвертируем значение при смене единиц измерения
            if (isMetric) {
              // Из дюймов в сантиметры
              _waistSize = _waistSizeCm;
            } else {
              // Из сантиметров в дюймы
              _waistSize = _waistSizeInches;
            }
            // Обновляем глобальную настройку
            widget.onUnitChanged(isMetric);
          }
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white24,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: GoogleFonts.inter(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

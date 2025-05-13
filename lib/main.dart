import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:device_preview/device_preview.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/auth_screen.dart';
import 'providers/workout_provider.dart';
import 'theme/app_theme.dart';
import 'package:flutter/foundation.dart';
import 'providers/chat_provider.dart';
import 'providers/survey_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/subscription_provider.dart';
import 'providers/notification_provider.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/disclaimer_screen.dart';
import 'services/auth_service.dart';
import 'services/survey_service.dart';
import 'services/chat_service.dart';
import 'screens/chat_screen.dart';
import 'screens/login_screen.dart';
import 'services/workout_service.dart';
import 'screens/splash_screen.dart';
import 'screens/new_auth_screen.dart';
import 'screens/subscription_screen.dart';
import 'screens/paywall/superwall_screen.dart';
import 'services/superwall_service.dart';
import 'screens/goals_flow_screen.dart';
import 'screens/basics_screen.dart';
import 'models/exercise.dart';
import 'widgets/notification_permission_dialog.dart';
import 'dart:async';

// Класс для отслеживания первого запуска
class FirstRunFlag {
  static const String _key = 'has_seen_onboarding';
  static bool _hasBeenShown = false;
  static bool _initialized = false;

  // Инициализирует флаг из SharedPreferences
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      _hasBeenShown = prefs.getBool(_key) ?? false;
      _initialized = true;
      debugPrint('FirstRunFlag initialized: $_hasBeenShown');
    } catch (e) {
      debugPrint('Error initializing FirstRunFlag: $e');
    }
  }

  // Проверяет, показан ли онбординг
  static bool get hasBeenShown => _hasBeenShown;

  // Устанавливает флаг, что онбординг был показан
  static Future<void> setShown() async {
    _hasBeenShown = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, true);
      debugPrint('FirstRunFlag set to shown');
    } catch (e) {
      debugPrint('Error saving FirstRunFlag: $e');
    }
  }
}

// Класс для отслеживания принятия дисклеймера
class DisclaimerFlag {
  static const String _key = 'has_accepted_disclaimer';
  static bool _hasAccepted = false;
  static bool _initialized = false;

  // Инициализирует флаг из SharedPreferences
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      _hasAccepted = prefs.getBool(_key) ?? false;
      _initialized = true;
      if (kDebugMode) debugPrint('DisclaimerFlag initialized: $_hasAccepted');
    } catch (e) {
      if (kDebugMode) debugPrint('Error initializing DisclaimerFlag: $e');
    }
  }

  // Проверяет, принят ли дисклеймер
  static bool get hasAccepted => _hasAccepted == true;

  // Устанавливает флаг, что дисклеймер был принят
  static Future<void> setAccepted() async {
    _hasAccepted = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, true);
    } catch (e) {
      if (kDebugMode) debugPrint('Error saving DisclaimerFlag: $e');
    }
  }
}

// Класс для отслеживания запроса разрешений на уведомления
class NotificationPermissionFlag {
  static const String _key = 'has_shown_notification_permission';
  // Устанавливаем начальное значение флага как true, чтобы диалог не показывался
  static bool _hasShown = true;
  static bool _initialized = false;

  // Инициализирует флаг из SharedPreferences
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      // Всегда используем значение true, независимо от того, что сохранено
      _hasShown = true;
      // Сохраняем значение true в SharedPreferences
      await prefs.setBool(_key, true);
      _initialized = true;
      debugPrint('NotificationPermissionFlag initialized: $_hasShown');
    } catch (e) {
      debugPrint('Error initializing NotificationPermissionFlag: $e');
    }
  }

  // Проверяет, был ли показан запрос на разрешение уведомлений - всегда возвращает true
  static bool get hasShown => true;

  // Метод оставлен для совместимости, но теперь не меняет состояние
  static Future<void> setShown() async {
    // Ничего не делаем, так как диалог всегда считается показанным
    debugPrint(
        'NotificationPermissionFlag: setShown called, but dialog is already disabled');
  }
}

// Глобальный ключ навигатора для доступа к навигации из любой точки приложения
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    await dotenv.load();

    final supabaseUrl = dotenv.env['SUPABASE_URL'];
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

    if (supabaseUrl == null || supabaseAnonKey == null) {
      throw Exception('Missing Supabase URL or Anon Key');
    }

    // Инициализация Supabase
    await Supabase.initialize(
      url: supabaseUrl.trim(),
      anonKey: supabaseAnonKey.trim(),
    );

    // Проверяем, есть ли активная сессия
    final session = await Supabase.instance.client.auth.currentSession;

    // Если есть сессия, обновляем метаданные пользователя
    if (session != null) {
      try {
        // Проверяем наличие флага завершения опроса в базе данных
        final userId = session.user.id;
        final response = await Supabase.instance.client
            .from('user_profiles')
            .select('has_completed_survey')
            .eq('id', userId)
            .single();

        if (response != null && response['has_completed_survey'] == true) {
          // Если опрос пройден в базе данных, обновляем и метаданные пользователя
          await Supabase.instance.client.auth.updateUser(
            UserAttributes(
              data: {
                'has_completed_survey': true,
              },
            ),
          );
          debugPrint(
              'Обновлены метаданные пользователя при запуске: has_completed_survey = true');
        }
      } catch (e) {
        debugPrint(
            'Ошибка при обновлении метаданных пользователя при запуске: $e');
      }
    }

    // Инициализируем флаг первого запуска
    await FirstRunFlag.initialize();

    // Инициализируем флаг принятия дисклеймера
    await DisclaimerFlag.initialize();

    // Инициализируем флаг запроса разрешений на уведомления
    await NotificationPermissionFlag.initialize();

    // Загружаем упражнения до инициализации Superwall
    print('📁 Main: Начинаем загрузку упражнений из файла...');
    print('📁 Main: Путь к файлу assets/exercise.json');
    print(
        '📁 Main: Текущее количество упражнений: ${WorkoutService.exercises.length}');

    await WorkoutService.loadExercises();
    print(
        '📁 Main: Завершена загрузка упражнений, теперь в массиве: ${WorkoutService.exercises.length}');

    // Дополнительно проверяем корректность загрузки упражнений
    final exercise = WorkoutService.exercises.firstWhere(
      (e) => e['name'] == 'Dumbbell Lateral Raise',
      orElse: () => {'name': 'Not found', 'videoUrl': null},
    );

    print('✅ Main: проверка упражнения Dumbbell Lateral Raise:');
    print('✅ Main: найдено: ${exercise['name'] != 'Not found'}');
    print('✅ Main: videoUrl: ${exercise['videoUrl']}');

    // Создаем тестовый объект Exercise для проверки
    if (exercise['name'] != 'Not found') {
      final testExercise = Exercise.fromJson(exercise);
      print('✅ Main: тестовый объект Exercise: $testExercise');
      print('✅ Main: videoUrl в объекте: ${testExercise.videoUrl}');
    }

    // Инициализация Superwall - теперь после загрузки упражнений
    try {
      debugPrint('Начинаем инициализацию Superwall...');

      // Даем небольшую задержку перед инициализацией
      await Future.delayed(Duration(milliseconds: 300));

      final superwallService = SuperwallService();
      await superwallService.initialize().timeout(
        Duration(seconds: 5),
        onTimeout: () {
          debugPrint('⏱️ Timeout при инициализации Superwall');
          return;
        },
      );

      debugPrint('✅ Main: Superwall инициализирован успешно');
    } catch (e) {
      // Если инициализация Superwall не удалась, это не должно останавливать приложение
      debugPrint('⚠️ Main: Ошибка инициализации Superwall: $e');
    }

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) {
              final provider = WorkoutProvider();
              // Загружаем статистику при создании провайдера
              Future.microtask(() => provider.loadStatistics());
              return provider;
            },
          ),
          ChangeNotifierProxyProvider<WorkoutProvider, AuthProvider>(
            create: (context) => AuthProvider(context.read<WorkoutProvider>()),
            update: (context, workoutProvider, previous) =>
                previous ?? AuthProvider(workoutProvider),
          ),
          Provider<SurveyService>(create: (_) => SurveyService()),
          ChangeNotifierProxyProvider<SurveyService, SurveyProvider>(
            create: (context) => SurveyProvider(context.read<SurveyService>()),
            update: (context, surveyService, previous) =>
                previous ?? SurveyProvider(surveyService),
          ),
          ChangeNotifierProvider(create: (_) => AuthService()),
          // Добавляем провайдер уведомлений
          ChangeNotifierProvider(create: (_) => NotificationProvider()),
          // Обновляем провайдер ChatService, чтобы создавать новый экземпляр при каждом входе
          Provider<ChatService>(
            create: (_) => ChatService(),
            // Не переиспользуем старый экземпляр при обновлении
            dispose: (_, service) => service.reset(),
          ),
          ChangeNotifierProxyProvider<ChatService, ChatProvider>(
            create: (context) => ChatProvider(context.read<ChatService>()),
            update: (context, chatService, previous) {
              if (previous != null) {
                // Очищаем сообщения при обновлении провайдера
                return previous..reset(chatService);
              }
              return ChatProvider(chatService);
            },
          ),
          ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
        ],
        child: const AppLifecycleObserver(child: MyApp()),
      ),
    );
  } catch (e) {
    if (kDebugMode) debugPrint('Error initializing app: $e');
    rethrow;
  }
}

/// Наблюдатель за жизненным циклом приложения для отправки уведомлений при выходе из приложения
class AppLifecycleObserver extends StatefulWidget {
  final Widget child;

  const AppLifecycleObserver({Key? key, required this.child}) : super(key: key);

  @override
  State<AppLifecycleObserver> createState() => _AppLifecycleObserverState();
}

class _AppLifecycleObserverState extends State<AppLifecycleObserver>
    with WidgetsBindingObserver {
  // Флаг указывающий, было ли отправлено уведомление
  bool _notificationSent = false;
  // Таймер для отложенной отправки уведомления
  Timer? _exitTimer;

  // Добавляем таймер для автоматического тестирования уведомления
  // после запуска приложения
  Timer? _testTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Инициализируем провайдер уведомлений
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notificationProvider =
          Provider.of<NotificationProvider>(context, listen: false);
      notificationProvider.initialize();

      // Отключаем автоматическое тестирование уведомлений
      // _testTimer = Timer(const Duration(seconds: 10), () {
      //   _testNotifications(notificationProvider);
      // });
    });
  }

  @override
  void dispose() {
    _exitTimer?.cancel();
    _testTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final notificationProvider =
        Provider.of<NotificationProvider>(context, listen: false);

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      debugPrint(
          'AppLifecycleObserver: приложение ушло в фон (состояние = $state)');

      // Сбрасываем флаг отправки уведомления
      _notificationSent = false;

      // Устанавливаем таймер для отправки уведомления
      // Это позволяет избежать ложных срабатываний при быстром переключении между приложениями
      _exitTimer?.cancel();
      _exitTimer = Timer(const Duration(seconds: 2), () {
        if (!_notificationSent) {
          _sendExitNotification(notificationProvider);
        }
      });
    } else if (state == AppLifecycleState.resumed) {
      debugPrint('AppLifecycleObserver: приложение вернулось на передний план');

      // Отменяем таймер и сбрасываем флаг
      _exitTimer?.cancel();
      _notificationSent = false;

      // Отменяем все уведомления при возвращении в приложение
      notificationProvider.cancelAllNotifications();
    }
  }

  // Метод для отправки уведомления при выходе
  void _sendExitNotification(NotificationProvider provider) async {
    // Полностью отключаем отправку уведомлений при выходе
    return;

    // if (_notificationSent) return;

    // _notificationSent = true;

    // // Сначала запросим разрешения, если еще не были запрошены
    // final hasPermission = await provider.requestPermissions();
    // debugPrint('AppLifecycleObserver: проверка разрешений - $hasPermission');

    // // Отправляем уведомление через провайдер
    // // Создаем небольшую задержку перед отправкой для более надежной работы
    // await Future.delayed(const Duration(milliseconds: 300));
    // debugPrint('AppLifecycleObserver: отправляем уведомление после выхода');
    // await provider.showExitNotification();
  }

  // Метод для тестирования отправки уведомлений
  Future<void> _testNotifications(NotificationProvider provider) async {
    debugPrint('AppLifecycleObserver: тестирование уведомлений');

    // Запрашиваем разрешения
    final hasPermission = await provider.requestPermissions();
    debugPrint('AppLifecycleObserver: разрешения для теста - $hasPermission');

    // Отправляем тестовое уведомление из каталога
    await provider.sendTestNotification();

    // Отправляем мотивационное уведомление через 3 секунды
    await Future.delayed(const Duration(seconds: 3));
    await provider.sendRandomMotivationalNotification();

    debugPrint('AppLifecycleObserver: тестовые уведомления отправлены');
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Инициализируем необходимые провайдеры при старте приложения
    Future.delayed(Duration.zero, () {
      Provider.of<AuthProvider>(context, listen: false).initialize();
      Provider.of<SubscriptionProvider>(context, listen: false).initialize();

      // Инициализируем провайдер уведомлений
      final notificationProvider =
          Provider.of<NotificationProvider>(context, listen: false);
      notificationProvider.initialize();

      // Диалог запроса уведомлений полностью отключен
      // if (!NotificationPermissionFlag.hasShown) {
      //   // Используем навигатор для доступа к контексту
      //   WidgetsBinding.instance.addPostFrameCallback((_) {
      //     if (navigatorKey.currentContext != null) {
      //       _showNotificationPermissionDialog(navigatorKey.currentContext!);
      //     }
      //   });
      // }
    });

    return MaterialApp(
      navigatorKey: navigatorKey,
      // useInheritedMediaQuery: true,
      // locale: DevicePreview.locale(context),
      // builder: DevicePreview.appBuilder,
      title: 'Fitness App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Inter',
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontFamily: 'Inter'),
          bodyMedium: TextStyle(fontFamily: 'Inter'),
          titleLarge: TextStyle(fontFamily: 'Inter'),
          titleMedium: TextStyle(fontFamily: 'Inter'),
          titleSmall: TextStyle(fontFamily: 'Inter'),
          displayLarge: TextStyle(fontFamily: 'Inter'),
          displayMedium: TextStyle(fontFamily: 'Inter'),
          displaySmall: TextStyle(fontFamily: 'Inter'),
          headlineLarge: TextStyle(fontFamily: 'Inter'),
          headlineMedium: TextStyle(fontFamily: 'Inter'),
          headlineSmall: TextStyle(fontFamily: 'Inter'),
        ),
      ),
      home: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          if (authProvider.isLoading) {
            return const SplashScreen();
          }

          // Проверяем, был ли показан онбординг (первый запуск приложения)
          final bool isFirstRun = _isFirstRun();

          // Если это первый запуск, ВСЕГДА показываем онбординг перед авторизацией
          if (isFirstRun) {
            debugPrint('Первый запуск: показываем онбординг');
            return OnboardingScreen(
              onComplete: () {
                // Помечаем, что онбординг показан
                _setFirstRunCompleted();
                // После онбординга направляем на экран авторизации
                Navigator.of(navigatorKey.currentContext!)
                    .pushReplacementNamed('/auth');
              },
            );
          }

          // Проверяем, принят ли дисклеймер
          // ВАЖНОЕ ИЗМЕНЕНИЕ: временно отключаем проверку дисклеймера для новых пользователей
          // Мы будем показывать дисклеймер ПОСЛЕ опроса и оплаты

          // Если пользователь авторизован
          if (authProvider.user != null) {
            debugPrint('Пользователь авторизован, проверяем состояние опроса');

            // Обновленная логика: если дисклеймер принят, идем на главный экран
            // Если не принят, но опрос завершен - показываем дисклеймер
            // В противном случае показываем экран опроса

            // Проверяем статус опроса
            final profile = authProvider.userProfile;
            final hasCompletedSurvey = profile?.hasCompletedSurvey == true ||
                authProvider.hasSurveyCompletionFlag();

            // Проверяем принят ли дисклеймер в локальном хранилище
            final disclaimerAccepted = DisclaimerFlag.hasAccepted;
            if (disclaimerAccepted) {
              authProvider.setDisclaimerAccepted(true);
            }

            debugPrint(
                'Статус опроса: $hasCompletedSurvey, Дисклеймер принят: $disclaimerAccepted');

            // Принудительно открываем экран опроса, если он не пройден
            if (!hasCompletedSurvey) {
              debugPrint('Опрос не пройден, открываем экран опроса');
              return const GoalsFlowScreen();
            }
            // Если опрос пройден, но дисклеймер не принят, показываем экран дисклеймера
            else if (!disclaimerAccepted) {
              debugPrint(
                  'Опрос пройден, но дисклеймер не принят, показываем экран дисклеймера');
              return const DisclaimerScreen();
            }
            // Если и опрос пройден, и дисклеймер принят, идем на главный экран
            else {
              debugPrint(
                  'Опрос пройден и дисклеймер принят, открываем главный экран');
              return const MainNavigationScreen();
            }
          }

          // Если есть аноним, удаляем его при запуске
          if (kIsWeb) {
            return const NewAuthScreen();
          }

          final user = authProvider.user;
          if (user == null) {
            // Пользователь не авторизован, показываем экран входа
            return const NewAuthScreen();
          }

          final profile = authProvider.userProfile;
          if (profile == null || !profile.hasCompletedSurvey) {
            return const GoalsFlowScreen();
          }

          // Если есть рост и вес, сразу считаем опрос пройденным
          if (profile.height! > 0 &&
              profile.weight! > 0 &&
              !profile.hasCompletedSurvey) {
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              debugPrint(
                  'Найдены данные роста и веса в профиле, автоматически отмечаем опрос как пройденный');

              // Обновляем профиль
              await authProvider
                  .saveUserProfile(profile.copyWith(hasCompletedSurvey: true));

              // Обновляем метаданные пользователя
              await authProvider.updateSurveyCompletionFlag(true);
            });
          }

          // Проверяем как флаг профиля, так и метаданные пользователя
          // Если хотя бы один из них указывает, что опрос пройден - считаем его пройденным
          final hasCompletedSurveyInProfile = profile.hasCompletedSurvey;
          final hasCompletedSurveyInMetadata =
              authProvider.hasSurveyCompletionFlag();
          final hasCompletedSurvey =
              hasCompletedSurveyInProfile || hasCompletedSurveyInMetadata;

          debugPrint(
              'Флаг в профиле: $hasCompletedSurveyInProfile, Флаг в метаданных: $hasCompletedSurveyInMetadata');

          if (!hasCompletedSurvey) {
            return const GoalsFlowScreen();
          }

          // Переходим на главный экран
          return const MainNavigationScreen();
        },
      ),
      routes: {
        '/auth': (context) => const NewAuthScreen(),
        '/login': (context) => LoginScreen(),
        '/main': (context) => const MainNavigationScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/basics': (context) => const BasicsScreen(),
        '/chat': (context) => const ChatScreen(),
        '/subscription': (context) => const SubscriptionScreen(),
        '/paywall': (context) {
          // Обертка для экрана paywall для перехода на главный экран
          // при нажатии кнопки Назад
          return WillPopScope(
            onWillPop: () async {
              // Переходим на главный экран при нажатии кнопки "Назад"
              Navigator.of(context).pushReplacementNamed('/main');
              return false;
            },
            child: const SuperwallScreen(),
          );
        },
      },
      debugShowCheckedModeBanner: false,
    );
  }

  // Проверяет, является ли это первым запуском приложения
  bool _isFirstRun() {
    // Получаем значение из FirstRunFlag
    return !FirstRunFlag.hasBeenShown;
  }

  // Помечает первый запуск как завершенный
  void _setFirstRunCompleted() {
    // Сохраняем значение через FirstRunFlag
    FirstRunFlag.setShown();
  }

  // Показывает диалог разрешения уведомлений
  void _showNotificationPermissionDialog(BuildContext context) {
    // Используем виджет напрямую вместо динамического импорта
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        // Импортируем напрямую
        return NotificationPermissionDialog(
          onPermissionGranted: () {
            // Сохраняем флаг, что диалог был показан
            NotificationPermissionFlag.setShown();
            debugPrint('Разрешение на уведомления получено');
          },
          onPermissionDenied: () {
            // Сохраняем флаг, что диалог был показан
            NotificationPermissionFlag.setShown();
            debugPrint('Разрешение на уведомления отклонено');
          },
        );
      },
    );
  }
}

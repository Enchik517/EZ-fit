import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Идентификаторы каналов уведомлений для Android
  static const String _mainChannelId = 'fitness_main_channel';
  static const String _scheduledChannelId = 'fitness_scheduled_channel';
  static const String _exitChannelId = 'fitness_exit_channel';

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  /// Инициализация сервиса уведомлений
  Future<void> initialize() async {
    // Инициализация временных зон для отложенных уведомлений
    tz_data.initializeTimeZones();

    // Настройки для Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Настройки для iOS
    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission:
          false, // Не запрашиваем разрешения при инициализации
      requestBadgePermission:
          false, // Не запрашиваем разрешения при инициализации
      requestSoundPermission:
          false, // Не запрашиваем разрешения при инициализации
    );

    // Объединяем настройки платформ
    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    // Инициализируем плагин с настройками
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Создаем каналы уведомлений для Android заранее
    await _createNotificationChannels();

    debugPrint('NotificationService: инициализация завершена');
  }

  /// Создает каналы уведомлений для Android
  Future<void> _createNotificationChannels() async {
    final androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      // Основной канал для обычных уведомлений
      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          _mainChannelId,
          'Фитнес-уведомления',
          description: 'Общие уведомления приложения',
          importance: Importance.high,
          enableVibration: true,
          enableLights: true,
          playSound: true,
          showBadge: true,
        ),
      );

      // Канал для запланированных уведомлений
      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          _scheduledChannelId,
          'Запланированные тренировки',
          description: 'Уведомления о запланированных тренировках',
          importance: Importance.high,
          enableVibration: true,
          enableLights: true,
          playSound: true,
          showBadge: true,
        ),
      );

      // Канал для уведомлений при выходе из приложения
      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          _exitChannelId,
          'Напоминания о тренировках',
          description: 'Напоминания о тренировках при выходе из приложения',
          importance: Importance.high,
          enableVibration: true,
          enableLights: true,
          playSound: true,
          showBadge: true,
        ),
      );

      debugPrint('NotificationService: каналы уведомлений созданы');
    }
  }

  /// Запрос разрешений на показ уведомлений (вызывается после инициализации)
  Future<bool> requestPermissions() async {
    // Для iOS запрашиваем разрешения отдельно
    final bool? iosPermission = await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
          critical: true,
        );

    // Для Android проверяем разрешения
    bool? androidPermission;
    try {
      final androidImpl =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImpl != null) {
        // Для Android 13+ нужно явно запрашивать разрешения
        androidPermission = await androidImpl.requestNotificationsPermission();

        // Также запрашиваем разрешение на точные будильники для запланированных уведомлений
        final hasAlarmPermission =
            await androidImpl.requestExactAlarmsPermission();
        debugPrint(
            'NotificationService: разрешение на точные будильники - $hasAlarmPermission');
      } else {
        // Для более старых версий Android разрешения есть по умолчанию
        androidPermission = true;
      }
    } catch (e) {
      debugPrint('Ошибка при запросе разрешений для Android: $e');
      androidPermission = false;
    }

    debugPrint(
        'NotificationService: Разрешения запрошены - iOS: $iosPermission, Android: $androidPermission');

    // Если хотя бы на одной платформе разрешено, возвращаем true
    return iosPermission == true || androidPermission == true;
  }

  /// Обработчик нажатий на уведомления
  void _onNotificationTap(NotificationResponse details) {
    debugPrint(
        'NotificationService: Нажатие на уведомление: ${details.payload}');
    // Здесь можно добавить логику обработки нажатий
  }

  /// Показать простое уведомление
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      // Настройки для Android
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        _mainChannelId, // Идентификатор канала
        'Фитнес-уведомления', // Название канала
        channelDescription: 'Общие уведомления приложения', // Описание канала
        importance: Importance.max,
        priority: Priority.max,
        showWhen: true,
        icon: '@mipmap/ic_launcher', // Используем иконку приложения
        largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        enableVibration: true,
        playSound: true,
        visibility: NotificationVisibility.public,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.message,
        color: Color.fromARGB(255, 0, 122, 255),
        ticker: 'Новое уведомление',
      );

      // Настройки для iOS
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
        badgeNumber: 1,
        interruptionLevel: InterruptionLevel.active,
      );

      // Объединяем настройки платформ
      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Отправляем уведомление
      await flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        platformDetails,
        payload: payload,
      );

      // Устанавливаем бейдж
      try {
        if (await FlutterAppBadger.isAppBadgeSupported()) {
          FlutterAppBadger.updateBadgeCount(1);
        }
      } catch (e) {
        debugPrint('Ошибка при обновлении бейджа: $e');
      }

      debugPrint('NotificationService: Отправлено уведомление "$title"');
    } catch (e) {
      debugPrint('Ошибка при отправке уведомления: $e');
    }
  }

  /// Запланировать отложенное уведомление
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required int seconds,
    String? payload,
  }) async {
    try {
      // Настройки для Android
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        _scheduledChannelId,
        'Запланированные тренировки',
        channelDescription: 'Уведомления о запланированных тренировках',
        importance: Importance.max,
        priority: Priority.max,
        icon: '@mipmap/ic_launcher',
        largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        enableVibration: true,
        playSound: true,
        visibility: NotificationVisibility.public,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.message,
        color: Color.fromARGB(255, 0, 122, 255),
      );

      // Настройки для iOS
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
        badgeNumber: 1,
        interruptionLevel: InterruptionLevel.active,
      );

      // Объединяем настройки платформ
      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Рассчитываем время уведомления
      final scheduledTime =
          tz.TZDateTime.now(tz.local).add(Duration(seconds: seconds));

      // Отправляем запланированное уведомление с правильными параметрами для версии 19.1.0
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledTime,
        platformDetails,
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      debugPrint(
          'NotificationService: Запланировано уведомление "$title" через $seconds секунд');
    } catch (e) {
      debugPrint('Ошибка при планировании уведомления: $e');
    }
  }

  /// Отмена уведомления по ID
  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
    debugPrint('NotificationService: Отменено уведомление с ID $id');
  }

  /// Отмена всех уведомлений
  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();

    // Обнуляем бейдж
    try {
      if (await FlutterAppBadger.isAppBadgeSupported()) {
        FlutterAppBadger.removeBadge();
      }
    } catch (e) {
      debugPrint('Ошибка при удалении бейджа: $e');
    }

    debugPrint('NotificationService: Отменены все уведомления');
  }
}

import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../services/notifications_catalog.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  bool _hasPermission = false;
  bool _isInitialized = false;

  bool get hasPermission => _hasPermission;
  bool get isInitialized => _isInitialized;

  /// Инициализация сервиса уведомлений
  Future<void> initialize() async {
    try {
      await _notificationService.initialize();
      _isInitialized = true;

      // Автоматически запрашиваем разрешение на показ уведомлений
      await requestPermissions();

      // Дополнительно запрашиваем разрешения для Android 13 и выше
      await _requestAndroidPermissions();

      notifyListeners();
      debugPrint('NotificationProvider: инициализация завершена');

      // Проверка доступности методов активации
      await _checkNotificationServices();
    } catch (e) {
      debugPrint('NotificationProvider: ошибка инициализации: $e');
    }
  }

  /// Проверка доступности сервисов уведомлений
  Future<void> _checkNotificationServices() async {
    try {
      final plugin = _notificationService.flutterLocalNotificationsPlugin;
      final androidImplementation =
          plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        // Проверяем, активны ли уведомления в настройках
        final areNotificationsEnabled =
            await androidImplementation.areNotificationsEnabled();
        debugPrint(
            'NotificationProvider: уведомления активированы в системе - $areNotificationsEnabled');
      }
    } catch (e) {
      debugPrint(
          'NotificationProvider: ошибка при проверке сервисов уведомлений: $e');
    }
  }

  /// Запрос разрешений для Android 13+
  Future<void> _requestAndroidPermissions() async {
    try {
      final plugin = _notificationService.flutterLocalNotificationsPlugin;
      final androidImplementation =
          plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        // Запрашиваем разрешение для Android 13+
        final permissionResult =
            await androidImplementation.requestNotificationsPermission();
        debugPrint(
            'NotificationProvider: результат запроса разрешений Android 13+ - $permissionResult');

        // Запрашиваем разрешение на точные будильники для показа запланированных уведомлений
        final alarmResult =
            await androidImplementation.requestExactAlarmsPermission();
        debugPrint(
            'NotificationProvider: разрешение на точные будильники - $alarmResult');
      }
    } catch (e) {
      debugPrint(
          'NotificationProvider: ошибка при запросе Android разрешений: $e');
    }
  }

  /// Запрос разрешений на показ уведомлений
  /// Возвращает true, если разрешения получены
  Future<bool> requestPermissions() async {
    try {
      _hasPermission = await _notificationService.requestPermissions();
      notifyListeners();

      debugPrint(
          'NotificationProvider: разрешения ${_hasPermission ? "получены" : "не получены"}');
      return _hasPermission;
    } catch (e) {
      debugPrint('NotificationProvider: ошибка при запросе разрешений: $e');
      return false;
    }
  }

  /// Показать простое уведомление
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) {
      debugPrint('NotificationProvider: сервис не инициализирован');
      await initialize();
    }

    debugPrint('NotificationProvider: отправка уведомления "$title"');
    await _notificationService.showNotification(
      id: id,
      title: title,
      body: body,
      payload: payload,
    );

    // Проверяем, активно ли уведомление
    debugPrint('NotificationProvider: проверка активных уведомлений');
    await _checkPendingNotifications();
  }

  /// Показать уведомление из каталога
  Future<void> showCatalogNotification(NotificationItem notification) async {
    debugPrint(
        'NotificationProvider: отправка уведомления из каталога: ${notification.title}');
    await showNotification(
      id: notification.id,
      title: notification.title,
      body: notification.body,
      payload: notification.payload,
    );
  }

  /// Запланировать отложенное уведомление
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required int seconds,
    String? payload,
  }) async {
    if (!_isInitialized) {
      debugPrint('NotificationProvider: сервис не инициализирован');
      await initialize();
    }

    debugPrint(
        'NotificationProvider: планирование уведомления "$title" через $seconds секунд');
    await _notificationService.scheduleNotification(
      id: id,
      title: title,
      body: body,
      seconds: seconds,
      payload: payload,
    );

    // Проверяем, запланировано ли уведомление
    debugPrint('NotificationProvider: проверка запланированных уведомлений');
    await _checkPendingNotifications();
  }

  /// Запланировать уведомление из каталога
  Future<void> scheduleCatalogNotification(
      NotificationItem notification, int seconds) async {
    debugPrint(
        'NotificationProvider: планирование уведомления из каталога "${notification.title}" через $seconds секунд');
    await scheduleNotification(
      id: notification.id,
      title: notification.title,
      body: notification.body,
      seconds: seconds,
      payload: notification.payload,
    );
  }

  /// Отправка уведомления после выхода из приложения
  Future<void> showExitNotification() async {
    if (!_isInitialized) {
      debugPrint('NotificationProvider: сервис не инициализирован');
      await initialize();
    }

    debugPrint(
        'NotificationProvider: отправка уведомления после выхода из приложения');

    // Перед отправкой проверяем активацию уведомлений
    await _checkNotificationServices();

    // Получаем уведомление из каталога
    final notification = NotificationsCatalog.exitAppNotification;

    // Отправляем уведомление
    await _notificationService.showNotification(
      id: notification.id,
      title: notification.title,
      body: notification.body,
      payload: notification.payload,
    );

    // Проверяем, активно ли уведомление
    debugPrint(
        'NotificationProvider: проверка активных уведомлений после showExitNotification');
    await _checkPendingNotifications();
  }

  /// Проверяет активные уведомления
  Future<void> _checkPendingNotifications() async {
    try {
      final plugin = _notificationService.flutterLocalNotificationsPlugin;
      final androidImplementation =
          plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        // Проверяем, есть ли активные уведомления
        final pendingNotifications = await plugin.pendingNotificationRequests();
        final activeNotifications =
            await androidImplementation.getActiveNotifications();

        debugPrint(
            'NotificationProvider: количество ожидающих уведомлений: ${pendingNotifications.length}');
        debugPrint(
            'NotificationProvider: количество активных уведомлений: ${activeNotifications.length}');

        if (pendingNotifications.isNotEmpty) {
          debugPrint(
              'NotificationProvider: ожидающие уведомления: ${pendingNotifications.map((n) => n.id).join(", ")}');
        }

        if (activeNotifications.isNotEmpty) {
          debugPrint(
              'NotificationProvider: активные уведомления: ${activeNotifications.map((n) => n.id).join(", ")}');
        }
      }
    } catch (e) {
      debugPrint(
          'NotificationProvider: ошибка при проверке активных уведомлений: $e');
    }
  }

  /// Отмена уведомления по ID
  Future<void> cancelNotification(int id) async {
    if (!_isInitialized) return;
    await _notificationService.cancelNotification(id);
  }

  /// Отмена всех уведомлений
  Future<void> cancelAllNotifications() async {
    if (!_isInitialized) return;
    await _notificationService.cancelAllNotifications();
  }

  /// Отправить тестовое уведомление
  Future<void> sendTestNotification() async {
    final notification = NotificationsCatalog.testNotification;
    await showCatalogNotification(notification);
  }

  /// Отправить случайное мотивационное уведомление
  Future<void> sendRandomMotivationalNotification() async {
    final notification =
        NotificationsCatalog.getRandomMotivationalNotification();
    await showCatalogNotification(notification);
  }

  /// Отправить напоминание о тренировке
  Future<void> sendWorkoutReminder(String workoutName) async {
    final notification = NotificationsCatalog.workoutReminder(workoutName);
    await showCatalogNotification(notification);
  }

  /// Отправить напоминание о питьевом режиме
  Future<void> sendWaterReminder() async {
    final notification = NotificationsCatalog.waterReminderNotification;
    await showCatalogNotification(notification);
  }

  /// Отправить уведомление о достижении цели
  Future<void> sendDailyGoalNotification() async {
    final notification = NotificationsCatalog.dailyGoalNotification;
    await showCatalogNotification(notification);
  }

  /// Отправить уведомление о достижении
  Future<void> sendAchievementNotification(String achievementName) async {
    final notification =
        NotificationsCatalog.achievementNotification(achievementName);
    await showCatalogNotification(notification);
  }
}

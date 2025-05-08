import 'package:flutter/material.dart';

/// Класс для хранения всех типов уведомлений в приложении
/// Позволяет централизованно управлять текстами и идентификаторами
class NotificationsCatalog {
  // Идентификаторы уведомлений
  static const int exitAppNotificationId = 1;
  static const int workoutReminderNotificationId = 2;
  static const int dailyGoalNotificationId = 3;
  static const int waterReminderNotificationId = 4;
  static const int motivationNotificationId = 5;
  static const int achievementNotificationId = 6;
  static const int testNotificationId = 999;

  /// Уведомление при выходе из приложения
  static NotificationItem get exitAppNotification => NotificationItem(
        id: exitAppNotificationId,
        title: 'Don\'t forget your workout!',
        body: 'Come back and continue your journey to the perfect body.',
        payload: 'exit_notification',
      );

  /// Напоминание о запланированной тренировке
  static NotificationItem workoutReminder(String workoutName) =>
      NotificationItem(
        id: workoutReminderNotificationId,
        title: 'Время тренировки!',
        body:
            'Пора начать тренировку "$workoutName"! Не откладывай свой успех.',
        payload: 'workout_reminder:$workoutName',
      );

  /// Уведомление о достижении дневной цели
  static NotificationItem get dailyGoalNotification => NotificationItem(
        id: dailyGoalNotificationId,
        title: 'Цель дня достигнута!',
        body:
            'Поздравляем! Вы успешно достигли своей дневной цели по активности.',
        payload: 'daily_goal',
      );

  /// Напоминание о питьевом режиме
  static NotificationItem get waterReminderNotification => NotificationItem(
        id: waterReminderNotificationId,
        title: 'Не забывай пить воду',
        body:
            'Регулярное питье поможет поддерживать водный баланс и улучшить результаты тренировок.',
        payload: 'water_reminder',
      );

  /// Мотивационное сообщение
  static List<NotificationItem> get motivationalNotifications => [
        NotificationItem(
          id: motivationNotificationId,
          title: 'Мотивация дня',
          body: 'Каждая тренировка — это шаг к твоей лучшей версии!',
          payload: 'motivation:1',
        ),
        NotificationItem(
          id: motivationNotificationId + 1,
          title: 'Оставайся сильным',
          body:
              'Не останавливайся, когда устанешь. Останавливайся, когда достигнешь цели!',
          payload: 'motivation:2',
        ),
        NotificationItem(
          id: motivationNotificationId + 2,
          title: 'Сила воли',
          body:
              'Сила воли важнее, чем способности. Продолжай работать над собой!',
          payload: 'motivation:3',
        ),
      ];

  /// Уведомление о достижении
  static NotificationItem achievementNotification(String achievementName) =>
      NotificationItem(
        id: achievementNotificationId,
        title: 'Новое достижение!',
        body:
            'Вы получили достижение "$achievementName". Продолжайте в том же духе!',
        payload: 'achievement:$achievementName',
      );

  /// Тестовое уведомление
  static NotificationItem get testNotification => NotificationItem(
        id: testNotificationId,
        title: 'Тестовое уведомление',
        body:
            'Это тестовое уведомление для проверки работы системы уведомлений',
        payload: 'test_notification',
      );

  /// Получить случайное мотивационное уведомление
  static NotificationItem getRandomMotivationalNotification() {
    final motivationalList = motivationalNotifications;
    final randomIndex =
        DateTime.now().millisecondsSinceEpoch % motivationalList.length;
    return motivationalList[randomIndex];
  }
}

/// Класс, представляющий отдельное уведомление
class NotificationItem {
  final int id;
  final String title;
  final String body;
  final String? payload;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    this.payload,
  });

  @override
  String toString() {
    return 'NotificationItem(id: $id, title: "$title", body: "$body", payload: $payload)';
  }
}

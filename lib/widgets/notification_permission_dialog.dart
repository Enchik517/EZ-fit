import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../services/notification_service.dart';

/// Диалог для запроса разрешений на уведомления
class NotificationPermissionDialog extends StatelessWidget {
  final VoidCallback? onPermissionGranted;
  final VoidCallback? onPermissionDenied;

  const NotificationPermissionDialog({
    Key? key,
    this.onPermissionGranted,
    this.onPermissionDenied,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.black
          : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Иконка уведомления
            Icon(
              Icons.notifications_active,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),

            // Заголовок
            Text(
              'Включить уведомления',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Описание
            Text(
              'Разрешите отправлять вам уведомления, чтобы получать напоминания о тренировках и не терять мотивацию.',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white70
                    : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Кнопки
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Кнопка "Не сейчас"
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      if (onPermissionDenied != null) {
                        onPermissionDenied!();
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Не сейчас'),
                  ),
                ),
                const SizedBox(width: 16),

                // Кнопка "Разрешить"
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final notificationProvider =
                          Provider.of<NotificationProvider>(context,
                              listen: false);

                      // Запрашиваем разрешения для iOS и старых версий Android
                      final hasPermission =
                          await notificationProvider.requestPermissions();

                      // Дополнительно запрашиваем разрешения для Android 13+
                      await _requestAndroidPermissions();

                      // Проверяем, нужно ли показать диалог о точных будильниках
                      bool needsAlarmPermission =
                          await _checkIfNeedsAlarmPermission();

                      if (context.mounted) {
                        Navigator.of(context).pop();

                        // Если нужно разрешение на точные будильники, показываем диалог
                        if (needsAlarmPermission && context.mounted) {
                          showExactAlarmPermissionDialog(context);
                        }

                        if (hasPermission) {
                          if (onPermissionGranted != null) {
                            onPermissionGranted!();
                          }
                        } else {
                          if (onPermissionDenied != null) {
                            onPermissionDenied!();
                          }
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Разрешить'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Запрашивает разрешения для Android 13+
  Future<void> _requestAndroidPermissions() async {
    try {
      // Получаем экземпляр сервиса напрямую
      final notificationService = NotificationService();
      final plugin = notificationService.flutterLocalNotificationsPlugin;
      final androidImpl = plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (androidImpl != null) {
        // Запрашиваем разрешение на показ уведомлений (Android 13+)
        await androidImpl.requestNotificationsPermission();

        // Запрашиваем разрешение на точные будильники (для запланированных уведомлений)
        await androidImpl.requestExactAlarmsPermission();

        debugPrint(
            'NotificationPermissionDialog: Android-разрешения запрошены');
      }
    } catch (e) {
      debugPrint(
          'NotificationPermissionDialog: ошибка запроса Android-разрешений: $e');
    }
  }

  /// Проверяет, нужно ли показать диалог о разрешении на точные будильники
  Future<bool> _checkIfNeedsAlarmPermission() async {
    try {
      final notificationService = NotificationService();
      final plugin = notificationService.flutterLocalNotificationsPlugin;
      final androidImpl = plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (androidImpl != null) {
        // Пытаемся запросить разрешение и получить результат
        try {
          // Этот метод вернет true, если разрешение уже есть или успешно получено
          // Вернет false, если пользователь отказал или нет возможности автоматически запросить
          final hasAlarmPermission =
              await androidImpl.requestExactAlarmsPermission();
          debugPrint('Разрешение на точные будильники: $hasAlarmPermission');
          // Проверяем результат, который может быть null (трактуем как false в этом случае)
          return !(hasAlarmPermission ?? false);
        } catch (e) {
          // Если здесь возникает ошибка, скорее всего, разрешение не дано
          debugPrint('Ошибка при запросе разрешения на точные будильники: $e');
          return true; // Считаем, что нужно показать диалог
        }
      }
    } catch (e) {
      debugPrint('Ошибка при проверке разрешения на точные будильники: $e');
    }
    return false;
  }
}

/// Функция для показа диалога разрешения уведомлений
Future<void> showNotificationPermissionDialog(
  BuildContext context, {
  VoidCallback? onPermissionGranted,
  VoidCallback? onPermissionDenied,
}) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return NotificationPermissionDialog(
        onPermissionGranted: onPermissionGranted,
        onPermissionDenied: onPermissionDenied,
      );
    },
  );
}

/// Функция для показа диалога о необходимости включить точные будильники
Future<void> showExactAlarmPermissionDialog(BuildContext context) async {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Дополнительное разрешение'),
        content: const Text(
            'Для правильной работы уведомлений на вашем устройстве необходимо разрешить приложению использовать точные будильники. '
            'Пожалуйста, перейдите в настройки приложения → Уведомления → Дополнительные разрешения и включите "Точные будильники".'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Понятно'),
          ),
        ],
      );
    },
  );
}

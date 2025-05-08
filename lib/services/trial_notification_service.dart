import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';
import '../services/user_service.dart';
import '../models/user_profile.dart';

class TrialNotificationService {
  static const String _trialStartDateKey = 'trial_start_date';
  static const String _onboardingReminderSentKey = 'onboarding_reminder_sent';
  static const int _onboardingReminderDelayHours = 48; // 48 часов
  static const int _onboardingReminderNotificationId = 9000;

  /// Регистрирует начало пробного периода
  Future<void> registerTrialStart() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Сохраняем текущее время как время начала пробного периода
      final now = DateTime.now().millisecondsSinceEpoch;
      await prefs.setInt(_trialStartDateKey, now);

      // Сбрасываем флаг отправки уведомления
      await prefs.setBool(_onboardingReminderSentKey, false);

      debugPrint(
          'TrialNotificationService: Пробный период зарегистрирован: ${DateTime.now()}');

      // Запланировать проверку завершения онбординга через 48 часов
      _scheduleOnboardingCheck();
    } catch (e) {
      debugPrint(
          'TrialNotificationService: Ошибка при регистрации пробного периода: $e');
    }
  }

  /// Проверяет, завершил ли пользователь онбординг, и отправляет уведомление если не завершил
  Future<void> _scheduleOnboardingCheck() async {
    try {
      final notificationService = NotificationService();

      // Запланировать уведомление через 48 часов
      await notificationService.scheduleNotification(
        id: _onboardingReminderNotificationId,
        title: "👋 Still With Us?",
        body:
            "You're almost there! Complete your setup today to get the most out of the app.",
        seconds:
            _onboardingReminderDelayHours * 3600, // Конвертируем часы в секунды
        payload: "onboarding_reminder",
      );

      debugPrint(
          'TrialNotificationService: Запланирована проверка онбординга через $_onboardingReminderDelayHours часов');
    } catch (e) {
      debugPrint(
          'TrialNotificationService: Ошибка при планировании проверки онбординга: $e');
    }
  }

  /// Отмечает, что уведомление о незавершенном онбординге было отправлено
  Future<void> markOnboardingReminderSent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingReminderSentKey, true);
      debugPrint(
          'TrialNotificationService: Уведомление о незавершенном онбординге отмечено как отправленное');
    } catch (e) {
      debugPrint(
          'TrialNotificationService: Ошибка при обновлении статуса уведомления: $e');
    }
  }

  /// Отменяет запланированное уведомление о незавершенном онбординге
  Future<void> cancelOnboardingReminder() async {
    try {
      final notificationService = NotificationService();
      await notificationService
          .cancelNotification(_onboardingReminderNotificationId);
      debugPrint(
          'TrialNotificationService: Уведомление о незавершенном онбординге отменено');
    } catch (e) {
      debugPrint('TrialNotificationService: Ошибка при отмене уведомления: $e');
    }
  }
}

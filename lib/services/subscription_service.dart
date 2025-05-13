import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/subscription_provider.dart';
import 'package:provider/provider.dart';

/// Сервис для управления статусом подписки пользователя
class SubscriptionService {
  static const String _subscriptionStatusKey = 'subscription_status';
  static const String _subscriptionExpiryDateKey = 'subscription_expiry_date';

  /// Кэшированный статус подписки
  bool? _isSubscribed;

  /// Дата истечения подписки
  DateTime? _expiryDate;

  /// Проверяет, имеет ли пользователь активную подписку
  /// Сначала проверяет локальный кэш, затем SharedPreferences
  Future<bool> isSubscribed() async {
    // Если у нас есть кэшированный статус, возвращаем его
    if (_isSubscribed != null && _expiryDate != null) {
      // Проверяем, не истекла ли подписка
      if (_expiryDate!.isAfter(DateTime.now())) {
        return _isSubscribed!;
      }
    }

    // Иначе загружаем статус из SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    _isSubscribed = prefs.getBool(_subscriptionStatusKey) ?? false;

    // Проверяем срок действия подписки
    final expiryTimestamp = prefs.getInt(_subscriptionExpiryDateKey);
    if (expiryTimestamp != null) {
      _expiryDate = DateTime.fromMillisecondsSinceEpoch(expiryTimestamp);

      // Если срок действия истек, сбрасываем статус подписки
      if (_expiryDate!.isBefore(DateTime.now())) {
        _isSubscribed = false;
        await prefs.setBool(_subscriptionStatusKey, false);
      }
    }

    return _isSubscribed ?? false;
  }

  /// Устанавливает статус подписки (для тестирования или после успешной оплаты)
  /// Сохраняет статус в SharedPreferences для сохранения между сеансами
  Future<void> setSubscriptionStatus(bool status, {Duration? duration}) async {
    _isSubscribed = status;

    // Устанавливаем срок действия подписки (по умолчанию 1 месяц)
    _expiryDate = DateTime.now().add(duration ?? const Duration(days: 30));

    // Сохраняем статус в SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_subscriptionStatusKey, status);
    await prefs.setInt(
        _subscriptionExpiryDateKey, _expiryDate!.millisecondsSinceEpoch);
  }

  /// Очищает кэш и сбрасывает статус подписки
  Future<void> clearCache() async {
    _isSubscribed = null;
    _expiryDate = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_subscriptionStatusKey);
    await prefs.remove(_subscriptionExpiryDateKey);
  }

  /// Показывает экран подписки
  void showSubscriptionScreen(BuildContext context) {
    final subscriptionProvider =
        Provider.of<SubscriptionProvider>(context, listen: false);
    subscriptionProvider.showSubscription();
  }

  /// Возвращает дату истечения подписки или null, если нет активной подписки
  Future<DateTime?> getExpiryDate() async {
    if (_expiryDate != null) {
      return _expiryDate;
    }

    final prefs = await SharedPreferences.getInstance();
    final expiryTimestamp = prefs.getInt(_subscriptionExpiryDateKey);

    if (expiryTimestamp != null) {
      _expiryDate = DateTime.fromMillisecondsSinceEpoch(expiryTimestamp);
      return _expiryDate;
    }

    return null;
  }

  /// Форматирует дату истечения подписки в читаемый формат
  String formatExpiryDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}

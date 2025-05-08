import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/superwall_service.dart';
import 'package:superwallkit_flutter/superwallkit_flutter.dart';

/// Провайдер для управления подписками через Superwall
class SubscriptionProvider with ChangeNotifier {
  final SuperwallService _superwallService = SuperwallService();
  bool _isSubscribed = false;
  bool _isLoading = false;

  /// Возвращает статус подписки
  bool get isSubscribed => _isSubscribed;

  /// Возвращает статус загрузки
  bool get isLoading => _isLoading;

  /// Инициализирует провайдер
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Инициализация Superwall
      await _superwallService.initialize();

      // По умолчанию считаем, что пользователь не подписан
      _isSubscribed = false;
    } catch (e) {
      //      _isSubscribed = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Показывает экран подписки Superwall с указанным плейсментом
  Future<void> showSubscription({String placementId = 'pro_feature'}) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Регистрируем плейсмент для показа paywall
      await _superwallService.registerPaywallForPlacement(placementId);
    } catch (e) {
      //    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Обновляет атрибуты пользователя для Superwall
  void updateUserAttributes(Map<String, dynamic> attributes) {
    _superwallService.setUserAttributes(attributes);
  }

  /// Идентифицирует пользователя в Superwall
  void identifyUser(String userId) {
    _superwallService.identifyUser(userId);
  }

  /// Устанавливает статус подписки
  void setSubscriptionStatus(bool status) {
    _isSubscribed = status;
    notifyListeners();
  }

  /// Устанавливает временный тестовый премиум статус (для разработки/тестирования)
  Future<void> setTestPremiumStatus() async {
    try {
      // Ставим флаг загрузки
      _isLoading = true;
      notifyListeners();

      // Добавляем небольшую задержку для имитации сетевого запроса
      await Future.delayed(Duration(milliseconds: 300));

      // Устанавливаем премиум статус
      _isSubscribed = true;
    } catch (e) {
      debugPrint('Ошибка при установке тестового премиум статуса: $e');
    } finally {
      // Убираем флаг загрузки
      _isLoading = false;
      notifyListeners();
    }
  }
}

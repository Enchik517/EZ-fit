import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../services/superwall_service.dart';
import '../services/subscription_service.dart';
import 'package:superwallkit_flutter/superwallkit_flutter.dart';
import '../screens/disclaimer_screen.dart';

/// Провайдер для управления подписками через Superwall
class SubscriptionProvider with ChangeNotifier {
  final SuperwallService _superwallService = SuperwallService();
  final SubscriptionService _subscriptionService = SubscriptionService();
  bool _isSubscribed = false;
  bool _isLoading = false;
  DateTime? _expiryDate;

  // Метод-канал для взаимодействия с нативным кодом Android
  static const platform = MethodChannel('com.yourapp/superwall');

  /// Возвращает статус подписки
  bool get isSubscribed => _isSubscribed;

  /// Возвращает статус загрузки
  bool get isLoading => _isLoading;

  /// Возвращает дату истечения подписки
  DateTime? get expiryDate => _expiryDate;

  /// Инициализирует провайдер
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Инициализация Superwall
      await _superwallService.initialize();

      // Проверяем статус подписки из сервиса
      _isSubscribed = await _subscriptionService.isSubscribed();
      _expiryDate = await _subscriptionService.getExpiryDate();
    } catch (e) {
      debugPrint('SubscriptionProvider: ошибка инициализации: $e');
      _isSubscribed = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Показывает экран подписки Superwall с указанным плейсментом
  Future<void> showSubscription({String placementId = 'pro_feature'}) async {
    // Проверяем, не отображается ли уже paywall
    if (_superwallService.isShowingPaywall) {
      debugPrint(
          'SubscriptionProvider: paywall уже отображается, пропускаем повторный вызов');
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // На Android настраиваем режим без возможности взаимодействия с фоном
      if (defaultTargetPlatform == TargetPlatform.android) {
        await _configureAndroidPaywall();
      }

      // Регистрируем плейсмент для показа paywall
      await _superwallService.registerPaywallForPlacement(placementId);
    } catch (e) {
      debugPrint('SubscriptionProvider: ошибка при показе подписки: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Настраивает нативное окно Superwall на Android для блокировки взаимодействия с фоном
  Future<void> _configureAndroidPaywall() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        // Вызываем нативный метод для настройки PaywallActivity
        await platform.invokeMethod('configurePaywall',
            {'disableBackgroundTouches': true, 'isFullscreen': true});
        debugPrint(
            'SubscriptionProvider: Android paywall настроен для полноэкранного режима');
      } catch (e) {
        debugPrint(
            'SubscriptionProvider: ошибка настройки Android paywall: $e');
      }
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
  Future<void> setSubscriptionStatus(bool status, {Duration? duration}) async {
    // Используем сервис для установки статуса подписки
    await _subscriptionService.setSubscriptionStatus(status,
        duration: duration);

    // Обновляем локальные значения
    _isSubscribed = status;
    _expiryDate = await _subscriptionService.getExpiryDate();

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

      // Устанавливаем премиум статус на 7 дней
      await setSubscriptionStatus(true, duration: const Duration(days: 7));
    } catch (e) {
      debugPrint('Ошибка при установке тестового премиум статуса: $e');
    } finally {
      // Убираем флаг загрузки
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Сбрасывает кэш статуса подписки
  Future<void> clearCache() async {
    await _subscriptionService.clearCache();
    _isSubscribed = false;
    _expiryDate = null;
    notifyListeners();
  }

  /// Перенаправляет на экран дисклеймера после успешной подписки
  void redirectToDisclaimerAfterPayment(BuildContext context) {
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
}

import 'package:flutter/foundation.dart';
import 'package:superwallkit_flutter/superwallkit_flutter.dart';
import 'package:flutter/material.dart';
import '../main.dart'; // Добавляем импорт для доступа к navigatorKey

/// Сервис для взаимодействия с Superwall SDK
class SuperwallService {
  static final SuperwallService _instance = SuperwallService._internal();
  bool _isConfigured = false; // Флаг для отслеживания успешной инициализации

  /// Статический метод для получения синглтона
  factory SuperwallService() => _instance;

  SuperwallService._internal();

  /// Проверяет, запущено ли приложение на iOS
  bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;

  /// Инициализирует SDK Superwall
  Future<void> initialize() async {
    // Пропускаем инициализацию, если не iOS (Superwall в основном для iOS)
    if (!_isIOS) {
      debugPrint('Superwall инициализация пропущена: не iOS платформа');
      return;
    }

    try {
      debugPrint('Начинаем инициализацию Superwall...');

      // Создаем опции конфигурации
      final options = SuperwallOptions();
      options.paywalls.shouldPreload = true;

      // ВСЕГДА выполняем полную конфигурацию, без проверок
      debugPrint('Выполняем принудительную конфигурацию Superwall');
      await Future.delayed(
          const Duration(milliseconds: 300)); // Увеличиваем задержку

      try {
        // Принудительно выполняем конфигурацию без проверок на предыдущую инициализацию
        await Superwall.configure(
          'pk_a8d000b9824387f66332c9958e30bfad0e9b22ec844b52fc',
          options: options,
        );
        debugPrint('Superwall: конфигурация успешно завершена');
        _isConfigured = true;
      } catch (configError) {
        debugPrint('ОШИБКА ПРИ КОНФИГУРАЦИИ SUPERWALL: $configError');
        _isConfigured = false;
        rethrow; // Пробрасываем ошибку выше для диагностики
      }
    } catch (e) {
      debugPrint('КРИТИЧЕСКАЯ ОШИБКА SUPERWALL: $e');
      _isConfigured = false;
      // Не пробрасываем ошибку, чтобы приложение продолжило работу
    }
  }

  /// Показывает paywall при регистрации placement
  Future<void> registerPaywallForPlacement(String placement) async {
    // Безопасная проверка инициализации
    if (!_isIOS) {
      debugPrint('Superwall не готов: не iOS платформа');
      _redirectToMainScreen();
      return;
    }

    if (!_isConfigured) {
      debugPrint('Superwall не готов: не инициализирован');
      _redirectToMainScreen();
      return;
    }

    try {
      debugPrint('Показываем paywall для placement: $placement');

      final handler = PaywallPresentationHandler();
      handler
        ..onPresent((info) {
          debugPrint('Paywall показан: $info');
        })
        ..onDismiss((info, result) {
          debugPrint('Paywall закрыт: $info, $result');
          _redirectToMainScreen();
        })
        ..onError((error) {
          debugPrint('Ошибка при показе paywall: $error');
          _redirectToMainScreen();
        });

      // Регистрируем placement и показываем paywall напрямую
      Superwall.shared.registerPlacement(placement, handler: handler);
    } catch (e) {
      debugPrint('Ошибка при регистрации paywall: $e');
      _redirectToMainScreen();
    }
  }

  /// Вспомогательный метод для перенаправления на главный экран
  void _redirectToMainScreen() {
    if (navigatorKey.currentContext != null) {
      Navigator.of(navigatorKey.currentContext!).pushReplacementNamed('/main');
    }
  }

  /// Устанавливает атрибуты пользователя
  void setUserAttributes(Map<String, dynamic> attributes) {
    // Безопасная проверка инициализации
    if (!_isConfigured) {
      debugPrint('Superwall не инициализирован, пропускаем setUserAttributes');
      return;
    }

    try {
      // Преобразуем Map<String, dynamic> в Map<String, Object>
      final Map<String, Object> cleanAttributes = {};
      attributes.forEach((key, value) {
        // Пропускаем null значения, так как Object не может быть null
        if (value != null) {
          cleanAttributes[key] = value;
        }
      });

      Superwall.shared.setUserAttributes(cleanAttributes);
    } catch (e) {
      debugPrint('Ошибка при установке атрибутов пользователя Superwall: $e');
    }
  }

  /// Идентифицирует пользователя
  void identifyUser(String userId) {
    // Безопасная проверка инициализации
    if (!_isConfigured) {
      debugPrint('Superwall не инициализирован, пропускаем identifyUser');
      return;
    }

    try {
      Superwall.shared.identify(userId);
    } catch (e) {
      debugPrint('Ошибка при идентификации пользователя Superwall: $e');
    }
  }

  /// Сбрасывает пользователя
  void resetUser() {
    // Безопасная проверка инициализации
    if (!_isConfigured) {
      debugPrint('Superwall не инициализирован, пропускаем resetUser');
      return;
    }

    try {
      Superwall.shared.reset();
    } catch (e) {
      debugPrint('Ошибка при сбросе пользователя Superwall: $e');
    }
  }
}

import 'package:flutter/foundation.dart';
import 'package:superwallkit_flutter/superwallkit_flutter.dart';
import 'package:flutter/material.dart';
import '../main.dart'; // Добавляем импорт для доступа к navigatorKey
import 'package:flutter/services.dart';

/// Сервис для взаимодействия с Superwall SDK
class SuperwallService {
  static final SuperwallService _instance = SuperwallService._internal();
  bool _isConfigured = false; // Флаг для отслеживания успешной инициализации
  bool _isShowingPaywall =
      false; // Флаг для отслеживания текущего показа paywall

  // Метод-канал для настройки нативного представления
  static const MethodChannel _channel =
      MethodChannel('com.fitbod/superwall_config');

  /// Статический метод для получения синглтона
  factory SuperwallService() => _instance;

  SuperwallService._internal();

  /// Проверяет, запущено ли приложение на iOS
  bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;

  /// Проверяет, запущено ли приложение на Android
  bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;

  /// Возвращает текущее состояние отображения paywall
  bool get isShowingPaywall => _isShowingPaywall;

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

      // Пытаемся настроить параметры модального представления
      await _configurePaywallPresentation();

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

  /// Настраивает параметры представления Superwall на нативном уровне
  Future<void> _configurePaywallPresentation() async {
    try {
      if (_isIOS) {
        // На iOS настраиваем модальное представление
        await _channel.invokeMethod('configureIOSPresentation', {
          'modalStyle': 'fullScreen',
          'disableDismiss': true,
          'disableBackgroundInteractions': true
        });
        debugPrint('Superwall: настроено iOS модальное представление');
      } else if (_isAndroid) {
        // На Android настраиваем активити
        await _channel.invokeMethod('configureAndroidPresentation', {
          'fullScreen': true,
          'immersiveMode': true,
          'disableDismiss': true
        });
        debugPrint('Superwall: настроено Android представление');
      }
    } catch (e) {
      debugPrint('Superwall: ошибка настройки нативного представления: $e');
      // Игнорируем ошибку, так как это дополнительная функциональность
    }
  }

  /// Показывает paywall при регистрации placement
  Future<void> registerPaywallForPlacement(String placement) async {
    // Безопасная проверка инициализации
    if (!_isIOS) {
      debugPrint('Superwall не готов: не iOS платформа');
      return; // Убираем перенаправление на главный экран
    }

    if (!_isConfigured) {
      debugPrint('Superwall не готов: не инициализирован');
      return; // Убираем перенаправление на главный экран
    }

    // Проверяем, не отображается ли уже paywall
    if (_isShowingPaywall) {
      debugPrint('Paywall уже отображается, пропускаем повторный вызов');
      return;
    }

    try {
      debugPrint('Показываем paywall для placement: $placement');

      // Устанавливаем флаг, что начинаем отображать paywall
      _isShowingPaywall = true;

      // Фиксируем текущий UI и блокируем взаимодействие с фоном
      // путем блокировки основного экрана на момент показа paywall
      if (_isAndroid) {
        try {
          await _channel.invokeMethod('prepareForPaywall', {'lockUI': true});
        } catch (e) {
          debugPrint('Ошибка при подготовке UI к показу paywall: $e');
        }
      }

      // Добавляем небольшую задержку для стабилизации UI перед показом paywall
      await Future.delayed(const Duration(milliseconds: 150));

      final handler = PaywallPresentationHandler();
      handler
        ..onPresent((info) {
          debugPrint('Paywall показан: $info');
        })
        ..onDismiss((info, result) {
          debugPrint('Paywall закрыт: $info, $result');
          // Сбрасываем флаг при закрытии paywall
          _isShowingPaywall = false;

          // Разблокируем UI после закрытия
          if (_isAndroid) {
            try {
              _channel.invokeMethod('cleanupAfterPaywall', {});
            } catch (e) {
              debugPrint(
                  'Ошибка при разблокировке UI после закрытия paywall: $e');
            }
          }
        })
        ..onError((error) {
          debugPrint('Ошибка при показе paywall: $error');
          // Сбрасываем флаг в случае ошибки
          _isShowingPaywall = false;

          // Разблокируем UI в случае ошибки
          if (_isAndroid) {
            try {
              _channel.invokeMethod('cleanupAfterPaywall', {});
            } catch (e) {
              debugPrint(
                  'Ошибка при разблокировке UI после ошибки paywall: $e');
            }
          }
        });

      // Регистрируем placement и показываем paywall напрямую
      Superwall.shared.registerPlacement(placement, handler: handler);
    } catch (e) {
      debugPrint('Ошибка при регистрации paywall: $e');
      // Сбрасываем флаг в случае исключения
      _isShowingPaywall = false;

      // Разблокируем UI в случае исключения
      if (_isAndroid) {
        try {
          _channel.invokeMethod('cleanupAfterPaywall', {});
        } catch (cleanupError) {
          debugPrint(
              'Ошибка при разблокировке UI после исключения: $cleanupError');
        }
      }
    }
  }

  /// Вспомогательный метод для перенаправления на главный экран
  /// Больше не используется при регистрации paywall, чтобы избежать автоматического редиректа
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

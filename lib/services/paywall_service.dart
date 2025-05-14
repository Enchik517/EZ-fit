import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'superwall_service.dart';

/// Сервис для работы с подписками через Superwall
class PaywallService {
  static const String _subscriptionStatusKey = 'subscription_status';
  static const String _subscriptionExpiryDateKey = 'subscription_expiry_date';

  // Используем SuperwallService
  final SuperwallService _superwallService = SuperwallService();

  List _products = [];
  final StreamController _purchaseController = StreamController.broadcast();

  // Список идентификаторов продуктов
  static const Set<String> _productIds = {
    'premium_monthly',
    'premium_yearly',
    'premium_lifetime'
  };

  Stream get purchaseStream => _purchaseController.stream;
  List get products => _products;

  Future<void> initialize() async {
    debugPrint('PaywallService: инициализация с использованием Superwall');

    // Инициализируем Superwall
    await _superwallService.initialize();

    // Создаем тестовые продукты для демонстрации
    _products = [
      {
        'id': 'premium_monthly',
        'title': 'Премиум подписка (ежемесячная)',
        'description': 'Полный доступ ко всем функциям приложения',
        'price': '299 руб.',
        'rawPrice': 299,
      },
      {
        'id': 'premium_yearly',
        'title': 'Премиум подписка (годовая)',
        'description': 'Полный доступ ко всем функциям приложения на целый год',
        'price': '2990 руб.',
        'rawPrice': 2990,
      },
      {
        'id': 'premium_lifetime',
        'title': 'Пожизненная премиум подписка',
        'description': 'Полный доступ ко всем функциям приложения навсегда',
        'price': '7990 руб.',
        'rawPrice': 7990,
      }
    ];

    debugPrint('PaywallService: создано ${_products.length} продуктов');
  }

  Future<void> loadProducts() async {
    // Продукты уже загружены в initialize()
    debugPrint('PaywallService: продукты уже загружены');
  }

  Future<void> purchaseSubscription(dynamic product) async {
    debugPrint(
        'PaywallService: покупка продукта ${product["id"]} через Superwall');

    try {
      // Показываем Superwall paywall
      await _superwallService.registerPaywallForPlacement('pro_feature');

      // Проверяем результат покупки из кэша после показа Superwall
      // В реальном сценарии, результат должен приходить из API Superwall
      final status = await getSubscriptionStatus();

      if (status['isSubscribed']) {
        // Если подписка активирована, отправляем событие о покупке
        final purchaseDetails = {
          'status': 'purchased',
          'productID': product['id'],
          'transactionId':
              'superwall_transaction_${DateTime.now().millisecondsSinceEpoch}',
        };

        _purchaseController.add(purchaseDetails);
        debugPrint('PaywallService: подписка активирована через Superwall');
      } else {
        debugPrint('PaywallService: подписка не была активирована');
      }
    } catch (e) {
      debugPrint('PaywallService: ошибка при покупке: $e');
      rethrow;
    }
  }

  Future<void> restorePurchases() async {
    debugPrint('PaywallService: восстановление покупок через Superwall');

    try {
      // Показываем Superwall для восстановления покупок
      await _superwallService.registerPaywallForPlacement('restore_purchases');

      // Так как Superwall сам обрабатывает восстановление,
      // нам нужно только проверить результат
      final status = await getSubscriptionStatus();

      if (status['isSubscribed']) {
        // Если подписка активирована, отправляем событие о восстановлении
        final purchaseDetails = {
          'status': 'restored',
          'productID':
              'premium_monthly', // Предполагаем, что была месячная подписка
          'transactionId': 'superwall_restored_transaction',
        };

        _purchaseController.add(purchaseDetails);
        debugPrint('PaywallService: подписка восстановлена через Superwall');
      } else {
        debugPrint('PaywallService: нет подписок для восстановления');
      }
    } catch (e) {
      debugPrint('PaywallService: ошибка при восстановлении покупок: $e');
      rethrow;
    }
  }

  // Проверка статуса подписки из кэша
  Future<Map<String, dynamic>> getSubscriptionStatus() async {
    final prefs = await SharedPreferences.getInstance();

    final isSubscribed = prefs.getBool(_subscriptionStatusKey) ?? false;
    final expiryDateString = prefs.getString(_subscriptionExpiryDateKey);
    DateTime? expiryDate;

    if (expiryDateString != null) {
      expiryDate = DateTime.tryParse(expiryDateString);

      // Проверяем, не истекла ли подписка
      if (expiryDate != null && expiryDate.isBefore(DateTime.now())) {
        // Подписка истекла
        await prefs.setBool(_subscriptionStatusKey, false);
        return {'isSubscribed': false, 'expiryDate': null};
      }
    }

    return {'isSubscribed': isSubscribed, 'expiryDate': expiryDate};
  }

  // Сохранение статуса подписки в кэш
  Future<void> saveSubscriptionStatus(
      {required bool isSubscribed, DateTime? expiryDate}) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_subscriptionStatusKey, isSubscribed);

    if (expiryDate != null) {
      await prefs.setString(
          _subscriptionExpiryDateKey, expiryDate.toIso8601String());
    } else {
      await prefs.remove(_subscriptionExpiryDateKey);
    }

    debugPrint(
        'PaywallService: сохранен статус подписки: $isSubscribed, срок: $expiryDate');
  }

  Future<void> clearSubscriptionCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_subscriptionStatusKey);
    await prefs.remove(_subscriptionExpiryDateKey);
    debugPrint('PaywallService: кэш подписки очищен');
  }

  void dispose() {
    _purchaseController.close();
    debugPrint('PaywallService: сервис завершил работу');
  }
}

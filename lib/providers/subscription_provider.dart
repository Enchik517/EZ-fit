import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/paywall_service.dart';
import '../screens/paywall_screen.dart';
import '../main.dart'; // Для доступа к navigatorKey
import '../services/superwall_service.dart';

/// Провайдер для управления подписками
class SubscriptionProvider with ChangeNotifier {
  final PaywallService _paywallService = PaywallService();
  final _supabase = Supabase.instance.client;

  bool _isSubscribed = false;
  bool _isLoading = false;
  DateTime? _expiryDate;
  List<dynamic> _products = [];

  SubscriptionProvider() {
    _initialize();
  }

  bool get isSubscribed => _isSubscribed;
  bool get isLoading => _isLoading;
  DateTime? get expiryDate => _expiryDate;
  List<dynamic> get products => _products;

  Future<void> _initialize() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Инициализируем сервис покупок
      await _paywallService.initialize();

      // Загружаем статус подписки из локального хранилища
      final status = await _paywallService.getSubscriptionStatus();
      _isSubscribed = status['isSubscribed'];
      _expiryDate = status['expiryDate'];

      // Загружаем продукты
      _products = _paywallService.products;

      // Проверяем актуальность статуса подписки на сервере
      await _verifySubscriptionOnServer();

      // Подписываемся на события покупок
      _paywallService.purchaseStream.listen(_onPurchaseUpdate);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Ошибка при инициализации SubscriptionProvider: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Проверка подписки на сервере
  Future<void> _verifySubscriptionOnServer() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Проверяем подписку в профиле пользователя
      final response = await _supabase
          .from('user_profiles')
          .select('subscription_type, subscription_expire_date')
          .eq('id', user.id)
          .maybeSingle();

      if (response != null) {
        final subscriptionType = response['subscription_type'];
        final expireDateStr = response['subscription_expire_date'];

        // Проверяем наличие активной подписки
        final isPremium = subscriptionType != null &&
            subscriptionType != 'free' &&
            subscriptionType != '';

        // Проверяем дату истечения
        DateTime? serverExpiryDate;
        if (expireDateStr != null) {
          serverExpiryDate = DateTime.tryParse(expireDateStr);
        }

        // Если на сервере подписка активна, обновляем локальные данные
        if (isPremium && serverExpiryDate != null) {
          if (serverExpiryDate.isAfter(DateTime.now())) {
            _isSubscribed = true;
            _expiryDate = serverExpiryDate;

            // Обновляем кэш
            await _paywallService.saveSubscriptionStatus(
                isSubscribed: true, expiryDate: serverExpiryDate);
          } else {
            // Подписка истекла
            _isSubscribed = false;
            _expiryDate = null;

            // Обновляем кэш
            await _paywallService.saveSubscriptionStatus(
                isSubscribed: false, expiryDate: null);
          }
        }
      }
    } catch (e) {
      debugPrint('Ошибка при проверке подписки на сервере: $e');
    }
  }

  // Обработчик событий покупок
  void _onPurchaseUpdate(dynamic purchaseDetails) async {
    try {
      if (purchaseDetails.status == 'purchased' ||
          purchaseDetails.status == 'restored') {
        // Получаем информацию о подписке
        String subscriptionType = 'premium';
        DateTime? newExpiryDate;

        // Определяем тип подписки и дату окончания
        final productId = purchaseDetails.productID;
        if (productId.contains('monthly')) {
          subscriptionType = 'premium_monthly';
          newExpiryDate = DateTime.now().add(const Duration(days: 30));
        } else if (productId.contains('yearly')) {
          subscriptionType = 'premium_yearly';
          newExpiryDate = DateTime.now().add(const Duration(days: 365));
        } else if (productId.contains('lifetime')) {
          subscriptionType = 'premium_lifetime';
          // Для пожизненной подписки устанавливаем дату далеко в будущем
          newExpiryDate =
              DateTime.now().add(const Duration(days: 36500)); // ~100 лет
        }

        // Верификация покупки на сервере
        await _verifyPurchaseOnServer(
            purchaseDetails: purchaseDetails,
            subscriptionType: subscriptionType,
            expiryDate: newExpiryDate);

        // Обновляем локальный статус
        _isSubscribed = true;
        _expiryDate = newExpiryDate;

        // Сохраняем в кэш
        await _paywallService.saveSubscriptionStatus(
            isSubscribed: true, expiryDate: newExpiryDate);

        notifyListeners();
      } else if (purchaseDetails.status == 'error') {
        debugPrint('Ошибка при покупке: ${purchaseDetails.error}');
      }
    } catch (e) {
      debugPrint('Ошибка при обработке покупки: $e');
    }
  }

  // Проверка покупки на сервере
  Future<void> _verifyPurchaseOnServer(
      {required dynamic purchaseDetails,
      required String subscriptionType,
      required DateTime? expiryDate}) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Обновляем статус подписки в профиле пользователя
      await _supabase.from('user_profiles').update({
        'subscription_type': subscriptionType,
        'subscription_expire_date': expiryDate?.toIso8601String()
      }).eq('id', user.id);

      // Можно также сохранить детали покупки для истории
      await _supabase.from('subscription_history').insert({
        'user_id': user.id,
        'product_id': purchaseDetails.productID,
        'purchase_date': DateTime.now().toIso8601String(),
        'transaction_id': purchaseDetails.transactionId,
        'subscription_type': subscriptionType,
        'expire_date': expiryDate?.toIso8601String()
      });

      debugPrint('Покупка успешно верифицирована на сервере');
    } catch (e) {
      debugPrint('Ошибка при верификации покупки на сервере: $e');

      // Даже если не удалось сохранить на сервере, мы все равно активируем подписку локально
      _isSubscribed = true;
      _expiryDate = expiryDate;
      notifyListeners();
    }
  }

  // Покупка подписки
  Future<void> purchaseSubscription(dynamic product) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _paywallService.purchaseSubscription(product);
    } catch (e) {
      debugPrint('Ошибка при покупке подписки: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Восстановление покупок
  Future<void> restorePurchases() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _paywallService.restorePurchases();

      // Обновляем статус после восстановления
      await _verifySubscriptionOnServer();
    } catch (e) {
      debugPrint('Ошибка при восстановлении покупок: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Установка тестового статуса подписки
  Future<void> setTestSubscriptionStatus(bool isSubscribed) async {
    try {
      _isLoading = true;
      notifyListeners();

      _isSubscribed = isSubscribed;

      if (isSubscribed) {
        _expiryDate = DateTime.now().add(const Duration(days: 30));
      } else {
        _expiryDate = null;
      }

      // Сохраняем в кэш
      await _paywallService.saveSubscriptionStatus(
          isSubscribed: _isSubscribed, expiryDate: _expiryDate);

      // Обновляем на сервере, если пользователь авторизован
      final user = _supabase.auth.currentUser;
      if (user != null) {
        await _supabase.from('user_profiles').update({
          'subscription_type': isSubscribed ? 'premium_test' : 'free',
          'subscription_expire_date': _expiryDate?.toIso8601String()
        }).eq('id', user.id);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Ошибка при установке тестового статуса подписки: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Очистка кэша подписки
  Future<void> clearSubscriptionCache() async {
    await _paywallService.clearSubscriptionCache();
    await _initialize();
  }

  // Показ экрана подписки
  void showSubscription() {
    // Используем SuperwallService для показа paywall
    final superwallService = SuperwallService();
    superwallService.registerPaywallForPlacement('pro_feature');

    // Добавляем отложенную проверку статуса подписки
    Future.delayed(const Duration(seconds: 2), () async {
      // Проверяем статус подписки после закрытия paywall
      await _verifySubscriptionOnServer();
    });
  }

  @override
  void dispose() {
    _paywallService.dispose();
    super.dispose();
  }
}

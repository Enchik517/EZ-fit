import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/subscription_provider.dart';
import 'package:superwallkit_flutter/superwallkit_flutter.dart';
import '../services/trial_notification_service.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Премиум доступ'),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Consumer<SubscriptionProvider>(
        builder: (context, subscriptionProvider, child) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (subscriptionProvider.isLoading)
                  const CircularProgressIndicator(color: Colors.white)
                else ...[
                  if (subscriptionProvider.isSubscribed)
                    Column(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 100,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Вы уже подписаны!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 40),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                          ),
                          child: const Text('Закрыть'),
                        ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        Image.asset(
                          'assets/images/premium.png',
                          height: 200,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.fitness_center,
                            color: Colors.white,
                            size: 100,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            'Разблокируйте полный доступ ко всем функциям приложения',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            '• Персональные тренировки\n• Неограниченное количество программ\n• Детальная статистика\n• Без рекламы',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ),
                        const SizedBox(height: 40),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                // Вместо перехода на экран, показываем paywall напрямую
                                try {
                                  final handler = PaywallPresentationHandler();
                                  handler
                                    ..onPresent((info) {
                                      debugPrint('Paywall показан: $info');
                                    })
                                    ..onDismiss((info, result) {
                                      debugPrint(
                                          'Paywall закрыт: $info, результат: $result');
                                    })
                                    ..onError((error) {
                                      debugPrint(
                                          'Ошибка при показе paywall: $error');
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                'Не удалось загрузить подписку')),
                                      );
                                    });

                                  // Показываем paywall напрямую без навигации
                                  Superwall.shared.registerPlacement(
                                      'pro_feature',
                                      handler: handler);
                                } catch (e) {
                                  debugPrint(
                                      'Ошибка при инициализации paywall: $e');
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Ошибка: $e')),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 16,
                                ),
                              ),
                              child: const Text(
                                'Подписаться',
                                style: TextStyle(fontSize: 18),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () {
                            // Установить временный тестовый статус премиум для пропуска экрана
                            subscriptionProvider.setTestPremiumStatus();

                            // Регистрируем начало пробного периода для отслеживания
                            final trialService = TrialNotificationService();
                            trialService.registerTrialStart();

                            // Вернуться к предыдущему экрану
                            Navigator.of(context).pop();

                            // Показать сообщение о временном доступе
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Вы получили временный премиум доступ'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          child: const Text(
                            'Продолжить без подписки',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

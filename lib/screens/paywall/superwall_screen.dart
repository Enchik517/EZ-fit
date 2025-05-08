import 'package:flutter/material.dart';
import 'package:superwallkit_flutter/superwallkit_flutter.dart';
import 'package:provider/provider.dart';
import '../../providers/subscription_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/trial_notification_service.dart';

/// Экран выбора перед показом Superwall paywall
class SuperwallScreen extends StatefulWidget {
  const SuperwallScreen({Key? key}) : super(key: key);

  @override
  State<SuperwallScreen> createState() => _SuperwallScreenState();
}

class _SuperwallScreenState extends State<SuperwallScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Премиум доступ'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pushReplacementNamed('/main'),
        ),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Loading...',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Expanded(
                        child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),

                          // Иконка или изображение
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.blue.shade700,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.star,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),

                          const SizedBox(height: 30),

                          // Заголовок
                          Text(
                            'Расширенный доступ',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 20),

                          // Описание
                          Text(
                            'Откройте для себя полный доступ ко всем функциям приложения и улучшите свой фитнес-опыт',
                            style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: 16,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 40),

                          // Преимущества премиум-доступа
                          _buildFeatureItem(
                            icon: Icons.fitness_center,
                            title: 'Индивидуальные тренировки',
                            description:
                                'Доступ к планам тренировок, адаптированным специально для вас',
                          ),

                          _buildFeatureItem(
                            icon: Icons.insights,
                            title: 'Расширенная аналитика',
                            description:
                                'Детальный анализ ваших тренировок и прогресса',
                          ),

                          _buildFeatureItem(
                            icon: Icons.update,
                            title: 'Регулярные обновления',
                            description:
                                'Новые тренировки и функции каждую неделю',
                          ),

                          const SizedBox(height: 50),
                        ],
                      ),
                    )),

                    // Кнопки внизу экрана
                    Column(
                      children: [
                        // Кнопка "Показать варианты подписки"
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _showPaywall,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Показать варианты подписки',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Кнопка "Try 3 Days for FREE"
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              // Устанавливаем временный премиум статус
                              final subscriptionProvider =
                                  Provider.of<SubscriptionProvider>(context,
                                      listen: false);
                              subscriptionProvider.setTestPremiumStatus();

                              // Регистрируем начало пробного периода для отслеживания
                              final trialService = TrialNotificationService();
                              trialService.registerTrialStart();

                              // Переходим на главный экран
                              Navigator.of(context)
                                  .pushReplacementNamed('/main');

                              // Показываем уведомление
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Бесплатный пробный период активирован'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Try 3 Days for FREE',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Кнопка пропуска
                        TextButton(
                          onPressed: () {
                            // Устанавливаем временный премиум статус
                            final subscriptionProvider =
                                Provider.of<SubscriptionProvider>(context,
                                    listen: false);
                            subscriptionProvider.setTestPremiumStatus();

                            // Переходим на главный экран
                            Navigator.of(context).pushReplacementNamed('/main');

                            // Показываем уведомление
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
                ),
              ),
            ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.shade900,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPaywall() {
    setState(() {
      _isLoading = true;
    });

    try {
      final handler = PaywallPresentationHandler();
      handler
        ..onPresent((info) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        })
        ..onDismiss((info, result) {
          if (mounted) {
            setState(() {
              _isLoading = false; // Убедимся, что флаг загрузки сброшен
            });
            Navigator.of(context).pushReplacementNamed('/main');
          }
        })
        ..onError((error) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Не удалось загрузить информацию о подписке'),
              ),
            );
            // Если произошла ошибка, перенаправляем на главный экран через небольшую задержку
            Future.delayed(Duration(seconds: 2), () {
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/main');
              }
            });
          }
        });

      Superwall.shared.registerPlacement('pro_feature', handler: handler);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
        // В случае ошибки перенаправляем на главный экран
        Future.delayed(Duration(seconds: 2), () {
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/main');
          }
        });
      }
    }
  }

  void _skipPaywall() async {
    try {
      // Сначала устанавливаем статус загрузки
      setState(() {
        _isLoading = true;
      });

      // Получаем провайдер
      final subscriptionProvider =
          Provider.of<SubscriptionProvider>(context, listen: false);

      // Устанавливаем временный премиум-статус
      await subscriptionProvider.setTestPremiumStatus();

      // Убеждаемся, что виджет всё ещё монтирован
      if (!mounted) return;

      // Сбрасываем флаг загрузки
      setState(() {
        _isLoading = false;
      });

      // Переходим на главный экран вместо возврата назад
      Navigator.of(context).pushReplacementNamed('/main');

      // Показываем уведомление через небольшую задержку
      Future.delayed(Duration(milliseconds: 100), () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Вы получили временный премиум доступ'),
            duration: Duration(seconds: 2),
          ),
        );
      });
    } catch (e) {
      //
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }
}

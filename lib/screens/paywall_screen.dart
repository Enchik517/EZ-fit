import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/subscription_provider.dart';

/// Экран для покупки подписки (Paywall)
class PaywallScreen extends StatelessWidget {
  final List<dynamic> products;
  final Function(dynamic) onPurchase;
  final VoidCallback onRestore;

  const PaywallScreen({
    Key? key,
    required this.products,
    required this.onPurchase,
    required this.onRestore,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context);
    final isLoading = subscriptionProvider.isLoading;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton(
            onPressed: isLoading ? null : onRestore,
            child: const Text(
              'Восстановить покупки',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                // Заголовок
                const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Text(
                        'ПРЕМИУМ ДОСТУП',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Разблокируйте все функции приложения',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // Преимущества
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 16.0),
                  margin: const EdgeInsets.symmetric(horizontal: 16.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFeatureItem('Все тренировки без ограничений'),
                      _buildFeatureItem('Персонализированные планы тренировок'),
                      _buildFeatureItem('Отслеживание прогресса'),
                      _buildFeatureItem('Статистика тренировок'),
                      _buildFeatureItem('Отсутствие рекламы'),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Подписки
                if (products.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Загрузка вариантов подписки...',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return _buildSubscriptionOption(product, context);
                    },
                  ),

                // Политика конфиденциальности и условия использования
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const Text(
                        'При оформлении подписки оплата будет списана с вашего аккаунта. Подписка продлевается автоматически, если автопродление не отключено как минимум за 24 часа до окончания текущего периода.',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildFooterButton('Политика конфиденциальности', () {
                            // Открытие политики конфиденциальности
                          }),
                          const SizedBox(width: 16),
                          _buildFooterButton('Условия использования', () {
                            // Открытие условий использования
                          }),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                    height: 100), // Дополнительное пространство внизу
              ],
            ),
          ),

          // Индикатор загрузки
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionOption(dynamic product, BuildContext context) {
    // Определяем, является ли это годовой подпиской
    final bool isYearly = product.id.contains('yearly');
    final bool isLifetime = product.id.contains('lifetime');

    String title = 'Ежемесячная подписка';
    String subtitle = 'Автоматическое продление';
    Color borderColor = Colors.transparent;
    Color backgroundColor = Colors.white.withOpacity(0.1);
    Widget? trailingWidget;

    if (isYearly) {
      title = 'Годовая подписка';
      subtitle = 'Экономия 50%! Автоматическое продление';
      borderColor = Colors.amber;
      backgroundColor = Colors.amber.withOpacity(0.1);
      trailingWidget = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.amber,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'ЛУЧШАЯ ЦЕНА',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
        ),
      );
    } else if (isLifetime) {
      title = 'Пожизненный доступ';
      subtitle = 'Разовый платеж';
      borderColor = Colors.blue;
      backgroundColor = Colors.blue.withOpacity(0.1);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: backgroundColor,
        border: Border.all(
          color: borderColor,
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: () => onPurchase(product),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.price,
                      style: TextStyle(
                        color: isYearly ? Colors.amber : Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailingWidget != null) trailingWidget,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooterButton(String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.blue,
          fontSize: 12,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}

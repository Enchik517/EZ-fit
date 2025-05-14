import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/subscription_provider.dart';

class SubscriptionRequiredWidget extends StatelessWidget {
  final String featureName;
  final String description;
  final Widget? icon;
  final String buttonText;
  final bool showPreview;
  final Widget? previewContent;

  const SubscriptionRequiredWidget({
    Key? key,
    this.featureName = 'Эта функция',
    this.description = 'Для доступа к этой функции требуется премиум подписка',
    this.icon,
    this.buttonText = 'Получить доступ',
    this.showPreview = false,
    this.previewContent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final subscriptionProvider =
        Provider.of<SubscriptionProvider>(context, listen: false);

    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Если есть превью контент, показываем его
            if (showPreview && previewContent != null)
              Container(
                margin: const EdgeInsets.symmetric(
                    vertical: 16.0, horizontal: 16.0),
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Предварительный просмотр',
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    previewContent!,
                  ],
                ),
              ),

            // Основной контент с информацией о необходимости подписки
            Container(
              margin: const EdgeInsets.all(16.0),
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  icon ??
                      const Icon(
                        Icons.lock,
                        color: Colors.amber,
                        size: 64,
                      ),
                  const SizedBox(height: 20),
                  Text(
                    featureName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Преимущества премиум подписки
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Премиум дает доступ к:',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildBenefitItem('Все тренировки без ограничений'),
                        _buildBenefitItem('Персонализированные планы'),
                        _buildBenefitItem('Отслеживание прогресса'),
                        _buildBenefitItem('Расширенная статистика'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Кнопка подписки
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        subscriptionProvider.showSubscription();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 4,
                      ),
                      child: Text(
                        buttonText,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.green.shade300,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

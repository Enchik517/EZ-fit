import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/subscription_provider.dart';

class SubscriptionRequiredWidget extends StatelessWidget {
  final String featureName;
  final String description;
  final Widget? icon;

  const SubscriptionRequiredWidget({
    Key? key,
    this.featureName = 'Эта функция',
    this.description = 'Для доступа к этой функции требуется премиум подписка',
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final subscriptionProvider =
        Provider.of<SubscriptionProvider>(context, listen: false);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon ??
              const Icon(
                Icons.lock,
                color: Colors.white,
                size: 64,
              ),
          const SizedBox(height: 24),
          Text(
            featureName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              description,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              subscriptionProvider.showSubscription();
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
              'Получить подписку',
              style: TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }
}

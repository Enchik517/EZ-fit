import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../providers/subscription_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Пункт меню подписки
          ListTile(
            title: Text(subscriptionProvider.isSubscribed
                ? 'Управление подпиской'
                : 'Премиум доступ'),
            subtitle: Text(subscriptionProvider.isSubscribed
                ? 'Управление вашей подпиской'
                : 'Разблокируйте все функции'),
            leading: Icon(
              Icons.star,
              color: subscriptionProvider.isSubscribed
                  ? Colors.amber
                  : Colors.grey,
            ),
            onTap: () => Navigator.of(context).pushNamed('/subscription'),
          ),
          const Divider(),
          ListTile(
            title: const Text('Delete Account'),
            subtitle: const Text('This action cannot be undone'),
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            onTap: () => _showDeleteAccountDialog(context),
          ),
          ListTile(
            title: const Text('Sign Out'),
            leading: const Icon(Icons.logout),
            onTap: () => _signOut(context),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteAccountDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteAccount(context);
    }
  }

  Future<void> _deleteAccount(BuildContext context) async {
    OverlayEntry? loadingOverlay;
    try {
      // Создаем стильный индикатор загрузки
      loadingOverlay = OverlayEntry(
        builder: (context) => Container(
          color: Colors.black.withOpacity(0.7),
          child: Center(
            child: Container(
              width: 180,
              padding: EdgeInsets.symmetric(vertical: 24, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 1,
                  )
                ],
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.2),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                        strokeWidth: 3,
                        backgroundColor: Colors.grey[800],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Column(
                    children: [
                      Text(
                        'Deleting Account',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Please wait...',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Показываем индикатор загрузки
      Overlay.of(context).insert(loadingOverlay);

      // Удаляем аккаунт
      await Supabase.instance.client.rpc('delete_user_account');

      // Выходим из аккаунта
      await Supabase.instance.client.auth.signOut();

      // Закрываем индикатор загрузки
      if (loadingOverlay != null) {
        loadingOverlay.remove();
      }

      // Navigate to auth screen
      Navigator.of(context).pushReplacementNamed('/auth');
    } catch (e) {
      // Закрываем индикатор загрузки в случае ошибки
      if (loadingOverlay != null) {
        loadingOverlay.remove();
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting account: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      // Создаем стильный индикатор загрузки
      final loadingOverlay = OverlayEntry(
        builder: (context) => Container(
          color: Colors.black.withOpacity(0.7),
          child: Center(
            child: Container(
              width: 180,
              padding: EdgeInsets.symmetric(vertical: 24, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 1,
                  )
                ],
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Анимированный индикатор загрузки
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.2),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                        strokeWidth: 3,
                        backgroundColor: Colors.grey[800],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Column(
                    children: [
                      Text(
                        'Signing Out',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Please wait...',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Показываем индикатор загрузки
      Overlay.of(context).insert(loadingOverlay);

      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signOut();

      // Закрываем индикатор загрузки
      loadingOverlay.remove();

      // Navigate to auth screen
      Navigator.of(context).pushReplacementNamed('/auth');
    } catch (e) {
      _showErrorDialog(context, 'Failed to sign out');
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

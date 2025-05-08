import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../login_screen.dart';
import 'notification_settings_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: ListView(
        children: [
          // Профиль
          ListTile(
            leading: Icon(Icons.person),
            title: Text('Profile Information'),
            subtitle:
                Text(Supabase.instance.client.auth.currentUser?.email ?? ''),
            onTap: () {
              // TODO: Показать информацию профиля
            },
          ),
          Divider(),

          // Смена пароля
          ListTile(
            leading: Icon(Icons.lock),
            title: Text('Change Password'),
            onTap: () => _showChangePasswordDialog(context),
          ),
          Divider(),

          // Настройки уведомлений
          ListTile(
            leading: Icon(Icons.notifications),
            title: Text('Notification Settings'),
            onTap: () => _showNotificationSettings(context),
          ),
          Divider(),

          // Кнопка выхода
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Sign Out'),
            onTap: () => _signOut(context),
          ),
          Divider(),

          // Удаление аккаунта
          ListTile(
            leading: Icon(Icons.delete_forever, color: Colors.red),
            title: Text('Delete Account', style: TextStyle(color: Colors.red)),
            onTap: () => _showDeleteAccountDialog(context),
          ),
        ],
      ),
    );
  }

  Future<void> _showChangePasswordDialog(BuildContext context) {
    final TextEditingController currentPasswordController =
        TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController =
        TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              decoration: InputDecoration(labelText: 'Current Password'),
              obscureText: true,
            ),
            TextField(
              controller: newPasswordController,
              decoration: InputDecoration(labelText: 'New Password'),
              obscureText: true,
            ),
            TextField(
              controller: confirmPasswordController,
              decoration: InputDecoration(labelText: 'Confirm New Password'),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newPasswordController.text !=
                  confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Passwords do not match')),
                );
                return;
              }

              try {
                await Supabase.instance.client.auth.updateUser(
                  UserAttributes(password: newPasswordController.text),
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Password updated successfully')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error updating password: $e')),
                );
              }
            },
            child: Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showNotificationSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationSettingsScreen(),
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      // Создаем красивый индикатор загрузки
      final loadingOverlay = OverlayEntry(
        builder: (context) => Container(
          color: Colors.black.withOpacity(0.8),
          child: Center(
            child: Container(
              width: 200,
              padding: EdgeInsets.symmetric(vertical: 30, horizontal: 26),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1E1E1E),
                    Color(0xFF252525),
                    Color(0xFF2C2C2C),
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 24,
                    spreadRadius: 2,
                    offset: Offset(0, 4),
                  )
                ],
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Анимированный индикатор загрузки
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Внешний круг
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.black.withOpacity(0.2),
                              Colors.black.withOpacity(0.05),
                            ],
                          ),
                        ),
                      ),
                      // Иконка внутри
                      Icon(
                        Icons.logout_rounded,
                        color: Colors.white.withOpacity(0.3),
                        size: 30,
                      ),
                      // Круговой индикатор загрузки
                      SizedBox(
                        width: 70,
                        height: 70,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.primary,
                          ),
                          strokeWidth: 3,
                          backgroundColor: Colors.grey[850],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  // Текстовая информация
                  Column(
                    children: [
                      Text(
                        'Signing Out',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Please wait...',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.2,
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

      await Supabase.instance.client.auth.signOut();

      // Закрываем индикатор загрузки
      loadingOverlay.remove();

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
    }
  }

  Future<void> _showDeleteAccountDialog(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Account'),
        content: Text(
          'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              OverlayEntry? loadingOverlay;
              try {
                // Создаем стильный индикатор загрузки
                loadingOverlay = OverlayEntry(
                  builder: (context) => Container(
                    color: Colors.black.withOpacity(0.7),
                    child: Center(
                      child: Container(
                        width: 180,
                        padding:
                            EdgeInsets.symmetric(vertical: 24, horizontal: 24),
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
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.2),
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

                // Используем AuthProvider для удаления аккаунта
                final authProvider =
                    Provider.of<AuthProvider>(context, listen: false);
                await authProvider.deleteAccount();

                // Закрываем индикатор загрузки
                if (loadingOverlay != null) {
                  loadingOverlay.remove();
                }

                // Navigate to auth screen
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                  (route) => false,
                );
              } catch (e) {
                // Закрываем индикатор загрузки в случае ошибки
                if (loadingOverlay != null) {
                  loadingOverlay.remove();
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting account: $e')),
                );
              }
            },
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }
}

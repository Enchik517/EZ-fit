import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // Добавьте эту зависимость в pubspec.yaml
import 'goals_flow_screen.dart'; // Импорт экрана опросника для новых пользователей
import 'onboarding/onboarding_screen.dart'; // Импорт экрана онбординга
import '../main.dart' show FirstRunFlag; // Импорт FirstRunFlag из main.dart
import 'disclaimer_screen.dart'; // Импорт экрана дисклеймера

class NewAuthScreen extends StatefulWidget {
  const NewAuthScreen({Key? key}) : super(key: key);

  @override
  State<NewAuthScreen> createState() => _NewAuthScreenState();
}

class _NewAuthScreenState extends State<NewAuthScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _heartController;
  late Animation<double> _heartRotation;

  @override
  void initState() {
    super.initState();
    _heartController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _heartRotation = Tween<double>(begin: 0, end: 0.1).animate(
        CurvedAnimation(parent: _heartController, curve: Curves.easeInOut))
      ..addListener(() {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _heartController.dispose();
    super.dispose();
  }

  Future<void> _continueWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      // Вызываем метод для входа через Google
      await authProvider.signInWithGoogle();

      if (!mounted) return;

      // Обязательно проверяем актуальное значение hasCompletedSurvey из базы
      final hasCompletedSurvey =
          await authProvider.forceCheckSurveyCompletionInDatabase();

      debugPrint(
          'Google Sign In - Принудительная проверка из базы hasCompletedSurvey: $hasCompletedSurvey');

      // Проверяем, нужно ли показать опросник для нового пользователя
      if (!hasCompletedSurvey) {
        debugPrint(
            'Showing GoalsFlowScreen for Google user (hasCompletedSurvey=false)');
        // Показываем опросник для сбора данных о пользователе
        await _showSurvey();
      } else {
        debugPrint('User profile is complete, going to main screen');
        // Переходим на главный экран
        Navigator.pushReplacementNamed(context, '/main');
      }
    } catch (e) {
      print('Error signing in with Google: $e');
      if (mounted) {
        // Проверяем, была ли это отмена аутентификации пользователем
        if (e.toString().contains('canceled') ||
            e.toString().contains('cancelled') ||
            e.toString().contains('cancel') ||
            e.toString().contains('auth_cancelled')) {
          // Если вход был отменен, мы НЕ перенаправляем пользователя дальше
          // Просто показываем сообщение и оставляем на экране входа
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child:
                        Icon(Icons.info_outline, color: Colors.white, size: 20),
                  ),
                  SizedBox(width: 16),
                  Text(
                    'Вход через Google был отменён',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.black.withOpacity(0.9),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              margin: EdgeInsets.all(16),
              duration: Duration(seconds: 3),
              elevation: 8,
              animation: CurvedAnimation(
                parent: const AlwaysStoppedAnimation(1),
                curve: Curves.easeOutCirc,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.error_outline,
                        color: Colors.white, size: 20),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Не удалось войти через Google',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.red.shade900,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              margin: EdgeInsets.all(16),
              elevation: 8,
              animation: CurvedAnimation(
                parent: const AlwaysStoppedAnimation(1),
                curve: Curves.easeOutCirc,
              ),
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _continueWithApple() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      // Используем метод авторизации через Apple
      await authProvider.signInWithApple();

      if (!mounted) return;

      // Обязательно проверяем актуальное значение hasCompletedSurvey из базы
      final hasCompletedSurvey =
          await authProvider.forceCheckSurveyCompletionInDatabase();

      debugPrint(
          'Apple Sign In - Принудительная проверка из базы hasCompletedSurvey: $hasCompletedSurvey');

      // Проверяем, нужно ли показать опросник для нового пользователя
      if (!hasCompletedSurvey) {
        debugPrint(
            'Showing GoalsFlowScreen for Apple user (hasCompletedSurvey=false)');
        // Показываем опросник для сбора данных о пользователе
        await _showSurvey();
      } else {
        debugPrint('User profile is complete, going to main screen');
        // Переходим на главный экран
        Navigator.pushReplacementNamed(context, '/main');
      }
    } catch (e) {
      print('Error signing in with Apple: $e');
      if (mounted) {
        // Проверяем, была ли это отмена аутентификации пользователем
        if (e.toString().contains('canceled') ||
            e.toString().contains('cancelled') ||
            e.toString().contains('cancel') ||
            e.toString().contains('auth_cancelled')) {
          // Если вход был отменен, мы НЕ перенаправляем пользователя дальше
          // Просто показываем сообщение и оставляем на экране входа
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child:
                        Icon(Icons.info_outline, color: Colors.white, size: 20),
                  ),
                  SizedBox(width: 16),
                  Text(
                    'Вход через Apple был отменён',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.black.withOpacity(0.9),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              margin: EdgeInsets.all(16),
              duration: Duration(seconds: 3),
              elevation: 8,
              animation: CurvedAnimation(
                parent: const AlwaysStoppedAnimation(1),
                curve: Curves.easeOutCirc,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.error_outline,
                        color: Colors.white, size: 20),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Не удалось войти через Apple',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.red.shade900,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              margin: EdgeInsets.all(16),
              elevation: 8,
              animation: CurvedAnimation(
                parent: const AlwaysStoppedAnimation(1),
                curve: Curves.easeOutCirc,
              ),
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Метод для показа опросника
  Future<void> _showSurvey() async {
    if (!mounted) return;

    debugPrint('_showSurvey: Начинаем показ экранов ввода данных');

    // Проверяем, принят ли дисклеймер
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    debugPrint(
        '_showSurvey: Статус дисклеймера hasAcceptedDisclaimer = ${authProvider.hasAcceptedDisclaimer}');

    if (!authProvider.hasAcceptedDisclaimer) {
      debugPrint('_showSurvey: Показываем сначала экран дисклеймера');
      // Сначала показываем экран дисклеймера
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => DisclaimerScreen(
            onAccept: () {
              debugPrint(
                  '_showSurvey: Дисклеймер принят, переходим на экран опроса');
              // После принятия сразу переходим на экран опроса
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                    builder: (context) => const GoalsFlowScreen()),
              );
            },
          ),
        ),
      );
    } else {
      debugPrint(
          '_showSurvey: Дисклеймер уже принят, сразу показываем экран опроса');
      // Если дисклеймер уже принят, сразу показываем экран опроса
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const GoalsFlowScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 1),
              // Вращающееся сердце
              Transform.rotate(
                angle: _heartRotation.value,
                child: const Icon(
                  Icons.favorite,
                  color: Colors.white,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              // Заголовок
              const Text(
                'the body that\nyou always wanted',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              // Подзаголовок
              Text(
                'with personal AI that understands your goals and creates workouts just for you',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
              const Spacer(flex: 2),
              // Кнопки авторизации
              _buildAuthButton(
                icon: FontAwesomeIcons.apple,
                text: 'Sign in with Apple',
                onPressed: _isLoading ? null : _continueWithApple,
                backgroundColor: Colors.white,
                textColor: Colors.black,
              ),
              const SizedBox(height: 12),
              _buildAuthButton(
                icon: FontAwesomeIcons.google,
                text: 'Sign in with Google',
                onPressed: _isLoading ? null : _continueWithGoogle,
                backgroundColor: Color(0xFFFEF9C3),
                textColor: Colors.black,
              ),
              const Spacer(flex: 1),
              // Условия использования
              Center(
                child: Text.rich(
                  TextSpan(
                    text: 'By continuing, you agree to our ',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    ),
                    children: [
                      TextSpan(
                        text: 'Terms of Service',
                        style: TextStyle(
                          color: Colors.white,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      TextSpan(text: ' and '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: TextStyle(
                          color: Colors.white,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuthButton({
    required IconData icon,
    required String text,
    required VoidCallback? onPressed,
    required Color backgroundColor,
    required Color textColor,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
          padding: EdgeInsets.zero,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/custom_text_field.dart';
import '../providers/auth_provider.dart';
import '../screens/disclaimer_screen.dart';
import '../screens/basics_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/goals_flow_screen.dart';
import 'package:provider/provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isLogin = true; // true для входа, false для регистрации
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _isLogin = true;
  }

  // Метод для входа через Google
  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.signInWithGoogle();

      if (!mounted) return;

      // Добавляем отладочные сообщения
      // debugPrint('Google Sign In completed. isNewUser: ${authProvider.isNewUser}');
      // debugPrint('Has completed survey: ${authProvider.userProfile?.hasCompletedSurvey}');

      // Проверяем, нужно ли показать опрос (новый пользователь)
      // ИСПРАВЛЕНО: Теперь используем прямую проверку hasCompletedSurvey для большей надежности
      if (authProvider.userProfile != null &&
          !authProvider.userProfile!.hasCompletedSurvey) {
        //        // Показываем опрос для сбора данных о пользователе
        await _showSurvey();
      } else {
        //        // Переходим на главный экран
        Navigator.pushReplacementNamed(context, '/main');
      }
    } catch (e) {
      //      if (!mounted) return;

      // Проверяем, была ли это отмена аутентификации пользователем
      if (e.toString().contains('canceled') ||
          e.toString().contains('cancelled') ||
          e.toString().contains('cancel')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white),
                SizedBox(width: 10),
                Text('Вход через Google был отменён'),
              ],
            ),
            backgroundColor: Colors.blue.shade800,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: EdgeInsets.all(10),
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 10),
                Expanded(child: Text('Не удалось войти через Google')),
              ],
            ),
            backgroundColor: Colors.red.shade800,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: EdgeInsets.all(10),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Метод для входа через Apple
  Future<void> _signInWithApple() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.signInWithApple();

      if (!mounted) return;

      // Добавляем отладочные сообщения
      // debugPrint('Apple Sign In completed. isNewUser: ${authProvider.isNewUser}');
      // debugPrint('Has completed survey: ${authProvider.userProfile?.hasCompletedSurvey}');

      // Проверяем, нужно ли показать опрос (новый пользователь)
      // ИСПРАВЛЕНО: Теперь используем прямую проверку hasCompletedSurvey для большей надежности
      if (authProvider.userProfile != null &&
          !authProvider.userProfile!.hasCompletedSurvey) {
        //        // Показываем опрос для сбора данных о пользователе
        await _showSurvey();
      } else {
        //        // Переходим на главный экран
        Navigator.pushReplacementNamed(context, '/main');
      }
    } catch (e) {
      //      if (!mounted) return;

      // Проверяем, была ли это отмена аутентификации пользователем
      if (e.toString().contains('canceled') ||
          e.toString().contains('cancelled') ||
          e.toString().contains('cancel')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white),
                SizedBox(width: 10),
                Text('Вход через Apple был отменён'),
              ],
            ),
            backgroundColor: Colors.blue.shade800,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: EdgeInsets.all(10),
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 10),
                Expanded(child: Text('Не удалось войти через Apple')),
              ],
            ),
            backgroundColor: Colors.red.shade800,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: EdgeInsets.all(10),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Метод для показа опроса
  Future<void> _showSurvey() async {
    // Перенаправляем пользователя на экран опроса
    final result = await Navigator.push(
        context, MaterialPageRoute(builder: (context) => GoalsFlowScreen()));

    if (result != null && mounted) {
      // После завершения опроса, обновляем профиль пользователя
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.userProfile != null) {
        // Обновляем базовые данные из результата опроса
        final Map<String, dynamic> userData = result as Map<String, dynamic>;

        final updatedProfile = authProvider.userProfile!.copyWith(
          // Обновляем обязательный флаг завершения опроса
          hasCompletedSurvey: true,

          // Обновляем основные данные из результата опроса
          gender: userData['gender'] as String?,
          birthDate: userData['birthDate'] as DateTime? ??
              authProvider.userProfile!.birthDate,
          height: userData['height'] as double?,
          weight: userData['weight'] as double?,
          fitnessLevel: userData['bodyFatLevel'] as String?,
          goals: userData['selectedGoals'] != null
              ? List<String>.from(userData['selectedGoals'] as List)
              : authProvider.userProfile!.goals,
          weeklyWorkouts: userData['workoutFrequency'] != null
              ? userData['workoutFrequency'].toString()
              : authProvider.userProfile!.weeklyWorkouts,
        );

        await authProvider.saveUserProfile(updatedProfile);
      }

      // Переходим на главный экран
      Navigator.pushReplacementNamed(context, '/main');
    }
  }

  // Вынесем обработчик регистрации в отдельный метод для лучшей читаемости
  Future<void> _doSignUp() async {
    //
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Используем OAuth вместо Email регистрации
    bool success = await authProvider.signInWithGoogle();
    if (!success) {
      success = await authProvider.signInWithApple();
    }

    //
    if (!mounted) {
      //      return;
    }

    // Проверяем текущего пользователя
    if (authProvider.user != null) {
      // Navigator.pushReplacement(
      //   context,
      //   MaterialPageRoute(builder: (context) => const GoalsFlowScreen())
      // );
    }
  }

  // Вынесем обработчик входа в отдельный метод для лучшей читаемости
  Future<void> _doLogin() async {
    //
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Логин через OAuth вместо Email
    bool success = await authProvider.signInWithGoogle();
    if (!success) {
      success = await authProvider.signInWithApple();
    }

    if (!mounted) return;

    // После успешного входа проверяем состояние профиля
    final profile = authProvider.userProfile;
    if (profile != null && profile.hasCompletedSurvey) {
      // Если профиль полностью заполнен, переходим на главный экран
      Navigator.pushReplacementNamed(context, '/main');
    } else if (profile != null) {
      // Если есть профиль, но не заполнен опрос
      if (!authProvider.hasAcceptedDisclaimer) {
        // Если не принято соглашение, показываем его
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DisclaimerScreen()),
        );
      } else {
        // Если соглашение принято, но опрос не заполнен - показываем опросник, а не онбординг
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const GoalsFlowScreen()),
        );
      }
    } else {
      // Если нет профиля
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DisclaimerScreen()),
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    //
    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        await _doLogin();
      } else {
        await _doSignUp();
      }
    } catch (e) {
      //      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString().contains('Too many attempts')
            ? 'Please wait, retrying registration...'
            : e.toString();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage ?? 'An error occurred')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: Colors.black,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: _buildAuthForm(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAuthForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _isLogin ? 'Welcome Back!' : 'Create Account',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 48),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                _errorMessage!,
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          CustomTextField(
            controller: _emailController,
            hintText: 'Email',
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!value.contains('@')) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          SizedBox(height: 16),
          CustomTextField(
            controller: _passwordController,
            hintText: 'Password',
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          SizedBox(height: 24),
          // Здесь используем разные тексты для кнопки в зависимости от режима
          ElevatedButton(
            onPressed: _isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isLoading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                    ),
                  )
                : Text(
                    _isLogin ? 'Login' : 'Sign Up',
                    style: TextStyle(fontSize: 16),
                  ),
          ),
          SizedBox(height: 16),
          // Здесь упрощаем переключение режима
          TextButton(
            onPressed: _isLoading
                ? null
                : () {
                    // print('Switching mode. Current mode is login: $_isLogin');
                    setState(() {
                      _isLogin = !_isLogin;
                      _errorMessage =
                          null; // Сбрасываем ошибку при переключении режима
                    });
                  },
            child: Text(
              _isLogin
                  ? 'Don\'t have an account? Sign Up'
                  : 'Already have an account? Login',
              style: TextStyle(color: Colors.white),
            ),
          ),
          SizedBox(height: 24),

          // Разделитель
          Row(
            children: [
              Expanded(child: Divider(color: Colors.white.withOpacity(0.3))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'OR',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 14,
                  ),
                ),
              ),
              Expanded(child: Divider(color: Colors.white.withOpacity(0.3))),
            ],
          ),

          SizedBox(height: 24),

          // Кнопка входа через Google
          OutlinedButton(
            onPressed: _isLoading ? null : _signInWithGoogle,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.white),
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/icons/google_logo.png',
                  width: 20,
                  height: 20,
                ),
                SizedBox(width: 12),
                Text(
                  'Continue with Google',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16),

          // Кнопка входа через Apple
          OutlinedButton(
            onPressed: _isLoading ? null : _signInWithApple,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.white),
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.apple,
                  color: Colors.white,
                  size: 24,
                ),
                SizedBox(width: 12),
                Text(
                  'Continue with Apple',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'registration_screen.dart';
import 'main_navigation_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'onboarding/onboarding_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/auth_provider.dart';
import 'goals_flow_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  final _authService = AuthService();
  late AnimationController _heartController;

  // Добавляем тестовые креды для разработки
  final devEmail = 'test@dev.com';
  final devPassword = 'test123';

  @override
  void initState() {
    super.initState();
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );
    _startHeartAnimation();
  }

  void _startHeartAnimation() {
    _heartController.forward(from: 0);
    _heartController.repeat();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _heartController.dispose();
    super.dispose();
  }

  Future<bool> _checkSurveyCompletion(String? userId) async {
    if (userId == null) return false;
    try {
      final response = await Supabase.instance.client
          .from('user_surveys')
          .select()
          .eq('user_id', userId)
          .single();
      return response != null;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A0B0B),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A0B0B),
              Color(0xFF1A0B0B).withRed(30),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Анимированное сердце
                RotationTransition(
                  turns: _heartController,
                  child: Text(
                    '❤️',
                    style: TextStyle(fontSize: 64),
                  ),
                ),
                SizedBox(height: 32),

                // Заголовок
                Text(
                  'the body that you\nalways wanted',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12),

                // Подзаголовок
                Text(
                  'with personal AI that understands your goals\nand creates workouts just for you',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[300],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 48),

                // Кнопки
                _buildAuthButton(
                  icon: FontAwesomeIcons.apple,
                  text: 'Continue with Apple',
                  onPressed: () {
                    // TODO: Implement Apple auth
                  },
                ),
                SizedBox(height: 16),

                _buildAuthButton(
                  icon: FontAwesomeIcons.google,
                  text: 'Continue with Google',
                  onPressed: () {
                    // TODO: Implement Google auth
                  },
                ),
                SizedBox(height: 16),

                SizedBox(height: 24),

                // Terms & Privacy
                Text.rich(
                  TextSpan(
                    text: 'By continuing, you agree to our ',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                    children: [
                      TextSpan(
                        text: 'Terms of Service',
                        style: TextStyle(
                          decoration: TextDecoration.underline,
                          color: Colors.grey[400],
                        ),
                      ),
                      TextSpan(text: ' and '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: TextStyle(
                          decoration: TextDecoration.underline,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAuthButton({
    required IconData icon,
    required String text,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            SizedBox(width: 12),
            Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

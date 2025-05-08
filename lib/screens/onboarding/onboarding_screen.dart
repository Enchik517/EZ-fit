import 'package:flutter/material.dart';
import '../login_screen.dart';
import '../disclaimer_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/subscription_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/trial_notification_service.dart';

class OnboardingPage {
  final String imagePath;
  final String title;
  final String subtitle;
  final String description;
  final bool hasCircle;

  OnboardingPage({
    required this.imagePath,
    required this.title,
    this.subtitle = '',
    this.description = '',
    this.hasCircle = true,
  });
}

class OnboardingScreen extends StatefulWidget {
  final bool isFromProfile;
  final VoidCallback? onComplete;

  const OnboardingScreen({
    Key? key,
    this.isFromProfile = false,
    this.onComplete,
  }) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      imagePath: 'assets/animations/Rocket.webp',
      title: 'meet your new',
      subtitle: 'personal trainer',
      hasCircle: false,
    ),
    OnboardingPage(
      imagePath: 'assets/animations/Brain.png',
      title: 'smart workouts',
      description:
          'EZ-fit offers new approach to fitness where you are in control. No need to struggle with planning and understanding workouts anymore.',
      hasCircle: false,
    ),
    OnboardingPage(
      imagePath: 'assets/animations/StarStruck.webp',
      title: 'whatever you want',
      description:
          'Let our AI design your workout in seconds based on whatever you want to do and how you feel — taking into account your history, weights, and exercises.',
      hasCircle: false,
    ),
    OnboardingPage(
      imagePath: 'assets/animations/Clock.webp',
      title: 'any time or place',
      description:
          'Traveling? New Gym? No Equipment? Want to workout at home? We got you. EZ-fit can create 10,000+ unique workouts tailored to your situation.',
      hasCircle: false,
    ),
    OnboardingPage(
      imagePath: 'assets/animations/HandWithIndexFingerAndThumbCrossed.webp',
      title: 'simple at its core',
      description:
          'We know how stressful, dull, and frustrating working out can be. EZ-fit is designed to keep this simple, and let you just do the work and see the results.',
      hasCircle: false,
    ),
    OnboardingPage(
      imagePath: 'assets/animations/Fire.webp',
      title: 'built for progress',
      description:
          'Leave us all the boring stuff… let our AI plan your sets, weights, and workouts based on your profile and progress (and 100+ scientific resources in its arsenal).',
      hasCircle: false,
    ),
    OnboardingPage(
      imagePath: 'assets/animations/LockedWithKey.webp',
      title: 'private at heart',
      description: 'We DO NOT and will NEVER sell your data.',
      hasCircle: false,
    ),
  ];

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
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (page) => setState(() => _currentPage = page),
                  itemBuilder: (context, index) => _buildPage(_pages[index]),
                ),
              ),
              _buildNavigation(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 80),
          _buildEmoji(page.imagePath, page.hasCircle),
          SizedBox(height: 60),
          if (page.subtitle.isEmpty) ...[
            Text(
              page.title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ] else ...[
            Text(
              page.title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w300,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              page.subtitle,
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (page.description.isNotEmpty) ...[
            SizedBox(height: 16),
            Text(
              page.description,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmoji(String imagePath, bool hasCircle) {
    final emojiWidget = Image.asset(
      imagePath,
      width: 120,
      height: 120,
      fit: BoxFit.contain,
    );

    if (!hasCircle) return emojiWidget;

    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: Center(child: emojiWidget),
    );
  }

  Widget _buildNavigation() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: 2,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: (_currentPage + 1) / _pages.length,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_currentPage > 0)
                TextButton(
                  onPressed: () => _pageController.previousPage(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  ),
                  child: Text(
                    'Back',
                    style: TextStyle(color: Colors.white),
                  ),
                )
              else
                SizedBox(width: 80),
              TextButton(
                onPressed: () {
                  if (_currentPage < _pages.length - 1) {
                    _pageController.nextPage(
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  } else {
                    _finishOnboarding();
                  }
                },
                child: Text(
                  _currentPage < _pages.length - 1
                      ? 'Next: Goals'
                      : 'Get Started',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _finishOnboarding() async {
    // Отменяем запланированное уведомление о незавершенном онбординге
    try {
      final trialService = TrialNotificationService();
      await trialService.cancelOnboardingReminder();
    } catch (e) {
      debugPrint('Ошибка при отмене уведомления об онбординге: $e');
    }

    // При первом запуске не обновляем профиль, т.к. пользователь ещё не авторизован
    // Просто вызываем callback, который будет перенаправлять на экран авторизации
    if (widget.onComplete != null) {
      widget.onComplete!();
      return;
    }

    // Этот код выполняется, когда онбординг запускается после авторизации
    // (старая логика, которая теперь будет использоваться только в особых случаях)
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.userProfile != null) {
      final updatedProfile = authProvider.userProfile!.copyWith(
        hasCompletedSurvey: true,
      );
      await authProvider.saveUserProfile(updatedProfile);

      // Проверяем, новый ли это пользователь
      final now = DateTime.now();
      final createdAt = authProvider.user?.createdAt;

      // Если пользователь создан недавно (менее 1 часа назад), показываем экран подписки
      if (createdAt != null) {
        final creationTime = DateTime.parse(createdAt);
        final difference = now.difference(creationTime);

        if (difference.inHours < 1) {
          // Новый пользователь, показываем paywall
          // final subscriptionProvider =
          //     Provider.of<SubscriptionProvider>(context, listen: false);
          // subscriptionProvider.showSubscription();
          // return;
        }
      }
    }

    // Перенаправляем на главный экран
    Navigator.of(context).pushReplacementNamed('/main');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

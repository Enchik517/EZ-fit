import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'auth_screen.dart';
import 'main_navigation_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  bool _isLastPage = false;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'meet your new',
      subtitle: 'personal trainer',
      image: 'assets/animations/Rocket.webp',
      backgroundColor: Colors.black,
    ),
    OnboardingPage(
      title: 'AI-Powered',
      subtitle: 'Workouts',
      image: 'assets/images/onboarding/ai.png',
      backgroundColor: Colors.black,
    ),
    OnboardingPage(
      title: 'Track Your',
      subtitle: 'Progress',
      image: 'assets/animations/StarStruck.webp',
      backgroundColor: Colors.black,
    ),
  ];

  void _finishOnboarding(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => MainNavigationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // PageView
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (index) {
              setState(() {
                _isLastPage = index == _pages.length - 1;
              });
            },
            itemBuilder: (context, index) => OnboardingPageWidget(page: _pages[index]),
          ),

          // Bottom navigation
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  // Page indicator
                  Center(
                    child: SmoothPageIndicator(
                      controller: _pageController,
                      count: _pages.length,
                      effect: WormEffect(
                        dotHeight: 8,
                        dotWidth: 8,
                        spacing: 8,
                        dotColor: Colors.grey[800]!,
                        activeDotColor: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: 32),
                  // Navigation buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Skip button
                      TextButton(
                        onPressed: () => _finishOnboarding(context),
                        child: Text(
                          'Skip',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ),
                      // Next/Start button
                      ElevatedButton(
                        onPressed: () {
                          if (_isLastPage) {
                            _finishOnboarding(context);
                          } else {
                            _pageController.nextPage(
                              duration: Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          _isLastPage ? 'Start' : 'Next',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String subtitle;
  final String image;
  final Color backgroundColor;

  OnboardingPage({
    required this.title,
    required this.subtitle,
    required this.image,
    required this.backgroundColor,
  });
}

class OnboardingPageWidget extends StatelessWidget {
  final OnboardingPage page;

  const OnboardingPageWidget({
    Key? key,
    required this.page,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: page.backgroundColor,
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            page.image,
            height: 200,
          ),
          SizedBox(height: 48),
          Text(
            page.title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w300,
            ),
          ),
          SizedBox(height: 8),
          Text(
            page.subtitle,
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
} 
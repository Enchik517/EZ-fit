import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/survey_provider.dart';
import 'widgets/sex_page.dart';
import 'widgets/birth_date_page.dart';
import 'widgets/height_page.dart';
import 'widgets/weight_page.dart';
import 'widgets/body_fat_page.dart';
import 'widgets/workout_frequency_page.dart';
import 'widgets/main_goal_page.dart';
import 'widgets/target_weight_page.dart';
import 'widgets/target_body_page.dart';
import 'widgets/injuries_page.dart';
import 'widgets/focus_page.dart';
import 'widgets/plan_generation_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GoalsScreen extends StatefulWidget {
  @override
  _GoalsScreenState createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 12;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1C),
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar
            LinearProgressIndicator(
              value: (_currentPage + 1) / _totalPages,
              backgroundColor: Colors.grey[800],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            
            // Main content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: NeverScrollableScrollPhysics(),
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  SexPage(onNext: _nextPage),
                  BirthDatePage(onNext: _nextPage),
                  HeightPage(onNext: _nextPage),
                  WeightPage(onNext: _nextPage),
                  BodyFatPage(onNext: _nextPage),
                  WorkoutFrequencyPage(onNext: _nextPage),
                  MainGoalPage(onNext: _nextPage),
                  TargetWeightPage(onNext: _nextPage),
                  TargetBodyPage(onNext: _nextPage),
                  InjuriesPage(onNext: _nextPage),
                  FocusPage(onNext: _nextPage),
                  PlanGenerationPage(onNext: _onComplete),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onComplete() async {
    final provider = context.read<SurveyProvider>();
    final auth = Supabase.instance.client.auth;
    
    try {
      // Сначала сохраняем данные
      await provider.saveSurveyData();
      
      // Сразу переходим в основное приложение
      Navigator.pushNamedAndRemoveUntil(
        context, 
        '/main',
        (route) => false, // Удаляем все предыдущие экраны из стека
      );
    } catch (e) {
      if (e.toString().contains('not authenticated')) {
        // Если ошибка аутентификации - сохраняем данные временно
        final tempSurveyData = provider.data;
        final tempState = provider.state;
        
        // Переходим на экран логина
        await Navigator.pushNamed(context, '/login');
        
        // После возврата с экрана логина проверяем авторизацию
        if (auth.currentUser != null) {
          // Восстанавливаем данные
          provider.updateState(tempState);
          
          // Пробуем сохранить снова
          await provider.saveSurveyData();
          
          // Переходим в основное приложение
          Navigator.pushNamedAndRemoveUntil(
            context, 
            '/main',
            (route) => false,
          );
        }
      } else {
        // Если другая ошибка - показываем сообщение
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
} 
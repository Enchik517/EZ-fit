import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_profile.dart';
import 'main_navigation_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BasicsScreen extends StatefulWidget {
  const BasicsScreen({super.key});

  @override
  State<BasicsScreen> createState() => _BasicsScreenState();
}

class _BasicsScreenState extends State<BasicsScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _syncWithHealth = false;
  String _selectedGender = 'male';
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  bool _isSaving = false;
  bool _isHeightMetric = true;
  bool _isWeightMetric = true;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!await authProvider.checkAuth()) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/auth');
      }
    }
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  String _getHeightUnit() => _isHeightMetric ? 'cm' : 'ft';
  String _getWeightUnit() => _isWeightMetric ? 'kg' : 'lbs';

  double _convertHeight(String value) {
    if (_isHeightMetric) return double.parse(value);
    // Convert feet to cm
    return double.parse(value) * 30.48;
  }

  double _convertWeight(String value) {
    if (_isWeightMetric) return double.parse(value);
    // Convert lbs to kg
    return double.parse(value) * 0.453592;
  }

  Future<void> _saveAndProceed() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Проверяем авторизацию перед сохранением
      if (!await authProvider.checkAuth()) {
        throw Exception('Please log in to continue');
      }

      final userId = authProvider.user!.id;
      final email = authProvider.user!.email;
      final username = email?.split('@')[0];

      // Получаем текущий профиль (который мог быть создан автоматически)
      final currentProfile = authProvider.userProfile;

      // Создаем обновленный профиль с заполненными базовыми данными
      final profile = UserProfile(
        id: userId,
        username: username,
        email: email,
        name: username,
        fullName: username ?? 'User',
        birthDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
        gender: _selectedGender,
        height: _convertHeight(_heightController.text),
        weight: _convertWeight(_weightController.text),
        fitnessLevel: 'beginner',
        weeklyWorkouts: '3-4',
        workoutDuration: '30-45',
        goals: ['general fitness'],
        equipment: ['none'],
        hasCompletedSurvey: true,
        createdAt: currentProfile?.createdAt,
        updatedAt: DateTime.now(),
      );

      await authProvider.saveUserProfile(profile);

      // Принудительно обновляем флаг в метаданных
      await authProvider.updateSurveyCompletionFlag(true);

      // Принудительно обновляем в базе данных
      await Supabase.instance.client
          .from('user_profiles')
          .update({'has_completed_survey': true}).eq('id', userId);

      if (mounted) {
        // Переходим сразу на главный экран вместо онбординга
        Navigator.pushReplacementNamed(context, '/main');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Basics',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 1,
                    color: Colors.grey[800],
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSection(
                        title: 'What is your sex?',
                        child: Column(
                          children: [
                            _buildOptionButton(
                              text: 'Female',
                              isSelected: _selectedGender == 'female',
                              onTap: () {
                                setState(() {
                                  _selectedGender = 'female';
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                            _buildOptionButton(
                              text: 'Male',
                              isSelected: _selectedGender == 'male',
                              onTap: () {
                                setState(() {
                                  _selectedGender = 'male';
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      _buildSection(
                        title: 'Your height',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _heightController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      hintText: 'Enter your height',
                                      suffixText: _getHeightUnit(),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your height';
                                      }
                                      final height = _convertHeight(value);
                                      if (height < 100 || height > 250) {
                                        return 'Enter valid height (100-250 cm)';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[900],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      _buildHeightUnitToggle('cm', true),
                                      _buildHeightUnitToggle('ft', false),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      _buildSection(
                        title: 'Your weight',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _weightController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      hintText: 'Enter your weight',
                                      suffixText: _getWeightUnit(),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your weight';
                                      }
                                      final weight = _convertWeight(value);
                                      if (weight < 30 || weight > 300) {
                                        return 'Enter valid weight (30-300 kg)';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[900],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      _buildWeightUnitToggle('kg', true),
                                      _buildWeightUnitToggle('lbs', false),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveAndProceed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.black),
                          ),
                        )
                      : const Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        child,
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildOptionButton({
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeightUnitToggle(String unit, bool isMetricUnit) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isHeightMetric = isMetricUnit;
          // Convert existing values if needed
          if (_heightController.text.isNotEmpty) {
            double value = double.parse(_heightController.text);
            if (isMetricUnit) {
              // Convert ft to cm
              _heightController.text = (value * 30.48).toStringAsFixed(1);
            } else {
              // Convert cm to ft
              _heightController.text = (value / 30.48).toStringAsFixed(1);
            }
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _isHeightMetric == isMetricUnit
              ? Colors.white
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          unit,
          style: TextStyle(
            color:
                _isHeightMetric == isMetricUnit ? Colors.black : Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildWeightUnitToggle(String unit, bool isMetricUnit) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isWeightMetric = isMetricUnit;
          // Convert existing values if needed
          if (_weightController.text.isNotEmpty) {
            double value = double.parse(_weightController.text);
            if (isMetricUnit) {
              // Convert lbs to kg
              _weightController.text = (value * 0.453592).toStringAsFixed(1);
            } else {
              // Convert kg to lbs
              _weightController.text = (value / 0.453592).toStringAsFixed(1);
            }
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _isWeightMetric == isMetricUnit
              ? Colors.white
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          unit,
          style: TextStyle(
            color:
                _isWeightMetric == isMetricUnit ? Colors.black : Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

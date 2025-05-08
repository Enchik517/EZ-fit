import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../main.dart';
import 'onboarding/onboarding_screen.dart';
import 'goals_flow_screen.dart';

class DisclaimerScreen extends StatefulWidget {
  final VoidCallback? onAccept;

  const DisclaimerScreen({Key? key, this.onAccept}) : super(key: key);

  @override
  State<DisclaimerScreen> createState() => _DisclaimerScreenState();
}

class _DisclaimerScreenState extends State<DisclaimerScreen> {
  bool _isAccepted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A0B0B),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Text(
                    '❤️',
                    style: TextStyle(
                      fontSize: 28,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'EZ-fit',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const Text(
                'Health Disclaimer',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    'Before starting any new fitness program or using this app, consult with a qualified healthcare professional, especially if you have pre-existing medical conditions, are pregnant, postpartum, nursing, recovering from an injury or surgery, or taking medications.\n\n'
                    'The exercises and recommendations provided in this app are for informational purposes only and may not be suitable for everyone. If you experience pain, dizziness, shortness of breath, or any discomfort during exercise, stop immediately and seek medical advice. Individual results may vary based on factors like genetics, diet, and consistency.\n\n'
                    'This app is not a substitute for professional medical advice, diagnosis, or treatment. By using this app, you agree that you are solely responsible for your health and well-being, and the developers, creators, and affiliates of this app are not liable for any injuries, damages, or health issues that may arise from its use. Stay safe and healthy—consult a professional before starting your fitness journey.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 16,
                      height: 1.5,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Switch(
                    value: _isAccepted,
                    onChanged: (value) {
                      setState(() {
                        _isAccepted = value;
                      });
                    },
                    activeColor: Colors.blue,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        text: 'I acknowledge and accept the terms of the ',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                        children: const [
                          TextSpan(
                            text: 'Health disclaimer',
                            style: TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isAccepted ? _acceptDisclaimer : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    disabledBackgroundColor: Colors.grey[800],
                    disabledForegroundColor: Colors.grey[600],
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No subscription found to restore'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: Text(
                    'Restore Subscription',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _acceptDisclaimer() async {
    print('Disclaimer accepted, updating flags');

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.setDisclaimerAccepted(true);

    // Сохраняем принятие дисклеймера локально
    await DisclaimerFlag.setAccepted();

    if (widget.onAccept != null) {
      print('Using provided onAccept callback');
      widget.onAccept!();
    } else {
      print('No callback provided, navigating to GoalsFlowScreen');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const GoalsFlowScreen()),
      );
    }
  }
}

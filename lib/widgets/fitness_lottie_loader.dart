import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class FitnessLottieLoader extends StatefulWidget {
  final Color? color;
  final double size;
  final String? message;
  final String lottiePath;

  const FitnessLottieLoader({
    Key? key,
    this.color,
    this.size = 120.0,
    this.message,
    this.lottiePath = 'assets/lottie/fitness_loading.json',
  }) : super(key: key);

  @override
  State<FitnessLottieLoader> createState() => _FitnessLottieLoaderState();
}

class _FitnessLottieLoaderState extends State<FitnessLottieLoader> {
  final List<String> _thinkingMessages = [
    '🧠 Creating perfect response...',
    '💪 Selecting workout routine...',
    '🥗 Analyzing nutrition data...',
    '🔍 Studying your profile...',
    '📊 Optimizing your program...',
    '⚡ Generating recommendations...',
    '🏃 Developing cardio plan...',
    '🏋️ Forming strength exercises...',
  ];

  String _currentMessage = '';
  int _messageIndex = 0;

  @override
  void initState() {
    super.initState();
    _updateMessage();
  }

  void _updateMessage() {
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() {
          if (widget.message != null) {
            _currentMessage = widget.message!;
          } else {
            _messageIndex = (_messageIndex + 1) % _thinkingMessages.length;
            _currentMessage = _thinkingMessages[_messageIndex];
          }
        });
        _updateMessage();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = widget.color ?? theme.colorScheme.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: ColorFiltered(
            colorFilter: ColorFilter.mode(
              color,
              BlendMode.srcIn,
            ),
            child: Lottie.asset(
              widget.lottiePath,
              width: widget.size,
              height: widget.size,
              fit: BoxFit.contain,
              repeat: true,
              animate: true,
            ),
          ),
        ),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, -0.5),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: Text(
            _currentMessage,
            key: ValueKey<String>(_currentMessage),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

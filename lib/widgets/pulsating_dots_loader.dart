import 'package:flutter/material.dart';
import 'dart:math' as math;

class PulsatingDotsLoader extends StatefulWidget {
  final Color? color;
  final double size;
  final String? message;
  final double dotsSize;
  final int dotsCount;
  final Duration pulseDuration;

  const PulsatingDotsLoader({
    Key? key,
    this.color,
    this.size = 30.0,
    this.message,
    this.dotsSize = 10.0,
    this.dotsCount = 3,
    this.pulseDuration = const Duration(milliseconds: 1500),
  }) : super(key: key);

  @override
  State<PulsatingDotsLoader> createState() => _PulsatingDotsLoaderState();
}

class _PulsatingDotsLoaderState extends State<PulsatingDotsLoader>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  final List<String> _thinkingMessages = [
    '🧠 Processing your request...',
    '💪 Selecting best workout...',
    '🔥 Creating nutrition plan...',
    '⚡ Analyzing your profile...',
    '✨ Generating solution...',
    '🧘 Personalizing response...',
    '📊 Calculating workload...',
    '🥗 Developing meal plan...',
  ];

  String _currentMessage = '';
  int _messageIndex = 0;

  @override
  void initState() {
    super.initState();

    _controllers = List.generate(
      widget.dotsCount,
      (index) => AnimationController(
        vsync: this,
        duration: widget.pulseDuration,
      ),
    );

    _animations = _controllers
        .map(
          (controller) => Tween<double>(begin: 0.5, end: 1.0).animate(
            CurvedAnimation(
              parent: controller,
              curve: Curves.easeInOut,
            ),
          ),
        )
        .toList();

    // Запускаем анимации со смещением
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 300), () {
        if (_controllers[i].isAnimating == false) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }

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
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = widget.color ?? theme.colorScheme.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
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
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            widget.dotsCount,
            (index) => Padding(
              padding: EdgeInsets.symmetric(horizontal: widget.dotsSize / 2),
              child: AnimatedBuilder(
                animation: _animations[index],
                builder: (context, child) {
                  return Transform.scale(
                    scale: _animations[index].value,
                    child: Container(
                      width: widget.dotsSize,
                      height: widget.dotsSize,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

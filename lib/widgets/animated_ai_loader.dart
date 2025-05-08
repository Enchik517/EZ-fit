import 'package:flutter/material.dart';
import 'dart:math' as math;

class AnimatedAILoader extends StatefulWidget {
  final Color? color;
  final double size;
  final String? message;

  const AnimatedAILoader({
    Key? key,
    this.color,
    this.size = 80.0,
    this.message,
  }) : super(key: key);

  @override
  State<AnimatedAILoader> createState() => _AnimatedAILoaderState();
}

class _AnimatedAILoaderState extends State<AnimatedAILoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;
  final List<String> _thinkingMessages = [
    'Analyzing your data...',
    'Creating recommendations...',
    'Selecting exercises...',
    'Optimizing workout...',
    'Counting calories...',
    'Preparing plan...',
    'Personalizing response...',
    'Processing request...',
  ];

  String _currentMessage = '';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    _rotationAnimation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutCubic,
      ),
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutSine,
      ),
    );

    _updateMessage();
  }

  void _updateMessage() {
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _currentMessage = widget.message ??
              _thinkingMessages[
                  math.Random().nextInt(_thinkingMessages.length)];
        });
        _updateMessage();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = widget.color ?? theme.colorScheme.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Transform.rotate(
                angle: _rotationAnimation.value,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.fitness_center,
                        color: color,
                        size: widget.size * 0.4,
                      ),
                      ...List.generate(4, (index) {
                        final angle = index * math.pi / 2;
                        final radius = widget.size * 0.3;
                        final offset = Offset(
                          radius *
                              math.cos(angle + _rotationAnimation.value * 2),
                          radius *
                              math.sin(angle + _rotationAnimation.value * 2),
                        );
                        return Positioned(
                          left: widget.size / 2 + offset.dx - 4,
                          top: widget.size / 2 + offset.dy - 4,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                        );
                      }),
                      Container(
                        width: widget.size * 0.9,
                        height: widget.size * 0.9,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: color.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.5),
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
      ],
    );
  }
}

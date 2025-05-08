import 'package:flutter/material.dart';

class BlinkingTimer extends StatefulWidget {
  final Duration duration;
  final TextStyle style;

  const BlinkingTimer({
    Key? key,
    required this.duration,
    required this.style,
  }) : super(key: key);

  @override
  State<BlinkingTimer> createState() => _BlinkingTimerState();
}

class _BlinkingTimerState extends State<BlinkingTimer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();
    _animation = Tween(begin: 1.0, end: 0.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(widget.duration.inHours);
    final minutes = twoDigits(widget.duration.inMinutes.remainder(60));
    final seconds = twoDigits(widget.duration.inSeconds.remainder(60));

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(hours, style: widget.style),
        FadeTransition(
          opacity: _animation,
          child: Text(':', style: widget.style),
        ),
        Text(minutes, style: widget.style),
        FadeTransition(
          opacity: _animation,
          child: Text(':', style: widget.style),
        ),
        Text(seconds, style: widget.style),
      ],
    );
  }
} 
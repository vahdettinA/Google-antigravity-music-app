import 'dart:math';
import 'package:flutter/material.dart';

/// Animated audio wave visualization widget
class AudioWaveAnimation extends StatefulWidget {
  final bool isPlaying;
  final Color color;

  const AudioWaveAnimation({
    super.key,
    required this.isPlaying,
    required this.color,
  });

  @override
  State<AudioWaveAnimation> createState() => _AudioWaveAnimationState();
}

class _AudioWaveAnimationState extends State<AudioWaveAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    if (widget.isPlaying) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(AudioWaveAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: WavePainter(
            animation: _controller.value,
            color: widget.color,
            isPlaying: widget.isPlaying,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class WavePainter extends CustomPainter {
  final double animation;
  final Color color;
  final bool isPlaying;

  WavePainter({
    required this.animation,
    required this.color,
    required this.isPlaying,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    final barCount = 30; // Reduced for cleaner look
    final barWidth = size.width / (barCount * 1.5);
    final spacing = barWidth / 2;

    for (int i = 0; i < barCount; i++) {
      final x = i * (barWidth + spacing) + barWidth / 2;

      // Smoother wave calculation
      final wave1 = sin((i / barCount * 2 * pi) + (animation * 2 * pi));
      final wave2 = cos((i / barCount * 3 * pi) + (animation * 3 * pi));

      // Normalize to 0-1 range roughly, keeping it lively
      final combinedWave = (wave1 + wave2).abs() / 2;

      // Calculate bar height
      final maxHeight = size.height;
      final minHeight = size.height * 0.15; // Slightly taller min height
      final barHeight = isPlaying
          ? minHeight +
                (maxHeight - minHeight) *
                    combinedWave *
                    0.8 // Scale down a bit
          : minHeight;

      // Draw bar
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(x, size.height / 2),
          width: barWidth,
          height: barHeight,
        ),
        Radius.circular(barWidth / 2),
      );

      // Simple solid color with some transparency for "glassy" feel if desired,
      // but user asked for white. Solid white looks clean.
      // I'll add a subtle opacity based on height to make it look "fading" at edges?
      // Nah, user said "white".

      paint.color = color.withValues(alpha: 0.8 + (combinedWave * 0.2));
      // Slightly more opaque when taller

      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(WavePainter oldDelegate) {
    return oldDelegate.animation != animation ||
        oldDelegate.isPlaying != isPlaying;
  }
}

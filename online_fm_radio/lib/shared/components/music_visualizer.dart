import 'dart:math';

import 'package:flutter/material.dart';

/// 音乐动效可视化组件，支持三种样式切换：柱状、线条、粒子。
///
/// 由于电台直播流没有实时波形数据，使用基于节奏的模拟动画，
/// 播放时持续动效，暂停时慢慢回落。
enum VisualizerStyle { bars, lines, particles }

class MusicVisualizer extends StatefulWidget {
  final bool isPlaying;
  final VisualizerStyle style;
  final Color color;
  final double height;

  const MusicVisualizer({
    super.key,
    required this.isPlaying,
    this.style = VisualizerStyle.bars,
    this.color = Colors.white,
    this.height = 60,
  });

  @override
  State<MusicVisualizer> createState() => _MusicVisualizerState();
}

class _MusicVisualizerState extends State<MusicVisualizer>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  final Random _random = Random();
  final List<double> _barHeights = [];
  final List<_Particle> _particles = [];
  static const int _barCount = 16;
  static const int _particleCount = 20;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..addListener(_updateAnimation);

    // 初始化柱状高度
    for (int i = 0; i < _barCount; i++) {
      _barHeights.add(0.1 + _random.nextDouble() * 0.3);
    }

    // 初始化粒子
    for (int i = 0; i < _particleCount; i++) {
      _particles.add(_Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: 2 + _random.nextDouble() * 4,
        speed: 0.3 + _random.nextDouble() * 0.8,
        phase: _random.nextDouble() * 2 * pi,
      ));
    }

    _controller.repeat();
  }

  void _updateAnimation() {
    setState(() {
      if (widget.isPlaying) {
        // 播放中：柱状高度随机跳动
        for (int i = 0; i < _barCount; i++) {
          final target = 0.3 + _random.nextDouble() * 0.7;
          _barHeights[i] += (target - _barHeights[i]) * 0.2;
        }
        // 粒子上浮
        for (final p in _particles) {
          p.y -= p.speed * 0.005;
          p.phase += 0.05;
          if (p.y < -0.1) {
            p.y = 1.1;
            p.x = _random.nextDouble();
          }
        }
      } else {
        // 暂停中：柱状慢慢回落
        for (int i = 0; i < _barCount; i++) {
          _barHeights[i] += (0.1 - _barHeights[i]) * 0.1;
        }
        // 粒子缓慢下沉
        for (final p in _particles) {
          p.y += 0.002;
          if (p.y > 1.1) p.y = 1.1;
        }
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
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: CustomPaint(
        painter: _VisualizerPainter(
          style: widget.style,
          color: widget.color,
          barHeights: _barHeights,
          particles: _particles,
        ),
      ),
    );
  }
}

class _VisualizerPainter extends CustomPainter {
  final VisualizerStyle style;
  final Color color;
  final List<double> barHeights;
  final List<_Particle> particles;

  _VisualizerPainter({
    required this.style,
    required this.color,
    required this.barHeights,
    required this.particles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    switch (style) {
      case VisualizerStyle.bars:
        _paintBars(canvas, size);
        break;
      case VisualizerStyle.lines:
        _paintLines(canvas, size);
        break;
      case VisualizerStyle.particles:
        _paintParticles(canvas, size);
        break;
    }
  }

  void _paintBars(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final barWidth = size.width / barHeights.length * 0.6;
    final gap = size.width / barHeights.length * 0.4;
    final totalWidth = barWidth + gap;

    for (int i = 0; i < barHeights.length; i++) {
      final x = i * totalWidth + gap / 2;
      final barHeight = size.height * barHeights[i];
      final y = size.height - barHeight;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        Radius.circular(barWidth / 2),
      );
      canvas.drawRRect(rect, paint);
    }
  }

  void _paintLines(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final step = size.width / (barHeights.length - 1);

    for (int i = 0; i < barHeights.length; i++) {
      final x = i * step;
      final y = size.height - size.height * barHeights[i];
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        final prevX = (i - 1) * step;
        final prevY = size.height - size.height * barHeights[i - 1];
        final midX = (prevX + x) / 2;
        path.quadraticBezierTo(prevX, prevY, midX, (prevY + y) / 2);
      }
    }
    canvas.drawPath(path, paint);

    // 镜像线（淡一点）
    final mirrorPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final mirrorPath = Path();
    for (int i = 0; i < barHeights.length; i++) {
      final x = i * step;
      final y = size.height + size.height * barHeights[i] * 0.3;
      if (i == 0) {
        mirrorPath.moveTo(x, y);
      } else {
        final prevX = (i - 1) * step;
        final prevY = size.height + size.height * barHeights[i - 1] * 0.3;
        final midX = (prevX + x) / 2;
        mirrorPath.quadraticBezierTo(prevX, prevY, midX, (prevY + y) / 2);
      }
    }
    canvas.drawPath(mirrorPath, mirrorPaint);
  }

  void _paintParticles(Canvas canvas, Size size) {
    for (final p in particles) {
      final x = p.x * size.width + sin(p.phase) * 10;
      final y = p.y * size.height;
      final opacity = 0.4 + 0.6 * (1 - p.y);
      final paint = Paint()..color = color.withOpacity(opacity.clamp(0.0, 1.0));
      canvas.drawCircle(Offset(x, y), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _VisualizerPainter oldDelegate) => true;
}

class _Particle {
  double x;
  double y;
  double size;
  double speed;
  double phase;

  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.phase,
  });
}

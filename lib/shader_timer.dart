import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:timertest/game_timer_controller.dart';

class ShaderTimer extends StatefulWidget {
  final GameTimerController controller;
  final double size;

  const ShaderTimer({
    super.key,
    required this.controller,
    this.size = 120,
  });

  @override
  State<ShaderTimer> createState() => _ShaderTimerState();
}

class _ShaderTimerState extends State<ShaderTimer> with TickerProviderStateMixin {
  ui.FragmentProgram? _timerProgram;
  ui.FragmentProgram? _iceProgram;

  // Configuration Colors
  final Color colorGreen = const Color(0xFF5BC297);
  final Color colorRingBg = const Color(0xFF262E38);
  final Color colorOuter = const Color(0xFF4D5261);
  final Color colorInner = const Color(0xFF404552);

  @override
  void initState() {
    super.initState();
    _loadShaders();
    // Attach controller to this widget's TickerProvider
    widget.controller.attach(this);
  }

  Future<void> _loadShaders() async {
    try {
      final results = await Future.wait([
        ui.FragmentProgram.fromAsset('shaders/timer.frag'),
        ui.FragmentProgram.fromAsset('shaders/ice.frag'),
      ]);

      setState(() {
        _timerProgram = results[0];
        _iceProgram = results[1];
      });
    } catch (e) {
      debugPrint('Error loading shaders: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_timerProgram == null || _iceProgram == null) {
      return const SizedBox.shrink();
    }

    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 60.0), // Margin from top of screen
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: AnimatedBuilder(
            animation: widget.controller,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  // LAYER 1: Base Timer Shader
                  CustomPaint(
                    size: Size(widget.size, widget.size),
                    painter: TimerShaderPainter(
                      shader: _timerProgram!.fragmentShader(),
                      progress: widget.controller.mainProgress,
                      colorGreen: colorGreen,
                      colorRingBg: colorRingBg,
                      colorOuter: colorOuter,
                      colorInner: colorInner,
                    ),
                  ),

                  // LAYER 2: Text Countdown
                  Text(
                    '${widget.controller.secondsRemaining}',
                    style: TextStyle(
                      fontSize: widget.size * 0.35,
                      fontWeight: FontWeight.bold,
                      color: widget.controller.isFrozen ? Colors.cyanAccent : colorGreen,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      shadows: widget.controller.isFrozen ? [
                         const Shadow(blurRadius: 10, color: Colors.cyanAccent)
                      ] : null,
                    ),
                  ),

                  // LAYER 3: Ice Overlay Shader (Only when frozen)
                  if (widget.controller.isFrozen)
                    CustomPaint(
                      size: Size(widget.size, widget.size),
                      painter: IceShaderPainter(
                        shader: _iceProgram!.fragmentShader(),
                        freezeProgress: widget.controller.freezeProgress,
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// --- PAINTERS ---

class TimerShaderPainter extends CustomPainter {
  final ui.FragmentShader shader;
  final double progress;
  final Color colorGreen;
  final Color colorRingBg;
  final Color colorOuter;
  final Color colorInner;

  TimerShaderPainter({
    required this.shader,
    required this.progress,
    required this.colorGreen,
    required this.colorRingBg,
    required this.colorOuter,
    required this.colorInner,
  });

  @override
  void paint(Canvas canvas, Size size) {
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    shader.setFloat(2, progress);
    shader.setFloat(3, colorGreen.red / 255);
    shader.setFloat(4, colorGreen.green / 255);
    shader.setFloat(5, colorGreen.blue / 255);
    shader.setFloat(6, colorRingBg.red / 255);
    shader.setFloat(7, colorRingBg.green / 255);
    shader.setFloat(8, colorRingBg.blue / 255);
    shader.setFloat(9, colorOuter.red / 255);
    shader.setFloat(10, colorOuter.green / 255);
    shader.setFloat(11, colorOuter.blue / 255);
    shader.setFloat(12, colorInner.red / 255);
    shader.setFloat(13, colorInner.green / 255);
    shader.setFloat(14, colorInner.blue / 255);

    final paint = Paint()..shader = shader;
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant TimerShaderPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class IceShaderPainter extends CustomPainter {
  final ui.FragmentShader shader;
  final double freezeProgress;

  IceShaderPainter({
    required this.shader,
    required this.freezeProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    shader.setFloat(2, freezeProgress);

    final paint = Paint()..shader = shader;
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant IceShaderPainter oldDelegate) =>
      oldDelegate.freezeProgress != freezeProgress;
}

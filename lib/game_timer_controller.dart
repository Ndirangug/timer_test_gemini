
import 'package:flutter/material.dart';

class GameTimerController extends ChangeNotifier {
  final Duration totalDuration;
  final VoidCallback? onFinished;

  late AnimationController _mainController;
  late AnimationController _freezeAnimController;

  bool _isFrozen = false;
  bool get isFrozen => _isFrozen;

  GameTimerController({
    required this.totalDuration,
    this.onFinished,
  });

  /// Must be called by the Widget to link the visual animation
  void attach(TickerProvider vsync) {
    // 1. Main Timer Controller
    _mainController = AnimationController(
      vsync: vsync,
      duration: totalDuration,
    );

    // FIX: Notify UI on every tick so the timer visually counts down
    _mainController.addListener(() {
      notifyListeners();
    });

    _mainController.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        onFinished?.call();
      }
    });

    // 2. Freeze Effect Controller
    _freezeAnimController = AnimationController(vsync: vsync);

    // FIX: Notify UI on every tick so the ice grows smoothly
    _freezeAnimController.addListener(() {
      notifyListeners();
    });

    _freezeAnimController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _finishFreeze();
      }
    });

    // Start countdown immediately (1.0 -> 0.0)
    _mainController.reverse(from: 1.0);
  }

  void dispose() {
    _mainController.dispose();
    _freezeAnimController.dispose();
    super.dispose();
  }

  double get mainProgress => _mainController.value;
  double get freezeProgress => _freezeAnimController.value;

  int get secondsRemaining =>
      (_mainController.value * totalDuration.inSeconds).ceil();

  // --- POWER UPS ---

  /// Freezes the timer for [duration] and plays ice animation.
  void triggerTimeFreeze(Duration duration) {
    if (_isFrozen || !_mainController.isAnimating) return;

    _isFrozen = true;
    _mainController.stop(); // Stop the countdown

    // Configure and start freeze animation (0.0 -> 1.0)
    _freezeAnimController.duration = duration;
    _freezeAnimController.forward(from: 0.0);
    
    notifyListeners();
  }

  void _finishFreeze() {
    // Instant shatter effect
    _isFrozen = false;
    _freezeAnimController.reset(); 

    // Resume main timer if not finished
    if (_mainController.status != AnimationStatus.dismissed) {
      _mainController.reverse(from: _mainController.value);
    }
    notifyListeners();
  }

  /// Rewinds time by [seconds].
  void triggerTimeMachine(int seconds) {
    final double currentSeconds = _mainController.value * totalDuration.inSeconds;
    final double newSeconds = (currentSeconds + seconds).clamp(0, totalDuration.inSeconds.toDouble());
    final double newProgress = newSeconds / totalDuration.inSeconds;

    _mainController.value = newProgress;

    // If running and not frozen, continue running
    if (!_isFrozen &&
        _mainController.status != AnimationStatus.dismissed &&
        _mainController.status != AnimationStatus.completed) {
      _mainController.reverse(from: newProgress);
    }
  }
}

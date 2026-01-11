import 'package:flutter/material.dart';
import 'package:timertest/game_timer_controller.dart';
import 'package:timertest/shader_timer.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Word Game Timer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5BC297)),
        useMaterial3: true,
      ),
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameTimerController _timerController;

  @override
  void initState() {
    super.initState();
    // Initialize Logic
    _timerController = GameTimerController(
      totalDuration: const Duration(seconds: 90),
      onFinished: () {
        debugPrint("GAME OVER!");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Time's up! Game Over.")),
        );
      },
    );
  }

  @override
  void dispose() {
    _timerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      body: Stack(
        children: [
          // 1. Placeholder for Game UI
          const Center(
            child: Text(
              "GAME BOARD AREA",
              style: TextStyle(color: Colors.grey, fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),

          // 2. The Timer (Positioned Top Center automatically by the widget)
          ShaderTimer(
            controller: _timerController,
            size: 150,
          ),

          // 3. Power-Up Buttons
          Positioned(
            bottom: 50,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildButton(
                  icon: Icons.ac_unit,
                  label: "Freeze (5s)",
                  color: Colors.cyan,
                  onTap: () => _timerController.triggerTimeFreeze(
                    const Duration(seconds: 5),
                  ),
                ),
                _buildButton(
                  icon: Icons.history,
                  label: "+15s Rewind",
                  color: Colors.orange,
                  onTap: () => _timerController.triggerTimeMachine(15),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      icon: Icon(icon),
      label: Text(label),
      onPressed: onTap,
    );
  }
}

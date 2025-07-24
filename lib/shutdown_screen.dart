// shutdown_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ShutdownScreen extends StatefulWidget {
  final String shutdownType; // 'admin' or 'client'

  const ShutdownScreen({Key? key, required this.shutdownType}) : super(key: key);

  @override
  State<ShutdownScreen> createState() => _ShutdownScreenState();
}

class _ShutdownScreenState extends State<ShutdownScreen> {
  Duration _remainingTime = Duration.zero;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  Future<void> _startCountdown() async {
    final prefs = await SharedPreferences.getInstance();
    final lockUntilString = prefs.getString("locked_until");

    if (lockUntilString != null) {
      final lockUntil = DateTime.parse(lockUntilString);
      _updateRemainingTime(lockUntil);

      _timer = Timer.periodic(Duration(seconds: 1), (_) {
        _updateRemainingTime(lockUntil);
      });
    }
  }

  void _updateRemainingTime(DateTime lockUntil) {
    final now = DateTime.now();
    final remaining = lockUntil.difference(now);
    if (remaining <= Duration.zero) {
      _timer?.cancel();
      Navigator.of(context).pop(); // Return to previous screen when time is up
    } else {
      setState(() {
        _remainingTime = remaining;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    return "${twoDigits(duration.inHours)}:"
        "${twoDigits(duration.inMinutes.remainder(60))}:"
        "${twoDigits(duration.inSeconds.remainder(60))}";
  }

  String _getShutdownTitle() {
    return widget.shutdownType == 'admin'
        ? "Shutdown for two hours"
        : "Shutdown for one day";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6C63FF),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_clock, size: 100, color: Colors.white),
            const SizedBox(height: 20),
            Text(
              _getShutdownTitle(),
              style: const TextStyle(
                fontSize: 26,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "You can continue after:",
              style: TextStyle(fontSize: 20, color: Colors.white),
            ),
            const SizedBox(height: 10),
            Text(
              _formatDuration(_remainingTime),
              style: const TextStyle(
                fontSize: 32,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

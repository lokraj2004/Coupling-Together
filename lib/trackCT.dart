import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'shutdown_screen.dart';

class TrackInitializer {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  Timer? _timer;
  double _totalUsageMB = 0.0;
  final double thresholdMB = 330.0;
  bool _isTrackingStarted = false;

  void start(BuildContext context) async {
    if (_isTrackingStarted) return;

    await _initializeTrackSlots();
    _startTracking(context);
    _isTrackingStarted = true;
  }

  Future<void> _initializeTrackSlots() async {
    final trackRef = _dbRef.child('track');
    final snapshot = await trackRef.get();

    if (!snapshot.exists) {
      final Map<String, dynamic> emptySlots = {
        for (int i = 1; i <= 10; i++) 'slot$i': 0,
      };
      await trackRef.set(emptySlots);
      print("Track slots initialized.");
    } else {
      print("Track slots already exist.");
    }
  }

  void _startTracking(BuildContext context) {
    _timer = Timer.periodic(const Duration(minutes: 4), (_) async {
      await _fetchAndCalculateUsage(context);
    });
    print("Started CT usage tracking every 4 minutes.");
  }

  Future<void> _fetchAndCalculateUsage(BuildContext context) async {
    try {
      final snapshot = await _dbRef.child('track').get();
      if (!snapshot.exists) {
        print("Track node not found during fetch.");
        return;
      }

      final data = Map<String, dynamic>.from(snapshot.value as Map<dynamic, dynamic>);
      double total = 0.0;

      for (int i = 1; i <= 10; i++) {
        final key = 'slot$i';
        final value = data[key];
        if (value != null) {
          total += double.tryParse(value.toString()) ?? 0.0;
        }
      }

      _totalUsageMB = total;
      print("Total usage: $_totalUsageMB MB");

      if (_totalUsageMB >= thresholdMB) {
        _timer?.cancel();
        _navigateToLimitReached(context);
      }
    } catch (e) {
      print("Error while tracking usage: $e");
    }
  }

  void stopTracking() {
    _timer?.cancel();
    print("Stopped CT usage tracking.");
  }

  void _navigateToLimitReached(BuildContext context) {
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const ShutdownScreen(shutdownType: 'client'),
        ),
      );
    }
  }
}

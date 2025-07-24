import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:flutter/material.dart';

class CTUsageResetManager {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child('track');
  static const String _lastResetDateKey = 'last_reset_date';

  /// Call this method once during CT app launch
  Future<void> checkAndResetIfNewDay() async {
    debugPrint("Going to reset");
    final prefs = await SharedPreferences.getInstance();

    final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final String? lastResetDate = prefs.getString(_lastResetDateKey);

    if (lastResetDate != today) {
      debugPrint("🕛 Date changed: $lastResetDate → $today. Resetting slots...");
      await _resetAllSlotUsages();
      await prefs.setString(_lastResetDateKey, today);
      debugPrint("🔑 Going to reset");
    } else {
      debugPrint("📅 Same day ($today). No reset needed.");
    }
  }

  /// Resets all slot usages in /track to 0
  Future<void> _resetAllSlotUsages() async {
    try {
      final snapshot = await _dbRef.get();
      if (snapshot.exists && snapshot.value != null) {
        final Map<String, dynamic> updates = {};

        for (int i = 1; i <= 10; i++) {
          updates['slot$i'] = 0;
        }

        await _dbRef.update(updates);
        debugPrint("✅ All slot usages reset to 0.");
      }
    } catch (e) {
      debugPrint("❌ Failed to reset slot usages: $e");
    }
  }
}

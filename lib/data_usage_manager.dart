import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DataUsageManager {
  static const double maxDailyUploadMB = 330.0;
  static const int lockDurationMinutes = 120;
  static const String _dataKey = 'firebase_data_usage';
  static const int thresholdBytes = 330 * 1024 * 1024; // 330 MB

  static const String _lockUntilKey = "locked_until";

  static double _currentDataSentMB = 0.0;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final lockUntilString = prefs.getString(_lockUntilKey);

    // If app is restarted and lock is still active, retain it.
    if (lockUntilString != null) {
      final lockUntil = DateTime.parse(lockUntilString);
      if (DateTime.now().isAfter(lockUntil)) {
        await prefs.remove(_lockUntilKey);
      }
    }

    // 🔄 Reset tracking variable on every start
    _currentDataSentMB = 0.0;
  }

  static Future<void> addUpload(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();

    final jsonSize = utf8.encode(jsonEncode(data)).length;
    _currentDataSentMB += jsonSize / (1024 * 1024); // Runtime only

    await addDataUsage(jsonSize); // Persist to disk

    if (_currentDataSentMB >= maxDailyUploadMB) {
      final lockUntil = DateTime.now().add(Duration(minutes: lockDurationMinutes));
      await prefs.setString(_lockUntilKey, lockUntil.toIso8601String());
    }
  }


  static Future<bool> isShutdownActive()async {
    final prefs = await SharedPreferences.getInstance();
    final lockUntilString = prefs.getString(_lockUntilKey);

    if (lockUntilString == null) return false;

    final lockUntil = DateTime.parse(lockUntilString);
    if (DateTime.now().isAfter(lockUntil)) {
      await prefs.remove(_lockUntilKey);
      return false;
    }

    return true;
  }



  static double getCurrentUsageMB() {
    return _currentDataSentMB;
  }

  static void resetDataSent() {
    _currentDataSentMB = 0.0;
  }
  static Future<int> getDataUsed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_dataKey) ?? 0;
  }

  static Future<void> addDataUsage(int bytes) async {
    final prefs = await SharedPreferences.getInstance();
    int current = prefs.getInt(_dataKey) ?? 0;
    await prefs.setInt(_dataKey, current + bytes);
  }
  static Future<void> resetUsage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_dataKey, 0);
  }

}

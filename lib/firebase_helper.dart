

import 'package:firebase_database/firebase_database.dart';
import 'data_usage_manager.dart';

typedef FirebaseData = Map<String, dynamic>;

class FirebaseHelper {
  static final FirebaseDatabase _database = FirebaseDatabase.instance;

  /// Pushes data to Firebase under path `sensors/<id>`
  static Future<void> pushSensorData({
    required int id,
    required String name,
    required double value,
    required String unit,
    required bool integerOnlyMode,
  }) async {
    if (await DataUsageManager.isShutdownActive()) {
      print("\uD83D\uDEA5 App usage limit reached. Firebase push blocked for now.");
      return;
    }

    final dynamic finalValue = integerOnlyMode ? value.toInt() : value;

    final FirebaseData data = {
      "id": id,
      "name": name,
      "value": finalValue,
      "unit": unit,
    };

    final ref = _database.ref("sensors/$id");
    await ref.set(data);

    await DataUsageManager.addUpload(data);
  }

  /// Deletes all data from Firebase (used on app exit)
  static Future<void> deleteAllData() async {
    try {
      await FirebaseDatabase.instance.ref("sensors").remove();

      print("\uD83D\uDDD1️ All Firebase data deleted on exit.");
    } catch (e) {
      print("\u274C Error deleting Firebase data: \$e");
    }
  }
}

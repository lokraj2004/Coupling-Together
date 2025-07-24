import 'package:flutter/services.dart';
import 'package:firebase_database/firebase_database.dart';

Future<void> authenticateWithAdminKey() async {
  const platform = MethodChannel('admin_data_channel');
  try {
    final String? key = await platform.invokeMethod('getAdminKey');
    if (key == null) throw Exception("No admin key received");

    final ref = FirebaseDatabase.instance.ref("auth_key");

    // Write key once — only if not already present
    final snapshot = await ref.get();
    if (!snapshot.exists) {
      await ref.set({
        'key': key,
        'timestamp': ServerValue.timestamp,
      });
      print("✅ Admin authenticated successfully.");

    } else {
      print("⚠️ Admin session key already exists.");
    }
  } catch (e) {
    print("❌ Admin authentication failed: $e");
  }
}

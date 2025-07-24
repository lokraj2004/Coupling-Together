import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_database/firebase_database.dart';
import 'data_usage_manager.dart';
import 'shutdown_screen.dart';

String formatName(String? name) {
  return (name == null || name == "NULL") ? '' : '. $name';
}

String formatValueAndUnit(dynamic value, String? unit) {
  final showValue = value is num && value >= 0;
  final showUnit = unit != null && unit != "NULL";

  if (!showValue && !showUnit) return '';
  if (!showValue) return showUnit ? '$unit' : '';
  if (!showUnit) return '$value';
  return '$value $unit';
}

Future<void> sendBaudRateToNative(int baudRate) async {
  const platform = MethodChannel('usb_data_channel');
  try {
    await platform.invokeMethod('setBaudRate', baudRate);
  } catch (e) {
    print('Failed to send baud rate: $e');
  }
}

Future<bool> handleOnWillPop(
    BuildContext context,
    DateTime? lastBackPressed,
    bool isExiting,
    Future<void> Function() onExitCallback,
    ) async {
  final now = DateTime.now();
  final difference = lastBackPressed == null
      ? Duration(days: 1)
      : now.difference(lastBackPressed);

  debugPrint("🔙 Back pressed. Time since last: ${difference.inMilliseconds}ms");

  if (difference < const Duration(seconds: 2)) {
    if (!isExiting) {
      await onExitCallback();
    }
    return true;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Tap back again to exit and clear Firebase')),
  );
  return false;
}

void checkForShutdown(BuildContext context) async {
  bool isShutdown = await DataUsageManager.isShutdownActive();
  if (isShutdown && context.mounted) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (context) => const ShutdownScreen(shutdownType: 'admin')),
    );
  }
}

void showDebugLogDialog(BuildContext context, List<String> debugLogs) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("🪵 Debug Logs"),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Scrollbar(
          child: SingleChildScrollView(
            child: Text(debugLogs.join('\n'), style: const TextStyle(fontSize: 12)),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Close"),
        )
      ],
    ),
  );
}

void showSensorLogDialog(BuildContext context, List<String> sensorLogs) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("📊 Sensor JSON Logs"),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Scrollbar(
          child: SingleChildScrollView(
            child: Text(sensorLogs.join('\n'), style: const TextStyle(fontSize: 12)),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Close"),
        )
      ],
    ),
  );
}

void showOptionsDialog(
    BuildContext context,
    bool isAveragingEnabled,
    bool isIntegerOnlyEnabled,
    ValueChanged<bool> onAverageToggle,
    ValueChanged<bool> onIntegerOnlyToggle,
    ) async {
  final usedBytes = await DataUsageManager.getDataUsed();
  final thresholdBytes = DataUsageManager.thresholdBytes;
  final remainingBytes = (thresholdBytes - usedBytes).clamp(0, thresholdBytes);

  double clientUsageMB = 0.0;
  try {
    final snapshot = await FirebaseDatabase.instance.ref('track').get();
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      for (var value in data.values) {
        clientUsageMB += double.tryParse(value.toString()) ?? 0.0;
      }
    }
  } catch (e) {
    print("❌ Error fetching client usage: $e");
  }

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Settings"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text("Average"),
              value: isAveragingEnabled,
              onChanged: (val) {
                onAverageToggle(val);
                Navigator.pop(context);
              },
            ),
            SwitchListTile(
              title: const Text("Integer only"),
              value: isIntegerOnlyEnabled,
              onChanged: (val) {
                onIntegerOnlyToggle(val);
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              title: const Text("Data Stored"),
              subtitle: Text(
                "Used: ${(usedBytes / (1024 * 1024)).toStringAsFixed(4)} MB\n"
                    "Remaining: ${(remainingBytes / (1024 * 1024)).toStringAsFixed(4)} MB",
              ),
              leading: const Icon(Icons.storage_rounded),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: const Text("Client Usage"),
              subtitle: Text("Total: ${clientUsageMB.toStringAsFixed(2)} MB"),
              leading: const Icon(Icons.network_check),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text("Close"),
            onPressed: () => Navigator.pop(context),
          )
        ],
      );
    },
  );
}

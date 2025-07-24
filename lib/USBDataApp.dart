import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_database/firebase_database.dart';
import 'data_usage_manager.dart';
import 'background_wrapper.dart';
import 'sensor_data.dart';
import 'firebase_helper.dart';
import 'trackCT.dart';
import 'usb_helpers.dart';
import 'serial_input_widget.dart';

class USBDataApp extends StatefulWidget {
  final int baudRate;
  USBDataApp({Key? key, required this.baudRate}) : super(key: key);
  @override
  State<USBDataApp> createState() => _USBDataAppState();
}

class _USBDataAppState extends State<USBDataApp> {
  static const platform = MethodChannel('usb_data_channel');
  List<Map<String, dynamic>> sensorData = [];
  List<String> debugLogs = [];
  List<String> sensorLogs = [];
  final Map<int, SensorData> sensorPool = {};
  final databaseRef = FirebaseDatabase.instance.ref("sensors_data");
  Map<int, List<double>> _valueBuffer = {};
  Map<int, Map<String, dynamic>> _metaBuffer = {};
  bool isAveragingEnabled = false;
  bool isIntegerOnlyEnabled = false;
  late TrackInitializer _usageTracker;
  bool _usbPermissionGranted = false;


  DateTime? lastBackPressed;
  bool isExiting = false;

  @override
  void initState() {
    super.initState();
    debugPrint("Selected Baud Rate: ${widget.baudRate}");
    sendBaudRateToNative(widget.baudRate);
    DataUsageManager.init();
    checkForShutdown(context); // ✅ moved
    _overrideDebugPrint();
    _listenToNative();
    startUSB();

    _usageTracker = TrackInitializer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _usageTracker.start(context);
    });
  }

  @override
  void dispose() {
    _usageTracker.stopTracking();
    super.dispose();
  }

  void _overrideDebugPrint() {
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message == null) return;
      setState(() {
        debugLogs.add(message);
        if (debugLogs.length > 200) {
          debugLogs.removeAt(0);
        }
      });
      print(message);
    };
  }

  Future<bool> _onWillPop() {
    return handleOnWillPop(
      context,
      lastBackPressed,
      isExiting,
          () async {
        isExiting = true;
        await FirebaseHelper.deleteAllData();
        DataUsageManager.resetUsage();
        DataUsageManager.resetDataSent();
        await Future.delayed(const Duration(seconds: 2));
        SystemNavigator.pop();
      },
    ).then((value) {
      if (!value) lastBackPressed = DateTime.now();
      return value;
    });
  }

  void processSensorData(Map<String, dynamic> data) async {
    int id = data["id"];
    String name = data["name"];
    double value = (data["value"] as num).toDouble();
    String unit = data["unit"];

    if (!isAveragingEnabled) {
      await FirebaseHelper.pushSensorData(
        id: id,
        name: name,
        value: value,
        unit: unit,
        integerOnlyMode: isIntegerOnlyEnabled,
      );
      return;
    }

    _valueBuffer.putIfAbsent(id, () => []).add(value);
    _metaBuffer[id] = {"name": name, "unit": unit};

    if (_valueBuffer[id]!.length >= 6) {
      double avg = _valueBuffer[id]!.reduce((a, b) => a + b) / 6.0;

      await FirebaseHelper.pushSensorData(
        id: id,
        name: _metaBuffer[id]!["name"],
        value: avg,
        unit: _metaBuffer[id]!["unit"],
        integerOnlyMode: isIntegerOnlyEnabled,
      );

      _valueBuffer[id]!.clear();
      _metaBuffer.remove(id);
    }
  }

  Future<void> startUSB() async {
    try {
      await platform.invokeMethod('startUSB');
      debugPrint("✅ USB read started.");
      debugPrint("✅ USB will read started.");
      setState(() {
        _usbPermissionGranted = true; // ✅ Set permission flag
      });
    } catch (e) {
      debugPrint("❌ Error starting USB: $e");
    }
  }

  void _listenToNative() {
    platform.setMethodCallHandler((call) async {
      debugPrint("📥 Method received: ${call.method}");

      if (call.method == "newData") {
        final jsonString = call.arguments;
        debugPrint("📦 Raw JSON: $jsonString");

        try {
          final data = jsonDecode(jsonString);
          processSensorData(data);
          int id = data["id"];
          String name = data["name"];
          double value = (data["value"] as num).toDouble();
          String unit = data["unit"];

          setState(() {
            if (!sensorPool.containsKey(id)) {
              sensorPool[id] = SensorData(id: id, name: name, value: value, unit: unit);
            } else {
              sensorPool[id]!.update(name: name, value: value, unit: unit);
            }

            final jsonOutput = sensorPool[id]!.toJson();
            sensorData.add(jsonOutput);

            sensorLogs.add(sensorPool[id]!.toString());
            if (sensorLogs.length > 200) {
              sensorLogs.removeAt(0);
            }
          });
        } catch (e) {
          debugPrint("❌ JSON parsing error: $e");
        }
      } else if (call.method == "logMessage") {
        final msg = call.arguments;
        setState(() {
          debugLogs.add("📡 Native: $msg");
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
    child: Container(
    decoration: const BoxDecoration(
    gradient: LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFCDFFD8), Color(0xFF94B9FF)],
    ),
    ),
        child: AppBar(
          title: const Text('Sensor Data', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500,color: Colors.black,
          )
          ),
          backgroundColor: Colors.transparent,
          actions: [
            IconButton(
              icon: const Icon(Icons.terminal),
              onPressed: () => showDebugLogDialog(context, debugLogs),
              tooltip: 'Show Logs',
            ),
            IconButton(
              icon: const Icon(Icons.data_object_outlined),
              onPressed: () => showSensorLogDialog(context, sensorLogs),
              tooltip: 'Sensor JSON Log',
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => showOptionsDialog(
                context,
                isAveragingEnabled,
                isIntegerOnlyEnabled,
                    (val) {
                  setState(() {
                    isAveragingEnabled = val;
                    _valueBuffer.clear();
                  });
                },
                    (val) {
                  setState(() {
                    isIntegerOnlyEnabled = val;
                  });
                },
              ),
            ),
          ],
        ),
    ),
        ),
        body: BackgroundWrapper(
        child:Column(
          children: [
            Expanded(
              child: sensorData.isEmpty
                  ? Center(child: Text("Waiting for data...", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500,color: Color(0xFFFAFAFA),
              ),
              )
              )
                  : ListView.builder(
                itemCount: sensorData.length,
                itemBuilder: (context, index) {
                  final item = sensorData[index];
                  final id = item['id'];
                  final name = item['name'];
                  final value = item['value'];
                  final unit = item['unit'];

                  final formattedTitle = '$id${formatName(name)}';
                  final formattedSubtitle = formatValueAndUnit(value, unit);

                  return Card(
                    margin: const EdgeInsets.all(8),
                    child: ListTile(
                      title: Text(formattedTitle.trim()),
                      subtitle: Text(formattedSubtitle.trim()),
                    ),
                  );

                },
              ),
            ),
            if (_usbPermissionGranted)
              const SerialInputWidget()
            else
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text("🔒 Waiting for USB permission...",
                    style: TextStyle(color: Colors.white70)),
              ),
          ],
        ),
        ) //BackgroundWrapper
      ),
    );
  }
}

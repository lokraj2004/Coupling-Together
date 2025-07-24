import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'baudrate.dart';
import 'background_wrapper.dart';

class USBDetectionPage extends StatefulWidget {
  @override
  _USBDetectionPageState createState() => _USBDetectionPageState();
}

class _USBDetectionPageState extends State<USBDetectionPage> {
  static const platform = MethodChannel('usb_data_channel');
  String deviceStatus = 'Checking for USB devices...';
  Map<String, dynamic> deviceInfo = {};
  bool isDeviceConnected = false;

  @override
  void initState() {
    super.initState();
    checkUSBDevice();
  }

  Future<void> checkUSBDevice() async {
    try {
      final result = await platform.invokeMethod('getUSBDeviceInfo');
      if (result != null && result is Map) {
        setState(() {
          deviceInfo = Map<String, dynamic>.from(result);
          isDeviceConnected = true;
        });
      } else {
        setState(() {
          deviceStatus = 'No USB devices connected.';
        });
      }
    } on PlatformException catch (e) {
      setState(() {
        deviceStatus = 'Failed to get device info: ${e.message}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            title: const Text("USB Detection"),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
        ),
      ),
      body: BackgroundWrapper(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: isDeviceConnected
              ? buildDeviceInfo()
              : buildDeviceStatusContainer(),
        ),
      ),
      floatingActionButton: isDeviceConnected
          ? FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => BaudRateSelector()),
          );
        },
        label: const Text("Next"),
        icon: const Icon(Icons.arrow_forward),
      )
          : null,
    );
  }

  Widget buildDeviceInfo() {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: deviceInfo.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.key,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.value.toString(),
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black54,
                    ),
                  ),
                  const Divider(thickness: 1),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget buildDeviceStatusContainer() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          deviceStatus,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
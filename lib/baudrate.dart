import 'package:flutter/material.dart';
import 'USBDataApp.dart';
import 'package:firebase_database/firebase_database.dart';
import 'background_wrapper.dart';


class BaudRateSelector extends StatefulWidget {
  @override
  _BaudRateSelectorState createState() => _BaudRateSelectorState();
}

class _BaudRateSelectorState extends State<BaudRateSelector> {
  final List<String> baudRates = [
    '9600',
    '115200',
    '57600',
    '19200',
    '38400',
  ];

  String? selectedRate;

  Future<void> _cleanupOldDataIfAny() async {
    final ref = FirebaseDatabase.instance.ref();

    try {
      await FirebaseDatabase.instance.ref("sensors").remove();
      debugPrint("deleted sensors node successfully");

    } catch (e) {
      debugPrint("❌ Error during cleanup: $e");
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
    colors: [ Color(0xFFCDFFD8),Color(0xFF94B9FF)  ],
    ),
    ),
      child: AppBar(
        title: Text('Instructions'),
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () async {
            Navigator.pop(context);
          },
        ),
      ),
    ),
        ),
      body: BackgroundWrapper(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
                children: [
            Padding(
            padding: const EdgeInsets.only(top: 16.0), // moves content slightly up
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter the baud rate',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Choose a baud rate',
                      border: OutlineInputBorder(),
                    ),
                    items: baudRates.map((rate) {
                      return DropdownMenuItem<String>(
                        value: rate,
                        child: Text(rate),
                      );
                    }).toList(),
                    value: selectedRate,
                    onChanged: (value) {
                      setState(() {
                        selectedRate = value;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: selectedRate == null
                        ? null
                        : () async {
                      await _cleanupOldDataIfAny();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => USBDataApp(
                            baudRate: int.parse(selectedRate!),
                          ),
                        ),
                      );
                    },
                    child: const Text('Next'),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Note:',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Ensure your USB device is connected before proceeding.\n'
                        '• The baud rate must match your hardware specification. It is defined in your microcontroller code.(example:Serial.begin(baudrate))\n'
                        '• Incorrect baud rate may result in unreadable data.\n'
                        '• Once, you entered the display page, you can\'t return to the previous page (this page) because of state management and security.\n'
                    '• So make sure All these points were correctly followed.\n'
                    ,
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
    ]
            )
          )
        ),
      ),
    );
  }
}

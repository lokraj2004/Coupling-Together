import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SerialInputWidget extends StatefulWidget {
  const SerialInputWidget({Key? key}) : super(key: key);

  @override
  State<SerialInputWidget> createState() => _SerialInputWidgetState();
}

class _SerialInputWidgetState extends State<SerialInputWidget> {
  final TextEditingController _controller = TextEditingController();
  static const platform = MethodChannel('usb_data_channel');

  void _sendSerialCommand(String command) async {
    if (command.trim().isEmpty) return;

    try {
      await platform.invokeMethod('sendSerial', command);
      debugPrint("📤 Sent to Serial: $command");
    } catch (e) {
      debugPrint("❌ Failed to send serial input: $e");
    }

    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: Colors.grey[200],
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: "Enter serial command",
                border: OutlineInputBorder(),
              ),
              onSubmitted: _sendSerialCommand,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () => _sendSerialCommand(_controller.text),
          ),
        ],
      ),
    );
  }
}
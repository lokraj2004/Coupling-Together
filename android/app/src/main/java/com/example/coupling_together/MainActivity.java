package com.example.coupling_together;

import com.example.coupling_together.AdminKeyHandler;
import java.nio.charset.StandardCharsets;
import android.app.PendingIntent;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.hardware.usb.UsbDevice;
import android.hardware.usb.UsbManager;
import android.os.Bundle;
import android.util.Log;
import com.example.coupling_together.USBHelper;

import androidx.annotation.NonNull;
import java.util.Map;
import java.util.HashMap;

import java.io.IOException;
import java.util.List;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

import com.hoho.android.usbserial.driver.UsbSerialDriver;
import com.hoho.android.usbserial.driver.UsbSerialPort;
import com.hoho.android.usbserial.driver.UsbSerialProber;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "usb_data_channel";
    private static final String ACTION_USB_PERMISSION = "com.example.coupling_together.USB_PERMISSION";

    private MethodChannel channel;
    private UsbSerialPort serialPort;
    private UsbManager manager;
    private UsbSerialDriver driver;

    // 📍 Baud rate received from Flutter
    private int selectedBaudRate = 9600;

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        manager = (UsbManager) getSystemService(USB_SERVICE);

        // Register USB permission broadcast receiver
        IntentFilter filter = new IntentFilter(ACTION_USB_PERMISSION);
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(usbReceiver, filter, Context.RECEIVER_NOT_EXPORTED);
        } else {
            registerReceiver(usbReceiver, filter);
        }

        channel = new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL);

        channel.setMethodCallHandler((call, result) -> {
            switch (call.method) {
                case "setBaudRate":  // 📍 Set baud rate from Flutter
                    try {
                        selectedBaudRate = call.arguments instanceof Integer ? (int) call.arguments : 9600;
                        Log.d("USB", "📥 Received baud rate: " + selectedBaudRate);
                        result.success("Baud rate set to " + selectedBaudRate);
                    } catch (Exception e) {
                        Log.e("USB", "❌ Failed to set baud rate", e);
                        result.error("SET_BAUD_ERROR", "Invalid baud rate", null);
                    }
                    break;
                case "startUSB":
                    requestUSBPermission();
                    result.success("USB permission requested");
                    break;
                case "sendSerial":
                    String message = call.arguments.toString(); // safer than (String)
                    if (serialPort != null) {
                        try {
                            // Append newline only if needed by your microcontroller
                            byte[] buffer = (message + "\n").getBytes(StandardCharsets.UTF_8);
                            serialPort.write(buffer, 1000);
                            result.success("✅ Sent: " + message);
                        } catch (IOException e) {
                            e.printStackTrace();
                            result.error("WRITE_ERROR", "Failed to write to serial port", e.getMessage());
                        }
                    } else {
                        result.error("NO_PORT", "Serial port is not open", null);
                    }
                    break;
                case "getUSBDeviceInfo":
                    Map<String, Object> usbInfo = USBHelper.getUSBDeviceInfo(this);
                    if (usbInfo == null || usbInfo.isEmpty()) {
                        result.error("NO_USB", "No USB devices found", null);
                    } else {
                        result.success(usbInfo);
                    }
                    break;
                default:
                    result.notImplemented();
                    break;
            }
        });
        AdminKeyHandler.register(flutterEngine);
    }

    private void requestUSBPermission() {

        List<UsbSerialDriver> availableDrivers = UsbSerialProber.getDefaultProber().findAllDrivers(manager);

        if (availableDrivers.isEmpty()) return;

        driver = availableDrivers.get(0);
        UsbDevice device = driver.getDevice();
        if (!manager.hasPermission(device)) {
            Log.d("USB", "Requesting permission...");
            PendingIntent permissionIntent = PendingIntent.getBroadcast(
                    this, 0, new Intent(ACTION_USB_PERMISSION), PendingIntent.FLAG_IMMUTABLE);
            manager.requestPermission(device, permissionIntent);
            runOnUiThread(() -> channel.invokeMethod("logMessage", "✅ Granted USB"));
        } else {
            runOnUiThread(() -> channel.invokeMethod("logMessage", "✅ Permission already granted."));
            Log.d("USB", "Permission already granted.");
            openSerialPort();
        }
    }


    private final BroadcastReceiver usbReceiver = new BroadcastReceiver() {
        public void onReceive(Context context, Intent intent) {
            if (intent.getAction().equals(ACTION_USB_PERMISSION)) {
                synchronized (this) {
                    UsbDevice device = intent.getParcelableExtra(UsbManager.EXTRA_DEVICE);
                    if (intent.getBooleanExtra(UsbManager.EXTRA_PERMISSION_GRANTED, false)) {
                        openSerialPort();
                        Log.d("USB", "🚀 Trying to open serial port for: " + driver.getDevice().getDeviceName());
                    } else {
                        Log.d("USB", "Permission denied for device");
                        runOnUiThread(() -> channel.invokeMethod("logMessage", "Permission denied"));
                    }
                }
            }
        }
    };


    private void openSerialPort() {
        try {
            Log.d("USB", "🔁 Opening serial port...");
            serialPort = driver.getPorts().get(0); // Most devices have only one port
            Log.d("USB", "🔌 Port selected.");
            runOnUiThread(() -> channel.invokeMethod("logMessage", "✅ Serial started"));

            serialPort.open(manager.openDevice(driver.getDevice()));
            serialPort.setParameters(selectedBaudRate, 8, UsbSerialPort.STOPBITS_1, UsbSerialPort.PARITY_NONE);

            Log.d("USB", "✅ Serial port opened successfully");
            runOnUiThread(() -> channel.invokeMethod("logMessage", "✅ Serial started successfully"));

            new Thread(() -> {
                byte[] buffer = new byte[64];
                StringBuilder incomingLine = new StringBuilder();

                while (true) {
                    try {
                        int len = serialPort.read(buffer, 1000);
                        if (len > 0) {
                            String chunk = new String(buffer, 0, len);
                            incomingLine.append(chunk);

                            int newlineIndex;
                            while ((newlineIndex = incomingLine.indexOf("\n")) != -1) {
                                // Extract full line and remove from buffer
                                String fullLine = incomingLine.substring(0, newlineIndex).trim();
                                incomingLine.delete(0, newlineIndex + 1);

                                Log.d("USB", "📩 Full line: " + fullLine);

                                // Updated logic for 4-part data split by ;
                                String[] parts = fullLine.split(";");
                                if (parts.length == 4) {
                                    try {
                                        String name = parts[0].trim();
                                        float value = Float.parseFloat(parts[1].trim());
                                        String unit = parts[2].trim();
                                        int sensorId = Integer.parseInt(parts[3].trim());

                                        String json = "{"
                                                + "\"name\":\"" + name + "\","
                                                + "\"value\":" + value + ","
                                                + "\"unit\":\"" + unit + "\","
                                                + "\"id\":" + sensorId
                                                + "}";

                                        Log.d("USB", "📡 Sending to Flutter: " + json);
                                        runOnUiThread(() -> channel.invokeMethod("newData", json));
                                    } catch (Exception e) {
                                        Log.e("USB", "❌ Parse error: " + fullLine, e);
                                        runOnUiThread(() -> channel.invokeMethod("logMessage", "❌ Parse error in: " + fullLine));
                                    }
                                } else {
                                    Log.e("USB", "❌ Malformed data (split != 4): " + fullLine);
                                    runOnUiThread(() -> channel.invokeMethod("logMessage", "❌ Invalid format received: " + fullLine));
                                }
                            }
                        }
                    } catch (IOException e) {
                        Log.e("USB", "❌ Read error", e);
                        runOnUiThread(() -> channel.invokeMethod("logMessage", "❌ Read error"));
                        break;
                    }
                }
            }).start();

        } catch (IOException e) {
            Log.e("USB", "❌ Error opening port", e);
        }
    }
}

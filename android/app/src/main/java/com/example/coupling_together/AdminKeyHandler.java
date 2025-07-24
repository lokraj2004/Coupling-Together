package com.example.coupling_together;


import android.util.Log;

import androidx.annotation.NonNull;

import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
public class AdminKeyHandler {

    private static final String CHANNEL_NAME = "admin_data_channel";
    private static final String ADMIN_KEY = "admin_Lokesh_key_40021152";

    public static void register(@NonNull FlutterEngine flutterEngine) {
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL_NAME)
                .setMethodCallHandler((call, result) -> {
                    if (call.method.equals("getAdminKey")) {
                        Log.d("AdminKeyHandler", "🔐 Admin key requested.");
                        result.success(ADMIN_KEY);
                    } else {
                        result.notImplemented();
                    }
                });
    }








}

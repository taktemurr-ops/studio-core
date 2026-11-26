package com.gamestudio100.studio_samsung;

import android.content.Context;

import androidx.annotation.NonNull;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

/** Samsung IAP SDK olmadan derleme: satın alma kullanılamaz. */
class SamsungIap implements MethodChannel.MethodCallHandler {
    SamsungIap(Context context, MethodChannel channel) {}

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        switch (call.method) {
            case "init": {
                Map<String, Object> m = new HashMap<>();
                m.put("available", false);
                m.put("products", new ArrayList<Object>());
                m.put("sdk", false);
                result.success(m);
                break;
            }
            case "buy":
                result.success(false);
                break;
            case "restore":
            case "finish":
                result.success(null);
                break;
            default:
                result.notImplemented();
        }
    }
}

package com.gamestudio100.studio_samsung;

import androidx.annotation.NonNull;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodChannel;

/** Kanal kaydı; asıl iş SamsungIap (SDK ya da stub kaynak kümesi). */
public class StudioSamsungPlugin implements FlutterPlugin {
    private MethodChannel channel;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        channel = new MethodChannel(binding.getBinaryMessenger(), "studio_samsung/iap");
        channel.setMethodCallHandler(new SamsungIap(binding.getApplicationContext(), channel));
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
        channel = null;
    }
}

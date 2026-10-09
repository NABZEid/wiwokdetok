package com.example.autoclicker

import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "autoclicker")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isEnabled" -> result.success(ClickService.instance != null)
                    "isRunning" -> result.success(ClickService.instance?.running == true)
                    "openSettings" -> {
                        startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
                        result.success(null)
                    }
                    "start" -> {
                        val s = ClickService.instance
                        if (s == null) {
                            result.success(false)
                        } else {
                            val x = (call.argument<Double>("x") ?: 500.0).toFloat()
                            val y = (call.argument<Double>("y") ?: 1000.0).toFloat()
                            val interval = (call.argument<Int>("interval") ?: 1000).toLong()
                            val max = call.argument<Int>("max") ?: 0
                            s.startClicking(x, y, interval, max)
                            result.success(true)
                        }
                    }
                    "stop" -> {
                        ClickService.instance?.stopClicking()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}

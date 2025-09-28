package com.example.test_athkar_app

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel

class MainActivity: FlutterActivity() {
    private val DND_CHANNEL = "com.athkar.app/do_not_disturb"
    private val DND_EVENTS_CHANNEL = "com.athkar.app/do_not_disturb_events"
    private val BATTERY_CHANNEL = "com.athkar.app/battery_optimization"
    private var doNotDisturbHandler: DoNotDisturbHandler? = null
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        doNotDisturbHandler = DoNotDisturbHandler(applicationContext)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DND_CHANNEL)
            .setMethodCallHandler(doNotDisturbHandler)
        
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, DND_EVENTS_CHANNEL)
            .setStreamHandler(doNotDisturbHandler?.getDndStreamHandler())
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BATTERY_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isBatteryOptimizationEnabled" -> {
                        result.success(isBatteryOptimizationEnabled())
                    }
                    "requestBatteryOptimizationDisable" -> {
                        result.success(requestBatteryOptimizationDisable())
                    }
                    else -> result.notImplemented()
                }
            }
        
        doNotDisturbHandler?.configureNotificationChannelsForDoNotDisturb()
    }
    
    override fun onResume() {
        super.onResume()
        doNotDisturbHandler?.notifyDndStatusChange()
    }
    
    private fun isBatteryOptimizationEnabled(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
            return !powerManager.isIgnoringBatteryOptimizations(packageName)
        }
        return false
    }
    
    private fun requestBatteryOptimizationDisable(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val intent = Intent().apply {
                action = Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS
                data = Uri.parse("package:$packageName")
            }
            
            return try {
                startActivity(intent)
                true
            } catch (e: Exception) {
                false
            }
        }
        return false
    }
}
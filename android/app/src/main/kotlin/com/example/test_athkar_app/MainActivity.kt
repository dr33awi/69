// android/app/src/main/kotlin/com/example/test_athkar_app/MainActivity.kt
package com.dhakarani.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.os.Build
import android.os.Bundle
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import android.util.Log

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.dhakarani.app/permissions"
    private val TAG = "MainActivity"
    private val NOTIFICATION_PERMISSION_CODE = 1001
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getAndroidVersion" -> {
                    result.success(Build.VERSION.SDK_INT)
                }
                "requestNotificationPermission" -> {
                    requestNotificationPermission(result)
                }
                "checkNotificationPermission" -> {
                    checkNotificationPermission(result)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    private fun requestNotificationPermission(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            when {
                ContextCompat.checkSelfPermission(
                    this,
                    android.Manifest.permission.POST_NOTIFICATIONS
                ) == PackageManager.PERMISSION_GRANTED -> {
                    Log.d(TAG, "Notification permission already granted")
                    result.success(true)
                }
                ActivityCompat.shouldShowRequestPermissionRationale(
                    this,
                    android.Manifest.permission.POST_NOTIFICATIONS
                ) -> {
                    Log.d(TAG, "Should show notification permission rationale")
                    // Request the permission
                    ActivityCompat.requestPermissions(
                        this,
                        arrayOf(android.Manifest.permission.POST_NOTIFICATIONS),
                        NOTIFICATION_PERMISSION_CODE
                    )
                    result.success(null) // Will be handled in onRequestPermissionsResult
                }
                else -> {
                    Log.d(TAG, "Requesting notification permission")
                    // Request the permission
                    ActivityCompat.requestPermissions(
                        this,
                        arrayOf(android.Manifest.permission.POST_NOTIFICATIONS),
                        NOTIFICATION_PERMISSION_CODE
                    )
                    result.success(null) // Will be handled in onRequestPermissionsResult
                }
            }
        } else {
            // For Android < 13, notifications are enabled by default
            Log.d(TAG, "Android < 13, notifications enabled by default")
            result.success(true)
        }
    }
    
    private fun checkNotificationPermission(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            val hasPermission = ContextCompat.checkSelfPermission(
                this,
                android.Manifest.permission.POST_NOTIFICATIONS
            ) == PackageManager.PERMISSION_GRANTED
            
            Log.d(TAG, "Notification permission check: $hasPermission")
            result.success(hasPermission)
        } else {
            // For Android < 13, check if notifications are enabled
            Log.d(TAG, "Android < 13, checking notification settings")
            result.success(true)
        }
    }
    
    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        
        if (requestCode == NOTIFICATION_PERMISSION_CODE) {
            val granted = grantResults.isNotEmpty() && 
                         grantResults[0] == PackageManager.PERMISSION_GRANTED
            
            Log.d(TAG, "Notification permission result: $granted")
            
            // You can send the result back to Flutter if needed
            // through an event channel or by calling a method
        }
    }
}
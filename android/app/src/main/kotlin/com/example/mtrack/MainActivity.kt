package com.example.mtrack

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.util.Log

class MainActivity: FlutterActivity() {
    private val CHANNEL = "sms_channel"
    private lateinit var smsHelper: SmsHelper

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Initialize SMS helper
        smsHelper = SmsHelper(this)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                
                "fetchSmsMessages" -> {
                    try {
                        val jsonResult = smsHelper.fetchSmsMessages()
                        result.success(jsonResult)
                    } catch (e: Exception) {
                        Log.e("MainActivity", "Error fetching SMS messages(mainactivity)", e)
                        result.error("SMS_ERROR", "Failed to fetch SMS messages(mainactivity)", e.message)
                    }
                }
                
                "fetchSmsMessagesSince" -> {
                    val sinceTimestamp = call.argument<Long>("sinceTimestamp") ?: 0L
                    
                    try {
                        val jsonResult = smsHelper.fetchSmsMessagesSince(sinceTimestamp)
                        result.success(jsonResult)
                    } catch (e: Exception) {
                        Log.e("MainActivity", "Error fetching SMS messages since timestamp", e)
                        result.error("SMS_ERROR", "Failed to fetch SMS messages since timestamp", e.message)
                    }
                }
                
                "getSmsCount" -> {
                    try {
                        val count = smsHelper.getSmsCount()
                        result.success(count)
                    } catch (e: Exception) {
                        Log.e("MainActivity", "Error getting SMS count", e)
                        result.error("SMS_ERROR", "Failed to get SMS count", e.message)
                    }
                }
                
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}

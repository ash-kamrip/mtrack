package com.example.mtrack

import android.Manifest
import android.content.ContentResolver
import android.content.Context
import android.content.pm.PackageManager
import android.database.Cursor
import android.net.Uri
import android.provider.Telephony
import android.util.Log
import androidx.core.app.ActivityCompat
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.*

class SmsHelper(private val context: Context) {
    
    companion object {
        private const val TAG = "SmsHelper"
        private const val SMS_PERMISSION = Manifest.permission.READ_SMS
    }
    
    /**
     * Fetch SMS messages
     * @return JSON string containing SMS messages
     */
    fun fetchSmsMessages(): String {
        try {
            val contentResolver: ContentResolver = context.contentResolver
            val uri: Uri = Telephony.Sms.CONTENT_URI
            
            // Define the columns we want to retrieve
            val projection = arrayOf(
                Telephony.Sms._ID,
                Telephony.Sms.ADDRESS,
                Telephony.Sms.BODY,
                Telephony.Sms.DATE,
                Telephony.Sms.TYPE,
                Telephony.Sms.READ
            )
            
            // Sort by date descending (newest first)
            val sortOrder = "${Telephony.Sms.DATE} DESC"
            
            val cursor: Cursor? = contentResolver.query(
                uri,
                projection,
                null,
                null,
                sortOrder
            )
            
            val messages = JSONArray()
            var count = 0
            var totalCount = 0
            
            cursor?.use { 
                totalCount = cursor.count
                Log.d(TAG, "Total SMS messages found: $totalCount")
                
                while (cursor.moveToNext()) {
                    val message = JSONObject()
                    
                    val id = cursor.getLong(cursor.getColumnIndexOrThrow(Telephony.Sms._ID))
                    val address = cursor.getString(cursor.getColumnIndexOrThrow(Telephony.Sms.ADDRESS)) ?: ""
                    val body = cursor.getString(cursor.getColumnIndexOrThrow(Telephony.Sms.BODY)) ?: ""
                    val date = cursor.getLong(cursor.getColumnIndexOrThrow(Telephony.Sms.DATE))
                    val type = cursor.getInt(cursor.getColumnIndexOrThrow(Telephony.Sms.TYPE))
                    val read = cursor.getInt(cursor.getColumnIndexOrThrow(Telephony.Sms.READ))
                    
                    message.put("id", id)
                    message.put("address", address)
                    message.put("body", body)
                    message.put("date", date)
                    message.put("type", type)
                    message.put("read", read)
                    
                    messages.put(message)
                    count++
                    
                    // Log first 5 messages for debugging
                    // if (count <= 5) {
                    //     Log.d(TAG, "SMS Message $count:")
                    //     Log.d(TAG, "  ID: $id")
                    //     Log.d(TAG, "  Address: $address")
                    //     Log.d(TAG, "  Body: ${body.take(100)}${if (body.length > 100) "..." else ""}")
                    //     Log.d(TAG, "  Date: $date")
                    //     Log.d(TAG, "  Type: $type")
                    //     Log.d(TAG, "  Read: $read")
                    //     Log.d(TAG, "  ---")
                    // }
                }
            }
            
            val result = JSONObject()
            result.put("success", true)
            result.put("messages", messages)
            result.put("count", count)
            result.put("total", totalCount)
            
            return result.toString()
            
        } catch (e: Exception) {
            Log.e(TAG, "Error fetching SMS messages", e)
            return createErrorResponse("Error fetching SMS: ${e.message}")
        }
    }
    
    /**
     * Fetch SMS messages since a specific timestamp
     * @param sinceTimestamp Timestamp in milliseconds
     * @return JSON string containing SMS messages
     */
    fun fetchSmsMessagesSince(sinceTimestamp: Long): String {
        
        try {
            val contentResolver: ContentResolver = context.contentResolver
            val uri: Uri = Telephony.Sms.CONTENT_URI
            
            val projection = arrayOf(
                Telephony.Sms._ID,
                Telephony.Sms.ADDRESS,
                Telephony.Sms.BODY,
                Telephony.Sms.DATE,
                Telephony.Sms.TYPE,
                Telephony.Sms.READ
            )
            
            // Filter messages since the given timestamp
            val selection = "${Telephony.Sms.DATE} > ?"
            val selectionArgs = arrayOf(sinceTimestamp.toString())
            val sortOrder = "${Telephony.Sms.DATE} DESC"
            
            val cursor: Cursor? = contentResolver.query(
                uri,
                projection,
                selection,
                selectionArgs,
                sortOrder
            )
            
            val messages = JSONArray()
            var count = 0
            
            cursor?.use { 
                while (cursor.moveToNext()) {
                    val message = JSONObject()
                    
                    message.put("id", cursor.getLong(cursor.getColumnIndexOrThrow(Telephony.Sms._ID)))
                    message.put("address", cursor.getString(cursor.getColumnIndexOrThrow(Telephony.Sms.ADDRESS)) ?: "")
                    message.put("body", cursor.getString(cursor.getColumnIndexOrThrow(Telephony.Sms.BODY)) ?: "")
                    message.put("date", cursor.getLong(cursor.getColumnIndexOrThrow(Telephony.Sms.DATE)))
                    message.put("type", cursor.getInt(cursor.getColumnIndexOrThrow(Telephony.Sms.TYPE)))
                    message.put("read", cursor.getInt(cursor.getColumnIndexOrThrow(Telephony.Sms.READ)))
                    
                    messages.put(message)
                    count++
                }
            }
            
            val result = JSONObject()
            result.put("success", true)
            result.put("messages", messages)
            result.put("count", count)
            result.put("since", sinceTimestamp)
            
            Log.d(TAG, "Fetched $count SMS messages since $sinceTimestamp")
            return result.toString()
            
        } catch (e: Exception) {
            Log.e(TAG, "Error fetching SMS messages since timestamp", e)
            return createErrorResponse("Error fetching SMS: ${e.message}")
        }
    }
    /**
     * Get total count of SMS messages
     * @return Total count of SMS messages
     */
    fun getSmsCount(): Int {
        
        try {
            val contentResolver: ContentResolver = context.contentResolver
            val uri: Uri = Telephony.Sms.CONTENT_URI
            
            val cursor: Cursor? = contentResolver.query(
                uri,
                arrayOf("COUNT(*)"),
                null,
                null,
                null
            )
            
            cursor?.use { 
                if (cursor.moveToFirst()) {
                    return cursor.getInt(0)
                }
            }
            
            return 0
        } catch (e: Exception) {
            Log.e(TAG, "Error getting SMS count", e)
            return 0
        }
    }
    
    private fun createErrorResponse(error: String): String {
        val result = JSONObject()
        result.put("success", false)
        result.put("error", error)
        return result.toString()
    }
} 
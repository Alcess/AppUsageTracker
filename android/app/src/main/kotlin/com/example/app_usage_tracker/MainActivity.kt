package com.example.app_usage_tracker

import android.app.AppOpsManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.admin.DevicePolicyManager
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.graphics.PixelFormat
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.WindowManager
import android.widget.TextView
import androidx.annotation.NonNull
import androidx.core.app.NotificationCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "app_usage_tracker/usage_access"
    private val PERMISSION_CHANNEL = "app_usage_tracker/permissions"
    private val SCREEN_LOCK_CHANNEL = "app_usage_tracker/screen_lock"
    private val SYSTEM_OVERLAY_CHANNEL = "app_usage_tracker/system_overlay"

    // Removed lifecycle cleanup to make lock persistent
    
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Original usage access channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call: MethodCall, result: MethodChannel.Result ->
                when (call.method) {
                    "hasUsageAccess" -> result.success(hasUsageAccess())
                    "requestUsageAccess" -> {
                        requestUsageAccess()
                        result.success(true)
                    }
                    "getTodayUsage" -> result.success(getTodayUsage())
                    "getUsage" -> {
                        val start = (call.argument<Number>("start")?.toLong()) ?: 0L
                        val end = (call.argument<Number>("end")?.toLong()) ?: System.currentTimeMillis()
                        val includeSystemApps = call.argument<Boolean>("includeSystemApps") ?: false
                        result.success(getUsage(start, end, includeSystemApps))
                    }
                    else -> result.notImplemented()
                }
            }

        // New permission handling channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PERMISSION_CHANNEL)
            .setMethodCallHandler { call: MethodCall, result: MethodChannel.Result ->
                when (call.method) {
                    "hasSystemAlertWindowPermission" -> result.success(hasSystemAlertWindowPermission())
                    "requestSystemAlertWindowPermission" -> {
                        requestSystemAlertWindowPermission()
                        result.success(true)
                    }
                    "hasAccessNotificationPolicyPermission" -> result.success(hasAccessNotificationPolicyPermission())
                    "requestAccessNotificationPolicyPermission" -> {
                        requestAccessNotificationPolicyPermission()
                        result.success(true)
                    }
                    "hasBatteryOptimizationExemption" -> result.success(hasBatteryOptimizationExemption())
                    "requestBatteryOptimizationExemption" -> {
                        requestBatteryOptimizationExemption()
                        result.success(true)
                    }
                    "requestIgnoreBatteryOptimizations" -> {
                        requestIgnoreBatteryOptimizations()
                        result.success(true)
                    }
                    "openAutoStartSettings" -> {
                        openAutoStartSettings()
                        result.success(true)
                    }
                    "openAppSettings" -> {
                        openAppSettings()
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }

        // Screen lock service channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SCREEN_LOCK_CHANNEL)
            .setMethodCallHandler { call: MethodCall, result: MethodChannel.Result ->
                when (call.method) {
                    "lockScreen" -> {
                        val success = lockScreen()
                        result.success(success)
                    }
                    "isDeviceAdminEnabled" -> result.success(false) // Simplified for now
                    "requestDeviceAdmin" -> {
                        // For now, just show notification instead of device admin
                        result.success(true)
                    }
                    "showBlockingNotification" -> {
                        val title = call.argument<String>("title") ?: "App Blocked"
                        val message = call.argument<String>("message") ?: "This app is blocked"
                        val appName = call.argument<String>("appName") ?: "Unknown App"
                        showBlockingNotification(title, message, appName)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }

        // System overlay channel for blocking other apps
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SYSTEM_OVERLAY_CHANNEL)
            .setMethodCallHandler { call: MethodCall, result: MethodChannel.Result ->
                when (call.method) {
                    "showSystemOverlay" -> {
                        val appName = call.argument<String>("appName") ?: "Unknown App"
                        val title = call.argument<String>("title") ?: "App Locked"
                        val message = call.argument<String>("message") ?: "This app is blocked"
                        val success = showSystemOverlay(appName, title, message)
                        result.success(success)
                    }
                    "hideSystemOverlay" -> {
                        hideSystemOverlay()
                        result.success(true)
                    }
                    "hasOverlayPermission" -> result.success(hasSystemAlertWindowPermission())
                    "requestOverlayPermission" -> {
                        requestSystemAlertWindowPermission()
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun hasUsageAccess(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(),
                packageName
            )
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(),
                packageName
            )
        }
        if (mode == AppOpsManager.MODE_ALLOWED) return true

        val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val end = System.currentTimeMillis()
        val start = end - 60_000
        val stats = usm.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, start, end)
        return stats != null && stats.isNotEmpty()
    }

    private fun requestUsageAccess() {
        try {
            val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
        } catch (_: Exception) {
        }
    }

    private fun startOfDayMillis(): Long {
        val cal = java.util.Calendar.getInstance()
        cal.set(java.util.Calendar.HOUR_OF_DAY, 0)
        cal.set(java.util.Calendar.MINUTE, 0)
        cal.set(java.util.Calendar.SECOND, 0)
        cal.set(java.util.Calendar.MILLISECOND, 0)
        return cal.timeInMillis
    }

    private fun computeLaunchCounts(start: Long, end: Long): Map<String, Int> {
        val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val events = usm.queryEvents(start, end)
        val counts = HashMap<String, Int>()
        val event = UsageEvents.Event()
        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            val type = event.eventType
            if (type == UsageEvents.Event.MOVE_TO_FOREGROUND ||
                (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q && type == UsageEvents.Event.ACTIVITY_RESUMED)
            ) {
                val pkg = event.packageName ?: continue
                counts[pkg] = (counts[pkg] ?: 0) + 1
            }
        }
        return counts
    }

    private fun getTodayUsage(): List<Map<String, Any>> {
        val start = startOfDayMillis()
        val end = System.currentTimeMillis()
        return getUsage(start, end, includeSystemApps = true)
    }

    private fun getUsage(start: Long, end: Long, includeSystemApps: Boolean): List<Map<String, Any>> {
        val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val pm = packageManager

        // Aggregate foreground time per package across the window
        val fgByPkg = HashMap<String, Long>()
        val stats = usm.queryUsageStats(UsageStatsManager.INTERVAL_BEST, start, end) ?: emptyList()
        for (s in stats) {
            val pkg = s.packageName ?: continue
            val curr = fgByPkg[pkg] ?: 0L
            fgByPkg[pkg] = curr + s.totalTimeInForeground
        }

        // Compute launch counts via events
        val launchCounts = computeLaunchCounts(start, end)

        val list = ArrayList<Map<String, Any>>()
        for ((pkg, fgMillis) in fgByPkg) {
            if (pkg == packageName) continue

            var appName = pkg
            var isSystem = false
            try {
                val ai = pm.getApplicationInfo(pkg, 0)
                appName = pm.getApplicationLabel(ai).toString()
                isSystem = (ai.flags and android.content.pm.ApplicationInfo.FLAG_SYSTEM) != 0 ||
                        (ai.flags and android.content.pm.ApplicationInfo.FLAG_UPDATED_SYSTEM_APP) != 0
            } catch (_: Exception) { }

            if (!includeSystemApps && isSystem) continue

            val minutes = (fgMillis / 60000L).toInt()
            if (minutes <= 0) continue

            val launches = launchCounts[pkg] ?: 0

            list.add(
                mapOf(
                    "packageName" to pkg,
                    "appName" to appName,
                    "minutesUsed" to minutes,
                    "launchCount" to launches
                )
            )
        }
        list.sortByDescending { (it["minutesUsed"] as Int?) ?: 0 }
        return list
    }

    // New permission methods
    private fun hasSystemAlertWindowPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(this)
        } else {
            true // Not required on older versions
        }
    }

    private fun requestSystemAlertWindowPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            try {
                val intent = Intent(
                    Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                    Uri.parse("package:$packageName")
                )
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(intent)
            } catch (e: Exception) {
                // Fallback to general settings
                openAppSettings()
            }
        }
    }

    private fun hasAccessNotificationPolicyPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.isNotificationPolicyAccessGranted
        } else {
            true // Not required on older versions
        }
    }

    private fun requestAccessNotificationPolicyPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            try {
                val intent = Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS)
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(intent)
            } catch (e: Exception) {
                // Fallback to general settings
                openAppSettings()
            }
        }
    }

    private fun openAppSettings() {
        try {
            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
            intent.data = Uri.parse("package:$packageName")
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
        } catch (e: Exception) {
            // Final fallback to general settings
            val intent = Intent(Settings.ACTION_SETTINGS)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
        }
    }

    // Battery optimization methods
    private fun hasBatteryOptimizationExemption(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
            powerManager.isIgnoringBatteryOptimizations(packageName)
        } else {
            true // Not applicable on older versions
        }
    }

    private fun requestBatteryOptimizationExemption() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            try {
                // First try the direct permission prompt
                requestIgnoreBatteryOptimizations()
            } catch (e: Exception) {
                // Fallback to general battery optimization settings
                val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(intent)
            }
        }
    }

    private fun requestIgnoreBatteryOptimizations() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            try {
                val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
                intent.data = Uri.parse("package:$packageName")
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(intent)
            } catch (e: Exception) {
                // Final fallback to general battery settings
                openBatterySettings()
            }
        }
    }

    private fun openBatterySettings() {
        try {
            val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
        } catch (e: Exception) {
            openAppSettings()
        }
    }

    private fun openAutoStartSettings() {
        // Try different manufacturer-specific autostart settings
        val autoStartIntents = listOf(
            // Xiaomi/MIUI
            Intent().apply {
                component = android.content.ComponentName(
                    "com.miui.securitycenter",
                    "com.miui.permcenter.autostart.AutoStartManagementActivity"
                )
            },
            // Huawei
            Intent().apply {
                component = android.content.ComponentName(
                    "com.huawei.systemmanager",
                    "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity"
                )
            },
            // OnePlus
            Intent().apply {
                component = android.content.ComponentName(
                    "com.oneplus.security",
                    "com.oneplus.security.chainlaunch.view.ChainLaunchAppListActivity"
                )
            },
            // Oppo
            Intent().apply {
                component = android.content.ComponentName(
                    "com.coloros.safecenter",
                    "com.coloros.safecenter.permission.startup.FakeActivity"
                )
            },
            // Vivo
            Intent().apply {
                component = android.content.ComponentName(
                    "com.vivo.permissionmanager",
                    "com.vivo.permissionmanager.activity.BgStartUpManagerActivity"
                )
            }
        )

        var opened = false
        for (intent in autoStartIntents) {
            try {
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(intent)
                opened = true
                break
            } catch (e: Exception) {
                // Continue to next intent
            }
        }

        if (!opened) {
            // Fallback to general app settings
            openAppSettings()
        }
    }

    // Simple screen lock methods
    private fun lockScreen(): Boolean {
        return try {
            // Try to use device policy manager to lock screen
            val devicePolicyManager = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
            devicePolicyManager.lockNow()
            true
        } catch (e: Exception) {
            // If device admin not available, show blocking notification instead
            showBlockingNotification(
                "Device Locked", 
                "Device locked by parental control", 
                "Parental Control"
            )
            false
        }
    }

    private fun showBlockingNotification(title: String, message: String, appName: String) {
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        
        // Create notification channel for Android 8.0+
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "parental_control",
                "Parental Control",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Parental control notifications"
                setSound(null, null)
            }
            notificationManager.createNotificationChannel(channel)
        }

        // Create intent to open this app when notification is tapped
        val intent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this, 
            0, 
            intent, 
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Build notification
        val notification = NotificationCompat.Builder(this, "parental_control")
            .setSmallIcon(android.R.drawable.ic_lock_idle_lock)
            .setContentTitle(title)
            .setContentText(message)
            .setStyle(NotificationCompat.BigTextStyle().bigText(message))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(false)
            .setOngoing(true)
            .setContentIntent(pendingIntent)
            .build()

        // Show notification
        notificationManager.notify(appName.hashCode(), notification)
    }

    // System overlay methods for blocking other apps
    private var systemOverlayView: View? = null

    private fun showSystemOverlay(appName: String, title: String, message: String): Boolean {
        if (!hasSystemAlertWindowPermission()) {
            // Fallback to notification if no overlay permission
            showBlockingNotification(title, message, appName)
            return false
        }

        try {
            // Remove existing overlay if present
            hideSystemOverlay()

            // Get window manager
            val windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager

            // Create overlay view with solid black background
            val overlayView = TextView(this).apply {
                text = if (appName == "Device Locked") {
                    "🔒 Device Locked\n\nThis device is locked by your parent.\n\nPlease contact your parent for permission."
                } else {
                    "$title\n\n$message\n\nContact your parent for permission"
                }
                textSize = 20f
                setTextColor(android.graphics.Color.WHITE)
                setBackgroundColor(android.graphics.Color.BLACK) // Solid black background
                gravity = Gravity.CENTER
                setPadding(60, 60, 60, 60)
                // Remove click listener for production - no dismiss option
            }

            // Enhanced window parameters for MAXIMUM overlay coverage
            val params = WindowManager.LayoutParams(
                WindowManager.LayoutParams.MATCH_PARENT,
                WindowManager.LayoutParams.MATCH_PARENT,
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
                } else {
                    @Suppress("DEPRECATION")
                    WindowManager.LayoutParams.TYPE_SYSTEM_ALERT
                },
                // Flags for maximum coverage - block all interaction
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                WindowManager.LayoutParams.FLAG_LAYOUT_INSET_DECOR or
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON,
                PixelFormat.OPAQUE // Opaque for solid black
            )

            // Ensure overlay appears at top-most level
            params.gravity = Gravity.TOP or Gravity.LEFT
            params.x = 0
            params.y = 0
            
            // Highest possible window level
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                params.type = WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            } else {
                @Suppress("DEPRECATION")
                params.type = WindowManager.LayoutParams.TYPE_SYSTEM_OVERLAY
            }

            // Add overlay to window manager
            windowManager.addView(overlayView, params)
            systemOverlayView = overlayView

            return true
        } catch (e: Exception) {
            // Fallback to notification
            showBlockingNotification(title, message, appName)
            return false
        }
    }

    private fun hideSystemOverlay() {
        systemOverlayView?.let { view ->
            try {
                val windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
                windowManager.removeView(view)
            } catch (e: Exception) {
                // View might already be removed
            }
            systemOverlayView = null
        }
    }
}

package com.example.app_usage_tracker

import android.app.AppOpsManager
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "app_usage_tracker/usage_access"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

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
}

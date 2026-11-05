package com.Kairo.airreply.bridge

import android.content.ActivityNotFoundException
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import com.Kairo.airreply.apps.BackgroundRestrictions
import com.Kairo.airreply.apps.InstalledAppsRepository
import com.Kairo.airreply.notifications.AlertChannels
import com.Kairo.airreply.notifications.ListenerHealth
import com.Kairo.airreply.notifications.NotificationMirrorService
import com.Kairo.airreply.notifications.ReplyExecutor
import com.Kairo.airreply.sync.SyncController
import com.Kairo.airreply.sync.SyncPreferences
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

/** `com.airreply/methods`: the commands of the Dart `NotificationBridge`. Context-only, so it works in any engine. */
class NativeMethodHandler(private val context: Context) : MethodChannel.MethodCallHandler {

    private val preferences = SyncPreferences(context)
    private val apps = InstalledAppsRepository(context)
    private val replies = ReplyExecutor(context)
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "isNotificationAccessGranted" -> result.success(NotificationMirrorService.isAccessGranted(context))
                "openNotificationAccessSettings" -> {
                    openNotificationAccessSettings()
                    result.success(null)
                }
                "openBatteryOptimizationSettings" -> {
                    startActivity(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS))
                    result.success(null)
                }
                "getBackgroundRestrictions" -> result.success(BackgroundRestrictions.status(context))
                "openAutostartSettings" -> {
                    BackgroundRestrictions.openAutostart(context)
                    result.success(null)
                }
                "clearNativeData" -> {
                    preferences.clear()
                    result.success(null)
                }
                "openAppSettings" -> {
                    BackgroundRestrictions.openAppSettings(context)
                    result.success(null)
                }
                "requestListenerRebind" -> {
                    ListenerHealth.ensureBound(context)
                    result.success(null)
                }
                "getInstalledApps" -> io.execute {
                    val apps = runCatching { apps.launchableApps() }
                    mainHandler.post {
                        apps.fold(
                            onSuccess = { result.success(it) },
                            onFailure = { result.error("apps_failed", it.message, null) },
                        )
                    }
                }
                "getAppIcon" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName == null) {
                        result.error("bad_args", "packageName is required", null)
                    } else {
                        io.execute {
                            val icon = runCatching { apps.iconFor(packageName) }.getOrNull()
                            mainHandler.post { result.success(icon) }
                        }
                    }
                }
                "getAppFilter" -> result.success(preferences.filterAsMap())
                "setAppFilter" -> {
                    preferences.setFilter(
                        mode = call.argument<String>("mode") ?: "all",
                        packages = call.argument<List<String>>("packages").orEmpty(),
                    )
                    result.success(null)
                }
                "startSync" -> {
                    SyncController.enable(context, receiving = call.argument<Boolean>("receiving") == true)
                    result.success(null)
                }
                "isAppVisible" -> result.success(AppVisibility.visible)
                "getAlertChannel" -> {
                    val id = call.argument<String>("id")
                    if (id == null) result.error("bad_args", "id is required", null)
                    else result.success(AlertChannels.state(context, id))
                }
                "openAppNotificationSettings" -> {
                    AlertChannels.openAppSettings(context)
                    result.success(null)
                }
                "openAlertChannelSettings" -> {
                    val id = call.argument<String>("id")
                    if (id == null) result.error("bad_args", "id is required", null)
                    else {
                        AlertChannels.openSettings(context, id, appPage = call.argument<Boolean>("appPage") == true)
                        result.success(null)
                    }
                }
                "stopSync" -> {
                    // Answer first: when the headless engine itself asks to stop, disabling destroys that engine.
                    result.success(null)
                    mainHandler.post { SyncController.disable(context) }
                }
                "reloadSync" -> {
                    // Same reason as stopSync: the caller may be the engine being replaced.
                    result.success(null)
                    mainHandler.post { SyncController.reload(context) }
                }
                "getSyncStatus" -> result.success(SyncController.status(context))
                "sendReply" -> {
                    val key = call.argument<String>("key")
                    val text = call.argument<String>("text")
                    if (key == null || text == null) {
                        result.error("bad_args", "key and text are required", null)
                    } else {
                        result.success(replies.send(key, text).wire)
                    }
                }
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            result.error("native_error", e.message ?: e.javaClass.simpleName, null)
        }
    }

    /** Deep-links to AirReply's own toggle where the platform supports it (Android 11+). */
    private fun openNotificationAccessSettings() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val detail = Intent(Settings.ACTION_NOTIFICATION_LISTENER_DETAIL_SETTINGS).putExtra(
                Settings.EXTRA_NOTIFICATION_LISTENER_COMPONENT_NAME,
                ComponentName(context, NotificationMirrorService::class.java).flattenToString(),
            )
            if (startActivity(detail)) return
        }
        startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))
    }

    private fun startActivity(intent: Intent): Boolean = try {
        context.startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        true
    } catch (_: ActivityNotFoundException) {
        false
    }

    private companion object {
        /** Shared by every handler instance; the app list is the only slow call. */
        val io = Executors.newSingleThreadExecutor()
    }
}

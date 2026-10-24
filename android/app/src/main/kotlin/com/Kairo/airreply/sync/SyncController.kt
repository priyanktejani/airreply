package com.Kairo.airreply.sync

import android.content.Context
import android.util.Log
import com.Kairo.airreply.notifications.NotificationEvent
import com.Kairo.airreply.notifications.ListenerHealth
import com.Kairo.airreply.notifications.NotificationEventHub
import com.Kairo.airreply.notifications.NotificationMirrorService

/**
 * The one place that switches sharing on or off. The method channel, the notification's Pause action, the boot
 * receiver and the listener all go through here, so the preference, the foreground service and the headless engine
 * never disagree.
 */
object SyncController {
    private const val TAG = "AirReplySync"

    /**
     * From the UI (app in the foreground, so starting a foreground service is allowed). Restarts a running engine so
     * it loads the current set of pairs (e.g. right after pairing another device).
     */
    fun enable(context: Context) {
        SyncPreferences(context).syncEnabled = true
        SyncForegroundService.start(context)
        BackgroundSyncEngine.restart(context)
        ListenerHealth.ensureBound(context)
        publishState(context)
    }

    /** A pair was added or removed: restart the engine if sharing is on. */
    fun reload(context: Context) {
        if (!SyncPreferences(context).syncEnabled) return
        BackgroundSyncEngine.restart(context)
        publishState(context)
    }

    fun disable(context: Context) {
        SyncPreferences(context).syncEnabled = false
        SyncForegroundService.stop(context)
        BackgroundSyncEngine.stop()
        publishState(context)
    }

    /** After boot, process restart or listener rebind: bring sharing back if the person left it on. */
    fun resumeIfEnabled(context: Context) {
        if (!SyncPreferences(context).syncEnabled) return
        BackgroundSyncEngine.ensureStarted(context)
        try {
            SyncForegroundService.start(context)
        } catch (e: Exception) {
            // Android 12+ may refuse a foreground service started from the background. The listener binding still
            // keeps the process (and the engine) alive; the service comes back the next time the app is opened.
            Log.w(TAG, "Foreground service not started", e)
        }
        publishState(context)
    }

    fun status(context: Context): Map<String, Any> = mapOf(
        "enabled" to SyncPreferences(context).syncEnabled,
        "running" to BackgroundSyncEngine.isRunning,
        "listenerConnected" to NotificationMirrorService.isConnected,
    )

    fun publishState(context: Context) {
        NotificationEventHub.publish(NotificationEvent.SyncStateChanged(status(context)))
    }
}

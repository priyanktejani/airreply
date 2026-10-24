package com.Kairo.airreply.notifications

import android.content.ComponentName
import android.content.Context
import android.provider.Settings
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import com.Kairo.airreply.sync.SyncController
import com.Kairo.airreply.sync.SyncPreferences

/**
 * Sees every notification posted on the sender phone, even while the Flutter UI is closed.
 *
 * Responsibilities stay narrow: filter, cache the reply action, and publish an event. Encrypting and uploading
 * happen in the headless sync engine (see BackgroundSyncEngine), replying in [ReplyExecutor].
 */
class NotificationMirrorService : NotificationListenerService() {

    private lateinit var parser: NotificationParser
    private lateinit var preferences: SyncPreferences

    /** Last mirrored fingerprint per key: apps re-post unchanged notifications (re-sorts, silent updates). */
    private val lastFingerprints = object : LinkedHashMap<String, Int>(64, 0.75f, true) {
        override fun removeEldestEntry(eldest: MutableMap.MutableEntry<String, Int>?) = size > MAX_TRACKED
    }

    override fun onCreate() {
        super.onCreate()
        parser = NotificationParser(this)
        preferences = SyncPreferences(this)
    }

    override fun onListenerConnected() {
        isConnected = true
        Log.i(TAG, "Listener connected")
        // Notifications already in the status bar: make them answerable, but do not flood the receiver with them.
        try {
            for (sbn in activeNotifications.orEmpty()) {
                val captured = parser.parse(sbn) ?: continue
                cacheReplyAction(sbn)
                lastFingerprints[sbn.key] = captured.fingerprint
            }
        } catch (e: SecurityException) {
            Log.w(TAG, "Could not read active notifications", e)
        }
        SyncController.resumeIfEnabled(applicationContext)
        SyncController.publishState(applicationContext)
    }

    override fun onListenerDisconnected() {
        isConnected = false
        Log.w(TAG, "Listener disconnected; requesting rebind")
        NotificationActionCache.clear()
        SyncController.publishState(applicationContext)
        // Ask the system to bind us again (e.g. after the process was trimmed).
        requestRebind(ComponentName(this, NotificationMirrorService::class.java))
    }

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        val captured = parser.parse(sbn) ?: return
        if (!preferences.allows(captured.packageName)) return

        cacheReplyAction(sbn)

        val previous = lastFingerprints.put(sbn.key, captured.fingerprint)
        // Our own reply echoed back into the conversation, or nothing new: keep the action, skip the mirror.
        if (captured.isSelfMessage || previous == captured.fingerprint) return

        Log.d(TAG, "Captured ${captured.packageName} (reply=${captured.canReply})")
        NotificationEventHub.publish(NotificationEvent.Posted(captured))
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification) {
        NotificationActionCache.remove(sbn.key)
        // Only notifications we track can have been mirrored; anything else would be a pointless backend query.
        val tracked = lastFingerprints.remove(sbn.key) != null
        if (!tracked || !preferences.allows(sbn.packageName)) return
        NotificationEventHub.publish(NotificationEvent.Removed(sbn.key))
    }

    private fun cacheReplyAction(sbn: StatusBarNotification) {
        val action = parser.replyAction(sbn.notification)
        if (action != null) NotificationActionCache.put(sbn.key, action) else NotificationActionCache.remove(sbn.key)
    }

    companion object {
        private const val TAG = "AirReplyListener"
        private const val MAX_TRACKED = 256

        @Volatile
        var isConnected = false
            private set

        /** Whether the person granted Notification access to this app. */
        fun isAccessGranted(context: Context): Boolean {
            val enabled = Settings.Secure.getString(context.contentResolver, "enabled_notification_listeners")
                ?: return false
            val self = ComponentName(context, NotificationMirrorService::class.java)
            return enabled.split(':').any { ComponentName.unflattenFromString(it) == self }
        }
    }
}

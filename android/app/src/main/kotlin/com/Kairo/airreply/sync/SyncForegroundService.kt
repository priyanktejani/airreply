package com.Kairo.airreply.sync

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.graphics.drawable.Icon
import android.os.Build
import android.os.IBinder
import com.Kairo.airreply.R

/**
 * Android 14+ compliant foreground service (type `remoteMessaging`) that keeps the sender's sync engine alive and
 * shows the persistent "Notification Sync Active" notification with a Pause action.
 */
class SyncForegroundService : Service() {

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // A service started with startForegroundService must call startForeground, even if it stops right away.
        startInForeground()

        if (intent?.action == ACTION_PAUSE || !SyncPreferences(this).syncEnabled) {
            SyncController.disable(applicationContext)
            return START_NOT_STICKY
        }
        BackgroundSyncEngine.ensureStarted(applicationContext)
        SyncController.publishState(applicationContext)
        return START_STICKY
    }

    override fun onDestroy() {
        SyncController.publishState(applicationContext)
        super.onDestroy()
    }

    private fun startInForeground() {
        ensureChannel()
        val notification = buildNotification()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_REMOTE_MESSAGING)
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    private val receiving: Boolean get() = SyncPreferences(this).receiving

    private fun buildNotification(): Notification {
        val openApp = packageManager.getLaunchIntentForPackage(packageName)?.let {
            PendingIntent.getActivity(this, 0, it, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
        }
        val pause = PendingIntent.getService(
            this,
            1,
            Intent(this, SyncForegroundService::class.java).setAction(ACTION_PAUSE),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        return Notification.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_stat_air_reply)
            .setColor(getColor(R.color.accent))
            .setContentTitle(getString(if (receiving) R.string.receive_notification_title else R.string.sync_notification_title))
            .setContentText(getString(if (receiving) R.string.receive_notification_text else R.string.sync_notification_text))
            .setCategory(Notification.CATEGORY_SERVICE)
            .setOngoing(true)
            .setShowWhen(false)
            .setContentIntent(openApp)
            .addAction(
                Notification.Action.Builder(
                    Icon.createWithResource(this, android.R.drawable.ic_media_pause),
                    getString(R.string.sync_pause),
                    pause,
                ).build(),
            )
            .apply {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    setForegroundServiceBehavior(Notification.FOREGROUND_SERVICE_IMMEDIATE)
                }
            }
            .build()
    }

    private fun ensureChannel() {
        val manager = getSystemService(NotificationManager::class.java)
        // Created every time: Android keeps the user's settings and only updates the name and description, so they
        // follow the phone's language.
        manager.createNotificationChannel(
            NotificationChannel(CHANNEL_ID, getString(R.string.sync_channel_name), NotificationManager.IMPORTANCE_LOW).apply {
                description = getString(R.string.sync_channel_description)
                setShowBadge(false)
            },
        )
    }

    companion object {
        private const val CHANNEL_ID = "air_reply_sync"
        private const val NOTIFICATION_ID = 4201
        private const val ACTION_PAUSE = "com.Kairo.airreply.action.PAUSE"

        fun start(context: Context) {
            context.startForegroundService(Intent(context, SyncForegroundService::class.java))
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, SyncForegroundService::class.java))
        }
    }
}

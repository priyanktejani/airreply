package com.Kairo.airreply.notifications

import android.app.NotificationManager
import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings

/**
 * What the system really does with an alert channel. The app asks for a pop-up (high importance) with sound, but the
 * person, or a phone maker's notification manager (OnePlus/OPPO hold back new apps' pop-ups and sounds), can lower
 * it; no app can raise it again, only the person, in the channel's settings.
 */
object AlertChannels {
    /** `shown` / `popsUp` / `sounds` for channel [id]; null while the channel does not exist yet. */
    fun state(context: Context, id: String): Map<String, Boolean>? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return mapOf("shown" to true, "popsUp" to true, "sounds" to true)
        val manager = context.getSystemService(NotificationManager::class.java)
        if (!manager.areNotificationsEnabled()) return mapOf("shown" to false, "popsUp" to false, "sounds" to false)
        val channel = manager.getNotificationChannel(id) ?: return null
        // The channel alone decides. (The app-wide `NotificationManager.importance` is no guide: since Android 13 it
        // reads "default" for every app allowed to notify, WhatsApp included; blocked is caught just above.)
        val importance = channel.importance
        return mapOf(
            "shown" to (importance > NotificationManager.IMPORTANCE_NONE),
            "popsUp" to (importance >= NotificationManager.IMPORTANCE_HIGH),
            "sounds" to (importance >= NotificationManager.IMPORTANCE_DEFAULT && channel.sound != null),
        )
    }

    /**
     * The channel's own page in the system settings (pop-up, sound, lock screen), else the app's notification page.
     * With [appPage], the app's page first: OnePlus, OPPO and realme keep Banner, Ring and Vibrate there, for the
     * whole app (off for apps not on their list), and a category's page offers Banner only once the app's is on.
     */
    fun openSettings(context: Context, id: String, appPage: Boolean = false) {
        val pkg = context.packageName
        val app = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).putExtra(Settings.EXTRA_APP_PACKAGE, pkg)
        if (appPage && Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && start(context, app)) return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = Intent(Settings.ACTION_CHANNEL_NOTIFICATION_SETTINGS)
                .putExtra(Settings.EXTRA_APP_PACKAGE, pkg)
                .putExtra(Settings.EXTRA_CHANNEL_ID, id)
            if (start(context, channel)) return
            if (start(context, app)) return
        }
        start(context, Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, android.net.Uri.fromParts("package", pkg, null)))
    }

    /** The app's own notification page in the system settings, where every switch for its alerts is. */
    fun openAppSettings(context: Context) {
        val pkg = context.packageName
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            start(context, Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).putExtra(Settings.EXTRA_APP_PACKAGE, pkg))
        ) return
        start(context, Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, android.net.Uri.fromParts("package", pkg, null)))
    }

    private fun start(context: Context, intent: Intent): Boolean = try {
        context.startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        true
    } catch (_: ActivityNotFoundException) {
        false
    }
}

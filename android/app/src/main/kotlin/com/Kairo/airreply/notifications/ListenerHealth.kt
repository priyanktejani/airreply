package com.Kairo.airreply.notifications

import android.content.ComponentName
import android.content.Context
import android.service.notification.NotificationListenerService
import android.util.Log

/**
 * Keeps the notification listener bound.
 *
 * Android re-binds a listener after its process dies, but OEM ROMs (MIUI, ColorOS, Funtouch, EMUI...) block that
 * restart unless the app has their "Autostart" permission, leaving notification access granted but nothing
 * listening. Asking for a rebind while the app is in the foreground is allowed everywhere, so the app does it
 * whenever it is opened and whenever sharing is switched on.
 */
object ListenerHealth {
    private const val TAG = "AirReplyListener"

    fun ensureBound(context: Context) {
        if (NotificationMirrorService.isConnected || !NotificationMirrorService.isAccessGranted(context)) return
        Log.w(TAG, "Notification access is granted but the listener is not bound; requesting a rebind")
        NotificationListenerService.requestRebind(ComponentName(context, NotificationMirrorService::class.java))
    }
}

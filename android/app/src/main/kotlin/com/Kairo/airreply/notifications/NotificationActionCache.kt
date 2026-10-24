package com.Kairo.airreply.notifications

import android.app.Notification
import java.util.concurrent.ConcurrentHashMap

/**
 * The live "Reply" actions of notifications currently in the status bar, keyed by `StatusBarNotification.key`.
 *
 * A [Notification.Action]'s PendingIntent cannot be serialised, so replies can only be executed while this process
 * holds it: entries are added when a notification is posted and dropped when it is removed.
 */
object NotificationActionCache {
    private val actions = ConcurrentHashMap<String, Notification.Action>()

    fun put(key: String, action: Notification.Action) {
        actions[key] = action
    }

    fun get(key: String): Notification.Action? = actions[key]

    fun remove(key: String) {
        actions.remove(key)
    }

    fun clear() = actions.clear()
}

package com.Kairo.airreply.notifications

import android.os.Handler
import android.os.Looper
import android.util.Log
import java.util.concurrent.CopyOnWriteArraySet

/** Something the listener or the sync pipeline reports. */
sealed interface NotificationEvent {
    data class Posted(val notification: CapturedNotification) : NotificationEvent
    data class Removed(val key: String) : NotificationEvent
    data class SyncStateChanged(val status: Map<String, Any>) : NotificationEvent

    /** Shape the Dart `NativeEvent.fromMap` expects. */
    fun toMap(): Map<String, Any?> = when (this) {
        is Posted -> mapOf("type" to "posted", "notification" to notification.toMap())
        is Removed -> mapOf("type" to "removed", "key" to key)
        is SyncStateChanged -> mapOf("type" to "syncState", "status" to status)
    }
}

/**
 * In-process fan-out from the listener service to whoever is attached: the UI's EventChannel and/or the headless
 * sync engine. Neither side knows about the other. Always delivers on the main thread (platform channels need it).
 */
object NotificationEventHub {
    fun interface Listener {
        fun onEvent(event: NotificationEvent)
    }

    private const val TAG = "AirReplyEvents"
    private val listeners = CopyOnWriteArraySet<Listener>()
    private val mainHandler = Handler(Looper.getMainLooper())

    fun subscribe(listener: Listener) {
        listeners.add(listener)
    }

    fun unsubscribe(listener: Listener) {
        listeners.remove(listener)
    }

    fun publish(event: NotificationEvent) {
        if (Looper.myLooper() == Looper.getMainLooper()) dispatch(event) else mainHandler.post { dispatch(event) }
    }

    private fun dispatch(event: NotificationEvent) {
        for (listener in listeners) {
            try {
                listener.onEvent(event)
            } catch (e: Exception) {
                Log.w(TAG, "Listener failed for $event", e)
            }
        }
    }
}

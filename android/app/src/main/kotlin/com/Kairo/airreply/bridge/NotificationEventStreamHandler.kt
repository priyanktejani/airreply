package com.Kairo.airreply.bridge

import com.Kairo.airreply.notifications.NotificationEventHub
import io.flutter.plugin.common.EventChannel

/** `com.airreply/events`: forwards hub events to the Flutter UI while it listens. */
class NotificationEventStreamHandler : EventChannel.StreamHandler {

    private var listener: NotificationEventHub.Listener? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        dispose()
        listener = NotificationEventHub.Listener { event -> events.success(event.toMap()) }
            .also(NotificationEventHub::subscribe)
    }

    override fun onCancel(arguments: Any?) = dispose()

    /** Also called when the engine goes away without the Dart side cancelling. */
    fun dispose() {
        listener?.let(NotificationEventHub::unsubscribe)
        listener = null
    }
}

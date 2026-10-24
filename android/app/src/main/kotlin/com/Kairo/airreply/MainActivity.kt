package com.Kairo.airreply

import com.Kairo.airreply.bridge.AirReplyChannels
import com.Kairo.airreply.bridge.NativeMethodHandler
import com.Kairo.airreply.bridge.NotificationEventStreamHandler
import com.Kairo.airreply.notifications.ListenerHealth
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/** Registers the AirReply channels on the UI engine. */
class MainActivity : FlutterActivity() {

    private val events = NotificationEventStreamHandler()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        MethodChannel(messenger, AirReplyChannels.METHODS).setMethodCallHandler(NativeMethodHandler(applicationContext))
        EventChannel(messenger, AirReplyChannels.EVENTS).setStreamHandler(events)
    }

    override fun onResume() {
        super.onResume()
        // The app is in front, so even ROMs that block background restarts let the listener be re-bound now.
        ListenerHealth.ensureBound(applicationContext)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        events.dispose()
        super.cleanUpFlutterEngine(flutterEngine)
    }
}

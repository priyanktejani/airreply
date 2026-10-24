package com.Kairo.airreply.sync

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.Kairo.airreply.bridge.AirReplyChannels
import com.Kairo.airreply.bridge.NativeMethodHandler
import com.Kairo.airreply.notifications.NotificationEvent
import com.Kairo.airreply.notifications.NotificationEventHub
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel

/**
 * A headless Flutter engine running `backgroundMain()` (lib/main.dart) for as long as sharing is on.
 *
 * It lets the sender encrypt, upload and execute replies with the same Dart code as the app (one crypto
 * implementation, one Firestore schema) while the UI is closed. Listener events are queued until Dart says it is
 * ready, then forwarded over `com.airreply/background`.
 */
object BackgroundSyncEngine {
    private const val TAG = "AirReplySyncEngine"
    private const val ENTRYPOINT = "backgroundMain"
    private const val MAX_QUEUED = 200

    private val mainHandler = Handler(Looper.getMainLooper())
    private val queued = ArrayDeque<Pair<String, Any?>>()
    private var engine: FlutterEngine? = null
    private var channel: MethodChannel? = null
    private var dartReady = false

    val isRunning: Boolean get() = engine != null

    private val listener = NotificationEventHub.Listener { event ->
        when (event) {
            is NotificationEvent.Posted -> deliver("notificationPosted", event.notification.toMap())
            is NotificationEvent.Removed -> deliver("notificationRemoved", mapOf("key" to event.key))
            is NotificationEvent.SyncStateChanged -> Unit
        }
    }

    fun ensureStarted(context: Context) {
        if (Looper.myLooper() != Looper.getMainLooper()) {
            mainHandler.post { ensureStarted(context) }
            return
        }
        if (engine != null) return

        val app = context.applicationContext
        val loader = FlutterInjector.instance().flutterLoader()
        loader.startInitialization(app)
        loader.ensureInitializationComplete(app, null)

        val flutterEngine = FlutterEngine(app)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        MethodChannel(messenger, AirReplyChannels.METHODS).setMethodCallHandler(NativeMethodHandler(app))
        channel = MethodChannel(messenger, AirReplyChannels.BACKGROUND).apply {
            setMethodCallHandler { call, result ->
                if (call.method == "ready") {
                    dartReady = true
                    flush()
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
        }
        engine = flutterEngine
        NotificationEventHub.subscribe(listener)

        flutterEngine.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint(loader.findAppBundlePath(), ENTRYPOINT),
        )
        Log.i(TAG, "Sync engine started")
    }

    /** Replaces the engine, so `backgroundMain()` runs again with the current pairs. */
    fun restart(context: Context) {
        if (Looper.myLooper() != Looper.getMainLooper()) {
            mainHandler.post { restart(context) }
            return
        }
        stop()
        ensureStarted(context)
    }

    fun stop() {
        if (Looper.myLooper() != Looper.getMainLooper()) {
            mainHandler.post { stop() }
            return
        }
        NotificationEventHub.unsubscribe(listener)
        channel?.setMethodCallHandler(null)
        engine?.destroy()
        engine = null
        channel = null
        dartReady = false
        queued.clear()
        Log.i(TAG, "Sync engine stopped")
    }

    private fun deliver(method: String, arguments: Any?) {
        val target = channel ?: return
        if (!dartReady) {
            if (queued.size >= MAX_QUEUED) queued.removeFirst()
            queued.addLast(method to arguments)
            return
        }
        target.invokeMethod(method, arguments)
    }

    private fun flush() {
        while (queued.isNotEmpty()) {
            val (method, arguments) = queued.removeFirst()
            channel?.invokeMethod(method, arguments)
        }
    }
}

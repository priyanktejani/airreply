package com.Kairo.airreply.bridge

/** Platform channel names. Keep in step with the Dart side in lib/core/platform/. */
object AirReplyChannels {
    /** Dart -> native commands; registered on the UI engine and on the headless sync engine. */
    const val METHODS = "com.airreply/methods"

    /** Native -> Dart live events for the UI (listener activity, sync on/off). */
    const val EVENTS = "com.airreply/events"

    /** Native -> Dart work for the headless sync engine only (posted / removed / wake). */
    const val BACKGROUND = "com.airreply/background"
}

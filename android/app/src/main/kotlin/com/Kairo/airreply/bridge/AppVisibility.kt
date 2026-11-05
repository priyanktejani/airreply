package com.Kairo.airreply.bridge

/**
 * Whether the app's window is in front. The headless engine that keeps a receiver receiving asks before raising an
 * alert: while the app is open, the app raises its own (and skips the conversation already on screen).
 */
object AppVisibility {
    @Volatile
    var visible: Boolean = false
}

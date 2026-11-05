package com.Kairo.airreply.sync

import android.content.Context

/**
 * Native-owned settings the listener needs while Flutter is not running: whether sharing is on, and the app
 * allowlist. Flutter reads and writes them through the method channel only.
 */
class SyncPreferences(context: Context) {

    private val prefs = context.applicationContext.getSharedPreferences(FILE, Context.MODE_PRIVATE)

    var syncEnabled: Boolean
        get() = prefs.getBoolean(KEY_ENABLED, false)
        set(value) = prefs.edit().putBoolean(KEY_ENABLED, value).apply()

    /**
     * The service keeps a device that shows notifications receiving while AirReply is closed (rather than a phone
     * sharing its own): the same service and engine, another status text and no notification listener.
     */
    var receiving: Boolean
        get() = prefs.getBoolean(KEY_RECEIVING, false)
        set(value) = prefs.edit().putBoolean(KEY_RECEIVING, value).apply()

    private val filterMode: String get() = prefs.getString(KEY_MODE, MODE_ALL) ?: MODE_ALL

    private val filterPackages: Set<String> get() = prefs.getStringSet(KEY_PACKAGES, emptySet()) ?: emptySet()

    fun allows(packageName: String): Boolean = filterMode == MODE_ALL || packageName in filterPackages

    fun filterAsMap(): Map<String, Any> = mapOf("mode" to filterMode, "packages" to filterPackages.toList())

    fun setFilter(mode: String, packages: Collection<String>) {
        prefs.edit()
            .putString(KEY_MODE, if (mode == MODE_SELECTED) MODE_SELECTED else MODE_ALL)
            .putStringSet(KEY_PACKAGES, packages.toSet())
            .apply()
    }

    /** Everything above, gone: Settings → Erase everything. */
    fun clear() {
        prefs.edit().clear().apply()
    }

    private companion object {
        const val FILE = "air_reply_sync"
        const val KEY_ENABLED = "sync_enabled"
        const val KEY_RECEIVING = "receiving"
        const val KEY_MODE = "filter_mode"
        const val KEY_PACKAGES = "filter_packages"
        const val MODE_ALL = "all"
        const val MODE_SELECTED = "selected"
    }
}

package com.Kairo.airreply.bridge

import android.content.ComponentName
import android.content.Context
import android.content.pm.PackageManager

/**
 * The app icon people choose (Settings → Appearance → App icon): each is a launcher activity-alias in the manifest,
 * and exactly one is enabled. Switching enables the new one before disabling the old, so the app always has an
 * entry, and does not stop the app. Launchers may take a moment to show the change.
 */
object AppIcons {
    private val aliases = mapOf("light" to ".LauncherLight", "dark" to ".LauncherDark")

    private fun component(context: Context, alias: String) = ComponentName(context.packageName, context.packageName + alias)

    /** "light" or "dark": the one that is enabled now (the manifest's default when neither was ever switched). */
    fun current(context: Context): String {
        val pm = context.packageManager
        val dark = pm.getComponentEnabledSetting(component(context, aliases.getValue("dark")))
        return if (dark == PackageManager.COMPONENT_ENABLED_STATE_ENABLED) "dark" else "light"
    }

    fun set(context: Context, name: String) {
        val chosen = aliases[name] ?: throw IllegalArgumentException("No app icon named $name")
        if (current(context) == name) return
        val pm = context.packageManager
        pm.setComponentEnabledSetting(
            component(context, chosen),
            PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
            PackageManager.DONT_KILL_APP,
        )
        for ((other, alias) in aliases) {
            if (other == name) continue
            pm.setComponentEnabledSetting(
                component(context, alias),
                PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                PackageManager.DONT_KILL_APP,
            )
        }
    }
}

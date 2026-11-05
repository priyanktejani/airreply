package com.Kairo.airreply.apps

import android.app.ActivityManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings

/**
 * What can stop the sender from running in the background on this phone, and the settings screens that lift it.
 *
 * Xiaomi, Oppo, Vivo, Huawei and others add an "Autostart" switch on top of Android's battery optimisation; while
 * it is off they refuse to restart the notification listener, so mirroring silently stops.
 */
object BackgroundRestrictions {

    /** OEM "Autostart" / "Startup manager" screens, most common first. Declared under <queries> in the manifest. */
    private val autostartScreens = listOf(
        ComponentName("com.miui.securitycenter", "com.miui.permcenter.autostart.AutoStartManagementActivity"),
        ComponentName("com.coloros.safecenter", "com.coloros.safecenter.permission.startup.StartupAppListActivity"),
        ComponentName("com.coloros.safecenter", "com.coloros.safecenter.startupapp.StartupAppListActivity"),
        ComponentName("com.oppo.safe", "com.oppo.safe.permission.startup.StartupAppListActivity"),
        ComponentName("com.vivo.permissionmanager", "com.vivo.permissionmanager.activity.BgStartUpManagerActivity"),
        ComponentName("com.iqoo.secure", "com.iqoo.secure.ui.phoneoptimize.AddWhiteListActivity"),
        ComponentName("com.huawei.systemmanager", "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity"),
        ComponentName("com.huawei.systemmanager", "com.huawei.systemmanager.optimize.process.ProtectActivity"),
        ComponentName("com.asus.mobilemanager", "com.asus.mobilemanager.autostart.AutoStartActivity"),
        ComponentName("com.letv.android.letvsafe", "com.letv.android.letvsafe.AutobootManageActivity"),
    )

    fun status(context: Context): Map<String, Any> = mapOf(
        "vendor" to Build.MANUFACTURER.lowercase(),
        "hasAutostartScreen" to (autostartIntent(context) != null),
        "ignoringBatteryOptimizations" to
            context.getSystemService(PowerManager::class.java).isIgnoringBatteryOptimizations(context.packageName),
        // "Restrict background usage" in the app's system settings (Android 9+): with it on, the system stops the
        // sharing service soon after the screen goes off
        "backgroundRestricted" to (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P &&
            context.getSystemService(ActivityManager::class.java).isBackgroundRestricted),
    )

    /** This app's page in the system settings: battery use, background activity, notifications. */
    fun openAppSettings(context: Context) {
        context.startActivity(
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                .setData(Uri.fromParts("package", context.packageName, null))
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
        )
    }

    /** Opens the OEM autostart screen, or this app's system settings page when the phone has none. */
    fun openAutostart(context: Context) {
        val intent = autostartIntent(context) ?: Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
            .setData(Uri.fromParts("package", context.packageName, null))
        context.startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
    }

    private fun autostartIntent(context: Context): Intent? {
        val pm = context.packageManager
        return autostartScreens.asSequence()
            .map { Intent().setComponent(it) }
            .firstOrNull { resolves(pm, it) }
    }

    private fun resolves(pm: PackageManager, intent: Intent): Boolean =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            pm.resolveActivity(intent, PackageManager.ResolveInfoFlags.of(0)) != null
        } else {
            @Suppress("DEPRECATION")
            pm.resolveActivity(intent, 0) != null
        }
}

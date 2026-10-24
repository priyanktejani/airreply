package com.Kairo.airreply.apps

import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.content.pm.ResolveInfo
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.Drawable
import android.os.Build
import java.io.ByteArrayOutputStream

/**
 * Launchable apps for the allowlist screen. Uses the `<queries>` launcher intent declared in the manifest instead of
 * QUERY_ALL_PACKAGES. Slow (icons): call off the main thread.
 */
class InstalledAppsRepository(private val context: Context) {

    fun launchableApps(): List<Map<String, Any?>> {
        val pm = context.packageManager
        return queryLauncherActivities(pm)
            .map { it.activityInfo.applicationInfo }
            .distinctBy { it.packageName }
            .filter { it.packageName != context.packageName }
            .map { info -> toMap(pm, info) }
            .sortedBy { (it["label"] as String).lowercase() }
    }

    /** [packageName]'s icon as a [size]-pixel PNG, or null when the package is not visible to this app. */
    fun iconFor(packageName: String, size: Int = MIRROR_ICON_SIZE): ByteArray? = try {
        toPng(context.packageManager.getApplicationIcon(packageName), size)
    } catch (_: PackageManager.NameNotFoundException) {
        null
    }

    private fun toMap(pm: PackageManager, info: ApplicationInfo): Map<String, Any?> = mapOf(
        "packageName" to info.packageName,
        "label" to pm.getApplicationLabel(info).toString(),
        "icon" to runCatching { toPng(pm.getApplicationIcon(info), ICON_SIZE) }.getOrNull(),
    )

    private fun queryLauncherActivities(pm: PackageManager): List<ResolveInfo> {
        val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            pm.queryIntentActivities(intent, PackageManager.ResolveInfoFlags.of(0))
        } else {
            @Suppress("DEPRECATION")
            pm.queryIntentActivities(intent, 0)
        }
    }

    private fun toPng(drawable: Drawable, size: Int): ByteArray {
        val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        drawable.setBounds(0, 0, size, size)
        drawable.draw(Canvas(bitmap))
        return ByteArrayOutputStream().use { out ->
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, out)
            bitmap.recycle()
            out.toByteArray()
        }
    }

    private companion object {
        const val ICON_SIZE = 96

        /** Small enough to travel inside an encrypted notification payload. */
        const val MIRROR_ICON_SIZE = 64
    }
}

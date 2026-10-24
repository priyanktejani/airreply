package com.Kairo.airreply.sync

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/** Brings sharing back after a reboot or an app update, if it was on. */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED, Intent.ACTION_MY_PACKAGE_REPLACED ->
                SyncController.resumeIfEnabled(context.applicationContext)
        }
    }
}

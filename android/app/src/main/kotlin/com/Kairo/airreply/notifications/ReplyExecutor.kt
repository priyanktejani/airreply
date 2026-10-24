package com.Kairo.airreply.notifications

import android.app.PendingIntent
import android.app.RemoteInput
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.util.Log

/** Outcome reported back to the receiver. Values match `ReplyDispatchResult` in Dart. */
enum class ReplyResult(val wire: String) {
    SENT("sent"),

    /** No cached action: the notification was dismissed, answered elsewhere, or the app replaced it. */
    EXPIRED("expired"),
    FAILED("failed"),
}

/** Answers a notification on this phone by firing its cached [RemoteInput] action, exactly as inline reply does. */
class ReplyExecutor(private val context: Context) {

    fun send(notificationKey: String, text: String): ReplyResult {
        val action = NotificationActionCache.get(notificationKey) ?: return ReplyResult.EXPIRED
        val inputs = action.remoteInputs?.takeIf { it.isNotEmpty() } ?: return ReplyResult.EXPIRED

        val results = Bundle().apply {
            for (input in inputs) putCharSequence(input.resultKey, text)
        }
        val intent = Intent().addFlags(Intent.FLAG_RECEIVER_FOREGROUND)
        RemoteInput.addResultsToIntent(inputs, intent, results)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            RemoteInput.setResultsSource(intent, RemoteInput.SOURCE_FREE_FORM_INPUT)
        }

        return try {
            action.actionIntent.send(context, 0, intent)
            ReplyResult.SENT
        } catch (e: PendingIntent.CanceledException) {
            // The app cancelled the PendingIntent: this conversation's reply action is gone.
            NotificationActionCache.remove(notificationKey)
            ReplyResult.EXPIRED
        } catch (e: Exception) {
            Log.w(TAG, "Reply failed for $notificationKey", e)
            ReplyResult.FAILED
        }
    }

    private companion object {
        const val TAG = "AirReplyReply"
    }
}

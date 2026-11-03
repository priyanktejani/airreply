package com.Kairo.airreply.notifications

import android.app.Notification
import android.app.Person
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.os.Parcelable
import android.service.notification.StatusBarNotification
import java.util.concurrent.ConcurrentHashMap

/** Turns a [StatusBarNotification] into a [CapturedNotification], or null when it should not be mirrored. */
class NotificationParser(private val context: Context) {

    private val appNames = ConcurrentHashMap<String, String>()

    fun parse(sbn: StatusBarNotification): CapturedNotification? {
        val notification = sbn.notification ?: return null
        if (sbn.packageName == context.packageName) return null
        if (notification.flags and IGNORED_FLAGS != 0) return null

        val extras = notification.extras
        val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString().orEmpty()
        val conversationTitle = extras.getCharSequence(Notification.EXTRA_CONVERSATION_TITLE)?.toString()
        val isGroup = Build.VERSION.SDK_INT >= Build.VERSION_CODES.P &&
            extras.getBoolean(Notification.EXTRA_IS_GROUP_CONVERSATION)
        val message = lastMessage(extras)

        val text = when {
            message != null && isGroup && message.sender != null -> "${message.sender}: ${message.text}"
            message != null -> message.text
            else -> (extras.getCharSequence(Notification.EXTRA_BIG_TEXT)
                ?: extras.getCharSequence(Notification.EXTRA_TEXT))?.toString().orEmpty()
        }
        if (title.isBlank() && text.isBlank()) return null
        val isMessage = message != null || notification.category == Notification.CATEGORY_MESSAGE
        // the message's own time when the app gives it: a re-post of the same message keeps it, so copies line up
        val messageAt = message?.time?.takeIf { it > 0 }

        return CapturedNotification(
            key = sbn.key,
            packageName = sbn.packageName,
            appName = appName(sbn.packageName),
            title = title,
            text = text,
            postedAt = messageAt ?: sbn.postTime,
            canReply = replyAction(notification) != null,
            conversationTitle = conversationTitle,
            isGroupConversation = isGroup,
            // In MessagingStyle, messages written by the device's user carry no sender.
            isSelfMessage = message != null && message.sender == null,
            sender = message?.sender,
            conversationId = conversationId(notification),
            isMessage = isMessage,
            messageAt = messageAt,
        )
    }

    /**
     * The conversation a message belongs to, as the app declares it for Android's conversation features (WhatsApp,
     * Telegram, Messages, Signal...: the chat or contact id). Null for apps that do not declare one.
     */
    private fun conversationId(notification: Notification): String? =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) notification.shortcutId?.takeIf { it.isNotBlank() } else null

    /** The first action that takes free-form text through a [android.app.RemoteInput], i.e. "Reply". */
    fun replyAction(notification: Notification): Notification.Action? =
        notification.actions?.firstOrNull { action ->
            action.remoteInputs?.any { it.allowFreeFormInput } == true
        }

    fun appName(packageName: String): String = appNames.getOrPut(packageName) {
        try {
            val pm = context.packageManager
            pm.getApplicationLabel(pm.getApplicationInfo(packageName, 0)).toString()
        } catch (_: PackageManager.NameNotFoundException) {
            packageName
        }
    }

    private data class Message(val text: String, val sender: String?, val time: Long)

    /** Latest entry of `EXTRA_MESSAGES` (MessagingStyle), as the platform bundles it. */
    private fun lastMessage(extras: Bundle): Message? {
        val messages: Array<out Parcelable>? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            extras.getParcelableArray(Notification.EXTRA_MESSAGES, Parcelable::class.java)
        } else {
            @Suppress("DEPRECATION")
            extras.getParcelableArray(Notification.EXTRA_MESSAGES)
        }
        val last = messages?.lastOrNull() as? Bundle ?: return null
        val text = last.getCharSequence(KEY_TEXT)?.toString() ?: return null
        return Message(text, senderName(last), last.getLong(KEY_TIMESTAMP))
    }

    private fun senderName(message: Bundle): String? {
        message.getCharSequence(KEY_SENDER)?.let { return it.toString() }
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P) return null
        val person: Person? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            message.getParcelable(KEY_SENDER_PERSON, Person::class.java)
        } else {
            @Suppress("DEPRECATION")
            message.getParcelable(KEY_SENDER_PERSON)
        }
        return person?.name?.toString()
    }

    private companion object {
        /** Persistent and summary notifications are not messages: never mirror them. */
        const val IGNORED_FLAGS = Notification.FLAG_ONGOING_EVENT or
            Notification.FLAG_GROUP_SUMMARY or
            Notification.FLAG_FOREGROUND_SERVICE

        // Keys of Notification.MessagingStyle.Message#toBundle().
        const val KEY_TEXT = "text"
        const val KEY_TIMESTAMP = "time"
        const val KEY_SENDER = "sender"
        const val KEY_SENDER_PERSON = "sender_person"
    }
}

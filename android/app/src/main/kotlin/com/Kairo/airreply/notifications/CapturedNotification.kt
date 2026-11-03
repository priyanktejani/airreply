package com.Kairo.airreply.notifications

/**
 * The fields of a status-bar notification that get mirrored. Mirrors `CapturedNotification` in
 * lib/core/platform/native_models.dart: keep [toMap] and its `fromMap` in step.
 */
data class CapturedNotification(
    val key: String,
    val packageName: String,
    val appName: String,
    val title: String,
    val text: String,
    val postedAt: Long,
    val canReply: Boolean,
    val conversationTitle: String?,
    val isGroupConversation: Boolean,
    /** The latest message of a conversation was written by this phone's user (e.g. a reply we just sent). */
    val isSelfMessage: Boolean,
    /** Who wrote the latest message (MessagingStyle), when the app says. */
    val sender: String?,
    /** The app's id for the conversation (`Notification.getShortcutId()`), when it declares one. */
    val conversationId: String?,
    /** A message from a person: MessagingStyle or `CATEGORY_MESSAGE`. */
    val isMessage: Boolean,
    /**
     * When the latest message was written, as the app stamps it (MessagingStyle); null for other notifications. The
     * app keeps this stamp when it re-posts the same message, and a new message gets a new one even with the same words.
     */
    val messageAt: Long? = null,
) {
    /**
     * What the receiver would see; an update with the same fingerprint is not worth mirroring again. For a message it
     * includes the message's own time, so "ok" sent twice is two messages, while a re-post of one message is not.
     */
    val fingerprint: Int get() = "$title\u0000$text\u0000${messageAt ?: 0}".hashCode()

    fun toMap(): Map<String, Any?> = mapOf(
        "key" to key,
        "packageName" to packageName,
        "appName" to appName,
        "title" to title,
        "text" to text,
        "postedAt" to postedAt,
        "canReply" to canReply,
        "conversationTitle" to conversationTitle,
        "isGroupConversation" to isGroupConversation,
        "sender" to sender,
        "conversationId" to conversationId,
        "isMessage" to isMessage,
    )
}

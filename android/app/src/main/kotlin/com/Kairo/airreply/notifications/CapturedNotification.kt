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
) {
    /** What the receiver would see; an update with the same fingerprint is not worth mirroring again. */
    val fingerprint: Int get() = "$title\u0000$text".hashCode()

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
    )
}

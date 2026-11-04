/// A problem report or a feature idea, as the person wrote it in Settings.
enum FeedbackKind { problem, idea }

/// The part of the app it is about.
enum FeedbackArea { notifications, replies, pairing, alerts, sync, design, other }

final class FeedbackMessage {
  const FeedbackMessage({required this.kind, required this.area, required this.message, this.details});

  final FeedbackKind kind;
  final FeedbackArea area;
  final String message;

  /// Device details, when the person chose to include them (see `DeviceDetails`).
  final Map<String, String>? details;

  static const minLength = 10;

  /// The email it becomes. In English whatever the app's language, like the diagnostics report: it is read by whoever
  /// maintains the app.
  ({String subject, String body}) toEmail() {
    final kindName = switch (kind) {
      FeedbackKind.problem => 'Problem',
      FeedbackKind.idea => 'Feature idea',
    };
    final areaName = switch (area) {
      FeedbackArea.notifications => 'Notifications',
      FeedbackArea.replies => 'Replies',
      FeedbackArea.pairing => 'Pairing',
      FeedbackArea.alerts => 'Alerts',
      FeedbackArea.sync => 'Sync',
      FeedbackArea.design => 'Look and feel',
      FeedbackArea.other => 'Other',
    };
    final body = StringBuffer(message.trim());
    if (details case final details? when details.isNotEmpty) {
      body
        ..writeln()
        ..writeln()
        ..writeln('-- Device details --');
      for (final MapEntry(:key, :value) in details.entries) {
        body.writeln('$key: $value');
      }
    }
    return (subject: '[AirReply] $kindName · $areaName', body: body.toString().trimRight());
  }

  /// A `mailto:` link to [to] with the subject and body filled in. Spaces are `%20`, not `+`, which mail apps would
  /// show as written.
  Uri mailto(String to) {
    final (:subject, :body) = toEmail();
    return Uri.parse('mailto:$to?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}');
  }
}

/// One titled group of facts on the diagnostics screen.
final class DiagnosticsSection {
  const DiagnosticsSection(this.title, this.rows);

  final String title;

  /// (label, value)
  final List<(String, String)> rows;
}

/// The diagnostics screen as plain text, for "Copy report". Holds no notification content and no keys.
String diagnosticsText(List<DiagnosticsSection> sections, {required DateTime generatedAt}) {
  final buffer = StringBuffer('AirReply diagnostics · ${generatedAt.toIso8601String()}\n');
  for (final section in sections) {
    buffer.writeln('\n[${section.title}]');
    for (final (label, value) in section.rows) {
      buffer.writeln('$label: $value');
    }
  }
  return buffer.toString();
}

/// "on" / "off" for switches in the report.
String onOff(bool? value) => switch (value) {
  true => 'on',
  false => 'off',
  null => 'unknown',
};

import 'package:air_reply/core/l10n/l10n.dart';
import 'package:intl/intl.dart';

// Times in the person's language: the words ("Yesterday", "5 min ago") come from the app's strings, month and weekday
// names from intl, which knows them for every language. English reads day first ("12 March"), as it always has.

String _locale(AppLocalizations l10n) => l10n.localeName == 'en' ? 'en_GB' : l10n.localeName;

/// "now", "5m", "3h", "Yesterday", "Mon", "12 Mar": compact times for feed cards.
String formatRelativeTime(AppLocalizations l10n, DateTime time, {DateTime? now}) {
  final current = now ?? DateTime.now();
  final diff = current.difference(time);
  if (diff.inSeconds < 45) return l10n.timeNow;
  if (diff.inMinutes < 60) return l10n.timeMinutesShort(diff.inMinutes);
  if (diff.inHours < 24 && current.day == time.day) return l10n.timeHoursShort(diff.inHours);

  final today = DateTime(current.year, current.month, current.day);
  final days = today.difference(DateTime(time.year, time.month, time.day)).inDays;
  if (days == 1) return l10n.timeYesterday;
  if (days < 7) return DateFormat.E(_locale(l10n)).format(time);
  return DateFormat.MMMd(_locale(l10n)).format(time);
}

/// "482 913"
String formatSixDigits(String code) => code.length == 6 ? '${code.substring(0, 3)} ${code.substring(3)}' : code;

/// Section heading for a day in a feed: "Today", "Yesterday", "Monday", "12 March", "12 March 2025".
String formatDayLabel(AppLocalizations l10n, DateTime time, {DateTime? now}) {
  final current = now ?? DateTime.now();
  final today = DateTime(current.year, current.month, current.day);
  final days = today.difference(DateTime(time.year, time.month, time.day)).inDays;
  if (days <= 0) return l10n.timeToday;
  if (days == 1) return l10n.timeYesterday;
  if (days < 7) return DateFormat.EEEE(_locale(l10n)).format(time);
  final locale = _locale(l10n);
  return (time.year == current.year ? DateFormat.MMMMd(locale) : DateFormat.yMMMMd(locale)).format(time);
}

/// "14:05"
String formatClock(AppLocalizations l10n, DateTime time) => DateFormat.Hm(_locale(l10n)).format(time);

/// "Saturday 24 October" (with the year when it is not this year).
String formatLongDate(AppLocalizations l10n, DateTime time, {DateTime? now}) {
  final locale = _locale(l10n);
  final thisYear = time.year == (now ?? DateTime.now()).year;
  return (thisYear ? DateFormat.MMMMEEEEd(locale) : DateFormat.yMMMMEEEEd(locale)).format(time);
}

/// "Today at 14:05", "Yesterday at 09:12", "12 March at 18:40": full timestamps for detail views.
String formatTimestamp(AppLocalizations l10n, DateTime time, {DateTime? now}) =>
    l10n.timeAt(formatDayLabel(l10n, time, now: now), formatClock(l10n, time));

/// "just now", "4 min ago", "3 h ago", "Yesterday", "12 Mar": how long since something happened.
String formatAgo(AppLocalizations l10n, DateTime time, {DateTime? now}) {
  final current = now ?? DateTime.now();
  final diff = current.difference(time);
  if (diff.inSeconds < 45) return l10n.timeJustNow;
  if (diff.inMinutes < 60) return l10n.timeMinutesAgo(diff.inMinutes);
  if (diff.inHours < 24 && current.day == time.day) return l10n.timeHoursAgo(diff.inHours);
  return formatRelativeTime(l10n, time, now: current);
}

/// "now", "5m", "3h", "Yesterday", "Mon", "12 Mar" — compact times for feed cards.
String formatRelativeTime(DateTime time, {DateTime? now}) {
  final current = now ?? DateTime.now();
  final diff = current.difference(time);
  if (diff.inSeconds < 45) return 'now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24 && current.day == time.day) return '${diff.inHours}h';

  final today = DateTime(current.year, current.month, current.day);
  final day = DateTime(time.year, time.month, time.day);
  final days = today.difference(day).inDays;
  if (days == 1) return 'Yesterday';
  if (days < 7) return const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][time.weekday - 1];
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${time.day} ${months[time.month - 1]}';
}

/// "482 913"
String formatSixDigits(String code) => code.length == 6 ? '${code.substring(0, 3)} ${code.substring(3)}' : code;

/// Section heading for a day in a feed: "Today", "Yesterday", "Monday", "12 March", "12 March 2025".
String formatDayLabel(DateTime time, {DateTime? now}) {
  final current = now ?? DateTime.now();
  final today = DateTime(current.year, current.month, current.day);
  final days = today.difference(DateTime(time.year, time.month, time.day)).inDays;
  if (days <= 0) return 'Today';
  if (days == 1) return 'Yesterday';
  if (days < 7) return _weekdays[time.weekday - 1];
  final label = '${time.day} ${_monthNames[time.month - 1]}';
  return time.year == current.year ? label : '$label ${time.year}';
}

const _weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
const _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// "14:05"
String formatClock(DateTime time) =>
    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

/// "Saturday, 24 October" (with the year when it is not this year).
String formatLongDate(DateTime time, {DateTime? now}) {
  final label = '${_weekdays[time.weekday - 1]}, ${time.day} ${_monthNames[time.month - 1]}';
  return time.year == (now ?? DateTime.now()).year ? label : '$label ${time.year}';
}

/// "Today at 14:05", "Yesterday at 09:12", "12 March at 18:40": full timestamps for detail views.
String formatTimestamp(DateTime time, {DateTime? now}) => '${formatDayLabel(time, now: now)} at ${formatClock(time)}';

/// "just now", "4 min ago", "3 h ago", "Yesterday", "12 Mar": how long since something happened.
String formatAgo(DateTime time, {DateTime? now}) {
  final current = now ?? DateTime.now();
  final diff = current.difference(time);
  if (diff.inSeconds < 45) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24 && current.day == time.day) return '${diff.inHours} h ago';
  return formatRelativeTime(time, now: current);
}

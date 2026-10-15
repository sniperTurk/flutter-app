/// Dates under the Hava Durumu fetch buttons (owner, 2026-10-14): numeric,
/// 24 h, the phone's local time, never month names.
library;

String _two(int v) => v.toString().padLeft(2, '0');

/// "14.10.2026".
String fetchDateText(DateTime t) {
  final l = t.toLocal();
  return '${_two(l.day)}.${_two(l.month)}.${l.year}';
}

/// "14.10.2026 14:36" for a UTC epoch-ms fetch time.
String fetchDateTimeText(int atMs) {
  final t = DateTime.fromMillisecondsSinceEpoch(atMs);
  return '${fetchDateText(t)} ${_two(t.hour)}:${_two(t.minute)}';
}

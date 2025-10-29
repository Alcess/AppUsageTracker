/// Utility for formatting durations in days, hours, and minutes.
String formatTime(int minutes) {
  final days = minutes ~/ 1440;
  final hours = (minutes % 1440) ~/ 60;
  final rem = minutes % 60;

  String output = '';

  if (days > 0) output += '${days}d ';
  if (hours > 0) output += '${hours}h ';
  output += '${rem}m';

  return output;
}

String formatDate(DateTime? date, {bool includeYear = true}) {
  if (date == null) {
    return '—';
  }
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final result = '${months[date.month - 1]} ${date.day}';
  return includeYear ? '$result, ${date.year}' : result;
}

String formatDateRange(DateTime? start, DateTime? end) {
  if (start == null && end == null) {
    return 'Dates to be confirmed';
  }
  if (start == null) {
    return 'Until ${formatDate(end)}';
  }
  if (end == null) {
    return 'From ${formatDate(start)}';
  }
  if (start.year == end.year) {
    return '${formatDate(start, includeYear: false)} – ${formatDate(end)}';
  }
  return '${formatDate(start)} – ${formatDate(end)}';
}

String formatTime(double time) {
  final totalMinutes = (time * 60).round();
  final hour24 = (totalMinutes ~/ 60) % 24;
  final minute = totalMinutes % 60;
  final period = hour24 >= 12 ? 'PM' : 'AM';
  final hour = hour24 % 12 == 0 ? 12 : hour24 % 12;
  return '$hour:${minute.toString().padLeft(2, '0')} $period';
}

String formatTimeRange(double start, double end) {
  return '${formatTime(start)} – ${formatTime(end)}';
}

String formatMoney(double amount) {
  final rounded = amount.round().toString();
  final buffer = StringBuffer();
  for (var index = 0; index < rounded.length; index++) {
    final remaining = rounded.length - index;
    buffer.write(rounded[index]);
    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write(',');
    }
  }
  return 'MMK $buffer';
}

String titleCase(String value) {
  if (value.isEmpty) {
    return 'Unknown';
  }
  return value
      .split(RegExp(r'[_\s]+'))
      .where((word) => word.isNotEmpty)
      .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
}

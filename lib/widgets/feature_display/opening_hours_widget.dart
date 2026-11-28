import 'package:flutter/material.dart';

class OpeningHoursWidget extends StatefulWidget {
  final Map<String, dynamic> openingHours;

  const OpeningHoursWidget({
    super.key,
    required this.openingHours,
  });

  @override
  State<OpeningHoursWidget> createState() => _OpeningHoursWidgetState();
}

class _OpeningHoursWidgetState extends State<OpeningHoursWidget> {
  bool _isExpanded = false;
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Safely extract data with null checks
    final bool isOpenNow = widget.openingHours['open_now'] ?? false;
    final dynamic weekdayTextRaw = widget.openingHours['weekday_text'];
    final dynamic periodsRaw = widget.openingHours['periods'];

    // Convert weekday_text to list of strings
    List<String> weekdayText = [];
    if (weekdayTextRaw is List) {
      weekdayText = weekdayTextRaw.map((e) => e.toString()).toList();
    }

    // Convert periods to list of maps
    List<Map<String, dynamic>> periods = [];
    if (periodsRaw is List) {
      for (var period in periodsRaw) {
        if (period is Map) {
          periods.add(Map<String, dynamic>.from(period));
        }
      }
    }

    final String nextOpenCloseInfo = _getNextOpenCloseInfo(isOpenNow, periods);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main opening hours row
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Row(
              children: [
                Text(
                  isOpenNow ? 'Open' : 'Closed',
                  style: textTheme.bodySmall?.copyWith(
                    color: isOpenNow ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (nextOpenCloseInfo.isNotEmpty) ...[
                  Text(
                    ' ⋅ ',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      nextOpenCloseInfo,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
                Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ],
            ),
          ), // Expanded content
          if (_isExpanded && weekdayText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: weekdayText.map<Widget>((dayText) {
                  final List<String> parts = dayText.split(': ');
                  if (parts.length == 2) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            parts[0],
                            style: textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            parts[1],
                            style: textTheme.bodySmall?.copyWith(
                              color:
                                  colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return Text(dayText, style: textTheme.bodySmall);
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  String _getNextOpenCloseInfo(
      bool isOpenNow, List<Map<String, dynamic>> periods) {
    if (periods.isEmpty) return '';

    final now = DateTime.now();
    final currentDay =
        now.weekday % 7; // Convert to Google's day format (0 = Sunday)
    final currentTime = now.hour * 100 + now.minute; // Convert to HHMM format

    try {
      if (isOpenNow) {
        // Find when it closes today or next available close time
        for (int i = 0; i < 7; i++) {
          final checkDay = (currentDay + i) % 7;
          final dayPeriods = periods
              .where((period) => period['open']?['day'] == checkDay)
              .toList();

          for (final period in dayPeriods) {
            final openTimeStr = period['open']?['time']?.toString() ?? '';
            final closeTimeStr = period['close']?['time']?.toString() ?? '';

            if (openTimeStr.isEmpty || closeTimeStr.isEmpty) continue;

            final openTime = int.tryParse(openTimeStr) ?? 0;
            final closeTime = int.tryParse(closeTimeStr) ?? 0;

            if (i == 0) {
              // Today - check if we're within opening hours and show close time
              if (currentTime >= openTime && currentTime < closeTime) {
                return 'Closes ${_formatTime(closeTimeStr)}';
              }
            } else {
              // Future day - show the first close time we find
              return 'Closes ${_formatTime(closeTimeStr)} ${_getDayName(checkDay)}';
            }
          }
        }
      } else {
        // Find next opening time
        for (int i = 0; i < 7; i++) {
          final checkDay = (currentDay + i) % 7;
          final dayPeriods = periods
              .where((period) => period['open']?['day'] == checkDay)
              .toList();

          for (final period in dayPeriods) {
            final openTimeStr = period['open']?['time']?.toString() ?? '';
            if (openTimeStr.isEmpty) continue;

            final openTime = int.tryParse(openTimeStr) ?? 0;

            if (i == 0 && openTime > currentTime) {
              // Opens later today
              return 'Opens ${_formatTime(openTimeStr)}';
            } else if (i > 0) {
              // Opens on a future day
              return 'Opens ${_formatTime(openTimeStr)} ${_getDayName(checkDay)}';
            }
          }
        }
      }
    } catch (e) {
      // Handle any parsing errors gracefully
      debugPrint('Error parsing opening hours: $e');
    }

    return '';
  }

  String _formatTime(String time) {
    try {
      final int timeInt = int.parse(time);
      final int hours = timeInt ~/ 100;
      final int minutes = timeInt % 100;

      if (hours == 0) {
        return minutes == 0
            ? '12 AM'
            : '12:${minutes.toString().padLeft(2, '0')} AM';
      } else if (hours < 12) {
        return minutes == 0
            ? '$hours AM'
            : '$hours:${minutes.toString().padLeft(2, '0')} AM';
      } else if (hours == 12) {
        return minutes == 0
            ? '12 PM'
            : '12:${minutes.toString().padLeft(2, '0')} PM';
      } else {
        final displayHour = hours - 12;
        return minutes == 0
            ? '$displayHour PM'
            : '$displayHour:${minutes.toString().padLeft(2, '0')} PM';
      }
    } catch (e) {
      return time;
    }
  }

  String _getDayName(int day) {
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return days[day % 7];
  }
}

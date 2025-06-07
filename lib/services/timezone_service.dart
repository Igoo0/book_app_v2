import 'package:intl/intl.dart';

class TimezoneService {
  static const Map<String, Map<String, dynamic>> _timezones = {
    'WIB': {
      'name': 'Western Indonesia Time',
      'offset': 7, // UTC+7
      'cities': ['Jakarta', 'Bandung', 'Medan', 'Palembang'],
    },
    'WITA': {
      'name': 'Central Indonesia Time',
      'offset': 8, // UTC+8
      'cities': ['Makassar', 'Denpasar', 'Balikpapan', 'Manado'],
    },
    'WIT': {
      'name': 'Eastern Indonesia Time',
      'offset': 9, // UTC+9
      'cities': ['Jayapura', 'Ambon', 'Ternate'],
    },
    'LONDON': {
      'name': 'London Time',
      'offset': 0, // UTC+0 (GMT) or UTC+1 (BST)
      'cities': ['London', 'Manchester', 'Birmingham', 'Edinburgh'],
    },
    'NYC': {
      'name': 'New York Time',
      'offset': -5, // UTC-5 (EST) or UTC-4 (EDT)
      'cities': ['New York', 'Boston', 'Washington D.C.', 'Philadelphia'],
    },
    'TOKYO': {
      'name': 'Japan Standard Time',
      'offset': 9, // UTC+9
      'cities': ['Tokyo', 'Osaka', 'Kyoto', 'Hiroshima'],
    },
    'SINGAPORE': {
      'name': 'Singapore Standard Time',
      'offset': 8, // UTC+8
      'cities': ['Singapore', 'Kuala Lumpur', 'Manila', 'Hong Kong'],
    },
  };

  static List<String> get supportedTimezones => _timezones.keys.toList();

  static String getTimezoneName(String code) {
    return _timezones[code]?['name'] ?? code;
  }

  static int getTimezoneOffset(String code) {
    return _timezones[code]?['offset'] ?? 0;
  }

  static List<String> getTimezoneCities(String code) {
    return List<String>.from(_timezones[code]?['cities'] ?? []);
  }

  static DateTime convertTime({
    required DateTime sourceTime,
    required String fromTimezone,
    required String toTimezone,
  }) {
    final fromOffset = getTimezoneOffset(fromTimezone);
    final toOffset = getTimezoneOffset(toTimezone);
    
    // Convert to UTC first
    final utcTime = sourceTime.subtract(Duration(hours: fromOffset));
    
    // Convert to target timezone
    final targetTime = utcTime.add(Duration(hours: toOffset));
    
    return targetTime;
  }

  static DateTime getCurrentTimeInTimezone(String timezone) {
    final now = DateTime.now().toUtc();
    final offset = getTimezoneOffset(timezone);
    return now.add(Duration(hours: offset));
  }

  static String formatTime(DateTime time, {String pattern = 'HH:mm:ss'}) {
    return DateFormat(pattern).format(time);
  }

  static String formatDateTime(DateTime time, {String pattern = 'yyyy-MM-dd HH:mm:ss'}) {
    return DateFormat(pattern).format(time);
  }

  static String formatTimeWithTimezone(DateTime time, String timezone) {
    final formattedTime = formatTime(time);
    final timezoneName = getTimezoneName(timezone);
    return '$formattedTime ($timezone - $timezoneName)';
  }

  static Map<String, String> getAllCurrentTimes() {
    final Map<String, String> times = {};
    
    for (final timezone in supportedTimezones) {
      final time = getCurrentTimeInTimezone(timezone);
      times[timezone] = formatTimeWithTimezone(time, timezone);
    }
    
    return times;
  }

  static List<Map<String, dynamic>> getTimezoneList() {
    return supportedTimezones.map((code) {
      final currentTime = getCurrentTimeInTimezone(code);
      return {
        'code': code,
        'name': getTimezoneName(code),
        'offset': getTimezoneOffset(code),
        'cities': getTimezoneCities(code),
        'currentTime': formatTime(currentTime),
        'fullDateTime': formatDateTime(currentTime),
      };
    }).toList();
  }

  static bool isDaylightSavingTime(String timezone, DateTime dateTime) {
    // Simplified DST check for London and NYC
    if (timezone == 'LONDON') {
      // BST: Last Sunday in March to last Sunday in October
      final year = dateTime.year;
      final marchLastSunday = _getLastSundayOfMonth(year, 3);
      final octoberLastSunday = _getLastSundayOfMonth(year, 10);
      
      return dateTime.isAfter(marchLastSunday) && dateTime.isBefore(octoberLastSunday);
    } else if (timezone == 'NYC') {
      // EDT: Second Sunday in March to first Sunday in November
      final year = dateTime.year;
      final marchSecondSunday = _getNthSundayOfMonth(year, 3, 2);
      final novemberFirstSunday = _getNthSundayOfMonth(year, 11, 1);
      
      return dateTime.isAfter(marchSecondSunday) && dateTime.isBefore(novemberFirstSunday);
    }
    
    return false; // Other timezones don't observe DST
  }

  static DateTime _getLastSundayOfMonth(int year, int month) {
    final lastDay = DateTime(year, month + 1, 0);
    final daysFromSunday = (lastDay.weekday % 7);
    return lastDay.subtract(Duration(days: daysFromSunday));
  }

  static DateTime _getNthSundayOfMonth(int year, int month, int n) {
    final firstDay = DateTime(year, month, 1);
    final firstSunday = firstDay.add(Duration(days: (7 - firstDay.weekday) % 7));
    return firstSunday.add(Duration(days: 7 * (n - 1)));
  }

  static String getTimeDifference(String fromTimezone, String toTimezone) {
    final fromOffset = getTimezoneOffset(fromTimezone);
    final toOffset = getTimezoneOffset(toTimezone);
    final difference = toOffset - fromOffset;
    
    if (difference == 0) {
      return 'Same time';
    } else if (difference > 0) {
      return '+${difference} hours';
    } else {
      return '${difference} hours';
    }
  }

  static List<Map<String, dynamic>> getTimeComparison() {
    // Use UTC as the base time for consistent calculations
    final baseTimeUtc = DateTime.now().toUtc();
    
    return supportedTimezones.map((timezone) {
      final offset = getTimezoneOffset(timezone);
      final time = baseTimeUtc.add(Duration(hours: offset));
      
      return {
        'timezone': timezone,
        'name': getTimezoneName(timezone),
        'time': formatTime(time),
        'date': formatDateTime(time),
        'offset': offset,
      };
    }).toList();
  }
}
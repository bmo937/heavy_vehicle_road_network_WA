import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'opening_hours_widget.dart';

/// Helper methods for building UI components in feature displays
class FeatureDisplayHelpers {
  /// Helper to build a property row
  static Widget buildProperty(
      BuildContext context, String name, dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return const SizedBox.shrink();
    }
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              name,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value.toString(),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildSearchProperty(BuildContext context, dynamic value,
      {String? propertyType}) {
    if (value == null || value.toString().isEmpty) {
      return const SizedBox.shrink(); // Special handling for opening hours
    }
    if (propertyType == 'opening_hours') {
      // Debug: Print the type and value
      debugPrint('Opening hours value type: ${value.runtimeType}');
      debugPrint('Opening hours value: $value');

      Widget openingHoursWidget;

      if (value is Map<String, dynamic>) {
        debugPrint('Using Map<String, dynamic> path');
        openingHoursWidget = OpeningHoursWidget(openingHours: value);
      } else if (value is Map) {
        debugPrint('Using Map conversion path');
        // Convert Map to Map<String, dynamic>
        final Map<String, dynamic> convertedMap =
            Map<String, dynamic>.from(value);
        openingHoursWidget = OpeningHoursWidget(openingHours: convertedMap);
      } else if (value is String) {
        debugPrint(
            'Opening hours data is a String, attempting to parse as JSON');
        try {
          // Parse the string as JSON
          final dynamic parsed = jsonDecode(value);
          if (parsed is Map<String, dynamic>) {
            debugPrint('Successfully parsed opening hours JSON');
            openingHoursWidget = OpeningHoursWidget(openingHours: parsed);
          } else if (parsed is Map) {
            debugPrint(
                'Successfully parsed opening hours JSON (converting Map)');
            final Map<String, dynamic> convertedMap =
                Map<String, dynamic>.from(parsed);
            openingHoursWidget = OpeningHoursWidget(openingHours: convertedMap);
          } else {
            debugPrint('Parsed JSON is not a Map: ${parsed.runtimeType}');
            return const SizedBox.shrink();
          }
        } catch (e) {
          debugPrint('Failed to parse opening hours JSON: $e');
          // Try to manually parse the string format
          try {
            debugPrint('Attempting manual parsing of opening hours string');
            final Map<String, dynamic> manuallyParsed =
                _parseOpeningHoursString(value);
            if (manuallyParsed.isNotEmpty) {
              debugPrint('Successfully manually parsed opening hours');
              openingHoursWidget =
                  OpeningHoursWidget(openingHours: manuallyParsed);
            } else {
              debugPrint('Manual parsing returned empty result');
              return const SizedBox.shrink();
            }
          } catch (manualError) {
            debugPrint('Manual parsing also failed: $manualError');
            return const SizedBox.shrink();
          }
        }
      } else {
        debugPrint(
            'Opening hours data is not a Map or String, type: ${value.runtimeType}');
        return const SizedBox.shrink();
      }

      // Return the opening hours with icon aligned like other properties
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: Icon(Icons.access_time),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: openingHoursWidget,
            ),
          ],
        ),
      );
    }

    // Determine the property type from the value if not provided
    String? detectedType = propertyType;
    if (detectedType == null) {
      if (value.toString().contains('@')) {
        detectedType = 'email';
      } else if (value.toString().startsWith('http')) {
        detectedType = 'website';
      } else if (value.toString().contains(RegExp(r'[\d\-\+\(\)\s]+'))) {
        detectedType = 'phone';
      }
    }

    IconData icon = Icons.info;
    bool isClickable = false;

    // Set icon and clickable status based on type
    switch (detectedType) {
      case 'formatted_address':
      case 'vicinity':
        icon = Icons.location_on;
        break;
      case 'opening_hours':
        icon = Icons.access_time;
        break;
      case 'formatted_phone_number':
      case 'phone':
        icon = Icons.phone;
        isClickable = true;
        break;
      case 'website':
        icon = Icons.language;
        isClickable = true;
        break;
      case 'email':
        icon = Icons.email;
        isClickable = true;
        break;
      default:
        icon = Icons.info;
        break;
    }

    final colorScheme = Theme.of(context).colorScheme;

    Widget textWidget = Text(
      value.toString(),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isClickable ? colorScheme.primary : null,
            // decoration: isClickable ? TextDecoration.underline : null,
          ),
    );

    if (isClickable) {
      textWidget = InkWell(
        onTap: () => _launchUrl(detectedType!, value.toString()),
        child: textWidget,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            // flex: 2,
            child: Icon(icon),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: textWidget,
          ),
        ],
      ),
    );
  }

  /// Helper method to launch URLs, phone numbers, and emails
  static Future<void> _launchUrl(String type, String value) async {
    late Uri uri;

    try {
      switch (type) {
        case 'formatted_phone_number':
        case 'phone':
          // Remove any non-digit characters except + for international numbers
          String phoneNumber = value.replaceAll(RegExp(r'[^\d\+]'), '');
          uri = Uri(scheme: 'tel', path: phoneNumber);
          break;
        case 'website':
          // Ensure the URL has a scheme
          if (!value.startsWith('http://') && !value.startsWith('https://')) {
            uri = Uri.parse('https://$value');
          } else {
            uri = Uri.parse(value);
          }
          break;
        case 'email':
          uri = Uri(scheme: 'mailto', path: value);
          break;
        default:
          return;
      }

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        // Handle the case when URL cannot be launched
        debugPrint('Could not launch $uri');
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  /// Helper to build a subtitle
  static Widget buildSubTitle(BuildContext context, dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return const SizedBox.shrink();
    }
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        value.toString(),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.primary,
            ),
      ),
    );
  }

  /// Helper widget to display facility availability as a chip
  static Widget buildFacilityChip(
      BuildContext context, String name, bool available) {
    final colorScheme = Theme.of(context).colorScheme;

    // Use theme-appropriate colors
    final availableColor = colorScheme.primary.withValues(alpha: 0.2);
    final unavailableColor = colorScheme.onSurface.withValues(alpha: 0.1);
    final availableBorderColor = colorScheme.primary.withValues(alpha: 0.5);
    final unavailableBorderColor = colorScheme.onSurface.withValues(alpha: 0.2);
    final availableTextColor = colorScheme.primary;
    final unavailableTextColor = colorScheme.onSurface.withValues(alpha: 0.5);

    return Chip(
      label: Text(
        name,
        style: TextStyle(
          color: available ? availableTextColor : unavailableTextColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: available ? availableColor : unavailableColor,
      side: BorderSide(
        color: available ? availableBorderColor : unavailableBorderColor,
        width: 1,
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  /// Helper method to format timestamp
  static String formatTimestamp(String? timestamp) {
    if (timestamp == null) return 'Unknown';
    try {
      final dateTime = DateTime.parse(timestamp);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return timestamp; // Return original if parsing fails
    }
  }

  /// Helper method to get appropriate icon name
  static String getIncidentIconName(String closureType, String incidentType) {
    // Convert closure type to snake_case for asset naming
    final String closureTypeFormatted = closureType
        .toLowerCase()
        .replaceAll(' ', '_')
        .replaceAll('/', '_')
        .replaceAll('(', '')
        .replaceAll(')', '');

    // If both are provided, combine them
    if (closureType.isNotEmpty && incidentType.isNotEmpty) {
      return 'incident_$closureTypeFormatted';
    } else if (closureType.isNotEmpty) {
      return 'incident_$closureTypeFormatted';
    } else {
      return 'incident_generic';
    }
  }

  /// Helper method to build consistent feature headers
  static Widget buildFeatureHeader(
      BuildContext context, String title, IconData icon,
      {Color? backgroundColor}) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final bgColor = backgroundColor ?? colorScheme.primaryContainer;
    final onBgColor = backgroundColor != null
        ? (backgroundColor == colorScheme.errorContainer
            ? colorScheme.onErrorContainer
            : colorScheme.onPrimaryContainer)
        : colorScheme.onPrimaryContainer;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: onBgColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: textTheme.titleMedium?.copyWith(
                color: onBgColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Helper method to manually parse opening hours string format
  static Map<String, dynamic> _parseOpeningHoursString(String openingHoursStr) {
    try {
      // This is Dart map syntax, not JSON, so we need to parse it differently
      final String cleaned = openingHoursStr.trim();
      if (!cleaned.startsWith('{') || !cleaned.endsWith('}')) {
        return {};
      }

      // Extract the main components manually
      Map<String, dynamic> result = {};

      // Extract open_now
      final openNowMatch =
          RegExp(r'open_now:\s*(true|false)').firstMatch(cleaned);
      if (openNowMatch != null) {
        result['open_now'] = openNowMatch.group(1) == 'true';
      }

      // Extract periods array
      final periodsMatch = RegExp(r'periods:\s*\[(.*?)\](?=,\s*weekday_text)')
          .firstMatch(cleaned);
      if (periodsMatch != null) {
        List<Map<String, dynamic>> periods = [];
        final periodsStr = periodsMatch.group(1) ?? '';

        // Split periods by }, { pattern
        final periodMatches = RegExp(r'\{([^}]+)\}').allMatches(periodsStr);
        for (final periodMatch in periodMatches) {
          final periodStr = periodMatch.group(1) ?? '';
          Map<String, dynamic> period = {};

          // Extract close and open
          final closeMatch =
              RegExp(r'close:\s*\{([^}]+)\}').firstMatch(periodStr);
          final openMatch =
              RegExp(r'open:\s*\{([^}]+)\}').firstMatch(periodStr);

          if (closeMatch != null) {
            final closeStr = closeMatch.group(1) ?? '';
            final dayMatch = RegExp(r'day:\s*(\d+)').firstMatch(closeStr);
            final timeMatch = RegExp(r'time:\s*(\d+)').firstMatch(closeStr);
            if (dayMatch != null && timeMatch != null) {
              period['close'] = {
                'day': int.parse(dayMatch.group(1)!),
                'time': int.parse(timeMatch.group(1)!)
              };
            }
          }

          if (openMatch != null) {
            final openStr = openMatch.group(1) ?? '';
            final dayMatch = RegExp(r'day:\s*(\d+)').firstMatch(openStr);
            final timeMatch = RegExp(r'time:\s*(\d+)').firstMatch(openStr);
            if (dayMatch != null && timeMatch != null) {
              period['open'] = {
                'day': int.parse(dayMatch.group(1)!),
                'time': int.parse(timeMatch.group(1)!)
              };
            }
          }

          if (period.isNotEmpty) {
            periods.add(period);
          }
        }
        result['periods'] = periods;
      }

      // Extract weekday_text array
      final weekdayMatch =
          RegExp(r'weekday_text:\s*\[(.*?)\]').firstMatch(cleaned);
      if (weekdayMatch != null) {
        final weekdayStr = weekdayMatch.group(1) ?? '';
        List<String> weekdayText = [];

        // Split by comma and clean up
        final days = weekdayStr.split(',');
        for (String day in days) {
          final cleanDay = day.trim();
          if (cleanDay.isNotEmpty) {
            weekdayText.add(cleanDay);
          }
        }
        result['weekday_text'] = weekdayText;
      }

      debugPrint('Successfully parsed opening hours: $result');
      return result;
    } catch (e) {
      debugPrint('Manual parsing failed: $e');
      return {};
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_notifier.riverpod.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: SettingsContent(),
    );
  }
}

/// Refactored settings content widget for embedding in SheetBodyWidget
class SettingsContent extends ConsumerWidget {
  const SettingsContent({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(settingsNotifierProvider);
    final markerColor = ref.watch(markerColorNotifierProvider);
    // final useHighResolutionImages = ref.watch(useHighResolutionImagesProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Theme Mode Setting
          ListTile(
            leading: Icon(Icons.palette_outlined),
            title: Text('Theme Mode'),
            subtitle: Text(_getThemeModeDescription(themeMode)),
            trailing: DropdownButton<ThemeMode>(
              value: themeMode,
              items: [
                DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
                DropdownMenuItem(
                    value: ThemeMode.system, child: Text('System')),
              ],
              onChanged: (value) {
                ref
                    .read(settingsNotifierProvider.notifier)
                    .setThemeMode(value!);
              },
            ),
          ),

          Divider(),

          // Marker Color Setting
          ListTile(
            leading: Icon(Icons.location_on_outlined),
            title: Text('Marker Color'),
            subtitle: Text('Choose color for location markers'),
            trailing: GestureDetector(
              onTap: () => _showColorPicker(context, ref, markerColor),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: markerColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey, width: 1),
                ),
              ),
            ),
          ),

          Divider(),

          // App Information Section
          ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('About'),
            subtitle: Text('Roads Map v4'),
            onTap: () {
              _showAboutDialog(context);
            },
          ),
        ],
      ),
    );
  }

  String _getThemeModeDescription(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light theme';
      case ThemeMode.dark:
        return 'Dark theme';
      case ThemeMode.system:
        return 'Follow system setting';
    }
  }

  void _showColorPicker(
      BuildContext context, WidgetRef ref, Color currentColor) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Choose Marker Color'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Color grid
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Colors.red,
                    Colors.blue,
                    Colors.green,
                    Colors.orange,
                    Colors.purple,
                    Colors.pink,
                    Colors.teal,
                    Colors.amber,
                    Colors.indigo,
                    Colors.cyan,
                    Colors.lime,
                    Colors.deepOrange,
                    Colors.deepPurple,
                    Colors.brown,
                    Colors.grey,
                    Colors.black,
                  ].map((color) {
                    return GestureDetector(
                      onTap: () {
                        ref
                            .read(markerColorNotifierProvider.notifier)
                            .setMarkerColor(color);
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: currentColor == color
                                ? Colors.white
                                : Colors.grey,
                            width: currentColor == color ? 3 : 1,
                          ),
                        ),
                        child: currentColor == color
                            ? Icon(Icons.check, color: Colors.white, size: 20)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Roads Map',
      applicationVersion: '4.0.0',
      applicationIcon: Icon(Icons.map, size: 48),
      children: [
        Text(
            'A comprehensive road mapping application for truck navigation and traffic information.'),
      ],
    );
  }
}

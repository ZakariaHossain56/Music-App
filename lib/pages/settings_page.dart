import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:music_app/themes/theme_provider.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(25),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Dark mode label
          const Text(
            "Dark Mode",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),

          // Dark mode switch
          CupertinoSwitch(
            value: Provider.of<ThemeProvider>(context, listen: false).isDarkMode,
            onChanged: (value) =>
                Provider.of<ThemeProvider>(context, listen: false).toggleTheme(),
          ),
        ],
      ),
    );
  }
}

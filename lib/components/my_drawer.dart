import 'package:flutter/material.dart';
import 'package:music_app/pages/settings_page.dart';

class MyDrawer extends StatelessWidget {
  final Function(int) onSelectPage;
  const MyDrawer({super.key, required this.onSelectPage});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.background,
      child: Column(
        children: [
          DrawerHeader(
            child: Center(
              child: Icon(
                Icons.music_note,
                size: 40,
                color: Theme.of(context).colorScheme.inversePrimary,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(left: 25.0, top: 25),
            child: ListTile(
              leading: const Icon(Icons.home),
              title: const Text("H O M E"),
              onTap: () => onSelectPage(0),
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(left: 25.0, top: 0),
            child: ListTile(
              leading: const Icon(Icons.home),
              title: const Text("F A V O R I T E S"),
              onTap: () => onSelectPage(1),
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(left: 25.0, top: 0),
            child: ListTile(
              leading: const Icon(Icons.settings),
              title: const Text("S E T T I N G S"),
              onTap: () => onSelectPage(2),
            ),
          ),
        ],
      ),
    );
  }
}

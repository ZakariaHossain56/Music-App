import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:music_app/models/playlist_provider.dart';
import 'package:music_app/pages/home_page.dart';
import 'package:music_app/themes/theme_provider.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => PlaylistProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, PlaylistProvider>(
      builder: (context, themeProvider, playlistProvider, _) {
        if (!themeProvider.isInitialized) {
          return const MaterialApp(
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        // Wrap entire app with Listener to catch all gestures
        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) => playlistProvider.userInteracted(),
          onPointerMove: (_) => playlistProvider.userInteracted(),
          onPointerHover: (_) => playlistProvider.userInteracted(),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: themeProvider.themeData,
            home: const HomePage(),
            scaffoldMessengerKey: playlistProvider.scaffoldMessengerKey,
          ),
        );
      },
    );
  }
}

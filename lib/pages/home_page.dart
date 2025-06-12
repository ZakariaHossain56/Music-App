import 'dart:io';

import 'package:flutter/material.dart';
import 'package:music_app/components/my_drawer.dart';
import 'package:music_app/models/playlist_provider.dart';
import 'package:music_app/models/song.dart';
import 'package:music_app/pages/favorites_page.dart';
import 'package:music_app/pages/settings_page.dart'; // Import SettingsPage here
import 'package:music_app/pages/song_page.dart';
import 'package:music_app/utils/permissions.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0; // 0 = Home, 1 = Favorites, 2 = Settings

  //get the playlist provider
  late final PlaylistProvider playlistProvider;

  //check if the playlist is refreshing
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();

    // Get playlist provider
    playlistProvider = Provider.of<PlaylistProvider>(context, listen: false);

    // Ask for permission and trigger init()
    requestStoragePermission().then((_) {
      playlistProvider.init(); // <-- initialize the provider logic once
    });
  }

  //go to a song
  void goToSong(int songIndex) {
    //update current song index
    playlistProvider.currentSongIndex = songIndex;

    //navigate to song index (still push new page here)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SongPage(),
      ),
    );
  }

  // Home page content extracted as a widget
  Widget _buildHomeContent() {
    return Consumer<PlaylistProvider>(builder: (context, value, child) {
      final List<Song> playlist = value.playlist;

      if (playlist.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.greenAccent,
                ),
                strokeWidth: 3,
              ),
              const SizedBox(height: 20),
              Text(
                'Loading your music...',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Scanning device storage 🎵',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context)
                      .colorScheme
                      .onBackground
                      .withOpacity(0.6),
                ),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        itemCount: playlist.length,
        itemBuilder: (context, index) {
          final Song song = playlist[index];
          return ListTile(
            title: Text(
              song.songName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(song.artistName),
            leading: song.albumArtImagePath.startsWith('/')
                ? Image.file(
                    File(song.albumArtImagePath),
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  )
                : Image.asset(
                    song.albumArtImagePath,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
            onTap: () => goToSong(index),
          );
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Pages can be Home content or SettingsPage
    final List<Widget> pages = [
      _buildHomeContent(),
      const FavoritesPage(),
      const SettingsPage(),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _selectedIndex == 0
                  ? "P L A Y L I S T"
                  : _selectedIndex == 1
                      ? "F A V O R I T E S"
                      : "S E T T I N G S",
            ),
          ],
        ),
        centerTitle: true,
        actions: _selectedIndex == 0 || _selectedIndex == 1
            ? [
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () async {
                      if (_isRefreshing) return;

                      setState(() => _isRefreshing = true);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            _selectedIndex == 0
                                ? 'Refreshing playlist...'
                                : 'Refreshing favorites...',
                          ),
                          backgroundColor: Colors.green.shade700,
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                        ),
                      );

                      try {
                        if (_selectedIndex == 0) {
                          await playlistProvider.init();
                        } else if (_selectedIndex == 1) {
                          await playlistProvider
                              .init(); // refresh favorites + playlist
                        }

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                        _selectedIndex == 0
                          ? 'Playlist refreshed!'
                          : 'Favorites refreshed!',
                      ),
                              backgroundColor: Colors.green.shade700,
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Failed to refresh playlist'),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } finally {
                        if (mounted) setState(() => _isRefreshing = false);
                      }
                    },
                  ),
                ),
              ]
            : null,
      ),
      drawer: MyDrawer(
        onSelectPage: (index) {
          setState(() {
            _selectedIndex = index;
          });
          Navigator.pop(context); // Close the drawer
        },
      ),
      body: pages[_selectedIndex],
    );
  }
}

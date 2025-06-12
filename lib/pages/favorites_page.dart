import 'dart:io';

import 'package:flutter/material.dart';
import 'package:music_app/models/playlist_provider.dart';
import 'package:music_app/models/song.dart';
import 'package:music_app/pages/song_page.dart';
import 'package:provider/provider.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  bool _isRefreshing = false;

  late PlaylistProvider playlistProvider;

  @override
  void initState() {
    super.initState();
    playlistProvider = Provider.of<PlaylistProvider>(context, listen: false);
    //_refreshFavorites(); // Initial load
  }

  Future<void> _refreshFavorites() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);

    await playlistProvider.init(); // This will reload both playlist & favorites

    if (mounted) {
      setState(() => _isRefreshing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Favorites refreshed!'),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void goToSong(int actualIndex) {
    playlistProvider.currentSongIndex = actualIndex;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SongPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.background,
      child: Consumer<PlaylistProvider>(
        builder: (context, value, child) {
          final favoriteIndices = value.favoriteSongIndices.toList();
          final List<Song> playlist = value.playlist;

          if (favoriteIndices.isEmpty) {
            return Center(
              child: Text(
                "No favorite songs yet.",
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context)
                      .colorScheme
                      .onBackground
                      .withOpacity(0.6),
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: favoriteIndices.length,
            itemBuilder: (context, i) {
              final actualIndex = favoriteIndices[i];
              final song = playlist[actualIndex];

              return ListTile(
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
                title: Text(
                  song.songName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(song.artistName),
                onTap: () => goToSong(actualIndex),
                trailing: IconButton(
                  icon: const Icon(Icons.favorite, color: Colors.red),
                  onPressed: () {
                    final wasFavorite = playlistProvider.favoriteSongIndices
                        .contains(actualIndex);
                    playlistProvider.toggleFavorite(actualIndex);

                    if (wasFavorite) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Removed from favorites'),
                          backgroundColor: Colors.redAccent,
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

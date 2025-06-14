import 'dart:io';

import 'package:flutter/material.dart';
import 'package:music_app/models/playlist_provider.dart';
import 'package:music_app/models/song.dart';
import 'package:music_app/pages/song_page.dart';
import 'package:music_app/themes/theme_provider.dart';
import 'package:provider/provider.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  bool _isRefreshing = false;
  late PlaylistProvider playlistProvider;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  

  @override
  void initState() {
    super.initState();
    playlistProvider = Provider.of<PlaylistProvider>(context, listen: false);

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshFavorites() async {

    //check for dark mode
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;


    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);

    await playlistProvider.init();

    

    if (mounted) {
      setState(() => _isRefreshing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Favorites refreshed!',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black, // Text color
            ),
          ),
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

    //check for dark mode
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Container(
      color: Theme.of(context).colorScheme.background,
      child: Consumer<PlaylistProvider>(
        builder: (context, value, child) {
          final favoriteIndices = value.favoriteSongIndices.toList();
          final List<Song> playlist = value.playlist;

          final filteredFavorites = favoriteIndices
              .map((i) => (i, playlist[i]))
              .where((entry) =>
                  entry.$2.songName.toLowerCase().contains(_searchQuery) ||
                  entry.$2.artistName.toLowerCase().contains(_searchQuery))
              .toList();

          return Column(
            children: [
              // Search Bar
              Container(
                margin: const EdgeInsets.only(left: 8, right: 8),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search favorites...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => _searchController.clear(),
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),

              // Song List
              Expanded(
                child: filteredFavorites.isEmpty
                    ? Center(
                        child: Text(
                          _searchQuery.isNotEmpty
                              ? "No matching favorites."
                              : "No favorite songs yet.",
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context)
                                .colorScheme
                                .onBackground
                                .withOpacity(0.6),
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredFavorites.length,
                        itemBuilder: (context, index) {
                          final actualIndex = filteredFavorites[index].$1;
                          final song = filteredFavorites[index].$2;

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
                              icon:
                                  const Icon(Icons.favorite, color: Colors.red),
                              onPressed: () {
                                final wasFavorite = value.favoriteSongIndices
                                    .contains(actualIndex);
                                value.toggleFavorite(actualIndex);

                                

                                if (wasFavorite) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Removed from favorites',
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black, // Text color
                                        ),
                                      ),
                                      backgroundColor: Colors.redAccent,
                                      behavior: SnackBarBehavior.floating,
                                      duration: const Duration(seconds: 3),
                                      action: SnackBarAction(
                                        label: 'Undo',
                                        textColor: Colors.white,
                                        onPressed: () {
                                          // Re-add the song to favorites
                                          value.toggleFavorite(actualIndex);
                                        },
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

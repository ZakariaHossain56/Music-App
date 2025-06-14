import 'dart:io';
import 'package:flutter/material.dart';
import 'package:music_app/models/playlist_provider.dart';
import 'package:music_app/pages/song_page.dart'; // Make sure you import this
import 'package:provider/provider.dart';

class MiniPlayerBar extends StatelessWidget {
  const MiniPlayerBar({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PlaylistProvider>(context);
    final songIndex = provider.currentSongIndex;
    final song = (songIndex != null && songIndex < provider.playlist.length)
        ? provider.playlist[songIndex]
        : null;

    if (song == null) return const SizedBox.shrink();

    return Material(
      elevation: 12,
      color: Theme.of(context).cardColor,
      child: Container(
        height: 70,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            // Tappable area to navigate to SongPage
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SongPage(),
                    ),
                  );
                },
                child: Row(
                  children: [
                    // Album Art
                    song.albumArtImagePath.startsWith('/')
                        ? Image.file(
                            File(song.albumArtImagePath),
                            height: 50,
                            width: 50,
                            fit: BoxFit.cover,
                          )
                        : Image.asset(
                            song.albumArtImagePath,
                            height: 50,
                            width: 50,
                            fit: BoxFit.cover,
                          ),
                    const SizedBox(width: 12),

                    // Song Info
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song.songName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            song.artistName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Playback controls (not clickable for navigation)
            IconButton(
              icon: const Icon(Icons.skip_previous),
              onPressed: provider.playPreviousSong,
            ),
            IconButton(
              icon: Icon(
                provider.isPlaying ? Icons.pause : Icons.play_arrow,
              ),
              onPressed: provider.pauseOrResume,
            ),
            IconButton(
              icon: const Icon(Icons.skip_next),
              onPressed: provider.playNextSong,
            ),
          ],
        ),
      ),
    );
  }
}

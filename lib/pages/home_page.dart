import 'dart:io';

import 'package:flutter/material.dart';
import 'package:music_app/components/my_drawer.dart';
import 'package:music_app/models/playlist_provider.dart';
import 'package:music_app/models/song.dart';
import 'package:music_app/pages/song_page.dart';
import 'package:music_app/utils/permissions.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  //get the playlist provider
  late final dynamic playlistProvider;

  @override
  void initState(){
    super.initState();

    //get playlist provider
    playlistProvider = Provider.of<PlaylistProvider>(context, listen: false);

    // Ask for permission and load songs
    requestStoragePermission().then((_) {
      playlistProvider.loadSongsFromLocalStorage();
    });

  }

  //go to a song
  void goToSong(int songIndex){
    //update current song index
    playlistProvider.currentSongIndex = songIndex;

    //navigate to song index
    Navigator.push(
      context, 
      MaterialPageRoute(
        builder: (context) => SongPage(),
        ),
      );
  }

  




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text("P L A Y L I S T"),
        centerTitle: true,
        ),
      drawer: MyDrawer(),
      body: Consumer<PlaylistProvider>(
        builder: (context, value, child){
          //get the playlist 
          final List<Song> playlist = value.playlist;

          //return list view UI
            return ListView.builder(
              itemCount: playlist.length,
              itemBuilder: (context, index){
                //get individual song
                final Song song = playlist[index];

                //return list tile UI
                return ListTile(
                  title: Text(song.songName),
                  subtitle: Text(song.artistName),
                  // leading: Image.asset(song.albumArtImagePath),
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
        }
      ),
    );
  }
}
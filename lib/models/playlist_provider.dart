
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:music_app/models/song.dart';
import 'package:path_provider/path_provider.dart'; // optional if you want to use app directory
import 'package:flutter_media_metadata/flutter_media_metadata.dart';

class PlaylistProvider extends ChangeNotifier{
  //playlist of songs
  final List<Song> _playlist = [
    //song 1
    Song(
      songName: "On My Way", 
      artistName: "Sabrina Carpenter", 
      albumArtImagePath: "assets/images/on_my_way.png", 
      audioPath: "audio/On_My_Way.mp3",
      ),

    //song 2
    Song(
      songName: "Tally", 
      artistName: "BLACKPINK", 
      albumArtImagePath: "assets/images/tally.jpg", 
      audioPath: "audio/Tally.mp3",
      ),

    //song 3
    Song(
      songName: "Jawan", 
      artistName: "Arijit Singh", 
      albumArtImagePath: "assets/images/chaleya.jpg", 
      audioPath: "audio/Chaleya.mp3"
      ),  
  ];


  //playlist from storage
  Future<void> loadSongsFromLocalStorage() async {
  final Directory dir = Directory('/storage/emulated/0/Download');

  if (!dir.existsSync()) return;

  final List<Song> loadedSongs = [];

  for (var file in dir.listSync()) {
    if (file.path.endsWith('.mp3')) {
      final metadata = await MetadataRetriever.fromFile(File(file.path));
      final String songName = metadata.trackName ?? file.uri.pathSegments.last;
      final Object artist = metadata.trackArtistNames ?? "Unknown Artist";
      final String artistName = artist is List<String> 
      ? (artist).join(', ') 
      : artist.toString();

      print('Song: $songName');
      print('Artist: $artist');

      // Default album art
      String imagePath = "assets/images/tally.jpg";

      // Save embedded image
      if (metadata.albumArt != null) {
        final tempDir = await getTemporaryDirectory();
        final filename = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        final imageFile = File('${tempDir.path}/$filename');
        await imageFile.writeAsBytes(metadata.albumArt!);
        imagePath = imageFile.path;
      }

      loadedSongs.add(Song(
        songName: songName,
        artistName: artistName,
        albumArtImagePath: imagePath,
        audioPath: file.path,
      ));
    }
  }

  _playlist.clear();
  _playlist.addAll(loadedSongs);
  notifyListeners();
}


  //current song playing index
  int? _currentSongIndex;

  //A U D I O  P L A Y E R
  //audio player
  final AudioPlayer _audioPlayer = AudioPlayer();

  //durations
  Duration _currentDuration = Duration.zero;
  Duration _totalDuration = Duration.zero;

  //constructor
  PlaylistProvider(){
    listenToDuration();
    loadSongsFromLocalStorage(); // Auto-load on startup
    }

  //initially not playing
  bool _isPlaying = false;

  //play the song
  void play() async{
    final String path = _playlist[_currentSongIndex!].audioPath;
    await _audioPlayer.stop();  //stop current song
    await _audioPlayer.play(AssetSource(path)); //play the new song
    _isPlaying = true;
    notifyListeners();
  }

  //pause current song
  void pause() async{
    await _audioPlayer.pause();
    _isPlaying = false;
    notifyListeners();
  }

  //resume playing
  void resume() async{
    await _audioPlayer.resume();
    _isPlaying = true;
    notifyListeners();
  }

  //pause or resume
  void pauseOrResume() async{
    if(_isPlaying){
      pause();
    }
    else{
      resume();
    }
    notifyListeners();
  }

  //seek to a specific position in the current song
  void seek(Duration position) async{
    await _audioPlayer.seek(position);
  }

  //play next song
  void playNextSong(){
    if(_currentSongIndex != null){
      if(_currentSongIndex! < _playlist.length - 1){
        //go to the next song if it's not the last song
        currentSongIndex = _currentSongIndex! + 1;
      }
      else{
        //if it's the last song, loop back to the first song
        currentSongIndex = 0;
      }
    }
  }

  //play previous song
  void playPreviousSong() async{
    //if more than 2 seconds have passed, restart the current song
    if(_currentDuration.inSeconds > 2){
      seek(Duration.zero);

    }
    //if it's within first 2 seconds of the song, go to previous song
    else{
      if(_currentSongIndex! > 0){
        currentSongIndex = _currentSongIndex! - 1;
      }
      else{
        //it it's the first song, loop back to last song
        currentSongIndex = _playlist.length - 1;
      }
    }
  }

  //listen to duration
  void listenToDuration(){
    //listen for total duration
    _audioPlayer.onDurationChanged.listen((newDuration){
      _totalDuration = newDuration;
      notifyListeners();
    });

    //listen for current duration
    _audioPlayer.onPositionChanged.listen((newPosition){
      _currentDuration = newPosition;
      notifyListeners();
    });

    //listen for song completion
    _audioPlayer.onPlayerComplete.listen((event){
      playNextSong();
    });

  }

  //dispose audio player  



  //G E T T E R S
  //get the playlist
  List<Song> get playlist => _playlist;

  //get the current song index
  int? get currentSongIndex => _currentSongIndex;

  //get the boolean value if it's playing
  bool get isPlaying => _isPlaying;

  //get current duration
  Duration get currentDuration => _currentDuration;

  //get total duration 
  Duration get totalDuration => _totalDuration;



  //S E T T E R S
  set currentSongIndex(int? newIndex){
    //update current song index
    _currentSongIndex = newIndex;
    if(newIndex != null){
      play(); //play the song at the new index
    }

    //update UI
    notifyListeners();
  }
}
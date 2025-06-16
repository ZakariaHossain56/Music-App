import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:music_app/models/song.dart';
import 'package:music_app/themes/theme_provider.dart';
import 'package:music_app/utils/permissions.dart';
import 'package:path_provider/path_provider.dart'; // optional if you want to use app directory
import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import 'dart:convert'; // For json
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';

class PlaylistProvider extends ChangeNotifier {
  //playlist of songs
  final List<Song> _playlist = [
    //song 1
    //   Song(
    //     songName: "On My Way",
    //     artistName: "Sabrina Carpenter",
    //     albumArtImagePath: "assets/images/on_my_way.png",
    //     audioPath: "audio/On_My_Way.mp3",
    //   ),

    //   //song 2
    //   Song(
    //     songName: "Tally",
    //     artistName: "BLACKPINK",
    //     albumArtImagePath: "assets/images/tally.jpg",
    //     audioPath: "audio/Tally.mp3",
    //   ),

    //   //song 3
    //   Song(
    //       songName: "Jawan",
    //       artistName: "Arijit Singh",
    //       albumArtImagePath: "assets/images/chaleya.jpg",
    //       audioPath: "audio/Chaleya.mp3"),
  ];

  late ThemeProvider _themeProvider;
  void updateTheme(ThemeProvider themeProvider) {
    _themeProvider = themeProvider;
  }

  bool get isDarkMode => _themeProvider.isDarkMode;
  //check for dark mode

// Inactivity timer to pause playback after 30 minutes of inactivity
  Timer? _inactivityTimer;

// Add this to your PlaylistProvider class
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  SnackBar? _currentSnackBar;

  Future<void> userInteracted() async {
    //check for dark mode
    final isDark = isDarkMode;

    // Remove any existing snackbar immediately
    scaffoldMessengerKey.currentState?.removeCurrentSnackBar();
    _currentSnackBar = null;

    _inactivityTimer?.cancel();

    if (_isPlaying) {
      _inactivityTimer = Timer(const Duration(minutes: 30), () async {
        if (_isPlaying) {
          await pauseDueToInactivity();
          // Show persistent snackbar that won't auto-dismiss
          _currentSnackBar = SnackBar(
            content: Text(
              'Playback paused due to inactivity',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.white, // Text color
              ),
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(days: 1),
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {
                scaffoldMessengerKey.currentState?.removeCurrentSnackBar();
              },
            ),
          );
          scaffoldMessengerKey.currentState?.showSnackBar(_currentSnackBar!);
        }
      });
    }
    notifyListeners();
  }

  //favorite songs
  // A set to keep track of favorite song indices
  final Set<int> _favoriteSongIndices = {};

  bool isFavorite(int index) => _favoriteSongIndices.contains(index);

  void toggleFavorite(int index) {
    if (_favoriteSongIndices.contains(index)) {
      _favoriteSongIndices.remove(index);
    } else {
      _favoriteSongIndices.add(index);
    }
    notifyListeners();
    _saveFavoritesToJson();
  }

  //current song playing index
  int? _currentSongIndex;

  //A U D I O  P L A Y E R
  //audio player
  AudioPlayer _audioPlayer = AudioPlayer();

  //durations
  Duration _currentDuration = Duration.zero;
  Duration _totalDuration = Duration.zero;

  //initially not playing
  bool _isPlaying = false;

  bool _isShuffling = false;
  LoopMode _loopMode = LoopMode.off; // We'll define this enum below

  bool _showInactivityWarning = false;

  //constructor
  PlaylistProvider() {
    listenToDuration();
  }

  // Update init method to load from JSON first:

  Future<void> init() async {
    bool loadedFromJson = await _loadPlaylistFromJson();
    if (!loadedFromJson) {
      await loadSongsFromLocalStorage();
      await _savePlaylistToJson();
    }
    await _loadFavoritesFromJson();
  }

// Save playlist to JSON
  Future<void> _savePlaylistToJson() async {
    final file = await _playlistFile;
    final jsonList = _playlist.map((song) => song.toJson()).toList();
    await file.writeAsString(jsonEncode(jsonList));
  }

// Load playlist from JSON
  Future<bool> _loadPlaylistFromJson() async {
    try {
      final file = await _playlistFile;
      if (!await file.exists()) return false;

      final content = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(content);

      _playlist.clear();
      for (var jsonSong in jsonList) {
        _playlist.add(Song.fromJson(jsonSong));
      }
      notifyListeners();
      return true;
    } catch (e) {
      print('Failed to load playlist JSON: $e');
      return false;
    }
  }

// Save favorites to JSON
  Future<void> _saveFavoritesToJson() async {
    final file = await _favoritesFile;
    await file.writeAsString(jsonEncode(_favoriteSongIndices.toList()));
  }

// Load favorites from JSON
  Future<void> _loadFavoritesFromJson() async {
    try {
      final file = await _favoritesFile;
      if (!await file.exists()) return;

      final content = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(content);
      _favoriteSongIndices.clear();
      for (var idx in jsonList) {
        if (idx is int) _favoriteSongIndices.add(idx);
      }
      notifyListeners();
    } catch (e) {
      print('Failed to load favorites JSON: $e');
    }
  }

//   Future<void> loadSongsFromLocalStorage() async {
//   final hasPermission = await requestStoragePermission();
//   if (!hasPermission) return;

//   final List<Directory> commonDirs = [
//     Directory('/storage/emulated/0/Music'),
//     Directory('/storage/emulated/0/Download'),
//     // Directory('/storage/emulated/0/Podcasts'),
//   ];

//   final List<Song> loadedSongs = [];
//   int filesProcessed = 0;
//   debugPrint("Starting song scan...");

//   for (final dir in commonDirs) {
//     if (!(await dir.exists())) {
//       debugPrint("Directory ${dir.path} doesn't exist");
//       continue;
//     }

//     debugPrint("Scanning ${dir.path}...");

//     try {
//       // Get all files recursively
//       final fileEntities = dir.list(recursive: true);

//       await for (final entity in fileEntities) {
//         // Skip if not a file or not an MP3
//         if (entity is! File || !entity.path.toLowerCase().endsWith('.mp3')) {
//           continue;
//         }

//         // Now we know it's a File object
//         final file = entity;
//         filesProcessed++;

//         if (filesProcessed % 10 == 0) {
//           debugPrint("Processed $filesProcessed files...");
//         }

//         try {
//           final metadata = await MetadataRetriever.fromFile(file);
//           final songName = metadata.trackName ?? path.basenameWithoutExtension(file.path);
//           final artist = metadata.trackArtistNames ?? "Unknown Artist";
//           final artistName = artist is List<String> ? artist.join(', ') : artist.toString();

//           String imagePath = "assets/images/on_my_way.png";

//           if (metadata.albumArt != null) {
//             final tempDir = await getTemporaryDirectory();
//             final filename = '${DateTime.now().millisecondsSinceEpoch}.jpg';
//             final imageFile = File('${tempDir.path}/$filename');
//             await imageFile.writeAsBytes(metadata.albumArt!);
//             imagePath = imageFile.path;
//           }

//           loadedSongs.add(Song(
//             songName: songName,
//             artistName: artistName,
//             albumArtImagePath: imagePath,
//             audioPath: file.path,
//           ));
//         } catch (e) {
//           debugPrint("Error processing ${file.path}: $e");
//         }
//       }
//     } catch (e) {
//       debugPrint("Error scanning ${dir.path}: $e");
//     }
//   }

//   debugPrint("Scan complete. Found ${loadedSongs.length} songs.");

//   _playlist.clear();
//   _playlist.addAll(loadedSongs);
//   notifyListeners();
//   await _savePlaylistToJson();
// }

  Future<void> loadSongsFromLocalStorage() async {
    final Directory downloadDir = Directory('/storage/emulated/0/Download');

    if (!downloadDir.existsSync()) return;

    final List<Song> loadedSongs = [];

    for (var file in downloadDir.listSync()) {
      if (file.path.endsWith('.mp3')) {
        final metadata = await MetadataRetriever.fromFile(File(file.path));
        final String songName =
            metadata.trackName ?? file.uri.pathSegments.last;
        final Object artist = metadata.trackArtistNames ?? "Unknown Artist";
        final String artistName =
            artist is List<String> ? artist.join(', ') : artist.toString();

        print('Song: $songName');
        print('Artist: $artistName');

        // Default album art
        String imagePath = "assets/images/on_my_way.png";

        // Save embedded image in app-private directory
        if (metadata.albumArt != null) {
          final Directory appDocDir = await getApplicationDocumentsDirectory();
          final String imageDirPath = '${appDocDir.path}/album_arts';

          final Directory imageDir = Directory(imageDirPath);
          if (!imageDir.existsSync()) {
            await imageDir.create(recursive: true);
          }

          final String filename =
              '${DateTime.now().millisecondsSinceEpoch}.jpg';
          final File imageFile = File('$imageDirPath/$filename');

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

    if (loadedSongs.isNotEmpty) {
      _playlist.clear();
      _playlist.addAll(loadedSongs);
      notifyListeners();
      await _savePlaylistToJson();
    }
  }

  

//for inactivity timer
  Duration _lastKnownPosition = Duration.zero;
  StreamSubscription<Duration>? _positionSubscription;
  // Optional: don't seek if paused manually
  bool _pausedByInactivity = false;

  void _startListeningPosition() {
    _positionSubscription?.cancel();
    _positionSubscription = _audioPlayer.onPositionChanged.listen((pos) {
      _lastKnownPosition = pos;
    });
  }

  void _stopListeningPosition() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }


  void play() async {
    final String path = _playlist[_currentSongIndex!].audioPath;
    await _audioPlayer.stop(); // stop current song
    await _audioPlayer.play(DeviceFileSource(path)); // play from file path
    _isPlaying = true;
    notifyListeners();

    userInteracted(); // reset/start inactivity timer
     _startListeningPosition(); // start updating position continuously
  }

// Always update position when pausing
  Future<void> pause() async {
  _inactivityTimer?.cancel();

  // Use cached last known position, no need to await onPositionChanged.first
  // _lastKnownPosition is already updated liv
  await _audioPlayer.pause();
  _isPlaying = false;
  notifyListeners();

  _stopListeningPosition(); // stop position updates since paused
}

Future<void> pauseDueToInactivity() async {
  await pause();
  _pausedByInactivity = true;
}

Future<void> resume() async {
  if (_pausedByInactivity) {
    await _audioPlayer.seek(_lastKnownPosition);
  }

  await _audioPlayer.resume();
  _isPlaying = true;
  _pausedByInactivity = false;
  notifyListeners();

  userInteracted(); // restart the inactivity timer
  _startListeningPosition(); // resume position tracking
}



  Future<void> pauseOrResume() async {
    if (_isPlaying) {
      await pause();
    } else {
      await resume();
    }
  }

  //seek to a specific position in the current song
  void seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  //play next song
  void playNextSong() {
    if (_currentSongIndex != null) {
      if (_currentSongIndex! < _playlist.length - 1) {
        //go to the next song if it's not the last song
        currentSongIndex = _currentSongIndex! + 1;
      } else {
        //if it's the last song, loop back to the first song
        currentSongIndex = 0;
      }
    }
  }

  //play previous song
  void playPreviousSong() async {
    //if more than 2 seconds have passed, restart the current song
    if (_currentDuration.inSeconds > 2) {
      seek(Duration.zero);
    }
    //if it's within first 2 seconds of the song, go to previous song
    else {
      if (_currentSongIndex! > 0) {
        currentSongIndex = _currentSongIndex! - 1;
      } else {
        //it it's the first song, loop back to last song
        currentSongIndex = _playlist.length - 1;
      }
    }
  }

  //toggle loop mode
  void toggleShuffle() {
    _isShuffling = !_isShuffling;
    notifyListeners();
  }

// Toggle loop mode
  void toggleLoop() {
    switch (_loopMode) {
      case LoopMode.off:
        _loopMode = LoopMode.one;
        break;
      case LoopMode.one:
        _loopMode = LoopMode.all;
        break;
      case LoopMode.all:
        _loopMode = LoopMode.off;
        break;
    }
    notifyListeners();
  }

  //listen to duration
  void listenToDuration() {
    //listen for total duration
    _audioPlayer.onDurationChanged.listen((newDuration) {
      _totalDuration = newDuration;
      notifyListeners();
    });

    //listen for current duration
    _audioPlayer.onPositionChanged.listen((newPosition) {
      _currentDuration = newPosition;
      notifyListeners();
    });

    // //listen for song completion
    // _audioPlayer.onPlayerComplete.listen((event) {
    //   playNextSong();
    // });

    _audioPlayer.onPlayerComplete.listen((event) {
      if (_loopMode == LoopMode.one) {
        play(); // replay the current song
      } else if (_isShuffling) {
        _currentSongIndex = _getRandomSongIndex(exclude: _currentSongIndex);
        play();
      } else if (_loopMode == LoopMode.all) {
        playNextSong(); // already wraps to 0 at the end
      } else {
        // LoopMode.off
        if (_currentSongIndex! < _playlist.length - 1) {
          playNextSong();
        } else {
          _isPlaying = false;
          notifyListeners();
        }
      }
    });
  }

  //play a random song
  int _getRandomSongIndex({int? exclude}) {
    final indices = List<int>.generate(_playlist.length, (i) => i);
    if (exclude != null && indices.length > 1) {
      indices.remove(exclude);
    }
    indices.shuffle();
    return indices.first;
  }

  //dispose audio player
  @override
  void dispose() {
    _inactivityTimer?.cancel();
    scaffoldMessengerKey.currentState?.removeCurrentSnackBar();
    _audioPlayer.dispose();
    super.dispose();
  }

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

  //get favorite song indices
  Set<int> get favoriteSongIndices => _favoriteSongIndices;

  //get playlist file
  Future<File> get _playlistFile async {
    final dir = await getApplicationDocumentsDirectory();
    return File(path.join(dir.path, 'playlist.json'));
  }

  //get favorites file
  Future<File> get _favoritesFile async {
    final dir = await getApplicationDocumentsDirectory();
    return File(path.join(dir.path, 'favorites.json'));
  }

  //get shuffling and loop mode
  bool get isShuffling => _isShuffling;
  LoopMode get loopMode => _loopMode;

  //get show inactivity warning
  bool get showInactivityWarning => _showInactivityWarning;

  //S E T T E R S
  set currentSongIndex(int? newIndex) {
    //update current song index
    _currentSongIndex = newIndex;
    if (newIndex != null) {
      play(); //play the song at the new index
    }

    //update UI
    notifyListeners();
  }
}

enum LoopMode {
  off,
  one,
  all,
}

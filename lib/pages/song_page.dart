
import 'package:flutter/material.dart';
import 'package:music_app/components/neu_box.dart';
import 'package:music_app/models/playlist_provider.dart';
import 'package:provider/provider.dart';

class SongPage extends StatelessWidget {
  const SongPage({super.key});

  //covert duration into min:sec
  String formatTime(Duration duration){

    String twoDigitSeconds = duration.inSeconds.remainder(60).toString().padLeft(2,'0');
    String formattedTime = "${duration.inMinutes}:$twoDigitSeconds";

    return formattedTime;
  }




  @override
  Widget build(BuildContext context) {
    return Consumer<PlaylistProvider>(
      builder: (context, value, child) {

        //get playlist
        final playlist = value.playlist;

        //get current song 
        final currentSong = playlist[value.currentSongIndex ?? 0];


        //return Scaffold UI
        return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(left: 25, right: 25, bottom: 25),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                //app bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    //back button
                    IconButton(onPressed: () => Navigator.pop(context), 
                    icon: Icon(Icons.arrow_back),
                    ),
            
                    //title
                    Text("P L A Y L I S T"),
            
                    //menu button
                    IconButton(
                      onPressed: (){}, 
                      icon: Icon(Icons.menu),
                      )
                  ],
                ),

                const SizedBox(height: 45,),
            
                //album artwork
                NeuBox(
                  child: Column(
                    children: [
                      //image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(currentSong.albumArtImagePath),
                        ),

                        //song, artist name and icon
                        Padding(
                          padding: EdgeInsets.all(15),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              //song and artist name
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    currentSong.songName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                    ),
                                    Text(currentSong.artistName),
                                ],
                              ),

                              //heart icon
                              Icon(
                                Icons.favorite,
                                color: Colors.red,
                              )
                            ],
                          ),
                          )
                    ],
                  ),
                  ),

                  const SizedBox(height: 25),
            
                //playback progress
                Column(
                  children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 25),
                      child:  Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          //start time
                          Text(formatTime(value.currentDuration)),

                          //shuffle icon
                          Icon(Icons.shuffle),

                          //repeat icon
                          Icon(Icons.repeat),

                          //end time
                          Text(formatTime(value.totalDuration)),
                        ],
                      ),
                ),

                //song duration progress
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8),
                        ),
                        child: Slider(
                          min: 0,
                          max: value.totalDuration.inSeconds.toDouble(),
                          value: value.currentDuration.inSeconds.toDouble(), 
                          activeColor: Colors.green,
                          onChanged: (double double){
                            //during when the user is sliding around
                          },
                          onChangeEnd: (double double){
                            //sliding has finished, go to that position in song duration
                            value.seek(Duration(seconds: double.toInt()));
                          },
                          ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25,),
                  
            
                //playback controls
                Row(
                  children: [
                    //skip previous
                    Expanded(
                      child: GestureDetector(
                        onTap: value.playPreviousSong,
                        child: NeuBox(
                          child: Icon(Icons.skip_previous),
                        ),
                      ),
                      ),

                      const SizedBox(width: 20,),

                    //play pause
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: value.pauseOrResume,
                        child: NeuBox(
                          child: Icon(value.isPlaying ? Icons.pause : Icons.play_arrow),
                        ),
                      ),
                      ),

                      const SizedBox(width: 20,),
                    
                    //skip forward
                    Expanded(
                      child: GestureDetector(
                        onTap: value.playNextSong,
                        child: NeuBox(
                          child: Icon(Icons.skip_next),
                        ),
                      ),
                      ),
                  ],
                )
              ],
            ),
          ),
        ),
      );
      }
    );
  }
}
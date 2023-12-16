import 'dart:ui';

import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rxdart/rxdart.dart';

class SongsList extends StatefulWidget {
  const SongsList({super.key});

  @override
  State<SongsList> createState() => _SongsListState();
}

class _SongsListState extends State<SongsList> {
  //on audio query plugin
  final OnAudioQuery _audioQuery = OnAudioQuery();

  //player
  final AudioPlayer _player = AudioPlayer();

  // Indicate if application has permission to the library.
  bool _hasPermission = false;

  PageStorageKey songStorageKey =
      const PageStorageKey("restore_songs_scroll_pos");

  bool _isPlayControlWidgetVisible = false;
  List<SongModel> songs = <SongModel>[];
  List<PlaylistModel> playlist = <PlaylistModel>[];

  // Query Albums
  List<AlbumModel> albums = <AlbumModel>[];

  // Query Albums

  String currentSongTitle = '';
  int currentIndex = 0;

  //initial state method to request storage permission
  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    // Check and request for permission.
    checkAndRequestPermissions();
  }

  //dispose the player when done
  @override
  void dispose() {
    _player.dispose();
    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: ()async {
        // changePlayerControlsWidgetVisibility();
        if(_isPlayControlWidgetVisible == true){
          _isPlayControlWidgetVisible = !_isPlayControlWidgetVisible;
          setState(() {

          });
          return false;
        }
        return true;

      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                height: double.infinity,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF303151).withOpacity(0.6),
                      const Color(0xFF303151).withOpacity(0.9),
                    ],
                  ),
                  // borderRadius: BorderRadius.circular(25),
                  // border: Border.all(width: 2, color: Colors.white30),
                ),
                child: _isPlayControlWidgetVisible == true
                    ? playControlWidget()
                    : tabsControlWidget(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void requestPermission() {
    Permission.storage.request();
  }

  Widget songsListView() {
    //use future builder to create a list view with songs
    return Column(
      children: [
        Expanded(
          child: !_hasPermission
              ? noAccessToLibraryWidget()
              : FutureBuilder<List<SongModel>>(
                  future: _audioQuery.querySongs(
                    sortType: SongSortType.DATE_ADDED,
                    orderType: OrderType.DESC_OR_GREATER,
                    uriType: UriType.EXTERNAL,
                    ignoreCase: true,
                  ),
                  builder: (context, item) {
                    //loading contact indicator
                    if (item.data == null) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    } else if (item.data!.isEmpty) {
                      return const Center(
                        child: Text(
                          "No Songs Found!, Add Some",
                          style: TextStyle(color: Colors.white30),
                        ),
                      );
                    }
                    //songs are available build list view
                    updateSongsLists(item.data!);
                    return ListView.builder(
                      key: songStorageKey, //for restoring data
                      itemCount: songs.length,

                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.only(top: 15, right: 12),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF30314D),
                            borderRadius: BorderRadius.circular(10),

                          ),
                          child: Row(
                            children: [
                              //album artwork
                              Flexible(
                                child: QueryArtworkWidget(
                                    id: songs[index].id,
                                    type: ArtworkType.AUDIO),
                              ),
                              //song title, size and duration
                              Flexible(
                                child: InkWell(
                                  onTap: () async {
                                    changePlayerControlsWidgetVisibility();

                                    //play song

                                    if (_player.playing) {
                                      await _player.setAudioSource(
                                          createPlaylist(item.data!),
                                          initialIndex: index);
                                    } else {
                                      await _player.seek(
                                          const Duration(microseconds: 0),
                                          index: index);
                                    }

                                    await _player.play();
                                  }, //play song
                                  child:
                                      //song title
                                      Padding(
                                        padding: const EdgeInsets.only(left: 10),
                                        child: Column(
                                    crossAxisAlignment:
                                          CrossAxisAlignment.start,

                                    children: [
                                        Text(
                                          songs.elementAt(index).artist ?? "",
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          songs.elementAt(index).album ?? "",
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w300,
                                          ),
                                        ),
                                    ],
                                  ),
                                      ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
        //bottom Row
        StreamBuilder<int?>(
          stream: _player.currentIndexStream,
          builder: (context, snapshot) {
            final currentIndex = snapshot.data;
            if (currentIndex != null) {
              return Container(
                decoration: const BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(20),
                      topLeft: Radius.circular(20),
                    )),
                margin: const EdgeInsets.only(right: 15),
                padding: const EdgeInsets.only(top: 5),
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height * 0.07,
                child: Padding(
                    padding: const EdgeInsets.only(right: 0),
                    child: ListTile(
                      title: Text(
                        songs[currentIndex].title ?? '',
                        style: const TextStyle(color: Colors.white),
                      ),
                      leading: CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.transparent,
                        child: QueryArtworkWidget(
                          id: songs[currentIndex].id,
                          type: ArtworkType.AUDIO,
                          artworkBorder: BorderRadius.circular(4),
                        ),
                      ),
                      trailing: InkWell(
                        onTap: () {
                          if (_player.playing) {
                            _player.pause();
                          } else if (_player.currentIndex != null) {
                            _player.play();
                          }
                        },
                        child: StreamBuilder<bool>(
                          stream: _player.playingStream,
                          builder: (context, snapshot) {
                            bool? playingState = snapshot.data;
                            if (playingState != null && playingState) {
                              return const Icon(
                                Icons.pause_circle_outline_outlined,
                                size: 48,
                                color: Colors.white70,
                              );
                            }
                            return const Icon(
                              Icons.play_circle_outline_outlined,
                              size: 48,
                              color: Colors.white70,
                            );
                          },
                        ),
                      ),
                      onTap: () async {
                        changePlayerControlsWidgetVisibility();
                        //play song
                        await _player.play();
                      },
                    )),
              );
            }
            return Container();
          },
        ),
      ],
    );
  }

  //player position and current playing song duration state stream
  Stream<PositionDurationState> get _positionDurationStateStream =>
      Rx.combineLatest2<Duration, Duration?, PositionDurationState>(
          _player.positionStream,
          _player.durationStream,
          (position, duration) => PositionDurationState(
              position: position, duration: duration ?? Duration.zero));

  //player control widget
  Container playControlWidget() {
    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height,
      padding: const EdgeInsets.only(top: 10, right: 20, left: 20),
      child: Column(
        children: [
          // control exit btn and like btn
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: changePlayerControlsWidgetVisibility,
                //hides the player view
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Color(0xFF899CCF),
                  size: 30,
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 20,
          ),
          //artwork container
          SizedBox(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.4,
            child: StreamBuilder<int?>(
              stream: _player.currentIndexStream,
              builder: (context, snapshot) {
                final currentIndex = snapshot.data;
                if (currentIndex != null) {
                  return QueryArtworkWidget(
                    id: songs[currentIndex].id,
                    type: ArtworkType.AUDIO,
                    artworkBorder: BorderRadius.circular(4),
                  );
                }
                return const CircularProgressIndicator();
              },
            ),
          ),

          //current song title container
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 20),
            child: StreamBuilder<int?>(
              stream: _player.currentIndexStream,
              builder: (context, snapshot) {
                final currentIndex = snapshot.data;
                if (currentIndex != null) {
                  return Text(
                    nameWithoutExtension(songs[currentIndex].title),
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.bold,
                        fontSize: 24),
                  );
                }
                return const Text("");
              },
            ),
          ),
          //current singer
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 8, bottom: 30),
            child: StreamBuilder<int?>(
              stream: _player.currentIndexStream,
              builder: (context, snapshot) {
                final currentIndex = snapshot.data;
                if (currentIndex != null) {
                  return Text(
                    nameWithoutExtension(songs[currentIndex].artist ?? ""),
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.8), fontSize: 18),
                  );
                }
                return const Text("");
              },
            ),
          ),
          //seek bar,current position and total song duration
          Container(
            padding: EdgeInsets.zero,
            margin: const EdgeInsets.only(bottom: 4),

            //slider bar duration state stream
            child: StreamBuilder<PositionDurationState>(
              stream: _positionDurationStateStream,
              builder: (context, snapshot) {
                final positionDurationState = snapshot.data;
                final progress =
                    positionDurationState?.position ?? Duration.zero;
                final duration =
                    positionDurationState?.duration ?? Duration.zero;

                return ProgressBar(
                  progress: progress,
                  total: duration,
                  baseBarColor: Colors.white54,
                  progressBarColor: Colors.white,
                  thumbColor: Colors.white,
                  timeLabelTextStyle: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                  onSeek: (duration) {
                    _player.seek(duration);
                  },
                );
              },
            ),
          ),
          const SizedBox(
            height: 30,
          ),
          //repeat mode, shuffle, seek pre, play/pause, list container
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              //repeat mode and shuffle
              InkWell(
                onTap: () {
                  final loopMode = _player.loopMode;
                  final shuffle = _player.shuffleModeEnabled;
                  if (LoopMode.all == loopMode && !shuffle) {
                    _player.setLoopMode(LoopMode.one);
                  } else if (LoopMode.one == loopMode && !shuffle) {
                    _player.setLoopMode(LoopMode.all);
                    _player.setShuffleModeEnabled(true);
                  } else {
                    _player.setLoopMode(LoopMode.all);
                    _player.setShuffleModeEnabled(false);
                  }
                },
                child: StreamBuilder<LoopMode>(
                  stream: _player.loopModeStream,
                  builder: (context, snapshot) {
                    final loopMode = snapshot.data;
                    final shuffle = _player.shuffleModeEnabled;
                    if (LoopMode.all == loopMode && !shuffle) {
                      return const Icon(
                        Icons.repeat,
                        color: Colors.white,
                        size: 32,
                      );
                    } else if (LoopMode.one == loopMode && !shuffle) {
                      return const Icon(
                        Icons.repeat_one,
                        color: Colors.white,
                        size: 32,
                      );
                    } else if (LoopMode.all == loopMode && shuffle) {
                      return const Icon(
                        Icons.shuffle,
                        color: Colors.white,
                        size: 32,
                      );
                    }
                    return const Icon(
                      Icons.shuffle_sharp,
                      color: Colors.grey,
                      size: 32,
                    );
                  },
                ),
              ),
              //skip to prev

              InkWell(
                onTap: () {
                  if (_player.hasPrevious) {
                    _player.seekToPrevious();
                  }
                },
                child: const Icon(
                  Icons.skip_previous,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              //play pause

              InkWell(
                onTap: () {
                  if (_player.playing) {
                    _player.pause();
                  } else if (_player.currentIndex != null) {
                    _player.play();
                  }
                },
                child: Container(
                  alignment: Alignment.center,
                  height: 55,
                  width: 55,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),

                  child: StreamBuilder<bool>(
                    stream: _player.playingStream,
                    builder: (context, snapshot) {
                      bool? playingState = snapshot.data;
                      if (playingState != null && playingState) {
                        return const Icon(
                          Icons.pause,
                          size: 35,
                          color: Color(0xFF31314F),
                        );
                      }
                      return const Icon(
                        Icons.play_arrow_sharp,
                        size: 35,
                        color: Color(0xFF31314F),
                      );
                    },
                  ),
                ),
              ),
              //skip next
              InkWell(
                onTap: () {
                  if (_player.hasNext) {
                    _player.seekToNext();
                  }
                },
                child: const Icon(
                  Icons.skip_next,
                  color: Colors.white,
                  size: 32,
                ),
              ),

              //go to play list
              InkWell(
                onTap: () {
                  changePlayerControlsWidgetVisibility();
                },
                child: const Icon(
                  Icons.playlist_play,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

//tabs control page widgets
  DefaultTabController tabsControlWidget() {
    return DefaultTabController(
      length: 1,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF303151).withOpacity(0.6),
                const Color(0xFF303151).withOpacity(0.9),
              ]),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 20, left: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          onTap: () {},
                          child: const Icon(
                            Icons.sort_rounded,
                            color: Color(0xFF899CCF),
                            size: 30,
                          ),
                        ),
                        InkWell(
                          onTap: () {},
                          child: const Icon(
                            Icons.more_vert,
                            color: Color(0xFF899CCF),
                            size: 30,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 30,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Text(
                      "Hello",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 50),
                    child: Text(
                      "Welcome...",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const TabBar(
                    isScrollable: true,
                    labelStyle: TextStyle(fontSize: 18),
                    indicator: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          width: 3,
                          color: Color(0xFF899CCF),
                        ),
                      ),
                    ),
                    tabs: [
                      Text("Music"),
                    ],
                  ),
                  Flexible(
                    flex: 1,
                    child: TabBarView(
                      children: [
                        //songs tab content
                        songsListView(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void changePlayerControlsWidgetVisibility() {
    setState(() {
      _isPlayControlWidgetVisible = !_isPlayControlWidgetVisible;
    });
  }

  void updateSongsLists(List<SongModel> _songs) {
    songs.clear();
    songs.addAll(_songs);
  }

  String nameWithoutExtension(String fullName) {
    return fullName.split(".").first.toString();
  }




  //create playlist
  ConcatenatingAudioSource createPlaylist(List<SongModel> songs) {
    List<AudioSource> sources = [];
    for (var song in songs) {
      sources.add(
        AudioSource.uri(
          Uri.parse(song.uri!),
          tag: MediaItem(
            id: '${song.id}',
            album: '${song.album}',
            title: song.displayNameWOExt,
            artUri: Uri.parse('https://example.com/albumart.jpg'),
          ),
        ),
      );
    }
    return ConcatenatingAudioSource(children: sources);
  }

  checkAndRequestPermissions({bool retry = false}) async {
    // The param 'retryRequest' is false, by default.
    _hasPermission = await _audioQuery.checkAndRequest(
      retryRequest: retry,
    );

    // Only call update the UI if application has all required permissions.
    _hasPermission ? setState(() {}) : null;
  }

  Widget noAccessToLibraryWidget() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.redAccent.withOpacity(0.5),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Application doesn't have access to the library"),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => checkAndRequestPermissions(retry: true),
            child: const Text("Allow"),
          ),
        ],
      ),
    );
  }
}

//position and duration state class
class PositionDurationState {
  PositionDurationState(
      {this.position = Duration.zero, this.duration = Duration.zero});

  Duration position, duration;
}

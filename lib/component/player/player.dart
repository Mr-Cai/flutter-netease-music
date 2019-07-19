import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:quiet/model/model.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:audio_service/audio_service.dart' as a;
import 'lryic.dart';
import 'play_list.dart';
import 'player_state.dart';
import 'package:overlay_support/overlay_support.dart';

export 'bottom_player_bar.dart';
export 'lryic.dart';
export 'player_state.dart';

abstract class PlayerControl<T> {
  static PlayerControl<Music> of(BuildContext context) {
    return PlayerController.control(context);
  }

  /// [item] music item
  void play(T item);

  void pause();

  void skipToNext();

  void skipToPrevious();

  void setPlayMode(PlayMode playMode);

  //set current playlist
  void setPlayList(List<T> list);

  void quiet();
}

PlaybackState _stateAdapter(a.PlaybackState state) {
  switch (state.basicState) {
    case a.BasicPlaybackState.none:
      return PlaybackState.none;
    case a.BasicPlaybackState.error:
    case a.BasicPlaybackState.stopped:
      return PlaybackState.ended;
    case a.BasicPlaybackState.paused:
    case a.BasicPlaybackState.playing:
      return PlaybackState.ready;
    case a.BasicPlaybackState.fastForwarding:
    case a.BasicPlaybackState.rewinding:
    case a.BasicPlaybackState.connecting:
    case a.BasicPlaybackState.buffering:
      return PlaybackState.buffering;
    case a.BasicPlaybackState.skippingToPrevious:
    case a.BasicPlaybackState.skippingToNext:
    case a.BasicPlaybackState.skippingToQueueItem:
      return null;
  }
  return null;
}

class PlayerController extends Model implements PlayerControl<Music> {
  var _state = PlayerControllerState.uninitialized();

  PlayerControllerState get value => _state;

  PlayerController() {
    a.AudioService.start(
      backgroundTask: _startMusicPlayerService,
      resumeOnClick: true,
      androidNotificationChannelName: 'Audio Service Demo',
      notificationColor: 0xFF2196f3,
      androidNotificationIcon: 'mipmap/ic_launcher',
    );
    a.AudioService.connect();
    a.AudioService.playbackStateStream.listen((state) {
      _state = _state.copyWith(
        playbackState: _stateAdapter(state),
        position: Duration(milliseconds: state.currentPosition),
      );
      notifyListeners();
    });
    a.AudioService.currentMediaItemStream.listen((item) {
      _state = _state.copyWith(current: _adapterToMusic(item));
    });
    a.AudioService.queueStream.listen((queue) {
      //do nothing yet
    });
  }

  static PlayerControllerState state(BuildContext context, {bool rebuildOnChange: true}) {
    final controller = of(context, rebuildOnChange: rebuildOnChange);
    return controller._state;
  }

  static PlayerControl<Music> control(BuildContext context) {
    return of(context, rebuildOnChange: false);
  }

  static PlayerController of(BuildContext context, {bool rebuildOnChange: false}) {
    return ScopedModel.of<PlayerController>(context, rebuildOnChange: rebuildOnChange);
  }

  @override
  void pause() {
    a.AudioService.pause();
  }

  @override
  void play(Music item) {
    a.AudioService.playFromMediaId(item.id.toString());
  }

  @override
  void skipToNext() {
    a.AudioService.skipToNext();
  }

  @override
  void skipToPrevious() {
    a.AudioService.skipToPrevious();
  }

  @override
  void setPlayMode(PlayMode playMode) {
    a.AudioService.customAction(_actionPlayMode, playMode.index);
    _state = _state.copyWith(playMode: playMode);
    notifyListeners();
  }

  @override
  void setPlayList(List<Music> list) {
    _state = _state.copyWith(playingList: list);
    a.AudioService.customAction(_actionPlayList, list.map((m) => m.toMap()).toList());
  }

  Music _adapterToMusic(a.MediaItem item) {
    assert(_state.playingList.isNotEmpty, "can not adapter $item to music because current playing list is emtpy");
    return _state.playingList.firstWhere((music) => music.id.toString() == item.id);
  }

  @override
  void quiet() {
    a.AudioService.stop();
  }

  void seekTo(int round) {
    //TODO
  }

  Music getPrevious() {
    //TODO
    return null;
  }

  Music getNext() {
    //TODO
    return null;
  }
}

const _actionPlayMode = "changePlayMode";

const _actionPlayList = "changePlayList";

// Start MusicPlayer in background.
void _startMusicPlayerService() async {
  final player = _Player();
  a.AudioServiceBackground.run(
      onStart: player.startService,
      onStop: player.quiet,
      onPlayFromMediaId: (String id) {
        assert(player.items.isNotEmpty, "we can not perform play for $id, since playList still empty now!");
        var item = player.items.firstWhere((item) => item.id == id);
        if (item == null) {
          debugPrint("can not find $id in playlist");
          item = player.items.first;
        }
        player.play(item);
      },
      onPause: player.pause,
      onCustomAction: (action, arg) {
        switch (action) {
          case _actionPlayMode:
            player.setPlayMode(PlayMode.values[arg]);
            break;
          case _actionPlayList:
            final musics = (arg as List).cast<Map>().map(Music.fromMap);
            final items = musics.map(_adapterToMediaItem).toList();
            player.setPlayList(items);
            break;
          default:
            throw "can not perform action : $action";
        }
      },
      onLoadChildren: (path) async {
        return player.items;
      });
}

a.MediaItem _adapterToMediaItem(Music music) {
  return a.MediaItem(
    id: music.id.toString(),
    album: music.album.name,
    title: music.title,
    artist: music.artistString,
    displayTitle: music.title,
    displaySubtitle: music.subTitle,
  );
}

class _Player with ShufflePlayList<a.MediaItem> implements PlayerControl<a.MediaItem> {
  // Start Player Service
  Future startService() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      var basicState = a.BasicPlaybackState.none;
      switch (state) {
        case AudioPlayerState.STOPPED:
          basicState = a.BasicPlaybackState.stopped;
          break;
        case AudioPlayerState.PLAYING:
          basicState = a.BasicPlaybackState.playing;
          break;
        case AudioPlayerState.PAUSED:
          basicState = a.BasicPlaybackState.paused;
          break;
        case AudioPlayerState.COMPLETED:
          basicState = a.BasicPlaybackState.paused;
          break;
      }
      a.AudioServiceBackground.setState(basicState: basicState, controls: [
        a.MediaControl(
            action: a.MediaAction.skipToPrevious,
            label: 'skipToPrevious',
            androidIcon: "drawable/ic_skip_previous_black_24dp"),
        a.MediaControl(
          action: a.MediaAction.skipToNext,
          label: 'skipToNext',
          androidIcon: "drawable/ic_skip_next_black_24dp",
        ),
      ]);
    });

    _audioPlayer.getCurrentPosition();
    //FIXME
    return Future.delayed(Duration(days: 0xFFFFFFFF));
  }

  final AudioPlayer _audioPlayer = AudioPlayer();

  a.MediaItem _current;

  @override
  void pause() {
    _audioPlayer.pause();
  }

  @override
  void play(a.MediaItem item) {
    //FIXME dynamic load from api
    _audioPlayer.play("http://music.163.com/song/media/outer/url?id=${item.id}.mp3");
  }

  @override
  void setPlayList(List<a.MediaItem> list) {
    items.clear();
    items.addAll(list);
    a.AudioServiceBackground.notifyChildrenChanged();
    a.AudioServiceBackground.setQueue(list);
  }

  @override
  void setPlayMode(PlayMode playMode) {
    this.playMode = playMode;
  }

  @override
  void skipToNext() {
    final next = getNext(_current);
    play(next);
  }

  @override
  void skipToPrevious() {
    final previous = getPrevious(_current);
    play(previous);
  }

  @override
  void quiet() {
    // TODO: implement quiet
  }
}

class Quiet extends StatefulWidget {
  Quiet({@required this.child, Key key}) : super(key: key);

  final Widget child;

  @override
  State<StatefulWidget> createState() => _QuietState();
}

class _QuietState extends State<Quiet> {
  final PlayerController quiet = PlayerController();

  PlayerControllerState value;

  void _onPlayerChange() {
    setState(() {
      value = quiet.value;
      if (value.hasError) {
        showSimpleNotification(context, Text("播放歌曲${value.current?.title ?? ""}失败!"),
            leading: Icon(Icons.error), background: Theme.of(context).errorColor);
      }
    });
  }

  @override
  void initState() {
    value = quiet.value;
    quiet.addListener(_onPlayerChange);
    _playingLyric.attachPlayer(quiet);
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    quiet.removeListener(_onPlayerChange);
  }

  final _playingLyric = PlayingLyric();

  @override
  Widget build(BuildContext context) {
    return ScopedModel<PlayerController>(
      model: quiet,
      child: ScopedModel(
        model: _playingLyric,
        child: PlayerState(
          child: widget.child,
          value: value,
        ),
      ),
    );
  }
}

class PlayerState extends InheritedModel<PlayerStateAspect> {
  PlayerState({@required Widget child, @required this.value}) : super(child: child);

  ///get current playing music
  final PlayerControllerState value;

  static PlayerState of(BuildContext context, {PlayerStateAspect aspect}) {
    return context.inheritFromWidgetOfExactType(PlayerState, aspect: aspect);
  }

  @override
  bool updateShouldNotify(PlayerState oldWidget) {
    return value != oldWidget.value;
  }

  @override
  bool updateShouldNotifyDependent(PlayerState oldWidget, Set<PlayerStateAspect> dependencies) {
    if (dependencies.contains(PlayerStateAspect.position) && (value.position != oldWidget.value.position)) {
      return true;
    }
    if (dependencies.contains(PlayerStateAspect.playbackState) &&
        ((value.playbackState != oldWidget.value.playbackState) ||
            (value.playWhenReady != oldWidget.value.playWhenReady || value.hasError != oldWidget.value.hasError))) {
      return true;
    }
    if (dependencies.contains(PlayerStateAspect.playlist) && (value.playingList != oldWidget.value.playingList)) {
      return true;
    }
    if (dependencies.contains(PlayerStateAspect.music) && (value.current != oldWidget.value.current)) {
      return true;
    }
    if (dependencies.contains(PlayerStateAspect.playMode) && (value.playMode) != oldWidget.value.playMode) {
      return true;
    }
    return false;
  }
}

enum PlayerStateAspect {
  ///the position of playing
  position,

  ///the playing state
  playbackState,

  ///the current playing
  music,

  ///the current playing playlist
  playlist,

  ///the play mode of playlist
  playMode,
}

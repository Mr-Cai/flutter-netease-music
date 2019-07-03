import 'package:audio_service/audio_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:quiet/model/model.dart';
import 'package:quiet/service/channel_media_player.dart';

void f() {

  QuietMusicPlayer player = QuietMusicPlayer();

  AudioServiceBackground.run(
    onStart: null,
    onStop: null,
    onCustomAction: player.onCustomAction,
  );
}

class QuietMusicPlayer {
  AudioPlayer _audioPlayer = AudioPlayer();

  PlayingList _playingList;

  void play() {}

  void _play(Music music) {
    _audioPlayer.play(music.url);
  }

  void playNext() {}

  void playPrevious() {}

  void onCustomAction(String action, arg) {}
}

///playing list
class PlayingList {
  static const String TOKEN_EMPTY = "empty_playlist";

  static final PlayingList empty = PlayingList(TOKEN_EMPTY, []);

  PlayingList(this.token, this.musics, {this.playMode = PlayMode.sequence})
      : assert(token != null),
        assert(musics != null),
        assert(playMode != null);

  final List<Music> musics;

  List<Music> shuffleMusicList;

  ///token identify this PlayingList
  final String token;

  ///current playing list play mode
  PlayMode playMode;

  ///get next music can be play by current
  Music getNext(Music current) {
    if (musics.isEmpty) {
      return null;
    }
    if (current == null) {
      return musics[0];
    }
    switch (playMode) {
      case PlayMode.single:
        return current;
      case PlayMode.sequence:
        var index = musics.indexOf(current) + 1;
        if (index == musics.length) {
          return musics.first;
        } else {
          return musics[index];
        }
        break;
      case PlayMode.shuffle:
        _ensureShuffleListGenerate();
        var index = shuffleMusicList.indexOf(current);
        if (index == -1) {
          return musics.first;
        } else if (index == musics.length - 1) {
          //shuffle list has been played to end, regenerate a list
          _isShuffleListDirty = true;
          _ensureShuffleListGenerate();
          return shuffleMusicList.first;
        } else {
          return shuffleMusicList[index + 1];
        }
        break;
    }
    throw Exception("illega state to get next music");
  }

  ///insert a song to playing list next position
  void insertToNext(Music current, Music next) {
    if (musics.isEmpty) {
      musics.add(next);
      return;
    }
    _ensureShuffleListGenerate();

    //if inserted is current, do nothing
    if (current == next) {
      return;
    }
    //remove if music list contains the insert item
    if (musics.remove(next)) {
      _isShuffleListDirty = true;
      _ensureShuffleListGenerate();
    }

    int index = musics.indexOf(current) + 1;
    musics.insert(index, next);

    int indexShuffle = shuffleMusicList.indexOf(current) + 1;
    shuffleMusicList.insert(indexShuffle, next);
  }

  ///get previous music can be play by current
  Music getPrevious(Music current) {
    if (musics.isEmpty) {
      return null;
    }
    if (current == null) {
      return musics.first;
    }
    switch (playMode) {
      case PlayMode.single:
        return current;
      case PlayMode.sequence:
        var index = musics.indexOf(current);
        if (index == -1) {
          return musics.first;
        } else if (index == 0) {
          return musics.last;
        } else {
          return musics[index - 1];
        }
        break;
      case PlayMode.shuffle:
        _ensureShuffleListGenerate();
        var index = shuffleMusicList.indexOf(current);
        if (index == -1) {
          return musics.first;
        } else if (index == 0) {
          //has reach the shuffle list head, need regenerate a shuffle list
          _isShuffleListDirty = true;
          _ensureShuffleListGenerate();
          return shuffleMusicList.last;
        } else {
          return shuffleMusicList[index - 1];
        }
        break;
    }
    throw Exception("illegal state to get previous music");
  }

  bool _isShuffleListDirty = true;

  /// create shuffle list for [PlayMode.shuffle]
  void _ensureShuffleListGenerate() {
    if (!_isShuffleListDirty) {
      return;
    }
    shuffleMusicList = List.from(musics);
    shuffleMusicList.shuffle();
    _isShuffleListDirty = false;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayingList &&
          runtimeType == other.runtimeType &&
          musics == other.musics &&
          token == other.token &&
          playMode == other.playMode;

  @override
  int get hashCode => musics.hashCode ^ token.hashCode ^ playMode.hashCode;
}

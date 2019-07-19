import 'package:quiet/model/model.dart';

/// PlayMode determine Player how to play next song.
enum PlayMode {
  /// Aways play single song.
  single,

  /// Play current list sequence.
  sequence,

  /// Random to play next song.
  shuffle
}

enum PlaybackState { none, buffering, ready, ended }

class DurationRange {
  DurationRange(this.start, this.end);

  final Duration start;
  final Duration end;

  double startFraction(Duration duration) {
    return start.inMilliseconds / duration.inMilliseconds;
  }

  double endFraction(Duration duration) {
    return end.inMilliseconds / duration.inMilliseconds;
  }

  @override
  String toString() => '$runtimeType(start: $start, end: $end)';
}

class PlayerControllerState {
  PlayerControllerState(
      {this.duration,
      this.position = Duration.zero,
      this.playWhenReady = false,
      this.buffered = const [],
      this.playbackState = PlaybackState.none,
      this.current,
      this.playingList = const [],
      this.token,
      this.playMode = PlayMode.sequence,
      this.errorMsg = _ERROR_NONE});

  static const String _ERROR_NONE = "NONE";

  PlayerControllerState.uninitialized() : this(duration: null);

  final Duration duration;
  final Duration position;

  final List<DurationRange> buffered;

  final PlaybackState playbackState;

  ///whether playback should proceed when isReady become true
  final bool playWhenReady;

  ///audio is buffering
  bool get isBuffering => playbackState == PlaybackState.buffering && !hasError;

  ///might be null
  final Music current;

  final String errorMsg;

  final List<Music> playingList;

  final String token;

  final PlayMode playMode;

  bool get initialized => duration != null;

  bool get hasError => errorMsg != _ERROR_NONE;

  bool get isPlaying =>
      (playbackState == PlaybackState.ready) && playWhenReady && !hasError;

  PlayerControllerState clearError() {
    if (!hasError) {
      return this;
    }
    return copyWith(errorMsg: _ERROR_NONE);
  }

  PlayerControllerState copyWith({
    Duration duration,
    Duration position,
    bool playWhenReady,
    String errorMsg,
    List<DurationRange> buffered,
    PlaybackState playbackState,
    Music current,
    List<Music> playingList,
    String token,
    PlayMode playMode,
  }) {
    return PlayerControllerState(
        duration: duration ?? this.duration,
        position: position ?? this.position,
        playWhenReady: playWhenReady ?? this.playWhenReady,
        errorMsg: errorMsg ?? this.errorMsg,
        buffered: buffered ?? this.buffered,
        playbackState: playbackState ?? this.playbackState,
        playingList: playingList ?? this.playingList,
        current: current ?? this.current,
        playMode: playMode ?? this.playMode,
        token: token ?? this.token);
  }
}

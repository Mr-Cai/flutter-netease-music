import 'package:flutter/material.dart';
import 'package:quiet/part/part.dart';

///
/// an widget which indicator player is Playing/Pausing/Buffering
///
class PlayingIndicator extends StatefulWidget {
  ///show when player is playing
  final Widget playing;

  ///show when player is pausing
  final Widget pausing;

  ///show when player is buffering
  final Widget buffering;

  const PlayingIndicator({Key key, this.playing, this.pausing, this.buffering}) : super(key: key);

  @override
  _PlayingIndicatorState createState() => _PlayingIndicatorState();
}

///TODO Add animation
class _PlayingIndicatorState extends State<PlayingIndicator> {
  static const _INDEX_BUFFERING = 2;
  static const _INDEX_PLAYING = 1;
  static const _INDEX_PAUSING = 0;

  int getStateIndex(BuildContext context) {
    final state = PlayerController.state(context);
    return state.isBuffering ? _INDEX_BUFFERING : state.isPlaying ? _INDEX_PLAYING : _INDEX_PAUSING;
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: getStateIndex(context),
      alignment: Alignment.center,
      children: <Widget>[widget.pausing, widget.playing, widget.buffering],
    );
  }
}

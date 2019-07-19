import 'player_state.dart';

mixin ShufflePlayList<T> {
  final List<T> items = [];

  PlayMode playMode;

  List<T> shuffleMusicList;

  ///get next music can be play by current
  T getNext(T current) {
    if (items.isEmpty) {
      return null;
    }
    if (current == null) {
      return items[0];
    }
    switch (playMode) {
      case PlayMode.single:
        return current;
      case PlayMode.sequence:
        var index = items.indexOf(current) + 1;
        if (index == items.length) {
          return items.first;
        } else {
          return items[index];
        }
        break;
      case PlayMode.shuffle:
        _ensureShuffleListGenerate();
        var index = shuffleMusicList.indexOf(current);
        if (index == -1) {
          return items.first;
        } else if (index == items.length - 1) {
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

  ///get previous music can be play by current
  T getPrevious(T current) {
    if (items.isEmpty) {
      return null;
    }
    if (current == null) {
      return items.first;
    }
    switch (playMode) {
      case PlayMode.single:
        return current;
      case PlayMode.sequence:
        var index = items.indexOf(current);
        if (index == -1) {
          return items.first;
        } else if (index == 0) {
          return items.last;
        } else {
          return items[index - 1];
        }
        break;
      case PlayMode.shuffle:
        _ensureShuffleListGenerate();
        var index = shuffleMusicList.indexOf(current);
        if (index == -1) {
          return items.first;
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

  ///insert a song to playing list next position
  void insertToNext(T current, T next) {
    if (items.isEmpty) {
      items.add(next);
      return;
    }
    _ensureShuffleListGenerate();

    //if inserted is current, do nothing
    if (current == next) {
      return;
    }
    //remove if music list contains the insert item
    if (items.remove(next)) {
      _isShuffleListDirty = true;
      _ensureShuffleListGenerate();
    }

    int index = items.indexOf(current) + 1;
    items.insert(index, next);

    int indexShuffle = shuffleMusicList.indexOf(current) + 1;
    shuffleMusicList.insert(indexShuffle, next);
  }

  bool _isShuffleListDirty = true;

  /// create shuffle list for [PlayMode.shuffle]
  void _ensureShuffleListGenerate() {
    if (!_isShuffleListDirty) {
      return;
    }
    shuffleMusicList = List.from(items);
    shuffleMusicList.shuffle();
    _isShuffleListDirty = false;
  }
}

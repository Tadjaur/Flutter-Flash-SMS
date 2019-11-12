import '../platform_services.dart';
import '../utils.dart';

class ChatsController {
//  static var _globalChatMap = {};
  static final List<MessageData> _overviewList = [];
  static void Function(void Function() func) _changeState;

  final List<MessageData> overviewList;

  /// Send new message to friend;
  final sendMessage;

  /// call the friend
  final dial;

  ChatsController()
      : this.sendMessage = PlatformServices.sendMessage,
        this.dial = PlatformServices.dial,
        this.overviewList = _overviewList;

  changeState(void Function(void Function() f) func) {
    _changeState = func;
  }

  /// Refresh the list of message.
  static addListMessage(MessageData msgOverView) {
    int idx = _overviewList.length - 1;
//    if (_globalChatMap[msgOverView.senderNumber] == null) {
//      _globalChatMap[msgOverView.senderNumber] = 1;
//    } else {
//      _globalChatMap[msgOverView.senderNumber]++;
//    }
    while (idx >= 0) {
      final old = _overviewList[idx].senderNumber;
      final nw = msgOverView.senderNumber;
      final _oldX = old.indexOf(nw);
      final _nwX = nw.indexOf(old);
      if (old == nw ||
          (_oldX > 0 && (_oldX + nw.length) == old.length) ||
          (_nwX > 0 && (_nwX + old.length) == nw.length)) {
        if (_overviewList[idx].timestamp < msgOverView.timestamp) {
          _overviewList[idx] = msgOverView;
        }
        return null;
      }
      idx--;
    }
    _overviewList.add(msgOverView);
    if (_changeState != null) {
      _changeState(() {});
    }
  }
}

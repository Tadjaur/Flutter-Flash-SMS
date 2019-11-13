import 'package:flash_sms/platform_services.dart';
import 'package:flash_sms/utils.dart';

class ChatController {
  static final List<MessageData> _overviewList = [];
  static void Function(void Function() func) _changeState;

  final List<MessageData> overviewList;
  Stream nativeChatMessagesCall;

  MessageData lastMsg;

  ChatController(this.lastMsg) : overviewList = _overviewList {
    if (_overviewList.isEmpty)
      PlatformServices.retrieveAllSmsInChat(lastMsg.threadId, lastMsg.senderNumber);
  }

  Future<MessageData> sendMessage(String txt) async {
    print(["sms_to_send", txt]);
    if (txt.trim().length > 0) {
      final value = await PlatformServices.sendMessage(txt.trim(), lastMsg.senderNumber);
      return MessageData.fromMap(value);
    }
    return null;
  }

  static void newMessage(msgOverView) {
    _overviewList.add(msgOverView);
    if (_changeState != null) {
      _changeState(() {});
    }
  }

  void cancelAllListener() {}

  void changeState(void Function(void Function() fn) func) {
    if (func == null) {
      this.overviewList.clear();
    }
    _changeState = func;
  }
}

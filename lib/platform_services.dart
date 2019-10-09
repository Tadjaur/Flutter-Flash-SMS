import 'dart:async';
import 'dart:convert';
import 'package:flash_sms/utils.dart';
import 'package:flutter/services.dart';
import 'package:meta/meta.dart';

class PlatformServices {
  static const String package = "com.tadjaur.flash_sms";
  static final List<MessageData> overviewList = [];
  static final Map<String, int> globalChatMap = {};
  static Function overviewListListener;

  /// handler is a function tthat
  PlatformServices({@required Function handler}) {
    _platform = MethodChannel("$package/sms");
    _platform.setMethodCallHandler(handleNativeCall);
    initFunction().then((v) => handler(v));
    _nativeChatsOverviewCallStreamCtrl = StreamController();
    _nativeChatMessagesCallStreamCtrl = StreamController();
    _nativeChatMessageReceiverStreamCtrl = StreamController();
  }

  static MethodChannel _platform;
  static bool _initialized = false;
  static StreamController<MessageData> _nativeChatsOverviewCallStreamCtrl;
  static StreamController _nativeChatMessagesCallStreamCtrl;
  static StreamController _nativeChatMessageReceiverStreamCtrl;

  static Stream<MessageData> get nativeChatsOverviewCall =>
      _nativeChatsOverviewCallStreamCtrl.stream;

  static Stream get nativeChatMessagesCall => _nativeChatMessagesCallStreamCtrl.stream;

  static Stream get nativeChatMessageReceiver => _nativeChatMessageReceiverStreamCtrl.stream;

  static nativeChatMessagesCallCancel() {
    _nativeChatMessagesCallStreamCtrl.close();
    _nativeChatMessagesCallStreamCtrl = StreamController();
  }

  static cancelNativeChatMessageReceiver() {
    _nativeChatMessageReceiverStreamCtrl.close();
    _nativeChatMessageReceiverStreamCtrl = StreamController();
  }

  static cancelNativeChatsOverviewCall() {
    _nativeChatsOverviewCallStreamCtrl.close();
    _nativeChatsOverviewCallStreamCtrl = StreamController();
  }

  /// First function to call after creation of specific canal.
  Future<bool> initFunction() async {
//    Directory dir = await path.getApplicationDocumentsDirectory();
//    final tmp = dir.list(recursive: true);
//    tmp.forEach((FileSystemEntity se) {
//      print(se.path);
//    });
    _initialized = true;
    return await invokation(methods.FP, defaultResult: true);
  }

  /// Invoke the platform specific method and print and return the result
  static Future<dynamic> invokation(String methodId,
      {dynamic params, dynamic defaultResult}) async {
    if (_initialized) {
      try {
        final result = await _platform.invokeMethod(methodId, params);
        print(["PlatformServices::Info", result]);
        return result;
      } catch (e) {
        print(["PlatformServices::Error", e]);
        return defaultResult;
      }
    } else {
      print("PlatformServices::Alert => service not init");
    }
  }

  static sendMessage(String msg, String number) async {
    return await invokation(methods.SSms,
        params: {"msg": msg, "num": number}, defaultResult: false);
  }

  static retrieveAllChatSms(String senderName, String thread_id, String senderNumber) async {
    return await invokation(methods.KChatList,
        defaultResult: [],
        params: {"name": senderName, "num": senderNumber, "thread_id": thread_id});
  }

  static dial(String phoneNumber) {
    invokation(methods.Dial, params: phoneNumber);
  }

  Future<dynamic> handleNativeCall(MethodCall methodCall) async {
    switch (methodCall.method) {
      case methods.KList:
        {
          print(["dart::${methods.KList}", methodCall.arguments]);
//          final en = jsonEncode(methodCall.arguments);
//          _nativeChatsCallStreamCtrl.add((jsonDecode(en) as List<dynamic>));
          return "received in ui";
        }
      case methods.KCOvList:
        {
          final msgOverView = MessageData.fromMap(methodCall.arguments);
          int idx = 0;
          if (globalChatMap[msgOverView.thread_id] == null) {
            globalChatMap[msgOverView.thread_id] = 1;
          } else {
            globalChatMap[msgOverView.thread_id]++;
          }
          while (idx < overviewList.length) {
            if (overviewList[idx].thread_id == msgOverView.thread_id) return null;
            idx++;
          }
          overviewList.add(msgOverView);
          if (overviewListListener != null) {
            try {
              overviewListListener();
            } catch (e) {}
          }
//          _nativeChatsOverviewCallStreamCtrl.add(msgOverView);
          return "received in ui";
        }
      case methods.KChatList:
        {
          print(["dart::${methods.KChatList}", methodCall.arguments]);
          final en = jsonEncode(methodCall.arguments);
          _nativeChatMessagesCallStreamCtrl
              .add((jsonDecode(en) as List<dynamic>).reversed.toList());
          return "received in ui";
        }
      case methods.KSmsI:
        {
          print(["dart::${methods.KSmsI}", methodCall.arguments]);
          _nativeChatMessageReceiverStreamCtrl.add(methodCall.arguments.toString());
          return "received in ui";
        }
      default:
        {
          return null;
        }
    }
  }
}

/// content the list of Method to call inside channel
mixin methods {
  static const FP = "firstOpen";
  static const String SSms = "sendSms";
  static const String RSms = "RetrieveAllSms";
  static const String KList = "KotlinList";
  static const String KCOvList = "KotlinChatOverviewList";
  static const String Dial = "newCall";
  static const String KChatList = "KotlinChatList";
  static const String KSmsI = "KotlinSmsIncomming";
}

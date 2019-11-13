import 'dart:async';
import 'package:flash_sms/controllers/chat_controller.dart';
import 'package:flash_sms/utils.dart';
import 'package:flutter/services.dart';
import 'package:meta/meta.dart';

import 'controllers/chats_controller.dart';

class PlatformServices {
  static const String package = "com.tadjaur.flash_sms";

  /// handler is a function tthat
  PlatformServices({@required Function handler}) {
    _platform = MethodChannel("$package/sms");
    _platform.setMethodCallHandler(handleNativeCall);
    initFunction().then((v) => handler(v));
  }

  static MethodChannel _platform;
  static bool _initialized = false;

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

  static Future<dynamic> sendMessage(String msg, String number) async {
    return await invokation(methods.SSms,
        params: {"msg": msg, "num": number}, defaultResult: false);
  }

  static retrieveAllSmsInChat(String threadId, String senderNumber) async {
    return await invokation(methods.KChatList,
        defaultResult: [],
        params: {"num": senderNumber, "thread_id": threadId});
  }

  static dial(String phoneNumber) {
    invokation(methods.Dial, params: phoneNumber);
  }

  Future<dynamic> handleNativeCall(MethodCall methodCall) async {
    switch (methodCall.method) {
      case methods.KCOvList:
        {
//          print(["dart::${methods.KCOvList}", methodCall.arguments]);
          final msgOverView = MessageData.fromMap(methodCall.arguments);
          ChatsController.addListMessage(msgOverView);
          return "received in ui";
        }
      case methods.KChatList:
        {
//          print(["dart::${methods.KChatList}", methodCall.arguments]);
          final msgOverView = MessageData.fromMap(methodCall.arguments);
          ChatController.newMessage(msgOverView);
          return "received in ui";
        }
      case methods.KSmsI:
        {
          final msgOverView = MessageData.fromMap(methodCall.arguments);
          ChatsController.addListMessage(msgOverView);
          ChatController.newMessage(msgOverView);
          return "received in ui";
        }
      default:
        {
          return null;
        }
    }
  }

  ///  In practice, common CPU-bound operations are:
  /// matrix multiplication
  /// cryptography-related (such as signing, hashing, key generation)
  /// image/audio/video manipulation
  /// serialization/deserialization
  /// offline machine learning model computation
  /// compression (such as zlib)
  /// Regular expression Denial of Service — ReDoS
  doAsync() {
//    compute()
  }
}

/// content the list of Method to call inside channel
mixin methods {
  static const FP = "firstOpen";
  static const String SSms = "sendSms";
  static const String RSms = "RetrieveAllSms";
  static const String KCOvList = "KotlinChatOverviewList";
  static const String Dial = "newCall";
  static const String KChatList = "KotlinChatList";
  static const String KSmsI = "KotlinSmsIncoming";
}


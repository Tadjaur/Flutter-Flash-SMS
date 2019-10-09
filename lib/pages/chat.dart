import 'package:flash_sms/platform_services.dart';
import 'package:flash_sms/utils.dart';
import 'package:flutter/material.dart';

import '../settings.dart';

class ChatPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<dynamic> chatMessageDataList = [];

  final TextEditingController editSmsCtrl = TextEditingController();
  String inputText = "";
  String friendName, friendNumber, friendAvatar;

  @override
  void initState() {
    PlatformServices.nativeChatMessageReceiver.listen((data) {
      Map<String, dynamic> value = {};
      final d = DateTime.now();
      value["name"] = friendName;
      value["phone"] = friendNumber;
      value["msg"] = data.toString();
      value["time"] = "${d.day}/${d.month} ${d.hour}:${d.minute}";
      value["timestamp"] = "${d.millisecondsSinceEpoch}";
      value["type"] = "1";
      setState(() {
        chatMessageDataList.insert(0, value);
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    PlatformServices.nativeChatMessagesCallCancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<String> arg = ModalRoute.of(context).settings.arguments;
    assert(arg != null);
    assert(arg.length == 3);
    friendName = arg[0];
    friendNumber = arg[1];
    friendAvatar = arg[2];
    return Scaffold(
      appBar: AppBar(
        title: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              friendName,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            friendNumber != friendName
                ? Text(
                    friendNumber,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w200),
                  )
                : SizedBox(),
          ],
        ),
      ),
      body: Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            Expanded(
              child: StreamBuilder<dynamic>(
                  stream: PlatformServices.nativeChatMessagesCall,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final lst = snapshot.requireData as List;
                      if (chatMessageDataList == null || chatMessageDataList.length < lst.length) {
                        chatMessageDataList = lst;
                      }
                    }
                    return ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: chatMessageDataList.length,
                      reverse: true,
                      itemBuilder: (BuildContext context, int index) {
                        final v = MessageData.fromMap(chatMessageDataList[index]);
                        return _buildMessageUi(v, context);
                      },
                    );
                  }),
            ),
            Container(
              height: 55.0,
              decoration: BoxDecoration(
                  border: Border.all(width: 2.0, color: Pref.of(context).darkBlue.withAlpha(15))),
              child: Row(
                children: <Widget>[
                  Expanded(
                      child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      decoration: InputDecoration(
                          hintText: "Enter Messages...",
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none),
                      controller: editSmsCtrl,
                      keyboardType: TextInputType.text,
                      onSubmitted: (String str) {
                        print(str);
                        inputText = str;
                        sendMessage();
                      },
                      onChanged: (String str) {
                        inputText = str;
                      },
                    ),
                  )),
                  GestureDetector(onTap: sendMessage, child: sendIcon(context))
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Padding sendIcon(BuildContext context, [int alpha = 255]) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Icon(
        Icons.send,
        size: 35.0,
        color: Pref.of(context).darkBlue.withAlpha(alpha),
      ),
    );
  }

  void sendMessage() async {
    print(["sms_to_send", inputText]);
    if (inputText.trim().length > 0) {
      await PlatformServices.sendMessage(inputText.trim(), friendNumber);
      final Map<String, String> value = {};
      final d = DateTime.now();
      value["name"] = friendName;
      value["phone"] = friendNumber;
      value["msg"] = inputText.trim();
      value["time"] = "${d.day}/${d.month} ${d.hour}:${d.minute}";
//      value["thread_id"] =
      value["timestamp"] = DateTime.now().millisecondsSinceEpoch.toString();
//    this._id = value["_id"];
      value["type"] = "2";
      setState(() {
        chatMessageDataList.insert(0, value);
        editSmsCtrl.clear();
      });
    }
  }

  Widget _buildMessageUi(MessageData data, BuildContext context) {
    bool isme = data.type == "2";
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 2.0),
      child: Row(
        mainAxisAlignment: isme ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: isme ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: <Widget>[
//          SizedBox(
//            width: isme ? 30.0 : 20,
//          ),
          !isme
              ? Container(
                  height: 10,
                  width: 10,
                  decoration: BoxDecoration(
                      color: Pref.of(context).primary.withBrigthness(-25),
                      borderRadius: BorderRadius.only(bottomLeft: Radius.elliptical(15, 15))),
                )
              : Expanded(
                  child: Container(),
                ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 5.0),
            constraints:
                BoxConstraints.loose(Size.fromWidth(MediaQuery.of(context).size.width - 50.0)),
            decoration: BoxDecoration(
                color: isme
                    ? Pref.of(context).primary.withBrigthness(-55)
                    : Pref.of(context).primary.withBrigthness(-20),
                borderRadius: BorderRadius.only(
                    topRight: Radius.circular(15.0),
                    topLeft: isme ? Radius.circular(15.0) : Radius.zero,
                    bottomRight: !isme ? Radius.circular(15.0) : Radius.zero,
                    bottomLeft: Radius.circular(15.0))),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(data.message, softWrap: true, overflow: TextOverflow.clip),
                SizedBox(
                  height: 5.0,
                ),
                Text(
                  data.time,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                )
              ],
            ),
          ),
          isme
              ? Container(
                  height: 7,
                  width: 7,
                  decoration: BoxDecoration(
                      color: Pref.of(context).primary.withBrigthness(-55),
                      borderRadius: BorderRadius.only(topRight: Radius.elliptical(15, 15))),
                )
              : Expanded(
                  child: Container(),
                ),
        ],
      ),
    );
  }
}

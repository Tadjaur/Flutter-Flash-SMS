import 'package:flash_sms/controllers/chat_controller.dart';
import 'package:flash_sms/utils.dart';
import 'package:flash_sms/widgets/message_ui.dart';
import 'package:flash_sms/widgets/swipable_item.dart';
import 'package:flutter/material.dart';

import '../settings.dart';

class ChatUI extends StatefulWidget {
  final MessageData lastMsg;

  @override
  State<StatefulWidget> createState() => _ChatPageState();
  final ChatController ctrl;

  ChatUI(this.lastMsg) : this.ctrl = ChatController(lastMsg);
}

class _ChatPageState extends State<ChatUI> {
  final TextEditingController editSmsCtrl = TextEditingController();
  String inputText = "";

  bool _enableEdit = true;

  @override
  void initState() {
    widget.ctrl.changeState(setState);
    super.initState();
  }

  @override
  void dispose() {
    widget.ctrl.changeState(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              widget.lastMsg.senderName,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            widget.lastMsg.senderNumber != widget.lastMsg.senderName
                ? Text(
                    widget.lastMsg.senderNumber,
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
                child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: widget.ctrl.overviewList.length,
                    reverse: true,
                    itemBuilder: (BuildContext context, int index) {
                      if (index >= widget.ctrl.overviewList.length) return null;
                      final dt = widget.ctrl.overviewList[index];
                      return SwipableItem(
                          direction: dt.type == "2"
                              ? SwipableDirection.endToStart
                              : SwipableDirection.startToEnd,
                          seuil: {
                            SwipableDirection.endToStart: 0.2,
                            SwipableDirection.startToEnd: 0.2
                          },
                          maxLimit: {
                            SwipableDirection.endToStart: 0.2,
                            SwipableDirection.startToEnd: 0.5
                          },
                          maxLimitNotify: () {},
                          onSuccess: () {},
                          background: Container(),
                          child: MessageUi(data: dt));
                    })),
            StringUtil.isNumber(widget.lastMsg.senderNumber)
                ? Container(
                    height: 55.0,
                    decoration: BoxDecoration(
                        border:
                            Border.all(width: 2.0, color: Pref.of(context).darkBlue.withAlpha(15))),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                            child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 10.0),
                          child: TextField(
                            decoration: InputDecoration(
                                hintText: "Enter Messages...",
                                border: InputBorder.none,
                                focusedBorder: InputBorder.none),
                            controller: editSmsCtrl,
                            keyboardType: TextInputType.text,
                            enabled: _enableEdit,
                            onSubmitted: (String str) async {
                              _enableEdit = false;
                              inputText = str;
                              final MessageData res = await widget.ctrl.sendMessage(inputText);
                              if (res != null) {
                                setState(() {
                                  widget.ctrl.overviewList.insert(0, res);
                                  inputText = "";
                                  editSmsCtrl.clear();
                                });
                              }
                              _enableEdit = true;
                            },
                            onChanged: (String str) {
                              inputText = str;
                            },
                          ),
                        )),
                        GestureDetector(
                            onTap: () async {
                              _enableEdit = false;
                              final MessageData res = await widget.ctrl.sendMessage(inputText);
                              _enableEdit = true;
                              if (res != null) {
                                setState(() {
                                  widget.ctrl.overviewList.insert(0, res);
                                  inputText = "";
                                  editSmsCtrl.clear();
                                });
                              }
                            },
                            child: sendIcon(context))
                      ],
                    ),
                  )
                : Container(),
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
}

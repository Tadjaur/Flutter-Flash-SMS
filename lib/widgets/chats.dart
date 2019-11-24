import 'package:flash_sms/controllers/chats_controller.dart';
import 'package:flash_sms/generated/i18n.dart';
import 'package:flash_sms/settings.dart';
import 'package:flash_sms/widgets/chat.dart';
import 'package:flash_sms/widgets/swipable_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils.dart';

class ChatsUI extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _ChatsState();

  final ChatsController ctrl;

  ChatsUI():
        ctrl = ChatsController();
}

class _ChatsState extends State<ChatsUI> {
  final pinnedFriendList = [];

  final nNumCtrl = TextEditingController();
  final nMsgCtrl = TextEditingController();

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
    String nAddress, nMessage;
//    widget.ctrl.newChatListener =  this.setState;
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Pref.of(context).lightBlue,
        onPressed: () {
          showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('New SMS'),
                  content: SingleChildScrollView(
                    child: ListBody(
                      children: <Widget>[
                        TextField(
                          controller: nNumCtrl,
                          keyboardType: TextInputType.number,
                          maxLength: 12,
                          onChanged: (text) {
                            nAddress = text;
                          },
                          decoration: InputDecoration(
                              hintText: "Enter Number",
                              border: InputBorder.none,
                              focusedBorder: InputBorder.none),
                        ),
                        TextField(
                          controller: nMsgCtrl,
                          keyboardType: TextInputType.text,
                          autocorrect: true,
                          onChanged: (msg) {
                            nMessage = msg;
                          },
                          decoration: InputDecoration(
                              hintText: "Enter Message",
                              border: InputBorder.none,
                              focusedBorder: InputBorder.none),
                        ),
                      ],
                    ),
                  ),
                  actions: <Widget>[
                    FlatButton(
                      child: Text('Send'),
                      onPressed: () {
                        widget.ctrl.sendMessage(nMessage, nAddress);
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                );
              });
        },
        child: Icon(Icons.add),
      ),
      backgroundColor: Pref.of(context).primary.withBrigthness(-35),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.fromLTRB(20.0, 40.0, 20.0, 20.0),
            child: Text(
              S.of(context).chats,
              style: TextStyle(
                color: Pref.of(context).darkBlue,
                fontSize: 26.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          pinnedFriendList.isEmpty
              ? SizedBox()
              : Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color(0xFF414350),
                      borderRadius: BorderRadius.circular(5.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black54,
                          offset: Offset(0.0, 1.5),
                          blurRadius: 1.0,
                          spreadRadius: -1.0,
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: pinnedFriendList,
                        ),
                      ),
                    ),
                  ),
                ),
          widget.ctrl.overviewList.length < 10
              ? SizedBox()
              : Padding(
                  padding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
                  child: TextField(
                    decoration: InputDecoration(
                        hintText: 'filter chats...',
                        hintStyle: TextStyle(
                          color: Pref.of(context).primary,
                        ),
                        filled: true,
                        fillColor: Pref.of(context).primary.withBrigthness(-50),
                        suffixIcon: Icon(
                          Icons.search,
                          color: Pref.of(context).darkBlue,
                        ),
                        border: InputBorder.none),
                  ),
                ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(50.0), topRight: Radius.circular(50.0)),
                  color: Pref.of(context).primary.withBrigthness(-15)),
              child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
//                  itemCount: widget.ctrl.overviewList.length,
                  itemBuilder: (BuildContext context, int index) {
                    if (index >= widget.ctrl.overviewList.length) return null;
                    final cod = widget.ctrl.overviewList[index];
                    return SwipableItem(
                      direction: SwipableDirection.endToStart,
                      child: ChatOverviewUi(cod),
                      secondaryBackground: Container(
                        color: Pref.of(context).transparent,
                        child: Icon(
                          Icons.call,
                          color: Pref.of(context).lightGreen2,
                        ),
                        alignment: Alignment.centerRight,
                      ),
                      onSuccess: () {
                        // vibration
                        HapticFeedback.vibrate();
                        widget.ctrl.dial(cod.senderNumber);
                        print("action to do");
                      },
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (BuildContext ctx){
                          return ChatUI(cod);
                        }));
                      },
                    );
                  }),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatOverviewUi extends StatelessWidget {
  final MessageData chat;

  ChatOverviewUi(this.chat);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFa0a0a0), width: 1.0),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: Row(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(0.0, 6.0, 16.0, 6.0),
              child: Container(
                width: 50.0,
                height: 50.0,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  border: Border.all(color: Pref.of(context).darkBlue, width: 2.0),
                  borderRadius: BorderRadius.circular(50.0),
                ),
                child: Center(
                    child: chat.avatar == null || chat.avatar.isEmpty ? Text(
                  getText(),
                  style: TextStyle(fontSize: 25.0, fontWeight: FontWeight.w900),
                ) : Container(decoration: BoxDecoration(image: DecorationImage(image: MemoryImage(chat.avatar)), borderRadius: BorderRadius.circular(50.0)))
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    chat.senderName,
                    style: TextStyle(
                      color: Pref.of(context).darkBlue,
                      fontWeight: FontWeight.w500,
                      fontSize: 18.0,
                    ),
                  ),
                  SizedBox(height: 10.0),
                  Text(
                    shortString(chat.message, 30, true),
                    style: TextStyle(
                      color: Pref.of(context).darkBlue.withBrigthness(50),
                      fontSize: 11.0,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  chat.time,
                  style: TextStyle(
                    color: Pref.of(context).darkBlue.withBrigthness(30),
                  ),
                ),
                SizedBox(
                  height: 10.0,
                ),
                Text(
                  chat.status ?? "",
                  style: TextStyle(
                    color: Pref.of(context).darkBlue.withBrigthness(30),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  shortString(String str, [amount = 2, trailingDot = false]) {
    if (str == null || str.length == 0) {
      return null;
    } else {
      return str[0].toUpperCase() +
          str.substring(1, (str.length > amount) ? amount : str.length) +
          (trailingDot && str.length > amount ? "..." : "");
    }
  }

  String getText() {
    try {
      int.parse(chat.senderName);
      return "#";
    } catch (e) {
      return shortString(chat.senderName) ?? shortString(chat.senderNumber);
    }
  }
}

/*class pinnedFriend extends StatelessWidget {
  final String avatar;
  final Color actColor;

  const pinnedFriend({
    Key key,
    this.avatar,
    this.actColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      overflow: Overflow.visible,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Container(
            padding: const EdgeInsets.all(3.4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50.0),
              border: Border.all(
                width: 2.0,
                color: const Color(0xFF558AED),
              ),
            ),
            child: Container(
              width: 54.0,
              height: 54.0,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50.0),
                image: DecorationImage(image: AssetImage(avatar), fit: BoxFit.cover),
              ),
            ),
          ),
        ),
        Positioned(
          top: 10.0,
          right: 10.0,
          child: Container(
            width: 10.0,
            height: 10.0,
            decoration: BoxDecoration(
              color: actColor,
              borderRadius: BorderRadius.circular(5.0),
              border: Border.all(
                width: 1.0,
                color: const Color(0xFFFFFFFF),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

final List<Widget> onlineFriend = [
  pinnedFriend(
    avatar: 'assets/img/1.jpg',
    actColor: Colors.greenAccent,
  ),
  pinnedFriend(
    avatar: 'assets/img/backdrop.png',
    actColor: Colors.yellowAccent,
  ),
  pinnedFriend(
    avatar: 'assets/img/avatar.png',
    actColor: Colors.redAccent,
  ),
  pinnedFriend(
    avatar: 'assets/img/5.jpg',
    actColor: Colors.yellowAccent,
  ),
  pinnedFriend(
    avatar: 'assets/img/6.jpg',
    actColor: Colors.greenAccent,
  ),
  pinnedFriend(
    avatar: 'assets/img/7.jpg',
    actColor: Colors.greenAccent,
  ),
  pinnedFriend(
    avatar: 'assets/img/1.jpg',
    actColor: Colors.greenAccent,
  ),
];*/

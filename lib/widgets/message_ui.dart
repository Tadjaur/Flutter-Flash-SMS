import 'package:flash_sms/utils.dart';
import 'package:flutter/material.dart';

import '../settings.dart';

class MessageUi extends StatelessWidget {
  const MessageUi({
    Key key,
    @required this.data,
  }) : super(key: key);

  final MessageData data;

  @override
  Widget build(BuildContext context) {
    bool isMe = data.type == "2";
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 2.0),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: <Widget>[
//          SizedBox(
//            width: isme ? 30.0 : 20,
//          ),
          !isMe
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
                color: isMe
                    ? Pref.of(context).primary.withBrigthness(-55)
                    : Pref.of(context).primary.withBrigthness(-20),
                borderRadius: BorderRadius.only(
                    topRight: Radius.circular(15.0),
                    topLeft: isMe ? Radius.circular(15.0) : Radius.zero,
                    bottomRight: !isMe ? Radius.circular(15.0) : Radius.zero,
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
          isMe
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

class MessageData {
  String senderName, senderNumber, message, time, status, avatar, type, timestamp, thread_id;

//  final String avatar;
  MessageData(this.senderName, this.senderNumber, this.message, this.time,
      {this.status = "", this.avatar = ""});

  MessageData.fromMap(value)
      : assert(value != null, "the map must not be null") {
    this.senderName = value["name"];
    this.senderNumber = value["phone"];
    this.message = value["msg"];
    this.time = value["time"];
    this.thread_id = value["thread_id"];
    this.timestamp = value["timestamp"];
//    this._id = value["_id"];
    this.type = value["type"];
  }
}

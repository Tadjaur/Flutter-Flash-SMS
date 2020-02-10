import 'dart:typed_data';

class MessageData {
  String senderName, senderNumber, message, time, status, type, threadId, id;
  int timestamp;
  Uint8List avatar;
  Uint8List photo;

  MessageData.fromMap(value) : assert(value != null, "the map must not be null") {
    this.senderName = value[MSG_K.KEY_NAME];
    this.senderNumber = value[MSG_K.ADDRESS];
    this.message = value[MSG_K.BODY];
    this.threadId = value[MSG_K.THREAD_ID];
    this.timestamp = int.parse(value[MSG_K.DATE] ??
        value[MSG_K.DATE_SENT] ??
        DateTime.now().millisecondsSinceEpoch.toString());
    final d = new DateTime.fromMillisecondsSinceEpoch(this.timestamp);
    this.time = DateUtils.toDateString(d);
    this.id = value[MSG_K.ID];
    this.avatar = value[MSG_K.KEY_THUMB];
    this.photo = value[MSG_K.KEY_PHOTO];
    this.type = value[MSG_K.TYPE] ?? "${MSG_K.MESSAGE_TYPE_INBOX}";
  }
}

mixin MSG_K {
  static const String ADDRESS = "address";
  static const String BODY = "body";
  static const String CREATOR = "creator";
  static const String DATE = "date";
  static const String DATE_SENT = "date_sent";
  static const String ERROR_CODE = "error_code";
  static const String ID = "_id";
  static const String KEY_MSG = "body";
  static const String KEY_NAME = "name";
  static const String KEY_THUMB = "thumbnail";
  static const String KEY_PHOTO = "photo";
  static const String LOCKED = "locked";
  static const int MESSAGE_TYPE_ALL = 0;
  static const int MESSAGE_TYPE_DRAFT = 3;
  static const int MESSAGE_TYPE_FAILED = 5;
  static const int MESSAGE_TYPE_INBOX = 1;
  static const int MESSAGE_TYPE_OUTBOX = 4;
  static const int MESSAGE_TYPE_QUEUED = 6;
  static const int MESSAGE_TYPE_SENT = 2;
  static const String READ = "read";
  static const String SEEN = "seen";
  static const String SERVICE_CENTER = "service_center";
  static const String STATUS = "status";
  static const String SUBJECT = "subject";
  static const String SUBSCRIPTION_ID = "sub_id";
  static const String THREAD_ID = "thread_id";
  static const String TYPE = "type";
}

mixin DateUtils {
  /// return the given [DateTime] to String representation based
  /// on it duration. Possible return value are: 'now', '01 min', '05:00', 'Wed 10:39', '05 Feb', '20 Dec 2012'
  static String toDateString(DateTime dt) {
    int diff = DateTime.now().millisecondsSinceEpoch - dt.millisecondsSinceEpoch;
    if (diff < (60 * 1000)) {
      return "now";
    }
    if (diff < (60 * 60 * 1000)) {
      return '${(diff / (60 * 1000)).floor()} min';
    }
    final h = dt.hour, m = dt.minute, timeStr = "${cv(h)}:${cv(m)}";
    if (diff < (24 * 60 * 60 * 1000)) {
      return timeStr;
    }
    if (diff < (2 * 24 * 60 * 60 * 1000)) {
      return 'yesterday $timeStr';
    }
    final dateInMonth = "${cv(dt.day)} ${weekMonthName(dt).month.substring(0, 3)}";
    if (diff < (365 * 24 * 60 * 60 * 1000)) {
      return dateInMonth;
    }

    return '$dateInMonth ${dt.year}';
  }

  /// take and integer and return it string representation
  /// prefixed with zero if it length is short than the count
  /// eg:
  ///
  ///   cv(1) return '01';
  ///
  ///   cv(11) return '11';
  ///
  ///   cv(12, 5) return '00012';
  static String cv(int v, [int count = 2]) {
    final ln = v.toString().length;
    return ln < count ? "0" * (count - ln) + '$v' : '$v';
  }

  static WeekMonth weekMonthName(DateTime dt) {
    var week = {
      'w1': 'Monday',
      'w2': 'Thuesday',
      'w3': 'Wednesday',
      'w4': 'Tursday',
      'w5': 'Friday',
      'w6': 'Saturday',
      'w7': 'Sunday',
    };
    var month = {
      "m1": "January",
      "m2": "Febuary",
      "m3": "Marh",
      "m4": "April",
      "m5": "May",
      "m6": "June",
      "m7": "Jully",
      "m8": "August",
      "m9": "September",
      "m10": "October",
      "m11": "November",
      "m12": "December",
    };
    return WeekMonth(week['w${dt.weekday}'], month['m${dt.month}']);
  }
}

class WeekMonth {
  final String _week, _month;

  WeekMonth(week, month)
      : this._week = week,
        this._month = month;

  String get week => _week;

  String get month => _month;
}

mixin StringUtil {
  static bool isNumber(String str) {
    try {
      double.parse(str);
      return true;
    } catch (e) {
      return false;
    }
  }
}

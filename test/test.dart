main(){
  final a = DateTime.now();
  print("${a.day}/${a.month} ${a.hour}:${a.minute}");
  print(a.millisecondsSinceEpoch);
  final old = "string";
  final nw = "ring";
  final _oldX = old.indexOf(nw);
  print((_oldX > 0 && (_oldX + nw.length) == old.length));
  print(int.parse("+237"));
  print(double.parse("237.00.1"));
  print(double.parse("237001"));
  print(double.parse("23 7001"));
}
main(){
  print(DateTime.now().toString());
  print(DateTime.now().toIso8601String());
  final a = DateTime.now();
  print("${a.day}/${a.month} ${a.hour}:${a.minute}");
  print(a.millisecondsSinceEpoch);
}
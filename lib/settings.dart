import 'package:flutter/material.dart';

class Pref extends StatefulWidget {
  Pref({@required this.child});

  final Widget child;

  @override
  _PrefState createState() => _PrefState();

  static _PrefState of(BuildContext context) {
    return (context.inheritFromWidgetOfExactType(_InheritedStateContainer)
            as _InheritedStateContainer)
        .data;
  }
}

class _PrefState extends State<Pref> {
  // Add all your theme properties and logic here:
  double get spacingUnit => 10.0;

  double get messageSpacing => 10.0;

  CustomColor get white => const CustomColor(0xfffcfcfc);

  CustomColor get accent => const CustomColor(0xFF8bec02);

  CustomColor get primary => const CustomColor(0xfffcfcfc);

  CustomColor get transparent => const CustomColor(0x00071824);

  CustomColor get darkBlue => const CustomColor(0xFF071824);

  CustomColor get baseBlue => const CustomColor(0xFF014560);

  CustomColor get lightBlue => const CustomColor(0xFF29abe2);

  CustomColor get baseGreen => const CustomColor(0xFF006e00);

  CustomColor get lightGreen2 => const CustomColor(0xFF32db64);

  CustomColor get green => const CustomColor(0xFF259a59);

  CustomColor get darkRed => const CustomColor(0xFF852020);

  String get lang => _language;

  String _language = "fr";

  @override
  Widget build(BuildContext context) {
    return _InheritedStateContainer(data: this, child: widget.child);
  }
}

class _InheritedStateContainer extends InheritedWidget {
  const _InheritedStateContainer({
    Key key,
    @required this.data,
    @required Widget child,
  })  : assert(child != null && data != null),
        super(key: key, child: child);

  final _PrefState data;

  @override
  bool updateShouldNotify(_InheritedStateContainer old) => true;
}

class CustomColor extends Color {
  const CustomColor.fromARGB(int a, int r, int g, int b) : super.fromARGB(a, r, g, b);

  const CustomColor.fromRGBO(int r, int g, int b, double opacity)
      : super.fromRGBO(r, g, b, opacity);

  const CustomColor(int value) : super(value);

  Color withBrigthness(int amount) {
    return Color.fromARGB(alpha, red + amount, green + amount, blue + amount);
  }
}

import 'package:flutter/material.dart';
import 'package:fu_uber/Core/Constants/colorConstants.dart';

typedef OnPressed = void Function();

class CircularFlatButton extends StatelessWidget {
  final double? size;
  final Widget child;
  final String name;
  final OnPressed? onPressed;

  const CircularFlatButton(
      {Key? key, this.size, required this.name, this.onPressed, required this.child})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        height: size,
        width: size,
        child: TextButton(
            style: TextButton.styleFrom(
              shape: const CircleBorder(),
              disabledBackgroundColor: ConstantColors.DeepBlue.withOpacity(0.2),
              padding: EdgeInsets.zero,
            ),
            onPressed: onPressed,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                child,
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.deepPurpleAccent,
                  ),
                )
              ],
            )));
  }
}

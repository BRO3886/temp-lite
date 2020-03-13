import 'package:flutter/material.dart';

class CurrentTemp extends StatelessWidget {
  final double temp;
  CurrentTemp(this.temp);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      child: Text(
        temp.toString()+"°",
        style: Theme.of(context).textTheme.display1,
      ),
    );
  }
}

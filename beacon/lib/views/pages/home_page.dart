import 'package:beacon/views/widget/map_widget.dart';
import 'package:flutter/material.dart';


class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      child: Padding(padding: const EdgeInsets.only(top: 20.0)
      , child: MapWidget()
      )
    );
  }
}
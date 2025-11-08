import 'package:beacon/data/constants.dart';
import 'package:beacon/data/notifiers.dart';
import 'package:beacon/views/pages/home_page.dart';
import 'package:beacon/views/pages/search_page.dart';
import 'package:flutter/material.dart';
import 'package:beacon/views/widget/navbar.dart';
import 'package:shared_preferences/shared_preferences.dart';

List <Widget> pages = [
  HomePage(),
  SearchPage(),
];

class WidgetTree extends StatelessWidget {
  const WidgetTree({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(valueListenable: selectedValueNotifier, builder: (context, selectedPage, child) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Beacon"), 
          centerTitle: true,
          actions: [IconButton(onPressed: () async{
              final SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.setBool(KConstants.themeModeKey, isDarkModeNotifier.value);
            isDarkModeNotifier.value = !isDarkModeNotifier.value;
          }, icon: ValueListenableBuilder(valueListenable: isDarkModeNotifier, builder: (context, isDarkMode, child) {
            return Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode);
          })),],
        ),
        body: pages[selectedPage],
        bottomNavigationBar: NavBar(),
    );
    },);
  }
}
import 'package:beacon/data/notifiers.dart';
import 'package:flutter/material.dart';


class NavBar extends StatelessWidget {
  const NavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(valueListenable: selectedValueNotifier, builder: (context, selectedPage, child) {
      return NavigationBar(destinations: [
          NavigationDestination(icon: Icon(Icons.home), label: "Home"),
          NavigationDestination(icon: Icon(Icons.person), label: "Profile"),
          NavigationDestination(icon: Icon(Icons.radar), label: "Beacons"),
          NavigationDestination(icon: Icon(Icons.star), label: "Favorites"),
        ],
          selectedIndex: selectedPage,
          onDestinationSelected: (value){
              selectedValueNotifier.value = value;
          }
    );
    },);
  }
}
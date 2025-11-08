import 'package:beacon/data/notifiers.dart';
import 'package:flutter/material.dart';
import 'package:beacon/views/pages/welcome_page.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.all(20.0)
    , child: Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundImage: AssetImage("assets/images/logo.png"),
        ),
        SizedBox(height: 5,),
        ListTile(
          leading: Icon(Icons.logout),
          title: Text("Logout"),
          onTap: ()
          {
            selectedValueNotifier.value = 0;
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) {
              return WelcomePage();
            },));
          },
        )
      ],
    ),
    );
  }
}
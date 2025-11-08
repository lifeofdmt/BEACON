import 'package:beacon/data/constants.dart';
import 'package:beacon/data/notifiers.dart';
import 'package:flutter/material.dart';
import 'package:beacon/views/pages/welcome_page.dart';
import 'package:flutter_color_picker_wheel/models/button_behaviour.dart';
import 'package:flutter_color_picker_wheel/widgets/flutter_color_picker_wheel.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Centered Row for avatar and arrows
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.arrow_left),
                ),
                CircleAvatar(
                  radius: 50,
                  backgroundImage: AssetImage("assets/images/logo_transparent.png"),
                ),
                IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.arrow_right),
                ),
              ],
            ),

            SizedBox(height: 10),
            Text('About Me', style: KTextStyle.titleTealText),

            GestureDetector(
              child: Container(
                padding: EdgeInsets.all(20),
                height: 200,
                width: double.infinity,
                child: Card(
                  color: Colors.redAccent,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Text("I'm a chill person"),
                  ),
                ),
              ),
            ),

            // Centered Row for color picker
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Woljie Color: "),
                SizedBox(width: 10,),
                WheelColorPicker(
                  onSelect: (value) {},
                  defaultColor: Colors.grey,
                  behaviour: ButtonBehaviour.clickToOpen,
                  innerRadius: 60,
                  buttonSize: 40,
                  pieceHeight: 25,
                ),
              ],
            ),

            ListTile(
              leading: Icon(Icons.logout),
              title: Text("Logout"),
              onTap: () {
                selectedValueNotifier.value = 0;
                Navigator.pushReplacement(context, MaterialPageRoute(
                  builder: (context) => WelcomePage(),
                ));
              },
            ),
          ],
        ),
      ),
    );
  }
}

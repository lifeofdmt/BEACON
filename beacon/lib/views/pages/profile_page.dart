import 'package:beacon/data/constants.dart';
import 'package:beacon/data/notifiers.dart';
import 'package:beacon/views/mobile/auth_service.dart';
import 'package:beacon/views/pages/onboarding.dart';
import 'package:beacon/views/widget_tree.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:beacon/views/pages/welcome_page.dart';
import 'package:flutter_color_picker_wheel/models/button_behaviour.dart';
import 'package:flutter_color_picker_wheel/widgets/flutter_color_picker_wheel.dart';


class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _aboutMeController = TextEditingController(text: "I'm a chill person");
  bool _editingAboutMe = false;
  String _settingsMessage = "";

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: Duration(milliseconds: 900));
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void logout() async {
    try {
      await authService.value.signOut();
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) {
        return WelcomePage();
      },), (route) => false);
    } on FirebaseAuthException catch (e) {
      setState(() { _settingsMessage = e.message ?? "Logout error"; });
    }
  }

  void deleteAccount() async {
    try {
      await authService.value.deleteAccount(email: _emailController.text, password: _passwordController.text);
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) {
        return WelcomePage();
      },), (route) => false);
    } catch (e) {
      setState(() { _settingsMessage = e.toString(); });
    }
  }

  void updateUsername() async {
    try {
      await authService.value.updateUsername(username: _usernameController.text);
      setState(() { _settingsMessage = "Username updated!"; });
    } catch (e) {
      setState(() { _settingsMessage = e.toString(); });
    }
  }

  void changePassword() async {
    try {
      await authService.value.updatePassword(
        email: _emailController.text,
        password: _passwordController.text,
        newPassword: _passwordController.text,
      );
      setState(() { _settingsMessage = "Password changed!"; });
    } catch (e) {
      setState(() { _settingsMessage = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedSwitcher(
                    duration: Duration(milliseconds: 500),
                    child: Icon(Icons.arrow_left, size: 32, color: Theme.of(context).colorScheme.primary, key: ValueKey("left")),
                  ),
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: AssetImage("assets/images/logo_transparent.png"),
                  ),
                  AnimatedSwitcher(
                    duration: Duration(milliseconds: 500),
                    child: Icon(Icons.arrow_right, size: 32, color: Theme.of(context).colorScheme.primary, key: ValueKey("right")),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Text('About Me', style: KTextStyle.titleTealText.copyWith(fontSize: 28, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
              Container(
                padding: EdgeInsets.all(20),
                width: double.infinity,
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  elevation: 8,
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_editingAboutMe)
                          Column(
                            children: [
                              TextField(
                                controller: _aboutMeController,
                                maxLines: 3,
                                decoration: InputDecoration(
                                  labelText: "Edit About Me",
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              SizedBox(height: 10),
                              Row(
                                children: [
                                  FilledButton(
                                    onPressed: () {
                                      setState(() { _editingAboutMe = false; });
                                    },
                                    child: Text("Save"),
                                  ),
                                  SizedBox(width: 10),
                                  TextButton(
                                    onPressed: () {
                                      setState(() { _editingAboutMe = false; _aboutMeController.text = "I'm a chill person"; });
                                    },
                                    child: Text("Cancel"),
                                  ),
                                ],
                              ),
                            ],
                          )
                        else
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(_aboutMeController.text, style: TextStyle(fontSize: 18, color: Theme.of(context).colorScheme.onSecondaryContainer)),
                              ),
                              IconButton(
                                icon: Icon(Icons.edit, color: Theme.of(context).colorScheme.primary),
                                onPressed: () {
                                  setState(() { _editingAboutMe = true; });
                                },
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Woljie Color: ", style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                  SizedBox(width: 10,),
                  WheelColorPicker(
                    onSelect: (value) {},
                    defaultColor: Theme.of(context).colorScheme.primary,
                    behaviour: ButtonBehaviour.clickToOpen,
                    innerRadius: 60,
                    buttonSize: 40,
                    pieceHeight: 25,
                  ),
                ],
              ),
              SizedBox(height: 30),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                elevation: 8,
                color: Theme.of(context).colorScheme.surface,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Settings", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                      SizedBox(height: 10),
                      FilledButton(
                        onPressed: updateUsername,
                        child: Text("Update Username"),
                        style: FilledButton.styleFrom(minimumSize: Size(double.infinity, 50))
                      ),
                      SizedBox(height: 10),
                      FilledButton(
                        onPressed: changePassword,
                        child: Text("Change Password"),
                        style: FilledButton.styleFrom(minimumSize: Size(double.infinity, 50))
                      ),
                      SizedBox(height: 10),
                      FilledButton(
                        onPressed: deleteAccount,
                        style: FilledButton.styleFrom(backgroundColor: Colors.redAccent, 
                        minimumSize: Size(double.infinity, 50)),
                        child: Text("Delete Account"),
                      ),
                      SizedBox(height: 10),
                      AnimatedSwitcher(
                        duration: Duration(milliseconds: 400),
                        child: _settingsMessage.isNotEmpty
                            ? Text(_settingsMessage, key: ValueKey(_settingsMessage), style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
                            : SizedBox.shrink(),
                      ),
                      SizedBox(height: 10),
                      ListTile(
                        leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.primary),
                        title: Text("Logout", style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                        onTap: logout,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:beacon/views/widget_tree.dart';
import 'package:lottie/lottie.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController controllerEmail = TextEditingController();
  final TextEditingController controllerPassword = TextEditingController();
  String confirmedEmail = "123@yahoo.com";
  String confirmedPassword = "123456789";

  @override
  void dispose() {
    controllerEmail.dispose();
    controllerPassword.dispose();
    super.dispose();
  }
    @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Hero(tag: "hero_2", child: Lottie.asset("assets/lotties/wolf_walk.json")),
              SizedBox(height: 15,),
              FilledButton(onPressed: () {
                onLoginPressed();
              }, style: FilledButton.styleFrom(minimumSize: Size(double.infinity, 50)),
              child: Row(
                children: [
                  Image.asset("assets/images/google_logo.avif", 
                  height: 25,),
                  Expanded(child: Text("Sign In With Google", 
                  textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),)),
                ],
              )),
            ],
          ),
        ),
      ),
    );
  }

  void onLoginPressed()
  {
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) {
        return WidgetTree();
      },), (route) => false);
  }
}
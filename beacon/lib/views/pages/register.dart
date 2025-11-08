import 'package:flutter/material.dart';
import 'package:beacon/views/widget_tree.dart';
import 'package:lottie/lottie.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});


  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController controllerEmail = TextEditingController();
  final TextEditingController controllerPassword = TextEditingController();
  String confirmedEmail = "123@yahoo.com";
  String confirmedPassword = "123456789";
  String errorMessage = "";

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
              TextField(
              controller: controllerEmail,
              decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
               hintText: "Email"), 
              onChanged: (value){
                setState(() {
                });
              },
            ),
            SizedBox(height: 15,),
              TextField(
              controller: controllerPassword,
              decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
               hintText: "Password"), 
              onChanged: (value){
                setState(() {
                });
              },
            ),
            SizedBox(height: 15,),
            FilledButton(onPressed: () {
              registerUser();
            }, style: FilledButton.styleFrom(minimumSize: Size(double.infinity, 50)),child: Text("Register")),
            SizedBox(height: 15,),
            Text(errorMessage, style: TextStyle(color: Colors.red),)
            ],
          ),
        ),
      ),
    );
  }

  void registerUser(){
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) {
        return WidgetTree();
      },), (route) => false);
    }
  }


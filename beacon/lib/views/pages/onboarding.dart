import 'package:beacon/data/constants.dart';
import 'package:beacon/views/pages/register.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Hero(tag: "hero_1", child: Lottie.asset("assets/lotties/splash.json")),
              SizedBox(height: 15,),
              Center(
                child: Text("BEACON  is the way to meet people who like to do the same things as you", 
                style: KTextStyle.descriptionText, textAlign: TextAlign.center,),
              ),
              SizedBox(height: 10,),
              FilledButton(onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return RegisterPage();
                },));
            }, style: FilledButton.styleFrom(), child: Text("Next"))
            ],
          ),
        ),
      ),
    );
  }
}
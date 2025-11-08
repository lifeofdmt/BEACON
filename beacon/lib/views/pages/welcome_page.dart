import 'package:beacon/views/pages/login_page.dart';
import 'package:beacon/views/pages/onboarding.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';


class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Hero(tag: "hero_1", child: Lottie.asset("assets/lotties/welcome.json", height: 400)),
                SizedBox(height: 5,),
                FittedBox(child: Text("BEACON", style: TextStyle(letterSpacing: 50, fontWeight: FontWeight.bold,
                 fontSize: 70))),
                SizedBox(height: 20,),
                FilledButton(onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return OnboardingPage();
                  },));
                }, style: FilledButton.styleFrom(minimumSize: Size(double.infinity, 40)), child: Text("Sign Up",)),
                  TextButton(onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return LoginPage();
                  },));
                }, style: TextButton.styleFrom(minimumSize: Size(double.infinity, 40)), child: Text("Login"))
              ],
            ),
          ),
        ),
      ),
    );
  }
}
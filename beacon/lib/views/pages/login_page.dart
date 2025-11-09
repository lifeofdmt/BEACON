import 'package:beacon/data/notifiers.dart';
import 'package:beacon/views/mobile/auth_service.dart';
import 'package:beacon/views/pages/password_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:beacon/views/widget_tree.dart';
import 'package:lottie/lottie.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}


class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final TextEditingController controllerEmail = TextEditingController();
  final TextEditingController controllerPassword = TextEditingController();
  String errorMessage = '';
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: Duration(milliseconds: 900));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
    _animController.forward();
  }

  @override
  void dispose() {
    controllerEmail.dispose();
    controllerPassword.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(elevation: 0, backgroundColor: Colors.transparent),
      body: Center(
        child: SingleChildScrollView(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Hero(tag: "hero_2", child: Lottie.asset("assets/lotties/wolf_walk.json", height: 180)),
                  SizedBox(height: 10),
                  Text("Welcome Back!", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 2)),
                  SizedBox(height: 20),
                  AnimatedContainer(
                    duration: Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 6))],
                    ),
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        TextField(
                          controller: controllerEmail,
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.email_outlined),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                            hintText: "Email",
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        SizedBox(height: 15),
                        TextField(
                          controller: controllerPassword,
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.lock_outline),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                            hintText: "Password",
                          ),
                          obscureText: true,
                        ),
                        SizedBox(height: 15),
                        AnimatedSwitcher(
                          duration: Duration(milliseconds: 400),
                          child: errorMessage.isNotEmpty
                              ? Text(errorMessage, key: ValueKey(errorMessage), style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
                              : SizedBox.shrink(),
                        ),
                        SizedBox(height: 10),
                        FilledButton(
                          onPressed: () {onLoginPressed();},
                          style: FilledButton.styleFrom(minimumSize: Size(double.infinity, 50)),
                          child: Text("Sign In", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                        SizedBox(height: 10),
                        FilledButton(
                          onPressed: () {signInWithGoogle();},
                          style: FilledButton.styleFrom(minimumSize: Size(double.infinity, 50)),
                          child: Row(
                            children: [
                              Image.asset("assets/images/google_logo.avif", height: 25),
                              Expanded(child: Text("Sign In With Google", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                            ],
                          ),
                        ),
                        SizedBox(height: 20),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) {
                              return PasswordPage();
                            },));
                          },
                          child: Container(
                            width: double.infinity,
                            alignment: Alignment.centerRight,
                            child: Text("Reset Password", textAlign: TextAlign.right, style: TextStyle(decoration: TextDecoration.underline)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void onLoginPressed() async{
    try {
      await authService.value.signIn(email: controllerEmail.text, password: controllerPassword.text);
      if (!mounted) return;
      selectedValueNotifier.value = 0;
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) {
        return WidgetTree();
      },), (route) => false);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
          errorMessage = e.message ?? "Your email/password is incorrect";
      });
    }
  }

  void signInWithGoogle() {
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) {
        return WidgetTree();
      },), (route) => false);
  }
}

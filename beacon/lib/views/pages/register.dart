import 'package:beacon/utils/string_utils.dart';
import 'package:beacon/views/mobile/auth_service.dart';
import 'package:beacon/views/mobile/database_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:beacon/views/widget_tree.dart';
import 'package:lottie/lottie.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});


  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> with SingleTickerProviderStateMixin {
  final TextEditingController controllerEmail = TextEditingController();
  final TextEditingController controllerPassword = TextEditingController();
  String errorMessage = "";
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
                  Text("Create Account", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 2)),
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
                        FilledButton(
                          onPressed: () {registerUser();},
                          style: FilledButton.styleFrom(minimumSize: Size(double.infinity, 50)),
                          child: Text("Register", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                        SizedBox(height: 15),
                        AnimatedSwitcher(
                          duration: Duration(milliseconds: 400),
                          child: errorMessage.isNotEmpty
                              ? Text(errorMessage, key: ValueKey(errorMessage), style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
                              : SizedBox.shrink(),
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

  void registerUser() async {
    try {
      setState(() {
        errorMessage = "";
      });

      // Create the account
      await authService.value.createAccount(
        email: controllerEmail.text,
        password: controllerPassword.text,
      );

      // Generate and set a memorable username if none exists
      final user = authService.value.currentuser;
      if (user != null && user.displayName == null) {
        final memorableName = StringUtils.generateMemorable();
        await user.updateDisplayName(memorableName);
      }

      // Create the user's data in the database
      await DatabaseService().create(
        path: "users/${user?.uid}",
        data: {
          "email": controllerEmail.text,
          "displayName": user?.displayName ?? StringUtils.generateMemorable(),
          "about": "",
          "createdAt": DateTime.now().toIso8601String(),
        },
      );

      if (mounted) {
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) {
          return WidgetTree();
        },), (route) => false);
      }
    } on FirebaseAuthException catch(e) {
      setState(() {
        errorMessage = e.message ?? 'There is an error';
      });
    } catch (e) {
      setState(() {
        errorMessage = 'An unexpected error occurred';
      });
    }
  }
}
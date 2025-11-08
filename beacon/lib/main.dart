import 'package:beacon/data/constants.dart';
import 'package:beacon/data/notifiers.dart';
import 'package:beacon/views/pages/welcome_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';


void main() async{
  runApp(const MyApp());

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
}


class MyApp extends StatelessWidget 
{
  const MyApp({super.key});

  
  @override
  Widget build(BuildContext context) 
  {
    return ValueListenableBuilder(valueListenable: isDarkModeNotifier, builder: (context, isDarkModePage, child) {
      return MaterialApp(
      debugShowCheckedModeBanner: false, 
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.redAccent, 
          brightness: isDarkModePage ? Brightness.dark : Brightness.light),
          
      ),
        home: MyHomePage());
    },);
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
    
  }

  void themeMode()async{
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool? repeat = prefs.getBool(KConstants.themeModeKey);
    isDarkModeNotifier.value = repeat ?? false;

  }
  @override
  Widget build(BuildContext context) {
    return WelcomePage();
  }
}



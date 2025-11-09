import 'package:beacon/data/notifiers.dart';
import 'package:beacon/views/pages/auth_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';


void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configure image cache to prevent memory issues
  PaintingBinding.instance.imageCache.maximumSize = 100; // Limit cached images
  PaintingBinding.instance.imageCache.maximumSizeBytes = 50 * 1024 * 1024; // 50MB max
  
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
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
        home: AuthLayout());
    },);
  }
}



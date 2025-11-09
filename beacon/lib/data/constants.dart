import 'package:flutter/material.dart';

const String GOOGLE_MAPS_API_KEY = "AIzaSyAS_QlAPSjayKePyn2Xpnxd3QQjylGniN8";
// Environment variable name for ElevenLabs API key. Do NOT hard-code the key in source.
// Provide the key at runtime via: flutter run --dart-define=ELEVENLABS_API_KEY=your_key
// or a .env file with ELEVENLABS_API_KEY=your_key (loaded by flutter_dotenv).
const String ELEVEN_LABS_API_KEY_ENV = 'sk_7646723ecd37925f500d5f55bae6f82af4fa5492294c5d0d';

class BeaconCategories {
  static const List<String> all = [
    'Social',
    'Religion',
    'Events',
    'Sports',
    'Help Needed',
    'Other'
  ];

  static const String defaultCategory = 'Social';
}

class KConstants 
{
  static const String themeModeKey = "themeModeKey";
}

class KTextStyle {
  static const TextStyle titleTealText = TextStyle(
  fontSize: 18, fontWeight: 
  FontWeight.w900);

  static const TextStyle descriptionText = TextStyle( 
  fontSize: 15, 
  fontWeight: FontWeight.w700);
}


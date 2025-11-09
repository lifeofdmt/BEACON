import 'package:flutter/material.dart';

const String GOOGLE_MAPS_API_KEY = "AIzaSyAS_QlAPSjayKePyn2Xpnxd3QQjylGniN8";

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


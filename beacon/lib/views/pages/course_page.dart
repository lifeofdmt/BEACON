import 'package:flutter/material.dart';
import 'package:beacon/views/widget/hero_widget.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;



class CoursePage extends StatefulWidget {
  const CoursePage({super.key});

  @override
  State<CoursePage> createState() => _CoursePageState();
}

class _CoursePageState extends State<CoursePage> {
  @override
  void initState() {
    getData();
    super.initState();
  }

  void getData()
  async{
    var url =
        Uri.https('bored-api.appbrewery.com', '/random');

    // Await the http get response, then decode the json-formatted response.
    var response = await http.get(url);
    if (response.statusCode == 200) {
      var jsonResponse =
          convert.jsonDecode(response.body) as Map<String, dynamic>;
      var itemCount = jsonResponse['accessibility'];
      print('Number of books about http: $itemCount.');
    } else {
      print('Request failed with status: ${response.statusCode}.');
    }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      
      body: Padding(padding: const EdgeInsets.symmetric(horizontal: 20.0)
      , child: SingleChildScrollView(
        child: Column(
          children: [
            HeroWidget(title: "COURSE",),
          ],
        ),
      ), ),
    );
  }
}
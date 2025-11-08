import 'package:flutter/material.dart';

class HeroWidget extends StatelessWidget {
  const HeroWidget({super.key, required this.title, this.next_page});

  final String title;
  final Widget? next_page;
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        GestureDetector(
          onTap: next_page != null ? () {
            Navigator.push(context, MaterialPageRoute(builder: (context) {
              return next_page!;
            },));
          } : null,
          child: Hero(
            tag: "hero_1",
            child: AspectRatio(
              aspectRatio: 1920/1080,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                  child: Center(child: Image.asset("assets/images/placeholder.png", colorBlendMode: BlendMode.modulate, fit: BoxFit.cover,)),
              ),
            ),
          ),
        ),
        FittedBox(child: Text(title, style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold, fontSize: 50, letterSpacing: 20),))
      ],
    );
  }
}
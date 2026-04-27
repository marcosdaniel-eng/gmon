import 'package:flutter/material.dart';

Widget buildImageContainer(
    Color color,
    String title,
    String subtitle,
    String imagePath
    ){
  return Container(
    color: color,
    child: Column(
      children: [
        const SizedBox(height: 60,),
        Image.asset(
          imagePath,
          fit: BoxFit.cover,
          width: 250,
        ),
        const SizedBox(height: 40,),
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 20),
          child:
          Text(title,textAlign:TextAlign.left,style: const TextStyle(color: Color(0xFF093e6a),
              fontSize: 15,
              fontWeight: FontWeight.bold),),
          )
        ),
        const SizedBox(height: 20,),

        Container(
          alignment:Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 20),
          child: Text(subtitle,style: const TextStyle(color: Colors.black,fontSize: 13),),
        )
      ],
    ),
  );
}
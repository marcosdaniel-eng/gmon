import 'package:flutter/material.dart';
import 'package:gmon/Monitor_menu.dart';
import 'package:gmon/main.dart';

import 'onboarding_screen.dart';


class Splashscreen extends StatefulWidget {
  const Splashscreen({super.key});

  @override
  State<Splashscreen> createState() => _SplashscreenState();
}

class _SplashscreenState extends State<Splashscreen> {
  @override
  void initState() {
    _goHome();
    super.initState();
  }

  _goHome()async{
    await Future.delayed(const Duration(milliseconds: 4000),() {});
    Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context)=>const MyOnboarding()));
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:Color(0xFF0d3a63),
      body: Center(
        child: Image.asset("assets/logo_miravalles.gif"),
      ),

    );
  }
}


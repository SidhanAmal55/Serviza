// splash_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/screen/layout/main_layout.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class ImageSplash extends StatefulWidget {
  const ImageSplash({super.key});

  @override
  State<ImageSplash> createState() => _ImageSplashState();
}

class _ImageSplashState extends State<ImageSplash> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainLayout()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => LoginScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFB27F5F), // coffee light
              Color(0xFF5D4037), // coffee dark
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/application_image.png'),
              const SizedBox(height: 10),
              const Text(
                "Serviza",
                style: TextStyle(
                  fontSize: 30,
                  color: Color.fromARGB(255, 255, 227, 17),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "DEVELOPED BY A.S.E.P ❤️",
                style: TextStyle(
                  fontSize: 20,
                  color: Color.fromARGB(255, 238, 246, 15),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

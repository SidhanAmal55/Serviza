
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:myapp/screen/home_screen.dart';
import 'package:myapp/screen/splash_screen.dart'; // Splash screen
import 'firebase_options.dart'; // Make sure this is generated via flutterfire configure

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'POINT Catering App',
      theme: ThemeData(primarySwatch: Colors.teal),
      home: const ImageSplash(), // Splash screen initially
      debugShowCheckedModeBanner: false,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_login/flutter_login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/screen/layout/main_layout.dart';

class LoginScreen extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Duration get loginTime => const Duration(milliseconds: 1500);

  // Coffee theme colors
  static const Color coffeeDark = Color(0xFF5D4037);
  static const Color coffeeLight = Color(0xFFF5E6D3);
  static const Color coffeeTan = Color(0xFFD7B899);
  static const Color coffeeAccent = Color(0xFF8D6E63);

  @override
  Widget build(BuildContext context) {
    return FlutterLogin(
      title: 'LOGIN TO SERVIZA',
      logo: const AssetImage('assets/images/application_image.png'),
      onLogin: _loginUser,
      onSignup: _signupUser,
      onRecoverPassword: _recoverPassword,
      onSubmitAnimationCompleted: () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainLayout()),
        );
      },
      theme: _loginTheme(),
      messages: LoginMessages(
        userHint: 'Email',
        passwordHint: 'Password',
        confirmPasswordHint: 'Confirm',
        loginButton: 'LOGIN',
        signupButton: 'SIGN UP',
      ),
    );
  }

  Future<String?> _loginUser(LoginData data) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: data.name,
        password: data.password,
      );
      return null;
    } on FirebaseAuthException {
      return "Invalid email or password";
    }
  }

  Future<String?> _signupUser(SignupData data) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: data.name!,
        password: data.password!,
      );
      return null;
    } on FirebaseAuthException {
      return "Invalid email or password";
    }
  }

  Future<String?> _recoverPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  LoginTheme _loginTheme() {
    return LoginTheme(
      primaryColor: coffeeDark,
      accentColor: coffeeAccent,
      titleStyle: const TextStyle(
        color: coffeeDark,
        fontFamily: 'Quicksand',
        letterSpacing: 4,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      pageColorLight: coffeeLight,
      pageColorDark: coffeeDark,
      beforeHeroFontSize: 20,
      bodyStyle: const TextStyle(color: Colors.black87),
      cardTheme: const CardTheme(
        color: Color(0xFFF5E6D3),
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      buttonTheme: LoginButtonTheme(
        backgroundColor: coffeeAccent,
        highlightColor: coffeeTan,
        splashColor: coffeeLight,
      ),
    );
  }
}

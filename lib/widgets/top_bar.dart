import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:myapp/screen/login_screen.dart';

class TopBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isMobile;
  final VoidCallback openDrawer;

  const TopBar({Key? key, required this.isMobile, required this.openDrawer})
    : super(key: key);

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color coffeeDark = Color(0xFF5D4037);
    const Color coffeeLight = Color(0xFFF5E6D3);
    const Color coffeeAccent = Color(0xFF8D6E63);

    return AppBar(
      backgroundColor: coffeeDark,
      title: const Text(
        'Catering Manager',
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      ),
      leading:
          isMobile
              ? IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: openDrawer,
              )
              : null,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: GestureDetector(
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => LoginScreen()),
                (route) => false,
              );
            },
            child: CircleAvatar(
              backgroundColor: coffeeLight,
              child: Icon(Icons.logout, color: coffeeAccent),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 24); // 56 + 24
}

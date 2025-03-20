import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'auth_screen.dart';

class ProfileScreen extends StatelessWidget {
  final User? user;

  // ✅ Ginamit ang super parameter para sa key
  const ProfileScreen({super.key, required this.user});

  void _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();

      if (!context.mounted) return; // Siguraduhin na mounted pa ang widget

      Fluttertoast.showToast(msg: "Logged out successfully!");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AuthScreen()), // Babalik sa login page
      );
    } catch (error) {
      Fluttertoast.showToast(msg: "Logout failed: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person, size: 100, color: Colors.blue),
            const SizedBox(height: 10),
            const Text(
              "Logged in as:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(
              user?.email ?? "No email", // Ipapakita ang email ng user
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout),
              label: const Text("Logout"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dashboard_screen.dart';
import 'register_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    final navigator = Navigator.of(context);
    setState(() => _isLoading = true);

    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (mounted) {
        navigator.pushReplacement(
          MaterialPageRoute(builder: (context) => DashboardScreen()), // ✅ Removed const
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) _showErrorMessage(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorMessage(FirebaseAuthException e) {
    String message = "An error occurred.";
    if (e.code == 'user-not-found') {
      message = "No user found for that email.";
    } else if (e.code == 'wrong-password') {
      message = "Incorrect password.";
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "Email"),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) return "Email is required.";
                  if (!RegExp(r"^[a-zA-Z0-9.+_-]+@[a-zA-Z0-9.-]+\.[a-z]+").hasMatch(value)) {
                    return "Enter a valid email.";
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: "Password"),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) return "Password is required.";
                  if (value.length < 6) return "Password must be at least 6 characters.";
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : Column(
                children: [
                  ElevatedButton(onPressed: _signIn, child: const Text("Login")),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => RegisterScreen()), // ✅ Removed const
                      );
                    },
                    child: const Text("Create Account"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

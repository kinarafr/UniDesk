import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main_layout.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final inputEmail = _emailController.text.trim();
    final inputPassword = _passwordController.text.trim();

    String actualEmail = inputEmail;
    String actualPassword = inputPassword;

    if (inputEmail == 'user' && inputPassword == 'user') {
      actualEmail = 'user@unidesk.edu';
      actualPassword = 'user123';
    }

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: actualEmail,
        password: actualPassword,
      );
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainLayout()),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (inputEmail == 'user' &&
          (e.code == 'user-not-found' ||
              e.code == 'invalid-credential' ||
              e.code == 'wrong-password')) {
        try {
          final cred = await FirebaseAuth.instance
              .createUserWithEmailAndPassword(
                email: actualEmail,
                password: actualPassword,
              );
          await FirebaseFirestore.instance
              .collection('users')
              .doc(cred.user!.uid)
              .set({
                'name': 'Demo Student',
                'email': actualEmail,
                'role': 'student',
                'createdAt': FieldValue.serverTimestamp(),
              });
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const MainLayout()),
            );
          }
        } catch (creationError) {
          setState(() {
            _errorMessage = creationError.toString();
          });
        }
        return; // Skip normal final block if we intercepted
      }

      setState(() {
        _errorMessage = e.message ?? 'An error occurred during login.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Brightness brightness = Theme.of(context).brightness;
    final bool isDarkMode = brightness == Brightness.dark;

    final String logoPath = isDarkMode
        ? 'assets/logos/NIBM_White.png'
        : 'assets/logos/NIBM_Black.png';

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Image.asset(
                  logoPath,
                  height: 120,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.school, size: 100),
                ),
                const SizedBox(height: 48),
                const Text(
                  'Welcome to UniDesk',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Login to access services',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email Address or Username',
                    prefixIcon: Icon(Icons.email),
                  ),
                  // keyboardType: TextInputType.emailAddress, // Removing to allow simple username input
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Login', style: TextStyle(fontSize: 18)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

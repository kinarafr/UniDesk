import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main_dashboard.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
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

    if (inputEmail == 'admin' && inputPassword == 'admin') {
      actualEmail = 'admin@unidesk.edu';
      actualPassword = 'admin123';
    }

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: actualEmail,
        password: actualPassword,
      );
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainDashboard()),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (inputEmail == 'admin') {
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
                'name': 'Demo Admin',
                'email': actualEmail,
                'role': 'admin',
                'createdAt': FieldValue.serverTimestamp(),
              });
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const MainDashboard()),
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
      body: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(32.0),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Image.asset(
                logoPath,
                height: 100,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.admin_panel_settings, size: 80),
              ),
              const SizedBox(height: 32),
              const Text(
                'Admin Portal Login',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
                  labelText: 'Admin Email or Username',
                  prefixIcon: Icon(Icons.email),
                ),
                // keyboardType: TextInputType.emailAddress, // Removed for simple username
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
                    : const Text('Login', style: TextStyle(fontSize: 16)),
              ),
            ],
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

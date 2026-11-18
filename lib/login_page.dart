import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_firebase/auth_service.dart';
import 'package:flutter_application_firebase/register_page.dart';
import 'package:flutter_application_firebase/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passwordCtrl = TextEditingController();
  bool loading = false;
  bool _sendingPasswordReset = false;

  @override
  void dispose() {
    emailCtrl.dispose();
    passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendPasswordResetEmail(AuthService auth) async {
    if (_sendingPasswordReset) return;
    final email = emailCtrl.text.trim();
    if (email.isEmpty) {
      _showResetMessage('Enter your email address, then tap Forgot password?');
      return;
    }

    setState(() => _sendingPasswordReset = true);
    try {
      await auth.sendPasswordResetEmail(email);
      _showResetMessage(
        'If an account exists for this email, you’ll receive a reset link.',
      );
    } on FirebaseAuthException catch (error) {
      _showResetMessage(switch (error.code) {
        'invalid-email' => 'Enter a valid email address.',
        'network-request-failed' =>
          'Check your internet connection and try again.',
        'too-many-requests' => 'Too many attempts. Please try again later.',
        _ => 'Could not request a reset link. Please try again.',
      });
    } finally {
      if (mounted) setState(() => _sendingPasswordReset = false);
    }
  }

  void _showResetMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AuthService auth = AuthService();

    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailCtrl,
                decoration: InputDecoration(
                  label: Text('Email'),
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12,),
              TextField(
                controller: passwordCtrl,
                decoration: InputDecoration(
                  label: Text('Password'),
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12,),
              ElevatedButton(
                child: loading ? CircularProgressIndicator(color: Colors.white,) : Text('Login with email'),
                onPressed: () async {
                  setState(() => loading = true);
                  final user = await auth.signInWithEmail(emailCtrl.text, passwordCtrl.text);
                  if (!mounted) return;
                  setState(() => loading = false);

                  if (user != null) {
                    if (!user.emailVerified) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Please verify your email before logging in.')
                          )
                      );
                    } else {
                      Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => HomePage())
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Invalid email or password'))
                    );
                  }
                },
              ),
              TextButton(
                onPressed: loading || _sendingPasswordReset
                    ? null
                    : () => _sendPasswordResetEmail(auth),
                child: const Text('Forgot password?'),
              ),
              SizedBox(height: 24,),
              Row(
                children: [
                  Expanded(child: Divider(),),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('OR'),
                  ),
                  Expanded(child: Divider(),),
                ],
              ),
              SizedBox(height: 24,),
              ElevatedButton.icon(
                icon: Icon(Icons.login),
                label: Text('Sign in with Google'),
                onPressed: () async {
                  setState(() => loading = true);
                  final user = await auth.signInWithGoogle();
                  if (!mounted) return;
                  setState(() => loading = false);
                  if (user != null) {
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => HomePage())
                    );
                  }
                },
              ),
              SizedBox(height: 12,),
              TextButton(
                child: Text('Dont have an account? Register'),
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => RegisterPage())
                  );
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}

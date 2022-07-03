import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe_payment/pages/home_page.dart';
import 'package:flutter_stripe_payment/services/auth_service.dart';
import 'package:flutter_stripe_payment/services/customer_service.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({Key? key}) : super(key: key);

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool _isSignIn = false;
  bool _loading = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Authentication')),
      body: Column(
        children: [
          TextField(
            decoration: const InputDecoration(label: Text('Email')),
            controller: _emailController,
          ),
          TextField(
            decoration: const InputDecoration(label: Text('Password')),
            obscureText: true,
            controller: _passwordController,
          ),
          ElevatedButton(
            onPressed: _onAuthButtonPressed,
            child: _loading
                ? const CircularProgressIndicator()
                : Text(_isSignIn ? 'Sign In' : 'Sign Up'),
          ),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
                style: const TextStyle(color: Colors.grey),
                text: _isSignIn
                    ? "Don't have an account?"
                    : 'Already registered?',
                children: [
                  TextSpan(
                      text: _isSignIn ? "Sign Up" : "Sign In",
                      style: const TextStyle(color: Colors.green),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          setState(() {
                            _isSignIn = !_isSignIn;
                          });
                        }),
                ]),
          ),
        ],
      ),
    );
  }

  _onAuthButtonPressed() async {
    try {
      setState(() {
        _loading = true;
      });
      final _authService = AuthService(customerService: CustomerService());
      if (_isSignIn) {
        await _authService.signIn(
            email: _emailController.text, password: _passwordController.text);
      } else {
        await _authService.signUp(
            email: _emailController.text, password: _passwordController.text);
      }
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (context) => const HomePage()));
    } catch (error) {
      print(error);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Failed to login"),
        duration: Duration(milliseconds: 300),
      ));
    }
    setState(() {
      _loading = false;
    });
  }
}

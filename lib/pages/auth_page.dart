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
  bool isSignIn = true;
  bool loading = false;

  final TextEditingController _emailController =
      TextEditingController(text: '');
  final TextEditingController _passwordController =
      TextEditingController(text: '');
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RichText(
              text: TextSpan(
                  style:
                      const TextStyle(color: Color(0XFF2c4352), fontSize: 35),
                  text: 'Fruit ',
                  children: [
                    TextSpan(
                      text: 'Market',
                      style: TextStyle(color: Theme.of(context).primaryColor),
                    ),
                  ]),
            ),
            const SizedBox(height: 50),
            TextField(
              decoration: const InputDecoration(label: Text('Email')),
              controller: _emailController,
            ),
            TextField(
              decoration: const InputDecoration(label: Text('Password')),
              obscureText: true,
              controller: _passwordController,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12) // <-- Radius
                    ),
                minimumSize: const Size.fromHeight(
                    50), // fromHeight use double.infinity as width and 40 is the height
              ),
              onPressed: _onAuthButtonPressed,
              child: loading
                  ? const CircularProgressIndicator()
                  : Text(isSignIn ? 'Sign In' : 'Sign Up'),
            ),
            const SizedBox(height: 20),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                  style: const TextStyle(color: Colors.grey),
                  text: isSignIn
                      ? "Don't have an account? "
                      : 'Already registered? ',
                  children: [
                    TextSpan(
                        text: isSignIn ? "Sign Up" : "Sign In",
                        style: TextStyle(color: Theme.of(context).primaryColor),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            setState(() {
                              isSignIn = !isSignIn;
                            });
                          }),
                  ]),
            ),
          ],
        ),
      ),
    );
  }

  _onAuthButtonPressed() async {
    try {
      setState(() {
        loading = true;
      });
      final _authService = AuthService(customerService: CustomerService());
      if (isSignIn) {
        await _authService.signIn(
            email: _emailController.text, password: _passwordController.text);
      } else {
        await _authService.signUp(
            email: _emailController.text, password: _passwordController.text);
      }
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (context) => const HomePage()));
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Failed to login"),
        duration: Duration(milliseconds: 300),
      ));
    }
    setState(() {
      loading = false;
    });
  }
}

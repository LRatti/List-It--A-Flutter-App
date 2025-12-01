import 'package:app_code/screens/auth/sign_in.dart';
import 'package:app_code/screens/auth/sign_up.dart';
import 'package:flutter/material.dart';


class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool isSignUpForm = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Auth'),
        backgroundColor: Colors.blue[500],
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text('Welcome.'),
        
              // sign up screen
              if (isSignUpForm)
                Column(
                  children: [
                    const SignUpForm(),
                    const Text('Already have an account?'),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          isSignUpForm = false;
                        });
                      },
                      child: Text('Sign in instead'),
                    )
                  ]
                ),

              // sign in screen
              if (!isSignUpForm)
                Column(
                  children: [
                    const SignInForm(),
                    const Text('Need an account?'),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          isSignUpForm = true;
                        });
                      },
                      child: Text('Sign up instead'),
                    )
                  ]
                ),
            ]
          )
        ),
      ),
    );
  }
}
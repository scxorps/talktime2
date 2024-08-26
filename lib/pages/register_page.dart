import 'package:flutter/material.dart';
import 'package:talktime2/services/auth/auth_service.dart';
import 'package:talktime2/components/my_button.dart';
import 'package:talktime2/components/my_textfield.dart';

class RegisterPage extends StatefulWidget {
  final void Function()? onTap;

  RegisterPage({
    super.key,
    required this.onTap,
  });

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _pwController = TextEditingController();
  final TextEditingController _pwConfirmController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  bool _obscurePassword = true;

  void Register(BuildContext context) {
    final _auth = AuthService();

    if (_pwController.text == _pwConfirmController.text) {
      try {
        _auth.signUpWithEmailPassword(
          _emailController.text,
          _pwController.text,
          _usernameController.text,  // Pass username
        ).then((userCredential) {
          // Handle post-registration actions, if needed
        });
      } catch (e) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(e.toString()),
          ),
        );
      }
    } else {
      showDialog(
        context: context,
        builder: (context) => const AlertDialog(
          title: Text('Passwords don\'t match!'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SingleChildScrollView(
        
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical:60.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 130,
                child: Image.asset('assets/images/logo.png'),
              ),
              Text(
                'TalkTime',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 6, 42, 90),
                ),
              ),
              SizedBox(height: 50),
              Text(
                "Let's create an account for you",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 15),
              MyTextfield(
                hintText: "Email",
                obscureText: false,
                controller: _emailController,
              ),
              SizedBox(height: 10),
              MyTextfield(
                hintText: "Username",
                obscureText: false,
                controller: _usernameController,  // Added Username Textfield
              ),
              SizedBox(height: 10),
              Stack(
                children: [
                  MyTextfield(
                    hintText: "Password",
                    obscureText: _obscurePassword,
                    controller: _pwController,
                  ),
                  Positioned(
                    right: 20,
                    bottom: 3,
                    child: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.remove_red_eye_outlined : Icons.remove_red_eye_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Stack(
                children: [
                  MyTextfield(
                    hintText: "Confirm Password",
                    obscureText: _obscurePassword,
                    controller: _pwConfirmController,
                  ),
                  Positioned(
                    right: 20,
                    bottom: 3,
                    child: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.remove_red_eye_outlined : Icons.remove_red_eye_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 25),
              MyButton(
                text: "Register",
                onTap: () => Register(context),
                color: Colors.orange,
              ),
              SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "You have an account? ",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  GestureDetector(
                    onTap: widget.onTap,
                    child: Text(
                      "Login!",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 50),  // Add bottom padding to ensure content is not cut off
            ],
          ),
        ),
      ),
    );
  }
}

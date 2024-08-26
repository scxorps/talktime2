import 'package:flutter/material.dart';
import 'package:talktime2/services/auth/auth_service.dart';
import 'package:talktime2/components/my_button.dart';
import 'package:talktime2/components/my_textfield.dart';

class LoginPage extends StatefulWidget {
  final void Function()? onTap;

  LoginPage({
    super.key,
    required this.onTap,
  });

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _identifierController = TextEditingController();  // Email or Username
  final TextEditingController _pwController = TextEditingController();

  bool _obscurePassword = true;

  Future<void> login(BuildContext context) async {
    final authService = AuthService();

    try {
      await authService.signInWithEmailOrUsername(
        _identifierController.text,
        _pwController.text,
      );
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(e.toString()),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Column(
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
            "Welcome back, we've missed you!",
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 15),
          MyTextfield(
            hintText: "Email or Username",
            obscureText: false,
            controller: _identifierController,
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
          SizedBox(height: 25),
          MyButton(
            text: "Login",
            onTap: () => login(context),
            color: Colors.blue,
          ),
          SizedBox(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Not a member? ",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              GestureDetector(
                onTap: widget.onTap,
                child: Text(
                  "Register now",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ignore_for_file: prefer_const_constructors, unused_import

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:talktime2/services/auth/auth_gate.dart';
import 'package:talktime2/services/auth/login_or_register.dart';
import 'package:talktime2/firebase_options.dart';
import 'package:talktime2/pages/register_page.dart';
import 'package:talktime2/themes/lightmode.dart';
import 'package:talktime2/themes/theme_provider.dart';
import 'pages/login_page.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyApp(),
      )
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return  MaterialApp(
      debugShowCheckedModeBanner: false,
      home:const AuthGate(),
      theme: Provider.of<ThemeProvider>(context).themeData,
    );
  }
}
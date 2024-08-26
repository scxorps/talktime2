// ignore_for_file: prefer_const_constructors
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:talktime2/components/My_AppBar.dart';
import 'package:talktime2/pages/Blocked_users_page.dart';
import 'package:talktime2/themes/theme_provider.dart';


class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: const MyAppBar(
        title: 'Settings',
        actions: [],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
            //dark mode
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.only(left: 25, top: 10, right: 25),
                padding: const EdgeInsets.only(left: 25, top: 20, right: 25, bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // dark mode
                  Text(
                    "Dark Mode",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.inversePrimary),
                    ),

                    // switch toggle
                    CupertinoSwitch(
                      onChanged: (value) =>
                          Provider.of<ThemeProvider>(context, listen: false)
                            .toggleTheme(),
                      value: Provider.of<ThemeProvider>(context, listen: false)
                          .isDarkMode,
                    ),
                  ],
                ),
              ),
              //blocked users
              Container(
                  decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.only(left: 25, top: 10, right: 25),
                padding: const EdgeInsets.only(left: 25, top: 20, right: 25, bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // dark mode
                  Text(
                    "Blocked Users ",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.inversePrimary),
                    ),

                    // switch toggle
                    IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context)=> BlockedUsersPage(),
                    )),
                    icon: Icon(Icons.arrow_forward_rounded,
                    color: Theme.of(context).colorScheme.primary,),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// ignore_for_file: prefer_const_constructors, sized_box_for_whitespace, no_leading_underscores_for_local_identifiers

import 'package:flutter/material.dart';
import 'package:talktime2/pages/Profile_Page.dart';
import 'package:talktime2/services/auth/auth_service.dart';
import 'package:talktime2/pages/settings_page.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key});

  void logout() {
    // Get auth service
    final _auth = AuthService();
    _auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              // Logo and Text
              DrawerHeader(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // logo
                    Container(
                      height: 90,
                      child: Image.asset('assets/images/logo.png'),
                    ),
                    SizedBox(height: 8), // Space between icon and text
                    Text(
                      "TalkTime",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 6, 42, 90),
                      ),
                    ),
                  ],
                ),
              ),
              // Home list tile
              Padding(
                padding: const EdgeInsets.only(left: 10),
                child: ListTile(
                  title: Text("H O M E"),
                  leading: Icon(Icons.home),
                  onTap: () {
                    // POP THE DRAWER
                    Navigator.pop(context);
                  },
                ),
              ),
              // Profile section with padding
              Padding(
                padding: const EdgeInsets.only(left: 10, top: 10, bottom: 10),
                child: ListTile(
                  title: Text("P R O F I L E "),
                  leading: Icon(Icons.person),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ProfilePage()),
                    );
                  },
                ),
              ),
              // Settings list tile
              Padding(
                padding: const EdgeInsets.only(left: 10),
                child: ListTile(
                  title: Text("S E T T I N G S"),
                  leading: Icon(Icons.settings),
                  onTap: () {
                    // POP THE DRAWER
                    Navigator.pop(context);
                    // NAVIGATE TO SETTINGS PAGE
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SettingsPage()),
                    );
                  },
                ),
              ),
            ],
          ),
          // Logout list tile
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child: ListTile(
              title: Text("L O G O U T"),
              leading: Icon(Icons.logout),
              onTap: logout,
            ),
          ),
        ],
      ),
    );
  }
}

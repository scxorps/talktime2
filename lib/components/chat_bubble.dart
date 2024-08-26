// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, unused_element

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:talktime2/themes/theme_provider.dart';

import '../services/chat/chat_service.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isCurrentUser;
  final String messageId;
  final String userId;


  const ChatBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    required this.messageId,
    required this.userId,
    });

    // show options
    void _showoptions(BuildContext context, String messageId, String userId){
      showModalBottomSheet(context: context,builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              // report button
              ListTile(
                leading: Icon(Icons.flag),
                title: Text('Report'),
                onTap: () {
                  Navigator.pop(context);
                  _reportMessage(context, messageId, userId);
                },
              ),

              // block user button
              ListTile(
                leading: Icon(Icons.block),
                title: Text('Block'),
                onTap: () {
                  Navigator.pop(context);
                  _blockUser(context, userId);
                },
              ),
              // cancel button
              ListTile(
                leading: Icon(Icons.cancel),
                title: Text('Cancel'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

    //report message
    void _reportMessage(BuildContext context, String messageId, String userId) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Report Message"),
          content: const Text("Are you sure you want to report this message?"),
          actions: [
            //cancel button
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),

            //report button
            TextButton(
              onPressed: () {
                ChatService().reportUser(messageId, userId);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Message Reported")));
              },
              child: const Text("Report"),
            ),
          ],
        ),
      );
    }

    //block user
    void _blockUser(BuildContext context, String userId) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Block User"),
          content: const Text("Are you sure you want to block this user?"),
          actions: [
            //cancel button
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),

            //block button
            TextButton(
              onPressed: () {
                // perform block
                ChatService().blockUser(userId);
                // dismiss dialog
                Navigator.pop(context);
                //dismiss page
                Navigator.pop(context);
                //let user know of result
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User Blocked!")));
              },
              child: const Text("Block"),
            ),
          ],
        ),
      );
    }

  @override
  Widget build(BuildContext context) {
  // light vs dark mode
  bool isDarkMode = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;

  return GestureDetector(
    onLongPress: () {
      if (!isCurrentUser) {
        // Show options
        _showoptions(context, messageId, userId);
      }
    },
    child: Container(
      decoration: BoxDecoration(
        color: isCurrentUser
            ? Colors.green
            : (isDarkMode ? Colors.grey.shade800 : Colors.grey.shade600),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
          bottomRight: isCurrentUser ? Radius.circular(20) : Radius.circular(20),  // Full curve for current user
          bottomLeft: isCurrentUser ? Radius.circular(20) : Radius.zero,  // Small curve for other users
        ),
      ),
      padding: EdgeInsets.all(12),
      margin: EdgeInsets.symmetric(vertical: 5, horizontal: 25),
      child: Text(
        message,
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
      ),
    ),
  );
}


}
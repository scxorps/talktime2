import 'package:flutter/material.dart';
import 'package:talktime2/components/My_AppBar.dart'; // Import the custom MyAppBar
import 'package:talktime2/components/user_tile.dart';
import 'package:talktime2/services/auth/auth_service.dart';
import 'package:talktime2/services/chat/chat_service.dart';

class BlockedUsersPage extends StatelessWidget {
  BlockedUsersPage({super.key});

  final ChatService chatService = ChatService();
  final AuthService authService = AuthService();

  void _showUnblockBox(BuildContext context, String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Unblock User"),
        content: const Text("Are you sure you want to unblock this user?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              chatService.unblockUser(userId);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("User unblocked")),
              );
            },
            child: const Text("Unblock"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String userId = authService.getCurrentUser()!.uid;

    return Scaffold(
      appBar: const MyAppBar(
        title: "BLOCKED USERS",
        actions: [], // Customize actions here if needed
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: chatService.getBlockedUsersStream(userId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text("Error loading.."),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final blockedUsers = snapshot.data ?? [];

          if (blockedUsers.isEmpty) {
            return const Center(
              child: Text("No blocked users"),
            );
          }

          print(blockedUsers);

          return ListView.builder(
            itemCount: blockedUsers.length,
            itemBuilder: (context, index) {
              final user = blockedUsers[index];
              return UserTile(
                text: user["email"] ?? "Unknown",
                onTap: () => _showUnblockBox(context, user['uid'] ?? ''),
              );
            },
          );
        },
      ),
    );
  }
}

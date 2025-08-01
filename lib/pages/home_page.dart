import 'package:flutter/material.dart';
import 'package:talktime2/components/My_AppBar.dart';
import 'package:talktime2/components/my_drawer.dart';
import 'package:talktime2/components/user_tile.dart';
import 'package:talktime2/pages/chat_page.dart';
import 'package:talktime2/services/auth/auth_service.dart';
import 'package:talktime2/services/chat/chat_service.dart';
import 'package:talktime2/models/user.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();

  Future<void> logout() async {
    try {
      await _authService.signOut();
    } catch (e) {
      // Handle logout error
      print("Logout error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MyAppBar(
        title: "All Users",
        actions: [],  // Add logout button or other actions here if needed
      ),
      drawer: MyDrawer(),
      body: _buildUserList(),
    );
  }

  Widget _buildUserList() {
  return StreamBuilder<List<AppUser>>(
    stream: _chatService.getUsersSortedByLatestMessage(),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Center(child: Text("Something went wrong: ${snapshot.error}"));
      }

      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      final users = snapshot.data ?? [];
      print("Users received from stream: ${users.length} users");

      if (users.isEmpty) {
        return const Center(child: Text("No users available"));
      }

      return ListView(
        children: users
            .where((user) => user.username != _authService.getCurrentUser()?.displayName)
            .map((user) {
              print("Processing user: ${user.username}");

              return StreamBuilder<Map<String, dynamic>>(
                stream: _chatService.getLatestMessageForUser(user.uid),
                builder: (context, messageSnapshot) {
                  if (messageSnapshot.hasError) {
                    print("Error fetching latest message for ${user.username}: ${messageSnapshot.error}");
                    return ListTile(
                      title: Text(user.username),
                      subtitle: Text('Error: ${messageSnapshot.error}'),
                    );
                  }

                  if (!messageSnapshot.hasData) {
                    print("Loading message for ${user.username}");
                    return ListTile(
                      title: Text(user.username),
                      subtitle: Text('Loading...'),
                    );
                  }

                  final latestMessage = messageSnapshot.data?['message'] ?? 'Start a conversation';
                  print("Latest message for ${user.username}: $latestMessage");

                  return UserTile(
                    text: user.username,
                    latestMessage: latestMessage,
                    profilePictureUrl: user.profileImageUrl, // Use the getter from AppUser
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatPage(
                            receiverEmail: user.email,
                            receiverID: user.uid,
                            receiverUsername: user.username,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            })
            .toList(),
      );
    },
  );
}

}

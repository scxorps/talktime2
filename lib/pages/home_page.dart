import 'package:flutter/material.dart';
import 'package:talktime2/components/My_AppBar.dart';
import 'package:talktime2/components/my_drawer.dart';
import 'package:talktime2/components/user_tile.dart';
import 'package:talktime2/pages/chat_page.dart';
import 'package:talktime2/services/auth/auth_service.dart';
import 'package:talktime2/services/chat/chat_service.dart';

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
        title: "Messages",
        actions: [],  // Add logout button or other actions here if needed
      ),
      drawer: MyDrawer(),
      body: _buildUserList(),
    );
  }

  Widget _buildUserList() {
  return StreamBuilder<List<Map<String, dynamic>>>(
    stream: _chatService.getUsersSortedByLatestMessage(),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Center(child: Text("Something went wrong: ${snapshot.error}"));
      }

      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      final users = snapshot.data ?? [];
      print("Users received from stream: $users");

      // Sort users by latest message timestamp
      users.sort((a, b) {
        final timestampA = a['latestMessageTimestamp']?.seconds ?? 0;
        final timestampB = b['latestMessageTimestamp']?.seconds ?? 0;
        return timestampB.compareTo(timestampA); // Sort descending
      });

      print("Sorted Users:");
      for (var user in users) {
        print("Username: ${user['username']}, Profile Picture: ${user['profilePicture']}, Last Interaction: ${user['latestMessageTimestamp']}");
      }

      if (users.isEmpty) {
        return const Center(child: Text("No users available"));
      }

      return ListView(
        children: users
            .where((userData) => userData["username"] != _authService.getCurrentUser()?.displayName)
            .map((userData) {
              final userId = userData["uid"];
              print("Processing user: ${userData["username"]}");

              return StreamBuilder<Map<String, dynamic>>(
                stream: _chatService.getLatestMessageForUser(userId),
                builder: (context, messageSnapshot) {
                  if (messageSnapshot.hasError) {
                    print("Error fetching latest message for ${userData["username"]}: ${messageSnapshot.error}");
                    return ListTile(
                      title: Text(userData["username"]),
                      subtitle: Text('Error: ${messageSnapshot.error}'),
                    );
                  }

                  if (!messageSnapshot.hasData) {
                    print("Loading message for ${userData["username"]}");
                    return ListTile(
                      title: Text(userData["username"]),
                      subtitle: Text('Loading...'),
                    );
                  }

                  final latestMessage = messageSnapshot.data?['message'] ?? 'Start a conversation';
                  print("Latest message for ${userData["username"]}: $latestMessage");

                  return UserTile(
                    text: userData["username"],
                    latestMessage: latestMessage,
                    profilePictureUrl: userData["profilePicture"], // Pass profile picture URL
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatPage(
                            receiverEmail: userData["email"],
                            receiverID: userData["uid"],
                            receiverUsername: userData["username"],
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

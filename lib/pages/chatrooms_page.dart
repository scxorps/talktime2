import 'package:flutter/material.dart';
import 'package:talktime2/services/chat/chat_service.dart';
import 'package:talktime2/services/auth/auth_service.dart';
import 'package:talktime2/models/chat_room.dart';
import 'package:talktime2/models/user.dart';
import 'package:talktime2/pages/chat_page.dart';
import 'package:talktime2/components/user_tile.dart';

class ChatRoomsPage extends StatelessWidget {
  ChatRoomsPage({Key? key}) : super(key: key);

  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final currentUser = _authService.getCurrentUser();
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Utilisateur non connecté.')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes conversations'),
      ),
      body: StreamBuilder<List<ChatRoom>>(
        stream: _chatService.getUserChatRooms(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Erreur: \\${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final chatRooms = snapshot.data ?? [];
          if (chatRooms.isEmpty) {
            return const Center(child: Text('Aucune conversation.'));
          }
          return ListView(
            children: chatRooms.map((chatRoom) {
              final otherUserId = chatRoom.participants.firstWhere(
                (id) => id != currentUser.uid,
                orElse: () => '',
              );
              if (otherUserId.isEmpty) {
                return const ListTile(title: Text('Utilisateur inconnu'));
              }
              return FutureBuilder(
                future: _authService.getUserByUID(otherUserId),
                builder: (context, userSnapshot) {
                  if (userSnapshot.hasError) {
                    return ListTile(
                      title: Text('Erreur utilisateur'),
                      subtitle: Text('Erreur: \\${userSnapshot.error}'),
                    );
                  }
                  if (!userSnapshot.hasData || userSnapshot.data == null) {
                    return const ListTile(
                      title: Text('Chargement...'),
                    );
                  }
                  final user = userSnapshot.data as AppUser;
                  return UserTile(
                    text: user.username,
                    latestMessage: chatRoom.lastMessage ?? 'Start a conversation',
                    profilePictureUrl: user.profileImageUrl,
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
            }).toList(),
          );
        },
      ),
    );
  }
}

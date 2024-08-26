// ignore_for_file: prefer_const_constructors

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:talktime2/components/chat_bubble.dart';
import 'package:talktime2/components/my_textfield.dart';
import 'package:talktime2/services/auth/auth_service.dart';
import 'package:talktime2/services/chat/chat_service.dart';

class ChatPage extends StatefulWidget {
  final String receiverEmail;
  final String receiverID;
  final String receiverUsername;

  ChatPage({
    super.key,
    required this.receiverEmail,
    required this.receiverID,
    required this.receiverUsername,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  FocusNode myFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    myFocusNode.addListener(() {
      if (myFocusNode.hasFocus) {
        Future.delayed(
          const Duration(milliseconds: 400),
          () => scrollDown(),
        );
      }
    });

    

    Future.delayed(
      const Duration(milliseconds: 300),
      () => scrollDown(),
    );
  }

  @override
  void dispose() {
    myFocusNode.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void scrollDown() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.bounceIn,
    );
  }

  void sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      await _chatService.sendMessage(widget.receiverID, _messageController.text);
      _messageController.clear();
    }
    scrollDown();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(widget.receiverUsername),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.grey,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildMessageList(),
          ),
          _buildUserInput(),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    String senderID = _authService.getCurrentUser()!.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: _chatService.getMessages(widget.receiverID, senderID),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Something went wrong. Please try again."));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text("this is your very start of this conversation."));
        }

        return ListView(
          controller: _scrollController,
          children: snapshot.data!.docs.map((doc) {
            if (doc.exists) {
              return _buildMessageItem(doc);
            } else {
              return SizedBox.shrink();
            }
          }).toList(),
        );
      },
    );
  }

  Widget _buildMessageItem(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    bool isCurrentUser = data['senderID'] == _authService.getCurrentUser()!.uid;

    var alignment = isCurrentUser ? Alignment.centerRight : Alignment.centerLeft;

    return Container(
      alignment: alignment,
      child: Column(
        crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          ChatBubble(
            message: data["message"],
            isCurrentUser: isCurrentUser,
            messageId: doc.id,
            userId: data["senderID"],
          )
        ],
      ),
    );
  }

  Widget _buildUserInput() {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 7),
    child: Row(
      children: [
        Expanded(
          child: MyTextfield(
            controller: _messageController,
            hintText: "Type a message...",
            obscureText: false,
            focusNode: myFocusNode,
          ),
        ),
        SizedBox(width: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(2, 2),
              ),
            ],
          ),
          child: IconButton(
            onPressed: sendMessage,
            icon: Icon(
              Icons.send,
              color: Colors.white,
            ),
          ),
        ),
      ],
    ),
  );
}

}

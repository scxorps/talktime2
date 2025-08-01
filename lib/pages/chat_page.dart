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

// Formatteur pour le séparateur de date
String _formatDateSeparator(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final messageDay = DateTime(date.year, date.month, date.day);
  final diff = today.difference(messageDay).inDays;
  if (diff == 0) {
    // Aujourd'hui
    return "Aujourd'hui";
  } else if (diff == 1) {
    return "Hier";
  } else if (diff < 7) {
    // Affiche le nom du jour (ex: Lundi)
    const jours = ["Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi", "Dimanche"];
    // DateTime.weekday: 1 = lundi, 7 = dimanche
    return jours[date.weekday - 1];
  } else {
    // Plus ancien : format "23 juil. à 21:10"
    final mois = ["janv.", "févr.", "mars", "avr.", "mai", "juin", "juil.", "août", "sept.", "oct.", "nov.", "déc."];
    String heure = date.hour.toString().padLeft(2, '0') + ":" + date.minute.toString().padLeft(2, '0');
    return "${date.day} ${mois[date.month - 1]} à $heure";
  }
}

// Widget MessageWithTime : Affiche un message avec l'heure au-dessus, visible au clic (un seul affiché à la fois)
// Version centralisée : un seul timestamp affiché à la fois, animation fluide
class MessageWithTime extends StatefulWidget {
  final Alignment alignment;
  final bool isCurrentUser;
  final String message;
  final String messageId;
  final String userId;
  final String timeString;
  final ValueNotifier<String?> selectedIdNotifier;

  const MessageWithTime({
    Key? key,
    required this.alignment,
    required this.isCurrentUser,
    required this.message,
    required this.messageId,
    required this.userId,
    required this.timeString,
    required this.selectedIdNotifier,
  }) : super(key: key);

  @override
  State<MessageWithTime> createState() => _MessageWithTimeState();
}

class _MessageWithTimeState extends State<MessageWithTime> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late VoidCallback _notifierListener;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _notifierListener = () {
      setState(() {
        final show = widget.selectedIdNotifier.value == widget.messageId;
        if (show) {
          _controller.forward();
        } else {
          _controller.reverse();
        }
      });
    };
    widget.selectedIdNotifier.addListener(_notifierListener);
    // Init state
    if (widget.selectedIdNotifier.value == widget.messageId) {
      _controller.value = 1.0;
    } else {
      _controller.value = 0.0;
    }
  }

  @override
  void didUpdateWidget(covariant MessageWithTime oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIdNotifier != widget.selectedIdNotifier) {
      oldWidget.selectedIdNotifier.removeListener(_notifierListener);
      widget.selectedIdNotifier.addListener(_notifierListener);
    }
  }

  @override
  void dispose() {
    widget.selectedIdNotifier.removeListener(_notifierListener);
    _controller.dispose();
    super.dispose();
  }

  void _onTap() {
    if (widget.selectedIdNotifier.value == widget.messageId) {
      widget.selectedIdNotifier.value = null;
    } else {
      widget.selectedIdNotifier.value = widget.messageId;
    }
  }

  @override
  Widget build(BuildContext context) {
    final showTime = widget.selectedIdNotifier.value == widget.messageId;
    return GestureDetector(
      onTap: _onTap,
      child: Column(
        crossAxisAlignment: widget.isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          FadeTransition(
            opacity: _fadeAnim,
            child: (showTime && widget.timeString.isNotEmpty)
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 2.0),
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        widget.timeString,
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                    ),
                  )
                : SizedBox.shrink(),
          ),
          Align(
            alignment: widget.alignment,
            child: ChatBubble(
              message: widget.message,
              isCurrentUser: widget.isCurrentUser,
              messageId: widget.messageId,
              userId: widget.userId,
            ),
          ),
        ],
      ),
    );
  }
}



class _ChatPageState extends State<ChatPage> {
  bool _wasTyping = false;
  late Stream<bool> _otherTypingStream;
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  FocusNode myFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<String?> _selectedMessageId = ValueNotifier<String?>(null);
  Future<dynamic>? _receiverProfileFuture;

  @override
  void initState() {
    super.initState();

    // Cache le Future du profil utilisateur pour éviter le loader à chaque rebuild
    _receiverProfileFuture = _authService.getUserByUID(widget.receiverID);

    myFocusNode.addListener(() {
      if (myFocusNode.hasFocus) {
        Future.delayed(
          const Duration(milliseconds: 400),
          () => scrollDown(),
        );
      }
    });

    // Stream pour l'état de saisie de l'autre utilisateur
    _otherTypingStream = _chatService.getTyping(widget.receiverID);

    Future.delayed(
      const Duration(milliseconds: 300),
      () => scrollDown(),
    );

    // Marquer les messages reçus comme lus à l'ouverture de la conversation
    final currentUserId = _authService.getCurrentUser()!.uid;
    final chatRoomID = [widget.receiverID, currentUserId]..sort();
    final chatRoomIDString = chatRoomID.join('_');
    _chatService.markMessagesAsRead(chatRoomIDString, currentUserId);
  }

  @override
  void dispose() {
    myFocusNode.dispose();
    _messageController.dispose();
    _selectedMessageId.dispose();
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
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.grey,
        elevation: 0,
        titleSpacing: 0,
        title: FutureBuilder(
          future: _authService.getUserByUID(widget.receiverID),
          builder: (context, snapshot) {
            Widget titleRow;
            if (snapshot.connectionState == ConnectionState.waiting) {
              titleRow = Row(
                children: [
                  CircleAvatar(radius: 18, backgroundColor: Colors.grey[300]),
                  SizedBox(width: 10),
                  Container(width: 80, height: 16, color: Colors.grey[300]),
                ],
              );
            } else if (!snapshot.hasData || snapshot.data == null) {
              titleRow = Row(
                children: [
                  CircleAvatar(radius: 18, backgroundColor: Colors.grey[300]),
                  SizedBox(width: 10),
                  Text(widget.receiverUsername, style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              );
            } else {
              final user = snapshot.data!;
              titleRow = Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundImage: (user.profilePicture.isNotEmpty && user.profilePicture.startsWith('http'))
                        ? NetworkImage(user.profilePicture)
                        : AssetImage('assets/images/defaultpic.png') as ImageProvider,
                    backgroundColor: Colors.grey[300],
                  ),
                  SizedBox(width: 10),
                  Text(user.username, style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              );
            }
            return titleRow;
          },
        ),
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

// Formatteur pour le séparateur de date

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

        // --- Marquer les messages reçus comme lus en temps réel ---
        final currentUserId = senderID;
        final chatRoomID = [widget.receiverID, currentUserId]..sort();
        final chatRoomIDString = chatRoomID.join('_');
        final unreadDocs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['receiverID'] == currentUserId && (data['isRead'] == false || data['isRead'] == null);
        }).toList();
        if (unreadDocs.isNotEmpty) {
          _chatService.markMessagesAsRead(chatRoomIDString, currentUserId);
        }

        // docs = tous les messages, on veut la bulle typing tout en bas
        final docs = snapshot.data!.docs;

        // --------- Ajout du séparateur de date ---------
        List<Widget> messageWidgets = [];
        DateTime? lastDate;
        int lastSentIndex = -1;
        int lastSeenSentIndex = -1;
        String? lastSeenSentMessageId;
        Map<String, int> docIdToIndex = {};
        // Construction des messages et détection du dernier message vu
        for (int i = 0; i < docs.length; i++) {
          final doc = docs[i];
          if (!doc.exists) continue;
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          bool isCurrentUser = data['senderID'] == senderID;
          if (isCurrentUser) {
            debugPrint('Message envoyé: id=${doc.id}, isRead=${data['isRead']}');
            lastSentIndex = i;
            if (data['isRead'] == true) {
              lastSeenSentIndex = i;
              lastSeenSentMessageId = doc.id;
            }
          }
          DateTime? sentTime;
          if (data['timestamp'] is Timestamp) {
            sentTime = (data['timestamp'] as Timestamp).toDate();
          } else if (data['timestamp'] is DateTime) {
            sentTime = data['timestamp'];
          }
          bool showDateSeparator = false;
          if (sentTime != null) {
            if (lastDate == null ||
                sentTime.year != lastDate.year ||
                sentTime.month != lastDate.month ||
                sentTime.day != lastDate.day) {
              showDateSeparator = true;
              lastDate = sentTime;
            }
          }
          if (showDateSeparator && sentTime != null) {
            messageWidgets.add(
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _formatDateSeparator(sentTime),
                      style: TextStyle(fontSize: 13, color: Colors.grey[700], fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ),
            );
          }
          final messageWidget = AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            switchInCurve: Curves.easeIn,
            switchOutCurve: Curves.easeOut,
            transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
            child: KeyedSubtree(
              key: ValueKey(doc.id),
              child: _buildMessageItem(
                doc,
                selectedIdNotifier: _selectedMessageId,
              ),
            ),
          );
          docIdToIndex[doc.id] = messageWidgets.length;
          messageWidgets.add(messageWidget);
        }

        // Nouvelle logique :
        // Si le dernier message est du destinataire, bulle sous ce message
        // Sinon, bulle sous le dernier message envoyé par l'utilisateur et vu
        if (docs.isNotEmpty) {
          final lastDoc = docs.last;
          final lastData = lastDoc.data() as Map<String, dynamic>;
          bool lastIsReceiver = lastData['senderID'] == widget.receiverID;
          String? bubbleMessageId;
          if (lastIsReceiver) {
            bubbleMessageId = lastDoc.id;
          } else {
            bubbleMessageId = lastSeenSentMessageId;
          }
          if (bubbleMessageId != null) {
            int? insertIndex = docIdToIndex[bubbleMessageId];
            if (insertIndex != null) {
              messageWidgets.insert(
                insertIndex + 1,
                FutureBuilder(
                  future: _authService.getUserByUID(widget.receiverID),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return SizedBox(height: 28);
                    }
                    final user = snapshot.data;
                    return Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        margin: const EdgeInsets.only(right: 12, top: 2, bottom: 2),
                        child: CircleAvatar(
                          radius: 13,
                          backgroundImage: (user != null && user.profilePicture.isNotEmpty && user.profilePicture.startsWith('http'))
                              ? NetworkImage(user.profilePicture)
                              : AssetImage('assets/images/defaultpic.png') as ImageProvider,
                          backgroundColor: Colors.grey[300],
                        ),
                      ),
                    );
                  },
                ),
              );
            }
          }
        }

        // Afficher la bulle typing tout en bas si besoin
        messageWidgets.add(
          StreamBuilder<bool>(
            stream: _otherTypingStream,
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data == true) {
                return FutureBuilder(
                  future: _authService.getUserByUID(widget.receiverID),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return SizedBox(height: 30);
                    }
                    final user = snap.data;
                    return Padding(
                      padding: const EdgeInsets.only(left: 16.0, top: 2, bottom: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 13,
                            backgroundImage: (user != null && user.profilePicture.isNotEmpty && user.profilePicture.startsWith('http'))
                                ? NetworkImage(user.profilePicture)
                                : AssetImage('assets/images/defaultpic.png') as ImageProvider,
                            backgroundColor: Colors.grey[300],
                          ),
                          SizedBox(width: 7),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 8,
                                  height: 8,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: Colors.green[500],
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 7),
                                Text(
                                  "typing...",
                                  style: TextStyle(fontSize: 13, color: Colors.grey[700], fontStyle: FontStyle.italic),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              }
              return SizedBox.shrink();
            },
          ),
        );

        // Plus besoin de scroll automatique avec reverse: true

        // Détection du clic en dehors des messages pour masquer le timestamp
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            _selectedMessageId.value = null;
          },
          child: ListView(
            controller: _scrollController,
            reverse: true,
            children: messageWidgets.reversed.toList(),
          ),
        );
      },
    );
  }

// (Suppression du code dupliqué/mal placé après le builder)

  Widget _buildMessageItem(DocumentSnapshot doc, {required ValueNotifier<String?> selectedIdNotifier}) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    bool isCurrentUser = data['senderID'] == _authService.getCurrentUser()!.uid;
    var alignment = isCurrentUser ? Alignment.centerRight : Alignment.centerLeft;
    DateTime? sentTime;
    if (data['timestamp'] is Timestamp) {
      sentTime = (data['timestamp'] as Timestamp).toDate();
    } else if (data['timestamp'] is DateTime) {
      sentTime = data['timestamp'];
    }
    String timeString = sentTime != null
        ? (sentTime.hour.toString().padLeft(2, '0') + ':' + sentTime.minute.toString().padLeft(2, '0'))
        : '';

    return MessageWithTime(
      alignment: alignment,
      isCurrentUser: isCurrentUser,
      message: data["message"],
      messageId: doc.id,
      userId: data["senderID"],
      timeString: timeString,
      selectedIdNotifier: selectedIdNotifier,
    );
  }


  Widget _buildUserInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 7),
      child: Row(
        children: [
          Expanded(
            child: Focus(
              onFocusChange: (hasFocus) {
                if (!hasFocus) {
                  _chatService.setTyping(widget.receiverID, false);
                  _wasTyping = false;
                }
              },
              child: GestureDetector(
                onTap: () {
                  scrollDown();
                },
                child: MyTextfield(
                  controller: _messageController,
                  hintText: "Type a message...",
                  obscureText: false,
                  focusNode: myFocusNode,
                  onChanged: (text) {
                    if (text.isNotEmpty && !_wasTyping) {
                      _chatService.setTyping(widget.receiverID, true);
                      _wasTyping = true;
                    } else if (text.isEmpty && _wasTyping) {
                      _chatService.setTyping(widget.receiverID, false);
                      _wasTyping = false;
                    }
                  },
                ),
              ),
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
              onPressed: () {
                sendMessage();
                _chatService.setTyping(widget.receiverID, false);
                _wasTyping = false;
              },
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

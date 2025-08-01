import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoom {
  final String id;
  final List<String> participants; // UIDs des utilisateurs
  final String? lastMessage;
  final Timestamp? lastMessageTimestamp;
  final Timestamp createdAt;

  ChatRoom({
    required this.id,
    required this.participants,
    this.lastMessage,
    this.lastMessageTimestamp,
    required this.createdAt,
  });

  factory ChatRoom.fromMap(String id, Map<String, dynamic> map) {
    // Sécurise chaque champ pour éviter les erreurs runtime
    final participantsRaw = map['participants'];
    List<String> participants = [];
    if (participantsRaw is List) {
      participants = participantsRaw.map((e) => e.toString()).toList();
    }

    final lastMessage = map['lastMessage']?.toString();

    Timestamp? lastMessageTimestamp;
    if (map['lastMessageTimestamp'] is Timestamp) {
      lastMessageTimestamp = map['lastMessageTimestamp'] as Timestamp;
    } else if (map['lastMessageTimestamp'] is int) {
      lastMessageTimestamp = Timestamp.fromMillisecondsSinceEpoch(map['lastMessageTimestamp']);
    }

    Timestamp createdAt;
    if (map['createdAt'] is Timestamp) {
      createdAt = map['createdAt'] as Timestamp;
    } else if (map['createdAt'] is int) {
      createdAt = Timestamp.fromMillisecondsSinceEpoch(map['createdAt']);
    } else {
      createdAt = Timestamp.now();
    }

    return ChatRoom(
      id: id,
      participants: participants,
      lastMessage: lastMessage,
      lastMessageTimestamp: lastMessageTimestamp,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageTimestamp': lastMessageTimestamp,
      'createdAt': createdAt,
    };
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:talktime2/models/message.dart';
import 'package:talktime2/models/user.dart';
import 'package:talktime2/models/chat_room.dart';
import 'package:flutter/material.dart';

class ChatService extends ChangeNotifier {

  // Met à jour l'état de saisie (typing) dans le chatroom
  Future<void> setTyping(String otherUserId, bool isTyping) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;
    final chatRoomID = [currentUser.uid, otherUserId]..sort();
    final chatRoomIDString = chatRoomID.join('_');
    await _firestore.collection('ChatRooms').doc(chatRoomIDString).set({
      'typing_${currentUser.uid}': isTyping,
    }, SetOptions(merge: true));
  }

  // Ecoute l'état de saisie de l'autre utilisateur
  Stream<bool> getTyping(String otherUserId) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return const Stream<bool>.empty();
    final chatRoomID = [currentUser.uid, otherUserId]..sort();
    final chatRoomIDString = chatRoomID.join('_');
    final otherTypingKey = 'typing_$otherUserId';
    return _firestore.collection('ChatRooms').doc(chatRoomIDString).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) return false;
      return data[otherTypingKey] == true;
    });
  }

  // Retourne tous les chatrooms où l'utilisateur est participant
  Stream<List<ChatRoom>> getUserChatRooms(String userId) {
    return _firestore
        .collection('ChatRooms')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTimestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatRoom.fromMap(doc.id, doc.data()))
            .toList());
  }
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  

  // Get users stream excluding the current user
  Stream<List<AppUser>> getUserStream() {
    return _firestore.collection("Users").snapshots().map((snapshot) {
      final currentUserEmail = _auth.currentUser?.email;
      return snapshot.docs
          .where((doc) => doc.data()['email'] != currentUserEmail)
          .map((doc) => AppUser.fromFirestore(doc))
          .toList();
    });
  }

  // Get users stream excluding blocked users
  Stream<List<AppUser>> getUserStreamExcludingBlocked() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw StateError('No user is currently logged in');
    }

    return _firestore
        .collection('Users')
        .doc(currentUser.uid)
        .collection('BlockedUsers')
        .snapshots()
        .asyncMap((snapshot) async {
      final blockedUserIds = snapshot.docs.map((doc) => doc.id).toList();
      final usersSnapshot = await _firestore.collection('Users').get();
      return usersSnapshot.docs
          .where((doc) =>
              doc.data()['email'] != currentUser.email &&
              !blockedUserIds.contains(doc.id))
          .map((doc) => AppUser.fromFirestore(doc))
          .toList();
    });
  }

  // Send a message
  Future<void> sendMessage(String receiverUsername, String message) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw StateError('No user is currently logged in');
      }

      final chatRoomID = [currentUser.uid, receiverUsername]..sort();
      final chatRoomIDString = chatRoomID.join('_');
      print("Sending message to chatRoomId: $chatRoomIDString"); // Debug

      final newMessage = Message(
        senderID: currentUser.uid,
        senderEmail: currentUser.email!,
        receiverID: receiverUsername,
        message: message,
        timestamp: Timestamp.now(),
        isRead: false,
      );

      // Ajout du message
      await _firestore
          .collection('ChatRooms')
          .doc(chatRoomIDString)
          .collection('Messages')
          .add(newMessage.toMap());

      // Création/mise à jour du ChatRoom avec métadonnées
      final chatRoom = ChatRoom(
        id: chatRoomIDString,
        participants: [currentUser.uid, receiverUsername],
        lastMessage: message,
        lastMessageTimestamp: newMessage.timestamp,
        createdAt: Timestamp.now(),
      );
      await _firestore
          .collection('ChatRooms')
          .doc(chatRoomIDString)
          .set(chatRoom.toMap(), SetOptions(merge: true));
    } catch (e) {
      print("Error sending message: $e");
    }
  }

  // Marquer tous les messages reçus comme lus dans un chatroom
  Future<void> markMessagesAsRead(String chatRoomIDString, String currentUserId) async {
    final messagesSnapshot = await _firestore
        .collection('ChatRooms')
        .doc(chatRoomIDString)
        .collection('Messages')
        .where('receiverID', isEqualTo: currentUserId)
        .where('isRead', isEqualTo: false)
        .get();
    for (final doc in messagesSnapshot.docs) {
      await doc.reference.update({'isRead': true});
    }
  }


  // Get messages for a chat room
  Stream<QuerySnapshot> getMessages(String receiverID, String senderID) {
  final chatRoomID = [receiverID, senderID]..sort();
  final chatRoomIDString = chatRoomID.join('_');
  print("Fetching messages for chatRoomId: $chatRoomIDString"); // Debug

  return _firestore
      .collection("ChatRooms")
      .doc(chatRoomIDString)
      .collection("Messages")
      .orderBy("timestamp", descending: false)
      .snapshots()
      .handleError((error) {
        print("Error fetching messages: $error"); // Debug
      });
}


  // Report a user
  Future<void> reportUser(String messageId, String userId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw StateError('No user is currently logged in');
      }

      final report = {
        'reportedBy': currentUser.uid,
        'messageId': messageId,
        'messageOwnerId': userId,
        'timestamp': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('Reports').add(report);
    } catch (e) {
      print("Error reporting user: $e");
    }
  }

  // Block a user
  Future<void> blockUser(String userId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw StateError('No user is currently logged in');
      }

      await _firestore
          .collection('Users')
          .doc(currentUser.uid)
          .collection('BlockedUsers')
          .doc(userId)
          .set({});
      notifyListeners();
    } catch (e) {
      print("Error blocking user: $e");
    }
  }

  // Unblock a user
  Future<void> unblockUser(String blockedUserId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw StateError('No user is currently logged in');
      }

      await _firestore
          .collection('Users')
          .doc(currentUser.uid)
          .collection('BlockedUsers')
          .doc(blockedUserId)
          .delete();
      notifyListeners();
    } catch (e) {
      print("Error unblocking user: $e");
    }
  }

  // Get blocked users stream
  Stream<List<AppUser>> getBlockedUsersStream(String userId) {
    return _firestore
        .collection('Users')
        .doc(userId)
        .collection('BlockedUsers')
        .snapshots()
        .asyncMap((snapshot) async {
      final blockedUserIds = snapshot.docs.map((doc) => doc.id).toList();
      final userDocs = await Future.wait(
        blockedUserIds.map((id) => _firestore.collection('Users').doc(id).get()),
      );
      return userDocs.map((doc) => AppUser.fromFirestore(doc)).toList();
    });
  }

  Stream<Map<String, dynamic>> getLatestMessageForUser(String userId) {
  final currentUser = _auth.currentUser;
  if (currentUser == null) {
    throw StateError('No user is currently logged in');
  }

  final chatRoomID = [currentUser.uid, userId]..sort();
  final chatRoomIDString = chatRoomID.join('_');

  return _firestore
      .collection('ChatRooms')
      .doc(chatRoomIDString)
      .collection('Messages')
      .orderBy('timestamp', descending: true)
      .limit(1)
      .snapshots()
      .map((snapshot) {
        print("Latest messages snapshot: ${snapshot.docs.map((doc) => doc.data())}");
        if (snapshot.docs.isEmpty) {
          return {'text': 'No message', 'timestamp': Timestamp.now()};
        }
        return snapshot.docs.first.data();
      });
}

Stream<List<AppUser>> getUsersSortedByLatestMessage() {
  final currentUser = _auth.currentUser;
  if (currentUser == null) {
    throw StateError('No user is currently logged in');
  }

  return _firestore.collection('Users').snapshots().asyncMap((snapshot) async {
    final currentUserEmail = currentUser.email;
    final blockedUserIds = (await _firestore
        .collection('Users')
        .doc(currentUser.uid)
        .collection('BlockedUsers')
        .get()).docs.map((doc) => doc.id).toList();

    final userDocs = snapshot.docs
        .where((doc) => doc.data()['email'] != currentUserEmail && !blockedUserIds.contains(doc.id))
        .toList();

    final usersWithLatestMessages = await Future.wait(userDocs.map((userDoc) async {
      final userId = userDoc.id;
      final chatRoomID = [currentUser.uid, userId]..sort();
      final chatRoomIDString = chatRoomID.join('_');
      final latestMessageSnapshot = await _firestore
        .collection('ChatRooms')
        .doc(chatRoomIDString)
        .collection('Messages')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

      final latestMessage = latestMessageSnapshot.docs.isEmpty
          ? {'message': 'No message', 'timestamp': Timestamp.now()}
          : latestMessageSnapshot.docs.first.data();

      final appUser = AppUser.fromFirestore(userDoc);
      
      // Return a tuple-like structure with user and latest message info
      return {
        'user': appUser,
        'latestMessage': latestMessage['message'],
        'latestMessageTimestamp': latestMessage['timestamp'],
      };
    }));

    // Sort users by latest message timestamp
    usersWithLatestMessages.sort((a, b) {
      final aTimestamp = (a['latestMessageTimestamp'] as Timestamp).toDate();
      final bTimestamp = (b['latestMessageTimestamp'] as Timestamp).toDate();
      return bTimestamp.compareTo(aTimestamp);
    });

    // Extract just the users from the sorted list
    return usersWithLatestMessages.map((item) => item['user'] as AppUser).toList();
  });
}


}

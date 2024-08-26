import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:talktime2/models/message.dart';
import 'package:flutter/material.dart';

class ChatService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  

  // Get users stream excluding the current user
  Stream<List<Map<String, dynamic>>> getUserStream() {
    return _firestore.collection("Users").snapshots().map((snapshot) {
      final currentUserEmail = _auth.currentUser?.email;
      return snapshot.docs
          .where((doc) => doc.data()['email'] != currentUserEmail)
          .map((doc) => doc.data())
          .toList();
    });
  }

  // Get users stream excluding blocked users
  Stream<List<Map<String, dynamic>>> getUserStreamExcludingBlocked() {
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
          .map((doc) => doc.data())
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
    );

    await _firestore
        .collection('ChatRooms')
        .doc(chatRoomIDString)
        .collection('Messages')
        .add(newMessage.toMap());
  } catch (e) {
    print("Error sending message: $e");
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
  Stream<List<Map<String, dynamic>>> getBlockedUsersStream(String userId) {
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
      return userDocs.map((doc) => doc.data() as Map<String, dynamic>).toList();
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

Stream<List<Map<String, dynamic>>> getUsersSortedByLatestMessage() {
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
        .map((doc) => doc.id)
        .toList();

    final usersWithLatestMessages = await Future.wait(userDocs.map((userId) async {
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

      final userDoc = await _firestore.collection('Users').doc(userId).get();
      final userData = userDoc.data()!;
      
      return {
        ...userData,
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

    return usersWithLatestMessages;
  });
}


}

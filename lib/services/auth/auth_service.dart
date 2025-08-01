import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:talktime2/models/user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Get current user as AppUser model
  Future<AppUser?> getCurrentAppUser() async {
    final User? firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;

    try {
      final doc = await _firestore.collection('Users').doc(firebaseUser.uid).get();
      if (doc.exists) {
        return AppUser.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error fetching current user: $e');
      return null;
    }
  }

  // Get any user by UID as AppUser model
  Future<AppUser?> getUserByUID(String uid) async {
    try {
      final doc = await _firestore.collection('Users').doc(uid).get();
      if (doc.exists) {
        return AppUser.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error fetching user by UID: $e');
      return null;
    }
  }

  // Update user's last seen timestamp
  Future<void> updateLastSeen() async {
    final User? firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return;

    try {
      await _firestore.collection('Users').doc(firebaseUser.uid).update({
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating last seen: $e');
    }
  }

  // Update user profile
  Future<void> updateUserProfile(AppUser updatedUser) async {
    try {
      await _firestore.collection('Users').doc(updatedUser.uid).update(
        updatedUser.toMap(),
      );
    } catch (e) {
      print('Error updating user profile: $e');
      throw Exception('Failed to update profile: $e');
    }
  }

  Future<UserCredential> signInWithEmailOrUsername(String identifier, String password) async {
    try {
      QuerySnapshot emailQuery = await _firestore.collection('Users')
        .where('email', isEqualTo: identifier)
        .get();

      if (emailQuery.docs.isNotEmpty) {
        return await _auth.signInWithEmailAndPassword(
          email: identifier,
          password: password,
        );
      } else {
        QuerySnapshot usernameQuery = await _firestore.collection('Users')
          .where('username', isEqualTo: identifier)
          .get();

        if (usernameQuery.docs.isNotEmpty) {
          String email = usernameQuery.docs.first['email'];
          return await _auth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
        } else {
          throw Exception('User not found');
        }
      }
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException during sign-in: ${e.message}');
      throw Exception(e.message);
    } catch (e) {
      print('Exception during sign-in: $e');
      throw Exception(e.toString());
    }
  }

  Future<UserCredential> signUpWithEmailPassword(String email, String password, String username) async {
    try {
      // Validate input
      if (!AppUser.isValidEmailStatic(email)) {
        throw Exception('Invalid email format. Please enter a valid email address.');
      }
      if (!AppUser.isValidUsernameStatic(username)) {
        throw Exception('Invalid username. Must be 3-30 characters, letters, numbers, dots, hyphens, and underscores only.');
      }

      // Check if username is already taken
      final usernameQuery = await _firestore.collection('Users')
          .where('username', isEqualTo: username)
          .get();
      
      if (usernameQuery.docs.isNotEmpty) {
        throw Exception('Username is already taken');
      }

      // Register user with Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        print('User credential is null');
        throw Exception('User credential is null');
      }

      // Create AppUser model
      final newUser = AppUser(
        uid: userCredential.user!.uid,
        email: email,
        username: username,
        profilePicture: 'assets/images/defaultpic.png',
        createdAt: DateTime.now(),
        lastSeen: DateTime.now(),
      );

      // Save user data to Firestore using AppUser model
      await _firestore.collection('Users').doc(userCredential.user!.uid).set(
        newUser.toMap(),
      );

      print('User registered and saved to Firestore successfully.');
      print('User data: ${newUser.toMap()}');
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException during sign-up: ${e.message}');
      throw Exception(e.message);
    } catch (e) {
      print('Exception during sign-up: $e');
      throw Exception(e.toString());
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      print('User signed out successfully.');
    } catch (e) {
      print('Error signing out: $e');
      throw Exception('Error signing out: $e');
    }
  }
}

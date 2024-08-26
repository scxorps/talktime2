import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? getCurrentUser() {
    return _auth.currentUser;
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
      // Register user with email and password
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        print('User credential is null');
        throw Exception('User credential is null');
      }

      // Log user details for debugging
      print('User registered with UID: ${userCredential.user!.uid}');
      print('User email: $email');
      print('User username: $username');

      // Get the default profile picture URL
      String defaultProfilePicUrl = 'assets/images/defaultpic.png'; // Replace with a valid URL or method to get it

      // Save user data to Firestore
      await _firestore.collection('Users').doc(userCredential.user!.uid).set(
        {
          'email': email,
          'uid': userCredential.user!.uid,
          'username': username,
          'profilePicture': defaultProfilePicUrl, // Add profilePicture field
        },
      );

      print('User registered and saved to Firestore successfully.');
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

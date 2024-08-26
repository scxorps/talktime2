import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class ProfileEdit {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  Future<void> updateProfile({
    required String email,
    required String username,
    required String newPassword,
    File? newProfilePicture,
    required BuildContext context,
    required Function(String) onSuccess,
    required Function(String) onError,
  }) async {
    final User? user = _auth.currentUser;
    if (user == null) {
      onError("No user is currently signed in.");
      return;
    }

    try {
      // Handle username change if specified
      if (username.isNotEmpty) {
        final bool confirmed = await _confirmUsernameChange(context);
        if (!confirmed) {
          onError("Username update canceled by the user.");
          return;
        }

        // Update the username in Firestore
        await _firestore.collection('Users').doc(user.uid).update({
          'username': username,
        });
      }

      // Prompt for current password if email or password is being updated
      if ((email.isNotEmpty && email != user.email) || newPassword.isNotEmpty) {
        final String? currentPassword = await _promptForCurrentPassword(context);

        if (currentPassword == null) {
          onError("Password update canceled by the user.");
          return;
        }

        try {
          // Re-authenticate the user with the current password
          AuthCredential credential = EmailAuthProvider.credential(
            email: user.email!,
            password: currentPassword,
          );
          await user.reauthenticateWithCredential(credential);

          // Update email if it has changed
          if (email.isNotEmpty && email != user.email) {
            await user.verifyBeforeUpdateEmail(email);
            onSuccess("Email update initiated. Please verify the new email address.");
            return;
          }

          // Update password if a new one is provided
          if (newPassword.isNotEmpty) {
            await user.updatePassword(newPassword);
          }
        } catch (e) {
          onError("Failed to update email or password: ${e.toString()}");
          return;
        }
      }

      // Handle profile picture update
      if (newProfilePicture != null) {
        final String? profilePictureUrl = await _uploadProfilePicture(newProfilePicture, user.uid);
        if (profilePictureUrl != null) {
          await _firestore.collection('Users').doc(user.uid).update({
            'profilePicture': profilePictureUrl,
          });
        }
      }

      onSuccess("Profile updated successfully.");
    } catch (e) {
      onError("Failed to update profile: ${e.toString()}");
    }
  }

  Future<String?> _uploadProfilePicture(File imageFile, String userId) async {
    try {
      final fileExtension = path.extension(imageFile.path);
      final storageRef = _storage.ref().child('profile_pictures/$userId$fileExtension');

      final uploadTask = storageRef.putFile(imageFile);
      final snapshot = await uploadTask.whenComplete(() {});

      if (snapshot.state == TaskState.success) {
        return await snapshot.ref.getDownloadURL();
      } else {
        throw Exception('Upload failed with state: ${snapshot.state}');
      }
    } catch (e) {
      return null;
    }
  }

  Future<bool> _confirmUsernameChange(BuildContext context) async {
    bool confirmed = false;
    await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Username Change'),
          content: Text('Are you sure you want to change your username?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Confirm'),
            ),
          ],
        );
      },
    ).then((value) {
      confirmed = value ?? false;
    });

    return confirmed;
  }

  Future<String?> _promptForCurrentPassword(BuildContext context) async {
    TextEditingController passwordController = TextEditingController();
    String? currentPassword;

    await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enter Current Password'),
          content: TextField(
            controller: passwordController,
            obscureText: true,
            decoration: InputDecoration(hintText: 'Current Password'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                currentPassword = passwordController.text;
                Navigator.of(context).pop();
              },
              child: Text('Submit'),
            ),
          ],
        );
      },
    );

    return currentPassword?.isNotEmpty == true ? currentPassword : null;
  }

  Future<File?> pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    return pickedFile != null ? File(pickedFile.path) : null;
  }

  Future<void> deleteUser({
    required BuildContext context,
    required Function(String) onSuccess,
    required Function(String) onError,
  }) async {
    final User? user = _auth.currentUser;
    if (user == null) {
      onError("No user is currently signed in.");
      return;
    }

    try {
      final String? currentPassword = await _promptForCurrentPassword(context);
      if (currentPassword == null) {
        onError("User deletion canceled by the user.");
        return;
      }

      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      await _firestore.collection('Users').doc(user.uid).delete();
      await user.delete();

      onSuccess("User account deleted successfully.");
    } catch (e) {
      onError("Failed to delete user account: ${e.toString()}");
    }
  }
}

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late TextEditingController _emailController;
  late TextEditingController _usernameController;
  late TextEditingController _newPasswordController;
  String _profilePictureUrl = 'assets/images/defaultpic.png'; // Default picture
  File? _profilePictureFile;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _usernameController = TextEditingController();
    _newPasswordController = TextEditingController();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('Users').doc(user.uid).get();
      final userData = userDoc.data() as Map<String, dynamic>? ?? {};

      setState(() {
        _emailController.text = userData['email'] ?? '';
        _usernameController.text = userData['username'] ?? '';
        _profilePictureUrl = userData['profilePicture'] ?? 'assets/images/defaultpic.png'; // Load profile picture
      });
    }
  }

  Future<void> _updateProfilePicture() async {
    final ImagePicker picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final File imageFile = File(pickedFile.path);
      final String? newProfilePictureUrl = await _uploadProfilePicture(imageFile);

      if (newProfilePictureUrl != null) {
        await _updateProfilePictureUrl(newProfilePictureUrl);

        setState(() {
          _profilePictureUrl = newProfilePictureUrl; // Update local state
        });

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profile picture updated successfully.')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upload profile picture.')));
      }
    }
  }

  Future<String?> _uploadProfilePicture(File imageFile) async {
    try {
      // Create a unique path for the image in Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_pictures/${DateTime.now().millisecondsSinceEpoch}.jpg');
      
      // Upload the file
      final uploadTask = storageRef.putFile(imageFile);

      // Monitor the upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        print('Upload progress: ${(snapshot.bytesTransferred / snapshot.totalBytes) * 100}%');
      });

      // Wait for the upload to complete
      final snapshot = await uploadTask;
      
      // Get the download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } on FirebaseException catch (e) {
      // Log specific FirebaseStorageException details
      print('FirebaseException during upload: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      // Log general exceptions
      print('Error uploading profile picture: $e');
      return null;
    }
  }

  Future<void> _updateProfilePictureUrl(String newUrl) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('Users').doc(user.uid).update({
        'profilePicture': newUrl,
      });
    }
  }

  Future<void> _handleUpdateProfile() async {
  final User? user = FirebaseAuth.instance.currentUser;

  if (user != null) {
    try {
      // Prompt for current password
      String? currentPassword = await _promptForCurrentPassword(context);
      if (currentPassword == null) {
        return; // User canceled the operation
      }

      // Re-authenticate if email is changed
      if (_emailController.text.isNotEmpty && _emailController.text != user.email) {
        AuthCredential credential = EmailAuthProvider.credential(
          email: user.email!,
          password: currentPassword,
        );
        await user.reauthenticateWithCredential(credential);

        // Update email
        await user.updateEmail(_emailController.text);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Email updated successfully.')),
        );

        return; // Exit as the email update is complete
      }

      // Update password if provided
      if (_newPasswordController.text.isNotEmpty) {
        AuthCredential credential = EmailAuthProvider.credential(
          email: user.email!,
          password: currentPassword,
        );
        await user.reauthenticateWithCredential(credential);
        await user.updatePassword(_newPasswordController.text);

        // Clear the password text field
        _newPasswordController.clear();
      }

      // Update username in Firestore
      await FirebaseFirestore.instance.collection('Users').doc(user.uid).update({
        'username': _usernameController.text,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated successfully.')),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.message}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An unexpected error occurred.')),
      );
    }
  }
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
              Navigator.of(context).pop(currentPassword);
            },
            child: Text('Submit'),
          ),
        ],
      );
    },
  );

  return currentPassword?.isNotEmpty == true ? currentPassword : null;
}


  void _handleDeleteUser() {
    // Implement your user delete code here
  }

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Profile"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 70,
                    backgroundImage: _profilePictureUrl.startsWith('http')
                      ? NetworkImage(_profilePictureUrl) as ImageProvider
                      : AssetImage(_profilePictureUrl) as ImageProvider,
                    backgroundColor: Colors.grey[300],
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: IconButton(
                      icon: Icon(Icons.edit, color: Colors.blue),
                      onPressed: _updateProfilePicture, // Trigger image picker
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 50),
            Text(
              "Email:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                hintText: 'Email',
              ),
            ),
            SizedBox(height: 16),
            Text(
              "Username:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                hintText: 'Username',
              ),
            ),
            SizedBox(height: 16),
            Text(
              "New Password:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                hintText: 'New Password',
              ),
            ),
            SizedBox(height: 160),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: _handleUpdateProfile,
                  child: Text('Edit Profile'),
                ),
                ElevatedButton(
                  onPressed: _handleDeleteUser,
                  child: Text('Delete User'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

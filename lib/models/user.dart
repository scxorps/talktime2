import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  final String username;
  final String profilePicture;
  final DateTime? createdAt;
  final DateTime? lastSeen;

  AppUser({
    required this.uid,
    required this.email,
    required this.username,
    required this.profilePicture,
    this.createdAt,
    this.lastSeen,
  });

  // Factory constructor from Firestore document
  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser.fromMap(data, doc.id);
  }

  // Factory constructor from Map
  factory AppUser.fromMap(Map<String, dynamic> data, String uid) {
    return AppUser(
      uid: uid,
      email: data['email'] ?? '',
      username: data['username'] ?? '',
      profilePicture: data['profilePicture'] ?? 'assets/images/defaultpic.png',
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate() 
          : null,
      lastSeen: data['lastSeen'] != null 
          ? (data['lastSeen'] as Timestamp).toDate() 
          : null,
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'username': username,
      'profilePicture': profilePicture,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : FieldValue.serverTimestamp(),
    };
  }

  // Convert to Map for Firestore updates (excludes uid)
  Map<String, dynamic> toUpdateMap() {
    final map = <String, dynamic>{};
    
    if (email.isNotEmpty) map['email'] = email;
    if (username.isNotEmpty) map['username'] = username;
    if (profilePicture.isNotEmpty) map['profilePicture'] = profilePicture;
    if (lastSeen != null) map['lastSeen'] = Timestamp.fromDate(lastSeen!);
    
    return map;
  }

  // Copy with method for immutable updates
  AppUser copyWith({
    String? uid,
    String? email,
    String? username,
    String? profilePicture,
    DateTime? createdAt,
    DateTime? lastSeen,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      username: username ?? this.username,
      profilePicture: profilePicture ?? this.profilePicture,
      createdAt: createdAt ?? this.createdAt,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  // Equality and hashCode for comparisons
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppUser && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;

  // String representation
  @override
  String toString() {
    return 'AppUser(uid: $uid, email: $email, username: $username, profilePicture: $profilePicture)';
  }

  // Validation methods
  bool get isValidEmail => email.contains('@') && email.contains('.');
  bool get isValidUsername => username.length >= 3;
  bool get hasProfilePicture => profilePicture.isNotEmpty && profilePicture != 'assets/images/defaultpic.png';
  
  // Static validation methods
  static bool isValidEmailStatic(String email) {
    // Regex plus permissive pour les emails
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return email.isNotEmpty && emailRegex.hasMatch(email);
  }
  
  static bool isValidUsernameStatic(String username) {
    // Autoriser plus de caractères dans les noms d'utilisateur
    // Lettres, chiffres, underscores, tirets, points - 3 à 30 caractères
    final usernameRegex = RegExp(r'^[a-zA-Z0-9._-]{3,30}$');
    return username.isNotEmpty && usernameRegex.hasMatch(username);
  }
  
  // Display methods
  String get displayName => username.isNotEmpty ? username : email.split('@').first;
  String get profileImageUrl => profilePicture.startsWith('http') ? profilePicture : 'assets/images/defaultpic.png';
}

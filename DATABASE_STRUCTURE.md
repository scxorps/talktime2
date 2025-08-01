# 🗄️ Database Structure Documentation - TalkTime2

## 📊 **Complete Firestore Database Schema**

### **1. 👥 Users Collection**
```
/Users/{userUID}
```

**Document Structure:**
```dart
{
  uid: String,              // Firebase Auth UID (primary key)
  email: String,            // "user@example.com" (unique, indexed)
  username: String,         // "john_doe" (unique, indexed)
  profilePicture: String,   // Firebase Storage URL or default path
  createdAt: Timestamp,     // Account creation date
  lastSeen: Timestamp       // Last activity timestamp
}
```

**Example Document:**
```json
{
  "uid": "abc123def456",
  "email": "john@example.com",
  "username": "john_doe",
  "profilePicture": "https://firebasestorage.googleapis.com/...",
  "createdAt": "2025-01-15T10:30:00Z",
  "lastSeen": "2025-01-15T15:45:00Z"
}
```

**Indexes:**
- `email` (single field, ascending)
- `username` (single field, ascending)
- `lastSeen` (single field, descending) - for online status

---

### **2. 🚫 BlockedUsers Subcollection**
```
/Users/{userUID}/BlockedUsers/{blockedUserUID}
```

**Document Structure:**
```dart
{} // Empty document - existence indicates block status
```

**Example:**
```
/Users/abc123/BlockedUsers/def456 -> {}
```

**Purpose:**
- Track blocked users per user
- Fast lookup for filtering
- Privacy and security

---

### **3. 💬 ChatRooms Collection**
```
/ChatRooms/{chatRoomID}
```

**ChatRoom ID Generation:**
```dart
// Deterministic room ID from participant UIDs
final participants = [userUID1, userUID2]..sort();
final chatRoomID = participants.join('_');
// Example: "abc123_def456"
```

**Document Structure:**
```dart
{
  participants: List<String>,      // [userUID1, userUID2]
  createdAt: Timestamp,           // Room creation time
  lastActivity: Timestamp,        // Last message timestamp
  lastMessage: String,            // Preview of latest message
  lastMessageBy: String           // UID of last message sender
}
```

**Example Document:**
```json
{
  "participants": ["abc123", "def456"],
  "createdAt": "2025-01-15T10:00:00Z",
  "lastActivity": "2025-01-15T15:45:00Z",
  "lastMessage": "Hello there!",
  "lastMessageBy": "abc123"
}
```

---

### **4. 📨 Messages Subcollection**
```
/ChatRooms/{chatRoomID}/Messages/{messageID}
```

**Document Structure:**
```dart
{
  senderID: String,         // UID of message sender
  senderEmail: String,      // Email of sender (denormalized)
  receiverID: String,       // UID of message receiver
  message: String,          // Message content
  timestamp: Timestamp,     // Message creation time
  messageType: String,      // "text", "image", "file" (future)
  readStatus: Map<String, bool>, // Read status per user
  editedAt: Timestamp?,     // If message was edited
  replyTo: String?          // Reference to replied message ID
}
```

**Example Document:**
```json
{
  "senderID": "abc123",
  "senderEmail": "john@example.com",
  "receiverID": "def456",
  "message": "Hello! How are you?",
  "timestamp": "2025-01-15T15:45:00Z",
  "messageType": "text",
  "readStatus": {
    "abc123": true,
    "def456": false
  }
}
```

**Indexes:**
- `timestamp` (single field, ascending)
- Composite: `(senderID, timestamp)`
- Composite: `(receiverID, timestamp)`

---

### **5. 🚨 Reports Collection**
```
/Reports/{reportID}
```

**Document Structure:**
```dart
{
  reportedBy: String,           // UID of user making report
  reportedUser: String,         // UID of reported user
  messageId: String,            // ID of reported message
  messageOwnerId: String,       // UID of message owner
  reason: String,               // Report reason
  description: String,          // Additional details
  timestamp: ServerTimestamp,   // Report creation time
  status: String,               // "pending", "reviewed", "resolved"
  reviewedBy: String?,          // Admin UID who reviewed
  reviewedAt: Timestamp?,       // Review timestamp
  action: String?               // "warning", "suspension", "ban"
}
```

**Example Document:**
```json
{
  "reportedBy": "abc123",
  "reportedUser": "def456",
  "messageId": "msg789",
  "messageOwnerId": "def456",
  "reason": "harassment",
  "description": "Inappropriate language",
  "timestamp": "2025-01-15T16:00:00Z",
  "status": "pending"
}
```

---

### **6. 🏪 Firebase Storage Structure**
```
/profile_pictures/{userUID}.{extension}
/chat_attachments/{chatRoomID}/{messageID}_{filename}
/temp_uploads/{userUID}/{timestamp}_{filename}
```

**Profile Pictures:**
- Path: `/profile_pictures/abc123.jpg`
- Public read access
- User-specific write access

**Chat Attachments (Future):**
- Path: `/chat_attachments/abc123_def456/msg789_document.pdf`
- Participant-only access

---

## 🔍 **Query Patterns**

### **Common Queries:**

1. **Get all users except current user:**
```dart
_firestore.collection('Users')
  .where('email', isNotEqualTo: currentUserEmail)
  .orderBy('email')
  .orderBy('lastSeen', descending: true)
```

2. **Get non-blocked users:**
```dart
// First get blocked user IDs
final blockedIds = await _firestore
  .collection('Users')
  .doc(currentUID)
  .collection('BlockedUsers')
  .get();

// Then filter main query
_firestore.collection('Users')
  .where(FieldPath.documentId, whereNotIn: blockedIds)
```

3. **Get chat messages:**
```dart
_firestore
  .collection('ChatRooms')
  .doc(chatRoomID)
  .collection('Messages')
  .orderBy('timestamp', descending: false)
  .limit(50)
```

4. **Get latest message per chat:**
```dart
_firestore
  .collection('ChatRooms')
  .doc(chatRoomID)
  .collection('Messages')
  .orderBy('timestamp', descending: true)
  .limit(1)
```

---

## 🔒 **Security Rules**

### **Recommended Firestore Rules:**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /Users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
      
      // BlockedUsers subcollection
      match /BlockedUsers/{blockedUserId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
    
    // ChatRooms collection
    match /ChatRooms/{chatRoomId} {
      function isParticipant() {
        return request.auth.uid in chatRoomId.split('_');
      }
      
      allow read, write: if request.auth != null && isParticipant();
      
      // Messages subcollection
      match /Messages/{messageId} {
        allow read, write: if request.auth != null && isParticipant();
      }
    }
    
    // Reports collection
    match /Reports/{reportId} {
      allow create: if request.auth != null;
      allow read: if request.auth != null && 
        (request.auth.uid == resource.data.reportedBy || 
         hasAdminRole(request.auth.uid));
    }
  }
}
```

---

## 📈 **Performance Optimizations**

### **1. Indexes:**
- Create composite indexes for common query patterns
- Single field indexes on frequently queried fields

### **2. Pagination:**
```dart
// Implement cursor-based pagination
.orderBy('timestamp')
.startAfter(lastDocument)
.limit(20)
```

### **3. Denormalization:**
- Store sender email in messages for quick display
- Cache latest message in chat room document
- Store user counts for statistics

### **4. Offline Support:**
```dart
// Enable offline persistence
FirebaseFirestore.instance.enablePersistence();

// Use cache-first queries when appropriate
GetOptions(source: Source.cache)
```

---

## 🚀 **Future Enhancements**

### **Planned Collections:**

1. **UserPreferences:**
```dart
/Users/{userUID}/Preferences/settings
{
  theme: "dark|light",
  notifications: bool,
  privacy: Map<String, dynamic>
}
```

2. **ChatRoomSettings:**
```dart
/ChatRooms/{chatRoomID}/Settings/config
{
  muteUntil: Timestamp?,
  customName: String?,
  pinnedMessages: List<String>
}
```

3. **UserStatistics:**
```dart
/Statistics/Users/{userUID}
{
  messagesSent: int,
  chatsStarted: int,
  lastLoginDate: Timestamp,
  totalOnlineTime: Duration
}
```

Cette structure est évolutive et optimisée pour une application de chat en temps réel ! 🎯

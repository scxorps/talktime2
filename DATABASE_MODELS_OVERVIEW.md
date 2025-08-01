# 📊 **Database Models - TalkTime2 Application**

## 🏗️ **Overview**
Cette documentation répertorie tous les modèles de données existants dans l'application TalkTime2, leurs structures, et leurs utilisations.

---

## 📋 **Existing Models**

### **1. 👤 AppUser Model**
**Fichier:** `lib/models/user.dart`

**Description:** Modèle principal pour la gestion des utilisateurs de l'application.

**Structure:**
```dart
class AppUser {
  final String uid;              // Firebase Auth UID (unique)
  final String email;            // Email utilisateur
  final String username;         // Nom d'utilisateur (unique)
  final String profilePicture;   // URL image profil
  final DateTime? createdAt;     // Date création compte
  final DateTime? lastSeen;      // Dernière activité
}
```

**Méthodes Disponibles:**
- ✅ `fromFirestore(DocumentSnapshot doc)` - Construction depuis Firestore
- ✅ `fromMap(Map<String, dynamic> data, String uid)` - Construction depuis Map
- ✅ `toMap()` - Conversion vers Map pour Firestore
- ✅ `toUpdateMap()` - Map pour mises à jour (sans uid)
- ✅ `copyWith()` - Copie immutable avec modifications
- ✅ `isValidEmailStatic(String email)` - Validation email
- ✅ `isValidUsernameStatic(String username)` - Validation username

**Getters Utiles:**
- `displayName` - Nom d'affichage (username ou partie email)
- `profileImageUrl` - URL image ou défaut
- `isValidEmail` - Vérifie validité email instance
- `isValidUsername` - Vérifie validité username instance
- `hasProfilePicture` - Vérifie si image personnalisée

**Utilisation:**
- Authentification et gestion utilisateurs
- Affichage profils et listes utilisateurs
- Gestion blocage utilisateurs

---

### **2. 💬 Message Model**
**Fichier:** `lib/models/message.dart`

**Description:** Modèle pour les messages échangés dans les chats.

**Structure:**
```dart
class Message {
  final String senderID;         // UID expéditeur
  final String senderEmail;      // Email expéditeur (dénormalisé)
  final String receiverID;       // UID destinataire
  final String message;          // Contenu message
  final Timestamp timestamp;     // Horodatage Firestore
}
```

**Méthodes Disponibles:**
- ✅ `toMap()` - Conversion vers Map pour Firestore

**Utilisation:**
- Stockage messages dans ChatRooms/{chatRoomID}/Messages
- Affichage historique conversations
- Tri chronologique messages

**⚠️ Améliorations Recommandées:**
- [ ] Ajouter `fromFirestore()` et `fromMap()`
- [ ] Ajouter `messageType` (text, image, file)
- [ ] Ajouter `readStatus` Map<String, bool>
- [ ] Ajouter `editedAt` pour messages modifiés
- [ ] Ajouter `replyTo` pour réponses

---

## 🔄 **Implicit Data Structures**

### **3. 🚫 BlockedUser Structure**
**Collection:** `/Users/{userUID}/BlockedUsers/{blockedUserUID}`

**Structure Firestore:**
```json
{} // Document vide - existence = blocage
```

**Utilisation:**
- Gestion utilisateurs bloqués
- Filtrage listes utilisateurs
- Contrôle accès conversations

---

### **4. 📝 Report Structure**
**Collection:** `/Reports/{reportID}`

**Structure Firestore:**
```json
{
  "reportedBy": "string",      // UID rapporteur
  "reportedUser": "string",    // UID utilisateur signalé
  "messageId": "string",       // ID message signalé
  "messageOwnerId": "string",  // UID propriétaire message
  "reason": "string",          // Raison signalement
  "description": "string",     // Description détaillée
  "timestamp": "Timestamp",    // Date signalement
  "status": "string"          // "pending", "reviewed", "resolved"
}
```

**Utilisation:**
- Signalement contenus inappropriés
- Modération application
- Historique signalements

---

### **5. 🏠 ChatRoom Structure**
**Collection:** `/ChatRooms/{chatRoomID}`

**Structure Firestore:**
```json
{
  "participants": ["uid1", "uid2"],  // Liste participants
  "createdAt": "Timestamp",          // Date création
  "lastActivity": "Timestamp",       // Dernière activité
  "lastMessage": "string",           // Dernier message
  "lastMessageBy": "string"          // UID dernier expéditeur
}
```

**ID Generation:**
```dart
final participants = [userUID1, userUID2]..sort();
final chatRoomID = participants.join('_');
// Exemple: "abc123_def456"
```

**Utilisation:**
- Organisation conversations
- Cache derniers messages
- Tri conversations par activité

---

## 🎯 **Models à Créer**

### **1. 📱 AppUser Profile Extensions**
```dart
class UserPreferences {
  final String theme;           // "dark" | "light"
  final bool notifications;     // Notifications activées
  final Map<String, dynamic> privacy; // Paramètres confidentialité
}

class UserStatistics {
  final int messagesSent;       // Nombre messages envoyés
  final int chatsStarted;       // Conversations initiées
  final DateTime lastLoginDate; // Dernière connexion
  final Duration totalOnlineTime; // Temps total en ligne
}
```

### **2. 💬 Enhanced Message Model**
```dart
class EnhancedMessage extends Message {
  final String messageType;     // "text", "image", "audio", "file"
  final Map<String, bool> readStatus; // Statut lecture par utilisateur
  final DateTime? editedAt;     // Date modification
  final String? replyTo;        // ID message de réponse
  final Map<String, dynamic>? metadata; // Métadonnées (taille fichier, etc.)
}
```

### **3. 🔐 ChatRoom Settings**
```dart
class ChatRoomSettings {
  final String chatRoomID;      // ID conversation
  final DateTime? muteUntil;    // Silencieux jusqu'à
  final String? customName;     // Nom personnalisé conversation
  final List<String> pinnedMessages; // Messages épinglés
  final bool? encryption;       // Chiffrement activé
}
```

### **4. 📊 Application Analytics**
```dart
class AppAnalytics {
  final String userId;          // UID utilisateur
  final Map<String, int> featureUsage; // Utilisation fonctionnalités
  final List<String> errors;    // Erreurs rencontrées
  final Duration sessionTime;   // Durée session
  final DateTime sessionStart; // Début session
}
```

---

## 🔄 **Migration Status**

### **✅ Completed Models:**
- [x] **AppUser** - Complet avec validations et méthodes utilitaires
- [x] **Message** - Fonctionnel mais basique

### **🚧 In Progress:**
- [ ] **Enhanced Message** - Extensions message avancées
- [ ] **ChatRoom Settings** - Paramètres conversations

### **📋 Planned:**
- [ ] **UserPreferences** - Préférences utilisateur
- [ ] **UserStatistics** - Statistiques utilisation
- [ ] **AppAnalytics** - Analytics application
- [ ] **Report** - Modèle signalement structuré
- [ ] **Notification** - Système notifications

---

## 🛠️ **Development Guidelines**

### **Model Standards:**
1. **Immutabilité** - Tous les champs `final`
2. **Factory Constructors** - `fromFirestore()`, `fromMap()`
3. **Conversion Methods** - `toMap()`, `toUpdateMap()`
4. **Validation** - Méthodes statiques de validation
5. **Copy Methods** - `copyWith()` pour modifications
6. **Equality** - Override `==` et `hashCode`
7. **String Representation** - Override `toString()`

### **Naming Conventions:**
- Classes: `PascalCase` (ex: `AppUser`)
- Properties: `camelCase` (ex: `lastSeen`)
- Methods: `camelCase` (ex: `isValidEmail`)
- Static Methods: `camelCaseStatic` (ex: `isValidEmailStatic`)

### **File Organization:**
```
lib/models/
├── user.dart          # AppUser model
├── message.dart       # Message model
├── chat_room.dart     # Future: ChatRoom model
├── preferences.dart   # Future: UserPreferences
└── analytics.dart     # Future: Analytics models
```

---

## 📈 **Performance Considerations**

### **Caching Strategy:**
- **AppUser** - Cache local utilisateurs fréquents
- **Message** - Pagination avec limite (50 messages)
- **ChatRoom** - Cache métadonnées conversations

### **Index Requirements:**
- `Users.email` (ascending)
- `Users.username` (ascending)
- `Users.lastSeen` (descending)
- `Messages.timestamp` (ascending)
- Composite: `(Messages.senderID, Messages.timestamp)`

### **Query Optimization:**
- Utiliser `where()` avec index appropriés
- Implémenter pagination avec `startAfter()`
- Limiter résultats avec `limit()`
- Cache first avec `GetOptions(source: Source.cache)`

---

## 🎯 **Summary**

**Current Models:** 2 (AppUser, Message)
**Implicit Structures:** 3 (BlockedUser, Report, ChatRoom)
**Planned Models:** 6 (Enhanced Message, UserPreferences, etc.)

L'architecture actuelle fournit une base solide avec le modèle **AppUser** moderne et typé. Le modèle **Message** nécessite des améliorations pour supporter des fonctionnalités avancées. Les structures implicites sont fonctionnelles mais bénéficieraient de modèles Dart structurés.

**Next Steps:** Créer les modèles Enhanced Message et ChatRoom Settings pour améliorer l'expérience utilisateur.

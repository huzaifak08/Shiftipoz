import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shiftipoz/helpers/constants.dart';
import 'package:shiftipoz/models/chat_model.dart';
import 'package:shiftipoz/models/message_model.dart';
import 'dart:developer' as dev;

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // --- DETERMINISTIC ID HELPER ---
  String getChatId(String uid1, String uid2) {
    dev.log("uid1: $uid1 and uid2: $uid2", name: "ChatService");
    List<String> ids = [uid1, uid2];
    ids.sort();
    dev.log(ids.join('_'), name: "ChatService");
    return ids.join('_');
  }

  // --- STREAMS ---

  Stream<List<ChatModel>> getInbox(String uid) {
    dev.log("📡 [INBOX_SUB] Subscribing for UID: $uid", name: "CHAT_DEBUG");

    return _firestore
        .collection('chats')
        .where('participants', arrayContains: uid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((doc) {
            final data = doc.data();

            // --- UNREAD COUNT DEBUG LOG ---
            // This logs the raw 'unreadCount' field to see if it's a Map or null
            final rawUnread = data['unreadCount'];
            dev.log(
              "📥 [INBOX_RAW] Room: ${doc.id} | unreadCount Field Type: ${rawUnread.runtimeType} | Content: $rawUnread",
              name: "CHAT_DEBUG",
            );

            // Check if there are "flat" fields with dots (e.g., unreadCount.UID)
            // that shouldn't be there if using nested Maps correctly.
            data.forEach((key, value) {
              if (key.contains('unreadCount.')) {
                dev.log(
                  "⚠️ [INBOX_WARNING] Found FLAT field: $key = $value. This should be INSIDE the unreadCount map!",
                  name: "CHAT_DEBUG",
                );
              }
            });

            return ChatModel.fromJson(data, doc.id);
          }).toList(),
        );
  }

  Stream<List<MessageModel>> getMessages(String chatId) {
    dev.log("📡 [MSG_SUB] Room: $chatId", name: "CHAT_DEBUG");
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) {
          dev.log(
            "📩 [MSG_DATA] New snapshot! Count: ${snap.docs.length}",
            name: "CHAT_DEBUG",
          );
          return snap.docs.map((doc) {
            final data = doc.data();
            // Crucial: Log timestamp to see if it's null (causing parsing error)
            dev.log(
              "💬 Msg: ${doc.id} | Content: ${data['content']} | Timestamp: ${data['timestamp']}",
              name: "CHAT_DEBUG",
            );
            return MessageModel.fromJson(data);
          }).toList();
        })
        .handleError((error) {
          dev.log(
            "❌ [MSG_STREAM_ERROR] Room $chatId: $error",
            name: "CHAT_DEBUG",
            error: error,
          );
        });
  }

  // --- CHAT ACTIONS ---

  // Inside ChatService.sendMessage
  /// Send a message and update the parent Chat document (Inbox Metadata)
  Future<void> sendMessage({
    required String chatId,
    required MessageModel message,
    required String receiverId,
    Map<String, dynamic>? productContext,
  }) async {
    dev.log(
      "🚀 [SEND_INIT] To: $receiverId | ChatID: $chatId",
      name: "CHAT_DEBUG",
    );

    try {
      final chatRef = _firestore.collection('chats').doc(chatId);
      final messageRef = chatRef.collection('messages').doc();

      // Assign the generated Firestore ID to the message model
      final finalMessage = message.copyWith(id: messageRef.id);
      final messageData = finalMessage.toJson();

      dev.log("📦 [SEND_PAYLOAD] Message: $messageData", name: "CHAT_DEBUG");

      WriteBatch batch = _firestore.batch();

      // 1. Set the message document in the sub-collection
      batch.set(messageRef, messageData);

      // 2. Prepare the metadata update for the Inbox
      // Using dot notation here with batch.update ensures we target the nested Map
      final Map<String, dynamic> chatMetadata = {
        'lastMessage': {
          'text': message.type == MessageType.text
              ? message.content
              : "[Media]",
          'senderId': message.senderId,
          'timestamp': FieldValue.serverTimestamp(),
        },
        'updatedAt': FieldValue.serverTimestamp(),
        'unreadCount.$receiverId': FieldValue.increment(
          1,
        ), // Increments receiver's counter
        'activeProductContext': productContext,
        'participants': FieldValue.arrayUnion([message.senderId, receiverId]),
      };

      dev.log(
        "📝 [SEND_METADATA] Updating Inbox Metadata via batch.update",
        name: "CHAT_DEBUG",
      );

      // We use update() to ensure unreadCount is treated as a Map path
      batch.update(chatRef, chatMetadata);

      await batch.commit();
      dev.log(
        "✅ [SEND_SUCCESS] Batch committed successfully.",
        name: "CHAT_DEBUG",
      );
    } on FirebaseException catch (e) {
      // Handle cases where the chat document doesn't exist yet (First Message)
      if (e.code == 'not-found') {
        dev.log(
          "🆕 [SEND_NEW] Room doesn't exist. Creating new chat document...",
          name: "CHAT_DEBUG",
        );

        await _firestore.collection('chats').doc(chatId).set({
          'participants': [message.senderId, receiverId],
          'unreadCount': {receiverId: 1, message.senderId: 0},
          'lastMessage': {
            'text': message.type == MessageType.text
                ? message.content
                : "[Media]",
            'senderId': message.senderId,
            'timestamp': FieldValue.serverTimestamp(),
          },
          'updatedAt': FieldValue.serverTimestamp(),
          'activeProductContext': productContext,
        }, SetOptions(merge: true));
      } else {
        dev.log(
          "❌ [SEND_ERROR] Firebase error: ${e.message}",
          name: "CHAT_DEBUG",
          error: e,
        );
        rethrow;
      }
    } catch (e) {
      dev.log("❌ [SEND_ERROR] Unknown error", name: "CHAT_DEBUG", error: e);
      rethrow;
    }
  }

  Future<void> markAsRead(
    String chatId,
    String uid,
    String lastMessageId,
  ) async {
    try {
      dev.log(
        "📖 [READ_UPDATE] Chat: $chatId | User: $uid | Msg: $lastMessageId",
        name: "CHAT_DEBUG",
      );
      await _firestore.collection('chats').doc(chatId).update({
        'lastSeenMessageId.$uid': lastMessageId,
        'unreadCount.$uid': 0,
      });
    } catch (e) {
      dev.log("⚠️ [READ_ERROR] $e", name: "CHAT_DEBUG");
    }
  }

  Future<void> setTypingStatus(String chatId, String uid, bool isTyping) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'isTyping.$uid': isTyping,
      });
    } catch (e) {
      dev.log("⚠️ [TYPING_ERROR] $e", name: "CHAT_DEBUG");
    }
  }

  // --- MEDIA ---

  Future<String> uploadChatMedia(
    File file,
    String chatId,
    MessageType type,
  ) async {
    dev.log("☁️ [UPLOAD_START] Type: ${type.name}", name: "CHAT_DEBUG");
    try {
      final ext = type == MessageType.audio ? 'm4a' : 'jpg';
      final ref = _storage.ref().child(
        'chats/$chatId/${DateTime.now().millisecondsSinceEpoch}.$ext',
      );

      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      String url = await snapshot.ref.getDownloadURL();

      dev.log("✅ [UPLOAD_URL] $url", name: "CHAT_DEBUG");
      return url;
    } catch (e) {
      dev.log("❌ [UPLOAD_ERROR]", name: "CHAT_DEBUG", error: e);
      rethrow;
    }
  }

  // --- PRESENCE ---
  Future<void> updateUserOnlineStatus(String uid, bool isOnline) async {
    try {
      dev.log(
        "👤 [STATUS_UPDATE] User: $uid | Online: $isOnline",
        name: "CHAT_DEBUG",
      );
      await _firestore.collection('users').doc(uid).update({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      dev.log("⚠️ [STATUS_ERROR] $e", name: "CHAT_DEBUG");
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String id;
  final List<String> participants;
  final Map<String, dynamic>? lastMessage;
  final Map<String, int> unreadCount;
  final Map<String, String> lastSeenMessageId;
  final Map<String, bool> isTyping;
  final Map<String, dynamic>? activeProductContext;
  final DateTime updatedAt;

  ChatModel({
    required this.id,
    required this.participants,
    this.lastMessage,
    required this.unreadCount,
    required this.lastSeenMessageId,
    required this.isTyping,
    this.activeProductContext,
    required this.updatedAt,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json, String docId) {
    final rawUnreadMap = json['unreadCount'];
    Map<String, int> parsedUnread = {};

    if (rawUnreadMap is Map) {
      rawUnreadMap.forEach((key, value) {
        // Ensure we convert any number type from Firestore to int
        parsedUnread[key.toString()] = (value is num) ? value.toInt() : 0;
      });
    }

    return ChatModel(
      id: docId,
      participants: List<String>.from(json['participants'] ?? []),
      lastMessage: json['lastMessage'],
      unreadCount: parsedUnread,
      lastSeenMessageId: Map<String, String>.from(
        json['lastSeenMessageId'] ?? {},
      ),
      activeProductContext: json['activeProductContext'],
      isTyping: Map<String, bool>.from(json['isTyping'] ?? {}),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // --- To JSON (Firestore) ---
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'participants': participants,
      'lastMessage': lastMessage,
      'unreadCount': unreadCount,
      'lastSeenMessageId': lastSeenMessageId,
      'isTyping': isTyping,
      'activeProductContext': activeProductContext,
      'updatedAt':
          FieldValue.serverTimestamp(), // Always use server time for sorting
    };
  }

  // --- CopyWith ---
  ChatModel copyWith({
    String? id,
    List<String>? participants,
    Map<String, dynamic>? lastMessage,
    Map<String, int>? unreadCount,
    Map<String, String>? lastSeenMessageId,
    Map<String, bool>? isTyping,
    Map<String, dynamic>? activeProductContext,
    DateTime? updatedAt,
  }) {
    return ChatModel(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      lastSeenMessageId: lastSeenMessageId ?? this.lastSeenMessageId,
      isTyping: isTyping ?? this.isTyping,
      activeProductContext: activeProductContext ?? this.activeProductContext,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

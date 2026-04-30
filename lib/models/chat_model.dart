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

  // --- From JSON (Firestore) ---
  factory ChatModel.fromJson(Map<String, dynamic> json, String docId) {
    return ChatModel(
      id: docId, // <--- Ensure the document ID is assigned here
      participants: List<String>.from(json['participants'] ?? []),
      lastMessage: json['lastMessage'],
      unreadCount: Map<String, int>.from(json['unreadCount'] ?? {}),
      lastSeenMessageId: Map<String, String>.from(
        json['lastSeenMessageId'] ?? {},
      ),
      isTyping: Map<String, bool>.from(json['isTyping'] ?? {}),
      activeProductContext: json['activeProductContext'],
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

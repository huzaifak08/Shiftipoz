import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shiftipoz/helpers/constants.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String content; // Text, or URL for Image/Audio
  final DateTime timestamp;
  final MessageType type;

  // Metadata holds extras like audio duration, image dimensions, or product details
  final Map<String, dynamic>? metadata;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.content,
    required this.timestamp,
    required this.type,
    this.metadata,
  });

  // --- From JSON (Firestore) ---
  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] ?? '',
      senderId: json['senderId'] ?? '',
      content: json['content'] ?? '',
      timestamp: (json['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: MessageType.values.firstWhere(
        (e) => e.name == (json['type'] ?? 'text'),
        orElse: () => MessageType.text,
      ),
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
    );
  }

  // --- To JSON (Firestore) ---
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'content': content,
      // Use FieldValue.serverTimestamp() when sending to Firestore
      'timestamp': Timestamp.fromDate(timestamp),
      'type': type.name,
      'metadata': metadata,
    };
  }

  // --- CopyWith ---
  MessageModel copyWith({
    String? id,
    String? senderId,
    String? content,
    DateTime? timestamp,
    MessageType? type,
    Map<String, dynamic>? metadata,
  }) {
    return MessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      metadata: metadata ?? this.metadata,
    );
  }
}

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String password;
  final String profilePic;
  final DateTime createdAt;

  // 🔐 Verification Flag
  final bool isEmailVerified;

  // 🔁 Sync fields (LOCAL ONLY)
  final bool isSynced;
  final DateTime? lastSyncAttempt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.password,
    required this.profilePic,
    required this.createdAt,
    required this.isEmailVerified, // New required field
    required this.isSynced,
    this.lastSyncAttempt,
  });

  // ===================== copyWith =====================
  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? password,
    String? profilePic,
    DateTime? createdAt,
    bool? isEmailVerified,
    bool? isSynced,
    DateTime? lastSyncAttempt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      profilePic: profilePic ?? this.profilePic,
      createdAt: createdAt ?? this.createdAt,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isSynced: isSynced ?? this.isSynced,
      lastSyncAttempt: lastSyncAttempt ?? this.lastSyncAttempt,
    );
  }

  // ===================== FIRESTORE =====================
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'password': password,
      'profilePic': profilePic,
      'isEmailVerified': isEmailVerified, // Save status to cloud
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      password: map['password'] ?? '',
      profilePic: map['profilePic'] ?? '',
      isEmailVerified:
          map['isEmailVerified'] ?? false, // Load status from cloud
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      isSynced: true,
      lastSyncAttempt: null,
    );
  }

  // ===================== LOCAL DB (CACHE) =====================
  Map<String, dynamic> toJsonDb() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'password': password,
      'profilePic': profilePic,
      'isEmailVerified': isEmailVerified ? 1 : 0, // SQLite friendly
      'createdAt': createdAt.toIso8601String(),
      'isSynced': isSynced ? 1 : 0,
      'lastSyncAttempt': lastSyncAttempt?.toIso8601String(),
    };
  }

  factory UserModel.fromJsonDb(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      password: json['password'] ?? '',
      isEmailVerified: (json['isEmailVerified'] ?? 0) == 1,
      profilePic: json['profilePic'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      isSynced: (json['isSynced'] ?? 0) == 1,
      lastSyncAttempt: json['lastSyncAttempt'] != null
          ? DateTime.parse(json['lastSyncAttempt'])
          : null,
    );
  }

  // ===================== JSON HELPERS =====================
  String toJson() => json.encode(toJsonDb());

  factory UserModel.fromJson(String source) =>
      UserModel.fromJsonDb(json.decode(source));
}

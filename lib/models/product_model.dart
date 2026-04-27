import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shiftipoz/helpers/constants.dart';
import 'package:shiftipoz/models/location_data.dart';
import 'package:shiftipoz/models/price_details.dart';

// Enum Extensions for easy Mapping
extension TransactionTypeX on TransactionType {
  String toMap() => name;
  static TransactionType fromMap(String name) =>
      TransactionType.values.byName(name);
}

extension CategoryTypeX on CategoryType {
  String toMap() => name;
  static CategoryType fromMap(String name) => CategoryType.values.byName(name);
}

class ProductModel {
  final String id;
  final String ownerId;
  final String title;
  final String description;
  final List<String> images;
  final CategoryType categoryType;
  final TransactionType transactionType;
  final PriceDetails priceDetails;
  final LocationData locationData;
  final Map<String, dynamic> metadata;
  final bool isAvailable;
  final DateTime createdAt;

  // 🔁 Sync fields (LOCAL ONLY)
  final bool isSynced;
  final DateTime? lastSyncAttempt;

  ProductModel({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.description,
    required this.images,
    required this.categoryType,
    required this.transactionType,
    required this.priceDetails,
    required this.locationData,
    required this.metadata,
    required this.isAvailable,
    required this.createdAt,
    required this.isSynced,
    this.lastSyncAttempt,
  });

  ProductModel copyWith({
    String? id,
    String? ownerId,
    String? title,
    String? description,
    List<String>? images,
    CategoryType? categoryType,
    TransactionType? transactionType,
    PriceDetails? priceDetails,
    LocationData? locationData,
    Map<String, dynamic>? metadata,
    bool? isAvailable,
    DateTime? createdAt,
    bool? isSynced,
    DateTime? lastSyncAttempt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      title: title ?? this.title,
      description: description ?? this.description,
      images: images ?? this.images,
      categoryType: categoryType ?? this.categoryType,
      transactionType: transactionType ?? this.transactionType,
      priceDetails: priceDetails ?? this.priceDetails,
      locationData: locationData ?? this.locationData,
      metadata: metadata ?? this.metadata,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
      lastSyncAttempt: lastSyncAttempt ?? this.lastSyncAttempt,
    );
  }

  // ===================== FIRESTORE =====================
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerId': ownerId,
      'title': title,
      'description': description,
      'images': images,
      'categoryType': categoryType.toMap(), // Saves as String
      'transactionType': transactionType.toMap(), // Saves as String
      'priceDetails': priceDetails.toMap(),
      'locationData': locationData.toMap(),
      'metadata': metadata,
      'isAvailable': isAvailable,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] ?? '',
      ownerId: map['ownerId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      images: List<String>.from(map['images'] ?? []),
      categoryType: CategoryTypeX.fromMap(map['categoryType'] ?? 'books'),
      transactionType: TransactionTypeX.fromMap(
        map['transactionType'] ?? 'giveaway',
      ),
      priceDetails: PriceDetails.fromMap(map['priceDetails'] ?? {}),
      locationData: LocationData.fromMap(map['locationData'] ?? {}),
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
      isAvailable: map['isAvailable'] ?? false,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      isSynced: true,
      lastSyncAttempt: null,
    );
  }

  // ===================== LOCAL DB (JSON) =====================
  String toJson() => json.encode(toMapForDb());

  Map<String, dynamic> toMapForDb() {
    var map = toMap();
    map['isSynced'] = isSynced ? 1 : 0;
    map['createdAt'] = createdAt.toIso8601String();
    return map;
  }
}

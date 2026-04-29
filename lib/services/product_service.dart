import 'dart:io';
import 'dart:developer' as dev;
import 'package:cloud_firestore/cloud_firestore.dart' hide GeoPoint;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_geo_hash/flutter_geo_hash.dart';
import 'package:shiftipoz/helpers/app_data.dart';
import 'package:shiftipoz/helpers/constants.dart';
import 'package:shiftipoz/models/product_model.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Inside ProductService
  Future<List<ProductModel>> fetchProductsByLocation({
    required String userGeohash,
    required int precision,
    DocumentSnapshot? lastDoc,
    bool isGlobal = false, // Add this
  }) async {
    try {
      var query = _firestore
          .collection(productsCollection)
          .where('isAvailable', isEqualTo: true);

      if (isGlobal) {
        // 🌍 Global Search: Just order by newest
        dev.log(
          "🌎 GLOBAL SEARCH: Fetching newest items worldwide",
          name: "ProductService",
        );
        query = query.orderBy('createdAt', descending: true);
      } else {
        // 📍 Proximity Search
        final int safeLength = precision > userGeohash.length
            ? userGeohash.length
            : precision;
        final String searchPrefix = userGeohash.substring(0, safeLength);
        final String endPrefix = '$searchPrefix~';

        dev.log("🔎 PROXIMITY: Prefix [$searchPrefix]", name: "ProductService");
        query = query
            .where('locationData.geohash', isGreaterThanOrEqualTo: searchPrefix)
            .where('locationData.geohash', isLessThanOrEqualTo: endPrefix)
            .orderBy('locationData.geohash');
      }

      query = query.limit(10);
      if (lastDoc != null) query = query.startAfterDocument(lastDoc);

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => ProductModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      dev.log("ProductService Error: $e");
      return [];
    }
  }

  /// --- Search Products by Title ---

  Future<List<ProductModel>> searchProductsByTitle({
    required String titleQuery,
    DocumentSnapshot? lastDoc,
  }) async {
    try {
      final List<String> terms = titleQuery
          .toLowerCase()
          .trim()
          .split(' ')
          .where((t) => t.isNotEmpty)
          .toList();

      if (terms.isEmpty) return [];

      // Use the LAST word for the database query to allow partial matching as they type
      // Example: "test bo" -> query Firestore for "bo"
      final String activeTerm = terms.last;

      var query = _firestore
          .collection(productsCollection)
          .where('searchTags', arrayContains: activeTerm)
          .where('isAvailable', isEqualTo: true)
          .limit(20);

      if (lastDoc != null) query = query.startAfterDocument(lastDoc);

      final snapshot = await query.get();

      var results = snapshot.docs
          .map((doc) => ProductModel.fromMap(doc.data()))
          .where((product) {
            final tags = product.searchTags ?? [];
            // Ensure the product matches ALL full words typed so far
            return terms.every((term) => tags.contains(term));
          })
          .toList();

      return results;
    } catch (e) {
      return [];
    }
  }

  /// Fetches products specifically uploaded by the current user
  Future<List<ProductModel>> fetchMyProducts({
    required String userId,
    DocumentSnapshot? lastDoc,
  }) async {
    try {
      dev.log(
        "📦 Fetching own products for UID: $userId",
        name: "ProductService",
      );

      var query = _firestore
          .collection(productsCollection)
          .where('ownerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true) // Show newest first
          .limit(10);

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        return ProductModel.fromMap(doc.data());
      }).toList();
    } catch (e) {
      dev.log("Error fetching personal products: $e", name: "ProductService");
      rethrow;
    }
  }

  /// Updates an existing product, handles new image uploads and old image deletions
  Future<void> updateProduct(ProductModel product, List<File> newImages) async {
    try {
      dev.log("🔄 Updating product: ${product.id}", name: "ProductService");

      List<String> finalImageUrls = List.from(product.images);

      // 1. Upload new images if any
      if (newImages.isNotEmpty) {
        for (File image in newImages) {
          String fileName = DateTime.now().millisecondsSinceEpoch.toString();
          Reference ref = _storage
              .ref()
              .child('products')
              .child(product.id)
              .child(fileName);

          await ref.putFile(image);
          String url = await ref.getDownloadURL();
          finalImageUrls.add(url);
        }
      }

      // 2. Prepare the data for Firestore
      // We update the search tags as well in case the title changed
      final List<String> tags = product.title.toLowerCase().split(' ');

      final Map<String, dynamic> updateData = {
        'title': product.title,
        'description': product.description,
        'images': finalImageUrls,
        'searchTags': tags,
        'categoryType': product.categoryType.name,
        'transactionType': product.transactionType.name,
        'priceDetails': {
          'value': product.priceDetails.value,
          'period': product.priceDetails.period,
          'securityDeposit': product.priceDetails.securityDeposit,
          'isFree': product.priceDetails.isFree,
        },
        'metadata': product.metadata,
        'isAvailable': product.isAvailable,
        // Note: We typically don't update ownerId or createdAt during an edit
      };

      // 3. Update Firestore document
      await _firestore
          .collection(productsCollection)
          .doc(product.id)
          .update(updateData);

      dev.log("✅ Product updated successfully", name: "ProductService");
    } catch (e) {
      dev.log("❌ Error updating product: $e", name: "ProductService");
      rethrow;
    }
  }

  /// --- 1. Multi-Image Upload ---
  /// Uploads a list of files and returns a list of download URLs
  Future<List<String>> uploadProductImages({
    required String productId,
    required List<File> images,
  }) async {
    List<String> downloadUrls = [];

    try {
      for (int i = 0; i < images.length; i++) {
        final ref = _storage
            .ref()
            .child('products')
            .child(productId)
            .child('image_$i.jpg');

        final uploadTask = await ref.putFile(images[i]);
        final url = await uploadTask.ref.getDownloadURL();
        downloadUrls.add(url);
      }
      return downloadUrls;
    } catch (e) {
      dev.log("ProductService: Image Upload Failed: $e");
      throw Exception("Failed to upload product images");
    }
  }

  /// --- 2. Save Product to Firestore ---
  /// This is the core method to "Shift" a new product into the database
  /// --- Improved Save Product ---
  /// We pass the 'base' model and the 'files' separately.
  Future<void> saveProduct(ProductModel product, List<File> imageFiles) async {
    try {
      // 1. Service manages the IDs and Timestamps to ensure they are valid
      final String productId = AppData.shared.uuid.v4();

      // 2. Service handles the conversion of Files -> URLs
      final imageUrls = await uploadProductImages(
        productId: productId,
        images: imageFiles,
      );

      // 3. Service generates the Geohash (so the UI doesn't have to)
      final geoPoint = GeoPoint(
        product.locationData.latitude,
        product.locationData.longitude,
      );

      final isValid = AppData.shared.geoHash.validateLocation(geoPoint);
      dev.log("Validate Location: $isValid");

      final String hash = AppData.shared.geoHash.geoHashForLocation(
        geoPoint,
        precision: 8,
      );

      dev.log("Product Hash: $hash");

      final searchTags = _generateSearchTags(product.title);

      dev.log("Seach Tags: $searchTags");

      // 4. Create the 'Final' immutable model for Firestore
      final finalProduct = product.copyWith(
        id: productId,
        images: imageUrls,
        createdAt: DateTime.now(),
        locationData: product.locationData.copyWith(geohash: hash),
        searchTags: searchTags,
        isSynced: true,
      );

      await _firestore
          .collection(productsCollection)
          .doc(finalProduct.id)
          .set(finalProduct.toMap());
    } catch (e) {
      dev.log("Save Failed: $e");
      throw Exception("Process failed: $e");
    }
  }

  /// --- 3. Fetch Single Product ---
  Future<ProductModel?> getProduct(String id) async {
    final doc = await _firestore.collection(productsCollection).doc(id).get();
    if (doc.exists && doc.data() != null) {
      return ProductModel.fromMap(doc.data()!);
    }
    return null;
  }

  /// Deletes a product document and all its associated images from storage
  Future<void> deleteProduct(String productId, List<String> imageUrls) async {
    try {
      dev.log(
        "🗑️ Deleting product and images: $productId",
        name: "ProductService",
      );

      // 1. Delete all images in parallel for better performance
      if (imageUrls.isNotEmpty) {
        await Future.wait(
          imageUrls.map((url) async {
            try {
              final ref = _storage.refFromURL(url);
              await ref.delete();
            } catch (e) {
              // Log but continue—we don't want a missing image to block document deletion
              dev.log(
                "⚠️ Storage deletion skipped/failed: $e",
                name: "ProductService",
              );
            }
          }),
        );
      }

      // 2. Delete the Firestore Document
      await _firestore.collection(productsCollection).doc(productId).delete();

      dev.log("✅ Deletion complete.", name: "ProductService");
    } catch (e) {
      dev.log("❌ Fatal error during deletion: $e", name: "ProductService");
      rethrow;
    }
  }

  List<String> _generateSearchTags(String title) {
    final List<String> tags = [];
    final List<String> words = title
        .toLowerCase()
        .trim()
        .split(' ')
        .where((w) => w.isNotEmpty)
        .toList();

    for (var word in words) {
      String cumulative = '';
      for (var char in word.characters) {
        cumulative += char;
        if (!tags.contains(cumulative)) {
          tags.add(cumulative);
        }
      }
    }
    return tags;
  }
}

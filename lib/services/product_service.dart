import 'dart:io';
import 'dart:developer' as dev;
import 'package:cloud_firestore/cloud_firestore.dart' hide GeoPoint;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_geo_hash/flutter_geo_hash.dart';
import 'package:shiftipoz/helpers/app_data.dart';
import 'package:shiftipoz/helpers/constants.dart';
import 'package:shiftipoz/models/product_model.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

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

      // 4. Create the 'Final' immutable model for Firestore
      final finalProduct = product.copyWith(
        id: productId,
        images: imageUrls,
        createdAt: DateTime.now(),
        locationData: product.locationData.copyWith(geohash: hash),
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
}

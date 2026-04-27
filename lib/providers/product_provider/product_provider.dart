import 'dart:io';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shiftipoz/helpers/constants.dart';
import 'package:shiftipoz/models/product_model.dart';
import 'package:shiftipoz/services/product_service.dart';
import 'dart:developer' as dev;

part 'product_provider.g.dart';

@Riverpod(keepAlive: true)
class ProductNotifier extends _$ProductNotifier {
  final ProductService _productService = ProductService();

  @override
  FutureOr<List<ProductModel>> build() async {
    // By default, fetch the most recent products (Near Me logic comes next)
    return await fetchProducts();
  }

  /// --- Fetch Logic ---
  Future<List<ProductModel>> fetchProducts({CategoryType? category}) async {
    try {
      // In a real-world scenario, we'd add Firestore query logic here.
      // For now, let's assume we're fetching the global feed.
      // We will implement the Geoflutterfire query here in the next step.

      // Placeholder for actual Firestore fetch
      return [];
    } catch (e, st) {
      dev.log("ProductProvider: Error fetching products: $e");
      state = AsyncValue.error(e, st);
      return [];
    }
  }

  /// --- Add Product ---
  /// This bridges the UI and the Service
  Future<void> addProduct(ProductModel draftProduct, List<File> images) async {
    // 1. Set global loading so the 'Add' button shows a spinner
    state = const AsyncValue.loading();

    try {
      // 2. Call the service to handle uploads and DB writes
      await _productService.saveProduct(draftProduct, images);

      // 3. Refresh the local list so the new product appears on the Home Screen
      ref.invalidateSelf();

      dev.log("ProductProvider: Product added and state refreshed");
    } catch (e, st) {
      dev.log("ProductProvider: Failed to add product: $e");
      state = AsyncValue.error(e, st);
      rethrow; // So the UI can show a SnackBar
    }
  }

  /// --- Delete Product ---
  Future<void> removeProduct(String productId) async {
    // Logic to delete from Firestore and update local state
    // Note: Don't forget to delete images from Firebase Storage too!
  }
}

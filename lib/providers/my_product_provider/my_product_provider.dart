import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shiftipoz/models/product_model.dart';
import 'package:shiftipoz/providers/product_provider/product_provider.dart';
import 'package:shiftipoz/services/product_service.dart';
import 'package:shiftipoz/providers/auth_provider/auth_provider.dart';
import 'dart:developer' as dev;

part 'my_product_provider.g.dart';

@Riverpod(keepAlive: true)
class MyProductsNotifier extends _$MyProductsNotifier {
  final ProductService _productService = ProductService();
  DocumentSnapshot? _lastDocument;
  bool _isFetching = false;

  @override
  FutureOr<List<ProductModel>> build() async {
    // 🚀 Reactive Kill Switch:
    // If user logs out, this list is automatically cleared.
    final authState = ref.watch(authControllerProvider);

    final user = authState.value;
    if (user == null) return [];

    return await fetchMyProducts();
  }

  Future<List<ProductModel>> fetchMyProducts() async {
    final user = ref.read(authControllerProvider).value;
    if (user == null) return [];

    state = const AsyncValue.loading();
    _lastDocument = null;

    try {
      final results = await _productService.fetchMyProducts(userId: user.uid);
      state = AsyncValue.data(results);
      return results;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return [];
    }
  }

  Future<void> loadMore() async {
    final user = ref.read(authControllerProvider).value;
    if (user == null || _isFetching) return;
    _isFetching = true;

    try {
      final moreItems = await _productService.fetchMyProducts(
        userId: user.uid,
        lastDoc: _lastDocument,
      );

      final currentList = state.value ?? [];
      state = AsyncValue.data([...currentList, ...moreItems]);
    } catch (e) {
      dev.log("MyProducts LoadMore Error: $e");
    } finally {
      _isFetching = false;
    }
  }

  /// --- Edit Product ---
  Future<void> editProduct(
    ProductModel updatedProduct,
    List<File> newImages,
  ) async {
    // 1. Capture the current state before attempting the update
    final previousState = state;

    try {
      // Optional: You can set a loading state here if you want a spinner
      // state = const AsyncValue.loading();

      // 2. Call the service to handle Firebase Storage uploads and Firestore updates
      await _productService.updateProduct(updatedProduct, newImages);

      // 3. If successful, refresh the providers to get the new image URLs
      // and updated metadata from the Cloud.
      ref.invalidateSelf();
      ref.invalidate(productProvider);

      dev.log(
        "✅ MyProductsProvider: Product updated successfully",
        name: "MyProductsProvider",
      );
    } catch (e) {
      dev.log("❌ Error in editProduct: $e", name: "MyProductsProvider");

      // 4. USE previousState: Restore the old data so the UI doesn't
      // look broken or empty after a failed network call.
      state = previousState;

      // Rethrow so the UI can show a SnackBar/Alert to the user
      rethrow;
    }
  }

  /// --- Delete Product ---
  Future<void> removeProduct(ProductModel product) async {
    // Store the current state in case we need to roll back
    final previousState = state;

    try {
      // 1. Optimistic UI Update: Remove it from the list immediately
      if (state.hasValue) {
        final updatedList = state.value!
            .where((p) => p.id != product.id)
            .toList();
        state = AsyncValue.data(updatedList);
      }

      // 2. Perform the actual Cloud Deletion
      await _productService.deleteProduct(product.id, product.images);

      // 3. Invalidate the global Marketplace so the item disappears there too
      ref.invalidate(productProvider);

      dev.log(
        "✅ Provider: Product removed successfully.",
        name: "MyProductsProvider",
      );
    } catch (e) {
      dev.log(
        "❌ Provider: Deletion failed, rolling back.",
        name: "MyProductsProvider",
      );

      // 4. Rollback: If Cloud deletion fails, put the item back in the list
      state = previousState;

      // Rethrow to let the UI show a SnackBar error
      rethrow;
    }
  }
}

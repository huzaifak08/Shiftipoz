import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shiftipoz/models/product_model.dart';
import 'package:shiftipoz/services/product_service.dart';
import 'dart:developer' as dev;

part 'product_provider.g.dart';

@Riverpod(keepAlive: true)
class ProductNotifier extends _$ProductNotifier {
  final ProductService _productService = ProductService();

  // Internal tracking
  DocumentSnapshot? _lastDocument;
  int _currentPrecision = 6;
  bool _isFetching = false;
  final Set<String> _shownIds = {};

  @override
  FutureOr<List<ProductModel>> build() async {
    // By default, fetch the most recent products (Near Me logic comes next)
    return await fetchInitialProducts();
  }

  // Inside ProductNotifier
  Future<List<ProductModel>> fetchInitialProducts({String? query}) async {
    _shownIds.clear();
    _lastDocument = null;
    _currentPrecision = 6;

    // Get actual hash from your location service
    final String userHash = "u36";
    List<ProductModel> results = [];

    if (query != null && query.isNotEmpty) {
      results = await _productService.searchProductsByTitle(titleQuery: query);
    } else {
      // --- THE EXPANSION LOOP ---
      while (results.length < 10) {
        final newBatch = await _productService.fetchProductsByLocation(
          userGeohash: userHash,
          precision: _currentPrecision,
          lastDoc: _lastDocument,
          isGlobal: _currentPrecision == 0, // New flag for global search
        );

        for (var item in newBatch) {
          if (!_shownIds.contains(item.id)) {
            results.add(item);
            _shownIds.add(item.id);
          }
        }

        if (results.length < 10) {
          if (_currentPrecision > 2) {
            _currentPrecision -= 2;
            _lastDocument = null;
          } else if (_currentPrecision == 2) {
            // 🌍 FINAL FRONTIER: If we still don't have 10, go Global
            _currentPrecision = 0;
            _lastDocument = null;
          } else {
            break; // Already at global level
          }
        } else {
          break;
        }
      }
    }
    state = AsyncValue.data(results);
    return results;
  }

  /// --- 2. The "Expanding Horizon" Logic (Load More) ---
  Future<void> loadMore({String? query}) async {
    if (_isFetching) return;
    _isFetching = true;

    try {
      const String userHash = "u36v";
      List<ProductModel> newItems = [];

      // 1. Fetch the next batch from the CURRENT horizon level
      newItems = await _productService.fetchProductsByLocation(
        userGeohash: userHash,
        precision: _currentPrecision,
        lastDoc: _lastDocument,
        isGlobal: _currentPrecision == 0, // Are we in global mode?
      );

      // 2. The "Horizon Jump" check
      // If the batch is empty or small, and we haven't hit Global (0) yet
      if (newItems.length < 10 && _currentPrecision > 0) {
        dev.log(
          "Horizon reached end. Expanding level...",
          name: "ProductProvider",
        );

        // Move to next level (6 -> 4 -> 2 -> 0)
        if (_currentPrecision > 2) {
          _currentPrecision -= 2;
        } else {
          _currentPrecision = 0; // The World
        }

        _lastDocument = null; // Reset pagination for the new, wider query

        // Recursive call to fill the 10-item quota
        await loadMore(query: query);
        return;
      }

      // 3. Update the UI with only the next 10 items
      _updateStateWithResults(newItems, isLoadMore: true);
    } catch (e) {
      dev.log("Load More Error: $e");
    } finally {
      _isFetching = false;
    }
  }

  /// --- Helper: Clean duplicates and update state ---
  void _updateStateWithResults(
    List<ProductModel> results, {
    bool isLoadMore = false,
  }) {
    // Filter out items the user has already seen in previous rings
    final uniqueResults = results
        .where((p) => !_shownIds.contains(p.id))
        .toList();

    for (var p in uniqueResults) {
      _shownIds.add(p.id);
    }

    if (isLoadMore) {
      final currentList = state.value ?? [];
      state = AsyncData([...currentList, ...uniqueResults]);
    } else {
      state = AsyncData(uniqueResults);
    }

    // Update last document for next pagination trigger
    // Note: This requires getting the snapshot from the service.
    // Usually, we modify fetchProductsByLocation to return a 'Result' object containing the snapshot.
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

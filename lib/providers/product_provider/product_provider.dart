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
    // 1. Reset pagination states
    _shownIds.clear();
    _lastDocument = null;
    _currentPrecision = 6;

    // Show loading for fresh start
    state = const AsyncValue.loading();

    try {
      List<ProductModel> results = [];

      // Check if we are searching or discovering
      final isQueryEmpty = query == null || query.trim().isEmpty;

      if (!isQueryEmpty) {
        // 🔍 SEARCH MODE
        dev.log("🔎 Searching for: $query");
        results = await _productService.searchProductsByTitle(
          titleQuery: query,
        );
      } else {
        // 🌍 DISCOVERY MODE (Your existing expansion loop)
        results = await _fetchDiscoveryBatch();
      }

      // Track IDs to prevent duplicates during "Load More"
      for (var item in results) {
        _shownIds.add(item.id);
      }

      state = AsyncValue.data(results);
      return results;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return [];
    }
  }

  // Refactor the expansion loop into a helper for cleaner code
  Future<List<ProductModel>> _fetchDiscoveryBatch() async {
    List<ProductModel> results = [];
    const String userHash = "u36";

    while (results.length < 10) {
      final newBatch = await _productService.fetchProductsByLocation(
        userGeohash: userHash,
        precision: _currentPrecision,
        lastDoc: _lastDocument,
        isGlobal: _currentPrecision == 0,
      );

      results.addAll(newBatch);

      if (results.length < 10) {
        if (_currentPrecision > 2) {
          _currentPrecision -= 2;
        } else if (_currentPrecision == 2) {
          _currentPrecision = 0;
        } else {
          break; // Max horizon reached
        }
      } else {
        break;
      }
    }
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart'
    show StateNotifier, StateNotifierProvider;

class ProductsUiState {
  final bool isSearching;
  final String searchQuery;
  final bool isLoadingMore;
  final int
  currentHorizonLevel; // 1: Neighborhood, 2: City, 3: Regional, 4: Global

  ProductsUiState({
    this.isSearching = false,
    this.searchQuery = "",
    this.isLoadingMore = false,
    this.currentHorizonLevel = 1,
  });

  ProductsUiState copyWith({
    bool? isSearching,
    String? searchQuery,
    bool? isLoadingMore,
    int? currentHorizonLevel,
  }) {
    return ProductsUiState(
      isSearching: isSearching ?? this.isSearching,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      currentHorizonLevel: currentHorizonLevel ?? this.currentHorizonLevel,
    );
  }
}

class ProductsUiNotifier extends StateNotifier<ProductsUiState> {
  ProductsUiNotifier() : super(ProductsUiState());

  // Controllers for the View to use
  final TextEditingController searchController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  void toggleSearch() {
    if (state.isSearching) searchController.clear();
    state = state.copyWith(isSearching: !state.isSearching, searchQuery: "");
  }

  void updateSearch(String q) {
    state = state.copyWith(searchQuery: q);
  }

  void setLoadingMore(bool loading) {
    state = state.copyWith(isLoadingMore: loading);
  }

  void incrementHorizon() {
    if (state.currentHorizonLevel < 4) {
      state = state.copyWith(
        currentHorizonLevel: state.currentHorizonLevel + 1,
      );
    }
  }

  void resetHorizon() {
    state = state.copyWith(currentHorizonLevel: 1);
  }

  @override
  void dispose() {
    searchController.dispose();
    scrollController.dispose();
    super.dispose();
  }
}

final productsUiProvider =
    StateNotifierProvider<ProductsUiNotifier, ProductsUiState>(
      (ref) => ProductsUiNotifier(),
    );

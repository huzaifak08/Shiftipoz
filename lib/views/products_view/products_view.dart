import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shiftipoz/helpers/constants.dart';
import 'package:shiftipoz/models/product_model.dart';
import 'package:shiftipoz/providers/product_provider/product_provider.dart';
import 'package:shiftipoz/views/add_update_product_view/add_update_product_view.dart';
import 'package:shiftipoz/views/products_view/products_view_model.dart';

class ProductsView extends ConsumerStatefulWidget {
  const ProductsView({super.key});

  @override
  ConsumerState<ProductsView> createState() => _ProductsViewState();
}

class _ProductsViewState extends ConsumerState<ProductsView> {
  @override
  void initState() {
    super.initState();
    // Attach scroll listener to the controller in UI Provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uiNotifier = ref.read(productsUiProvider.notifier);
      uiNotifier.scrollController.addListener(() {
        if (uiNotifier.scrollController.position.pixels >=
            uiNotifier.scrollController.position.maxScrollExtent - 300) {
          _loadMore();
        }
      });
    });
  }

  Future<void> _loadMore() async {
    final uiState = ref.read(productsUiProvider);
    if (!uiState.isLoadingMore) {
      ref.read(productsUiProvider.notifier).setLoadingMore(true);
      await ref
          .read(productProvider.notifier)
          .loadMore(query: uiState.isSearching ? uiState.searchQuery : null);
      ref.read(productsUiProvider.notifier).setLoadingMore(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uiState = ref.watch(productsUiProvider);
    final uiNotifier = ref.read(productsUiProvider.notifier);
    final productsAsync = ref.watch(productProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(productProvider.notifier).fetchInitialProducts(),
        child: CustomScrollView(
          controller: uiNotifier.scrollController,
          slivers: [
            // --- PREMIUM STICKY SEARCH BAR ---
            _buildSliverAppBar(uiState, uiNotifier, theme),

            // --- HORIZON CONTEXT BAR ---
            _buildHorizonHeader(uiState, theme),

            // --- PRODUCT GRID ---
            productsAsync.when(
              data: (products) => products.isEmpty
                  ? const SliverFillRemaining(
                      child: Center(
                        child: Text("Nothing found in this horizon."),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: 0.72,
                            ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) =>
                              _ProductCard(product: products[index]),
                          childCount: products.length,
                        ),
                      ),
                    ),
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) =>
                  SliverFillRemaining(child: Center(child: Text("Error: $e"))),
            ),

            // --- PAGINATION LOADER ---
            if (uiState.isLoadingMore)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(
    ProductsUiState uiState,
    ProductsUiNotifier uiNotifier,
    ThemeData theme,
  ) {
    return SliverAppBar(
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: theme.scaffoldBackgroundColor,
      title: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: uiState.isSearching
            ? TextField(
                key: const ValueKey('searchField'),
                controller: uiNotifier.searchController,
                autofocus: true,
                onChanged: uiNotifier.updateSearch,
                decoration: const InputDecoration(
                  hintText: "Search title...",
                  border: InputBorder.none,
                ),
              )
            : const Text(
                "Shiftipoz",
                style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
              ),
      ),
      actions: [
        IconButton(
          onPressed: uiNotifier.toggleSearch,
          icon: Icon(uiState.isSearching ? Icons.close : Icons.search),
        ),
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AddUpdateProductView()),
            );
          },
          icon: Icon(Icons.add),
        ),
      ],
    );
  }

  Widget _buildHorizonHeader(ProductsUiState uiState, ThemeData theme) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.explore_outlined,
                    size: 14,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "Horizon: Level ${uiState.currentHorizonLevel}",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Image Holder
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    image: DecorationImage(
                      image: NetworkImage(
                        product.images.isNotEmpty
                            ? product.images[0]
                            : 'https://via.placeholder.com/150',
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Transaction Badge
                Positioned(
                  top: 10,
                  left: 10,
                  child: _TypeBadge(type: product.transactionType),
                ),
              ],
            ),
          ),

          // 2. Details
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product.priceDetails.isFree
                      ? "GIVEAWAY"
                      : "${product.priceDetails.value} / ${product.priceDetails.period ?? 'once'}",
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.location_pin, size: 12, color: theme.hintColor),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        product.locationData.cityName,
                        style: TextStyle(color: theme.hintColor, fontSize: 11),
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final TransactionType type;
  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (type) {
      case TransactionType.giveaway:
        color = Colors.green;
        break;
      case TransactionType.rent:
        color = Colors.orange;
        break;
      case TransactionType.sell:
        color = Colors.redAccent;
        break;
      case TransactionType.borrow:
        color = Colors.blue;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8)],
      ),
      child: Text(
        type.name.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

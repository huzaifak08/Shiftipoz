import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shiftipoz/components/custom_loader.dart';
import 'package:shiftipoz/components/product_card.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uiNotifier = ref.read(productsUiProvider.notifier);
      uiNotifier.scrollController.addListener(() {
        if (uiNotifier.scrollController.position.pixels >=
            uiNotifier.scrollController.position.maxScrollExtent - 400) {
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
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () =>
              ref.read(productProvider.notifier).fetchInitialProducts(),
          child: CustomScrollView(
            controller: uiNotifier.scrollController,
            slivers: [
              // 1. BRANDING HEADER
              SliverToBoxAdapter(child: _buildBrandingHeader(theme)),

              // 2. SEARCH BAR (Sticky-ready)
              SliverToBoxAdapter(
                child: _buildSearchBar(uiState, uiNotifier, theme),
              ),

              // 3. CATEGORY SELECTOR (UI ONLY)
              SliverToBoxAdapter(child: _buildCategorySection(theme)),

              // 4. MAIN CONTENT AREA
              productsAsync.when(
                data: (products) {
                  // Check if the search bar actually has text
                  final bool isSearchActive = uiState.searchQuery
                      .trim()
                      .isNotEmpty;

                  // SCENARIO A: Search found nothing
                  if (isSearchActive && products.isEmpty) {
                    return const SliverFillRemaining(
                      child: _NoResultsFoundView(),
                    );
                  }

                  // SCENARIO B: Home screen is empty (No products in the world yet)
                  if (!isSearchActive && products.isEmpty) {
                    return const SliverFillRemaining(child: _EmptyStateView());
                  }

                  // SCENARIO C: Success (Show the grid)
                  return SliverPadding(
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
                            ProductCard(product: products[index]),
                        childCount: products.length,
                      ),
                    ),
                  );
                },
                loading: () => const SliverFillRemaining(child: CustomLoader()),
                error: (e, _) => SliverFillRemaining(
                  child: _ErrorStateView(error: e.toString()),
                ),
              ),

              // 5. PAGINATION SPINNER
              if (uiState.isLoadingMore)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 30),
                    child: Center(child: CustomLoader(size: 120)),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Theme.of(
                context,
              ).colorScheme.secondary.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddUpdateProductView(),
              ),
            );
          },
          // Using a more "Marketplace" friendly icon
          icon: const Icon(Icons.add_rounded, size: 28),
          label: const Text(
            "LIST ITEM",
            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
          ),
          // This uses the theme colors we defined above automatically
        ),
      ),
    );
  }

  Widget _buildBrandingHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        children: [
          SvgPicture.asset('assets/images/logo.svg', height: 40),
          const SizedBox(width: 12),
          Text(
            "SHIFTIPOZ",
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {}, // Notification/Profile placeholder
            icon: Icon(
              Icons.notifications_none_rounded,
              color: theme.hintColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(
    ProductsUiState uiState,
    ProductsUiNotifier uiNotifier,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.3,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
        child: TextField(
          controller: uiNotifier.searchController,
          onChanged: uiNotifier.updateSearch,
          decoration: InputDecoration(
            hintText: "Search books nearby...",
            prefixIcon: Icon(Icons.search, color: theme.colorScheme.primary),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySection(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              "Categories",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _CategoryChip(
                  label: "Books",
                  icon: Icons.menu_book_rounded,
                  isSelected: true,
                  theme: theme,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final ThemeData theme;

  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected
            ? theme.colorScheme.primary
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isSelected
              ? Colors.transparent
              : theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isSelected ? Colors.white : theme.hintColor,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : theme.hintColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyStateView extends StatelessWidget {
  const _EmptyStateView();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.auto_stories_outlined,
          size: 80,
          color: Colors.grey.withValues(alpha: 0.3),
        ),
        const SizedBox(height: 20),
        const Text(
          "The horizon is clear!",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 8),
        const Text(
          "No books found near you yet. Try expanding the horizon.",
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _ErrorStateView extends StatelessWidget {
  final String error;
  const _ErrorStateView({required this.error});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 50, color: Colors.redAccent),
          const SizedBox(height: 20),
          Text(
            "Something went wrong",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _NoResultsFoundView extends StatelessWidget {
  const _NoResultsFoundView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 80,
            color: Colors.grey.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 20),
          const Text(
            "No Matches Found",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text(
            "We couldn't find any books matching that title. Check your spelling or try a different keyword.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

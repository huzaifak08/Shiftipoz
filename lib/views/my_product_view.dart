import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shiftipoz/components/custom_loader.dart';
import 'package:shiftipoz/components/product_card.dart';
import 'package:shiftipoz/models/product_model.dart';
import 'package:shiftipoz/providers/my_product_provider/my_product_provider.dart';

class MyProductView extends ConsumerWidget {
  const MyProductView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final myProductsAsync = ref.watch(myProductsProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () =>
              ref.read(myProductsProvider.notifier).fetchMyProducts(),
          color: theme.colorScheme.primary,
          child: CustomScrollView(
            slivers: [
              // 1. DYNAMIC HEADER
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "MY INVENTORY",
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      myProductsAsync.when(
                        data: (list) => Text(
                          "${list.length} active listings",
                          style: TextStyle(
                            color: theme.hintColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        loading: () => const SizedBox(),
                        error: (_, _) => const SizedBox(),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // 2. PRODUCT GRID
              myProductsAsync.when(
                data: (products) {
                  if (products.isEmpty) {
                    return const SliverFillRemaining(child: _NoInventoryView());
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio:
                                0.65, // Taller to fit management buttons
                          ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                            _ManagementCard(product: products[index]),
                        childCount: products.length,
                      ),
                    ),
                  );
                },
                loading: () => const SliverFillRemaining(child: CustomLoader()),
                error: (e, _) => SliverFillRemaining(
                  child: Center(child: Text("Error: $e")),
                ),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 120),
              ), // Space for Bottom Bar
            ],
          ),
        ),
      ),
    );
  }
}

/// A specialized card that allows users to delete or edit their own items
class _ManagementCard extends ConsumerWidget {
  final ProductModel product;
  const _ManagementCard({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Reusing the beautiful marketplace card look
        Expanded(child: ProductCard(product: product)),
        const SizedBox(height: 8),
        // Management Actions
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                icon: Icons.edit_outlined,
                label: "Edit",
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                textColor: theme.colorScheme.primary,
                onTap: () {
                  // Todo: Navigate to Edit View
                },
              ),
            ),
            const SizedBox(width: 8),
            _ActionButton(
              icon: Icons.delete_outline_rounded,
              label: "",
              color: Colors.redAccent.withValues(alpha: 0.1),
              textColor: Colors.redAccent,
              onTap: () => _confirmDeletion(context, ref),
            ),
          ],
        ),
      ],
    );
  }

  void _confirmDeletion(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Listing?"),
        content: const Text(
          "This action cannot be undone. The product and its images will be permanently removed.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(myProductsProvider.notifier).removeProduct(product);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: textColor),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NoInventoryView extends StatelessWidget {
  const _NoInventoryView();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.inventory_2_outlined,
          size: 80,
          color: Colors.grey.withValues(alpha: 0.2),
        ),
        const SizedBox(height: 20),
        const Text(
          "Your shop is empty",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 8),
        const Text(
          "Items you list for sale will appear here.",
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

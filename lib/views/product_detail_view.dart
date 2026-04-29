import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shiftipoz/models/product_model.dart';
import 'package:shiftipoz/providers/auth_provider/auth_provider.dart';
import 'package:shiftipoz/providers/my_product_provider/my_product_provider.dart';
import 'package:shiftipoz/views/add_update_product_view/add_update_product_view.dart';

class ProductDetailView extends ConsumerStatefulWidget {
  final ProductModel product;
  const ProductDetailView({super.key, required this.product});

  @override
  ConsumerState<ProductDetailView> createState() => _ProductDetailViewState();
}

class _ProductDetailViewState extends ConsumerState<ProductDetailView> {
  int _currentImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authUser = ref.watch(authControllerProvider).value;
    final isOwner = authUser?.uid == widget.product.ownerId;

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // 1. IMAGE GALLERY (HERO)
              SliverAppBar(
                expandedHeight: MediaQuery.of(context).size.height * 0.45,
                pinned: true,
                stretch: true,
                leading: _buildCircleBackButton(context),
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [StretchMode.zoomBackground],
                  background: _buildImageGallery(context),
                ),
              ),

              // 2. PRODUCT INFO
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPriceAndCategory(theme),
                      const SizedBox(height: 12),
                      Text(
                        widget.product.title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildLocationRow(theme),
                      const Divider(height: 40),
                      Text(
                        "Description",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.product.description,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.hintColor,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildSellerInfo(theme),
                      const SizedBox(height: 120), // Bottom padding for buttons
                    ],
                  ),
                ),
              ),
            ],
          ),

          // 3. STICKY BOTTOM ACTIONS
          _buildBottomActions(context, isOwner, theme, widget.product),
        ],
      ),
    );
  }

  Widget _buildImageGallery(BuildContext context) {
    return Stack(
      children: [
        PageView.builder(
          itemCount: widget.product.images.length,
          onPageChanged: (index) => setState(() => _currentImageIndex = index),
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () => _openFullScreenPreview(context, index),
              child: Hero(
                tag: 'details_${DateTime.now().microsecondsSinceEpoch}',
                child: Image.network(
                  widget.product.images[index],
                  fit: BoxFit.cover,
                ),
              ),
            );
          },
        ),
        // Image Indicator
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: widget.product.images.asMap().entries.map((entry) {
              return Container(
                width: _currentImageIndex == entry.key ? 24 : 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.white.withValues(
                    alpha: _currentImageIndex == entry.key ? 0.9 : 0.4,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceAndCategory(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            "BOOKS", // Placeholder for Category
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        Text(
          "Rs. ${widget.product.priceDetails.value}",
          style: theme.textTheme.headlineSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationRow(ThemeData theme) {
    return Row(
      children: [
        Icon(Icons.location_on_outlined, size: 16, color: theme.hintColor),
        const SizedBox(width: 4),
        Text(
          "Wah Cantt, Pakistan", // Dynamically handled later
          style: TextStyle(color: theme.hintColor),
        ),
      ],
    );
  }

  Widget _buildSellerInfo(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Colors.grey,
            child: Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Seller Profile",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                "Member since 2026",
                style: TextStyle(color: theme.hintColor, fontSize: 12),
              ),
            ],
          ),
          const Spacer(),
          TextButton(onPressed: () {}, child: const Text("View Profile")),
        ],
      ),
    );
  }

  Widget _buildBottomActions(
    BuildContext context,
    bool isOwner,
    ThemeData theme,
    ProductModel product,
  ) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 55),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(
              color: theme.colorScheme.outline.withValues(alpha: 0.1),
            ),
          ),
        ),
        child: isOwner
            ? Row(
                children: [
                  Expanded(
                    child: _LargeButton(
                      label: "EDIT ITEM",
                      icon: Icons.edit_outlined,
                      color: theme.colorScheme.secondary,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                AddUpdateProductView(productModel: product),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  _SquareButton(
                    icon: Icons.delete_outline_rounded,
                    color: Colors.redAccent.withValues(alpha: 0.1),
                    iconColor: Colors.redAccent,
                    onTap: () => _handleDelete(context, ref),
                  ),
                ],
              )
            : Row(
                children: [
                  _SquareButton(
                    icon: Icons.chat_bubble_outline_rounded,
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    iconColor: theme.colorScheme.primary,
                    onTap: () {},
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _LargeButton(
                      label: "I'M INTERESTED",
                      icon: Icons.auto_awesome,
                      color: theme.colorScheme.primary,
                      onTap: () {},
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  void _openFullScreenPreview(BuildContext context, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _FullScreenGallery(
          images: widget.product.images,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  Widget _buildCircleBackButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: CircleAvatar(
        backgroundColor: Colors.black26,
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  void _handleDelete(BuildContext context, WidgetRef ref) {
    // Call the removeProduct from MyProductsNotifier we created earlier
    ref.read(myProductsProvider.notifier).removeProduct(widget.product);
    Navigator.pop(context);
  }
}

// --- SUPPORTING UI WIDGETS ---

class _LargeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _LargeButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
    );
  }
}

class _SquareButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  const _SquareButton({
    required this.icon,
    required this.color,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(icon, color: iconColor),
      ),
    );
  }
}

// --- FULL SCREEN PREVIEW VIEW ---

class _FullScreenGallery extends StatelessWidget {
  final List<String> images;
  final int initialIndex;
  const _FullScreenGallery({required this.images, required this.initialIndex});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: PageView.builder(
        controller: PageController(initialPage: initialIndex),
        itemCount: images.length,
        itemBuilder: (context, index) {
          return InteractiveViewer(
            child: Center(
              child: Image.network(images[index], fit: BoxFit.contain),
            ),
          );
        },
      ),
    );
  }
}

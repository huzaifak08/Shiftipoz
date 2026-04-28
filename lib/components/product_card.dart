import 'package:flutter/material.dart';
import 'package:shiftipoz/helpers/constants.dart';
import 'package:shiftipoz/models/product_model.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  const ProductCard({super.key, required this.product});

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

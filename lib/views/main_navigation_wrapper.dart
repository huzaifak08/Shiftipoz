import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shiftipoz/providers/navigation_provider/navigation_provider.dart';
import 'package:shiftipoz/views/home_view.dart';
import 'package:shiftipoz/views/my_product_view.dart';
import 'package:shiftipoz/views/products_view/products_view.dart';
import 'package:shiftipoz/views/profile_view.dart';

class MainNavigationWrapper extends ConsumerWidget {
  const MainNavigationWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(navigationIndexProvider);

    // Our 5 main views
    final List<Widget> pages = [
      const HomeView(), // 0: Unit Conversion
      const ProductsView(), // 1: Marketplace
      const MyProductView(), // 2: User's Own Products (NEW)
      const _PlaceholderView(title: "Chats"), // 3: Chats
      const ProfileView(), // 4: Profile
    ];

    return Scaffold(
      body: IndexedStack(index: selectedIndex, children: pages),
      extendBody: false,
      bottomNavigationBar: _BeautifulBottomBar(
        selectedIndex: selectedIndex,
        onTap: (index) =>
            ref.read(navigationIndexProvider.notifier).state = index,
      ),
    );
  }
}

class _BeautifulBottomBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const _BeautifulBottomBar({required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 25),
      padding: const EdgeInsets.only(top: 10, bottom: 25, left: 8, right: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceEvenly, // Use spaceEvenly for 5 items
        children: [
          _NavBarItem(
            icon: Icons.swap_horiz_rounded,
            label: "Convert",
            isSelected: selectedIndex == 0,
            onTap: () => onTap(0),
            theme: theme,
          ),
          _NavBarItem(
            icon: Icons.local_mall_rounded,
            label: "Market",
            isSelected: selectedIndex == 1,
            onTap: () => onTap(1),
            theme: theme,
          ),
          // --- NEW TAB ---
          _NavBarItem(
            icon: Icons.inventory_2_rounded,
            label: "Inventory",
            isSelected: selectedIndex == 2,
            onTap: () => onTap(2),
            theme: theme,
          ),
          _NavBarItem(
            icon: Icons.chat_bubble_outline_rounded,
            label: "Chats",
            isSelected: selectedIndex == 3,
            onTap: () => onTap(3),
            theme: theme,
          ),
          _NavBarItem(
            icon: Icons.person_outline_rounded,
            label: "Profile",
            isSelected: selectedIndex == 4,
            onTap: () => onTap(4),
            theme: theme,
          ),
        ],
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final ThemeData theme;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.hintColor.withValues(alpha: 0.5),
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontSize: 10,
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

// Simple Stateless Placeholder for Chats
class _PlaceholderView extends StatelessWidget {
  final String title;
  const _PlaceholderView({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.hourglass_empty_rounded,
              size: 60,
              color: Theme.of(context).hintColor.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 20),
            Text(
              "$title View Coming Soon",
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

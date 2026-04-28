import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shiftipoz/cache/tables/user_table.dart';
import 'package:shiftipoz/components/avatar_picker.dart';
import 'package:shiftipoz/components/custom_button.dart';
import 'package:shiftipoz/helpers/app_data.dart';
import 'package:shiftipoz/models/user_model.dart';
import 'package:shiftipoz/providers/auth_provider/auth_provider.dart';
import 'package:shiftipoz/providers/user_provider/user_provider.dart';
import 'package:shiftipoz/views/auth/verify_email_view.dart';
import 'package:shiftipoz/views/home_view.dart';

class ProfileView extends ConsumerStatefulWidget {
  const ProfileView({super.key});

  @override
  ConsumerState<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends ConsumerState<ProfileView> {
  late TextEditingController _nameController;
  bool _isEditing = false;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    // Initialize controller with current name from provider
    final user = ref.read(userProvider).value;
    _nameController = TextEditingController(text: user?.name ?? "");
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdateName(UserModel user) async {
    if (_nameController.text.trim().isEmpty) return;

    final updatedUser = user.copyWith(name: _nameController.text.trim());

    await ref.read(userProvider.notifier).updateProfile(updatedUser);

    setState(() => _isEditing = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userState = ref.watch(userProvider);
    final auth = ref.watch(authControllerProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profile"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: userState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Error: $err")),
        data: (user) {
          if (user == null) {
            return const Center(child: Text("No user data found"));
          }

          _nameController.text = user.name;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Avatar Section
                auth?.emailVerified == false
                    ? IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VerifyEmailView(),
                            ),
                          );
                        },
                        icon: Icon(
                          Icons.warning_amber_outlined,
                          color: Colors.amber,
                          size: 50,
                        ),
                      )
                    : AvatarPicker(
                        initialImageUrl: user.profilePic,
                        onImageSelected: (file) {
                          setState(() {
                            _selectedImage = file;
                          });
                        },
                      ),

                const SizedBox(height: 32),

                // Personal Info Section
                _buildSectionLabel(theme, "Personal Information"),
                const SizedBox(height: 12),
                _buildEditableTile(
                  theme,
                  label: "Full Name",
                  controller: _nameController,
                  icon: Icons.person_outline_rounded,
                  isEditing: _isEditing,
                  onEditPressed: () => setState(() => _isEditing = true),
                  onSavePressed: () => _handleUpdateName(user),
                ),

                const SizedBox(height: 16),
                _buildReadOnlyTile(
                  theme,
                  label: "Email Address",
                  value: user.email,
                  icon: Icons.email_outlined,
                ),

                const SizedBox(height: 32),

                // Security Section
                _buildSectionLabel(theme, "Security"),
                const SizedBox(height: 12),
                _buildActionTile(
                  theme,
                  label: "Change Password",
                  subtitle: "Send a reset link to your email",
                  icon: Icons.lock_reset_rounded,
                  onTap: () {
                    ref
                        .read(authControllerProvider.notifier)
                        .passwordReset(user.email);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Reset link sent to your email!"),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                _selectedImage != null
                    ? CustomButton(
                        isLoading: false,
                        theme: theme,
                        title: "Save Picture",
                        onPressed: () async {
                          if (_selectedImage != null) {
                            await ref
                                .read(userProvider.notifier)
                                .changeProfilePicture(_selectedImage!);

                            setState(() {
                              _selectedImage = null;
                            });

                            ScaffoldMessenger.of(
                              AppData.shared.navigatorKey.currentContext ??
                                  context,
                            ).showSnackBar(
                              const SnackBar(
                                content: Text("Profile Picture Changed"),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("No Image Selected"),
                              ),
                            );
                          }
                        },
                      )
                    : CustomButton(
                        isLoading: false,
                        theme: theme,
                        title: "Log out",
                        onPressed: () => _handleLogout(context),
                      ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- UI Components ---

  Widget _buildSectionLabel(ThemeData theme, String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEditableTile(
    ThemeData theme, {
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required bool isEditing,
    required VoidCallback onEditPressed,
    required VoidCallback onSavePressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodySmall),
                TextField(
                  controller: controller,
                  enabled: isEditing,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: isEditing ? onSavePressed : onEditPressed,
            icon: Icon(
              isEditing ? Icons.check_circle_rounded : Icons.edit_rounded,
              color: isEditing ? Colors.green : theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyTile(
    ThemeData theme, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.bodySmall),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(
    ThemeData theme, {
    required String label,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(subtitle, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          ],
        ),
      ),
    );
  }

  // Logout:
  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text(
          "Are you sure you want to sign out? Local cache will be preserved.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              // 1. Clear the Singleton

              // 2. Clear Local SQLite Cache (Crucial for security)
              await UserTable.clearAllUsers();
              // await LedgerTable.deleteAllLedgers();

              // 3. Invalidate Providers (This resets their state to default/loading)
              // Todo: This will trigger the build() methods to run again and see 'null' user
              ref.invalidate(userProvider);
              // ref.invalidate(projectNotifierProvider);
              // ref.invalidate(ledgerNotifierProvider);

              // 4. Perform Firebase Logout
              await ref.read(authControllerProvider.notifier).logout();

              // 5. Navigate to Sign In
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeView()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: Text("Logout", style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }
}

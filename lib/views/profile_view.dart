import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shiftipoz/cache/tables/user_table.dart';
import 'package:shiftipoz/components/avatar_picker.dart';
import 'package:shiftipoz/components/custom_button.dart';
import 'package:shiftipoz/helpers/app_data.dart';
import 'package:shiftipoz/models/user_model.dart';
import 'package:shiftipoz/providers/auth_provider/auth_provider.dart';
import 'package:shiftipoz/providers/navigation_provider/navigation_provider.dart';
import 'package:shiftipoz/providers/product_provider/product_provider.dart';
import 'package:shiftipoz/providers/current_user_provider/current_user_provider.dart';
import 'package:shiftipoz/views/auth/sign_in_view.dart';
import 'package:shiftipoz/views/auth/verify_email_view.dart';

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
    final user = ref.read(currentUserProvider).value;
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

    await ref.read(currentUserProvider.notifier).updateProfile(updatedUser);

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
    final userState = ref.watch(currentUserProvider);
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
            return SessionExpiredView(
              onLoginPressed: () {
                // Navigate to your Auth/Login screen
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => SignInView()),
                );
              },
            );
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
                                .read(currentUserProvider.notifier)
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
              // 1. Close dialog
              Navigator.pop(context);

              // 2. Clear Singleton/Navigation UI state
              ref.read(navigationIndexProvider.notifier).update((state) => 0);

              // 3. Clear Local SQLite Cache (User data)
              await UserTable.clearAllUsers();

              // 4. Invalidate providers IMMEDIATELY
              // This forces them into a loading/null state so they don't try to sync
              ref.invalidate(productProvider);
              ref.invalidate(currentUserProvider);

              // 5. Perform Logout (This will update authControllerProvider state)
              await ref.read(authControllerProvider.notifier).logout();

              // 6. Final reset to ensure everything is fresh
              ref.invalidate(authControllerProvider);
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

class SessionExpiredView extends StatelessWidget {
  final VoidCallback onLoginPressed;

  const SessionExpiredView({super.key, required this.onLoginPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. ICON HOLDER (The "Locked" Vibe)
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.lock_person_rounded,
                  size: 60,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 40),

              // 2. TEXT CONTENT
              Text(
                "SESSION EXPIRED",
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "To keep your books and conversions safe, please sign back into your Shiftipoz account.",
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.hintColor,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),

              // 3. ACTION BUTTON
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: onLoginPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "LOG IN AGAIN",
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),

              // 4. SUBTLE LOGO FOOTER
              const SizedBox(height: 60),
              Opacity(
                opacity: 0.2,
                child: Text(
                  "SHIFTIPOZ SECURITY",
                  style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 4,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

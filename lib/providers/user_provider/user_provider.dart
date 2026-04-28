import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shiftipoz/cache/tables/user_table.dart';
import 'package:shiftipoz/models/user_model.dart';
import 'package:shiftipoz/providers/auth_provider/auth_provider.dart';
import 'package:shiftipoz/services/user_service.dart';
import 'dart:developer' as dev;

part 'user_provider.g.dart';

@Riverpod(keepAlive: true)
class UserNotifier extends _$UserNotifier {
  final UserService _userService = UserService();

  @override
  FutureOr<UserModel?> build() async {
    // watch the auth state
    final authAsync = ref.watch(authControllerProvider);

    return authAsync.when(
      data: (user) {
        if (user == null) {
          // IMPORTANT: If auth is null, we MUST NOT try to load from cache
          // otherwise we show old data while the app is transitioning.
          return null;
        }
        return _initUser(user.uid);
      },
      error: (_, _) => null,
      loading: () => null, // Stay null while auth is checking
    );
  }

  /// Core logic: Cache first, then Cloud, then Sync
  Future<UserModel?> _initUser(String uid) async {
    // A. Check local cache
    final localUser = await UserTable.getUser(uid);

    if (localUser != null) {
      dev.log(
        "UserProvider: Cache hit. Triggering background sync.",
        name: "UserProvider",
      );
      // Return cached data immediately, then sync in background
      _syncUserWithCloud(uid);
      return localUser;
    }

    // B. Cache is empty, fetch from Cloud
    dev.log(
      "UserProvider: Cache empty. Fetching from Cloud.",
      name: "UserProvider",
    );
    return await _syncUserWithCloud(uid);
  }

  /// Fetches from Firestore, updates cache, and pushes to state
  Future<UserModel?> _syncUserWithCloud(String uid) async {
    try {
      final cloudUser = await _userService.getUserData(uid);
      if (cloudUser != null) {
        // Update SQLite
        await UserTable.saveUser(cloudUser.copyWith(isSynced: true));
        // Update State
        state = AsyncData(cloudUser);
        return cloudUser;
      }
    } catch (e) {
      dev.log("UserProvider Sync Error: $e", name: "UserProvider");
    }
    return null;
  }

  // --- CRUD & Sync Methods (Same as Project/Ledger Providers) ---

  /// Update user profile (Optimistic UI approach)
  Future<void> updateProfile(UserModel updatedUser) async {
    // 1. Update UI and Cache immediately (isSynced = false)
    final localUpdate = updatedUser.copyWith(isSynced: false);
    state = AsyncData(localUpdate);
    await UserTable.saveUser(localUpdate);

    try {
      // 2. Update Firestore
      await _userService.saveOrUpdateUser(localUpdate);

      // 3. Mark as synced on success
      final syncedUser = localUpdate.copyWith(isSynced: true);
      await UserTable.saveUser(syncedUser);
      state = AsyncData(syncedUser);
    } catch (e) {
      dev.log("Failed to sync user update: $e");
      // Optional: Rollback or keep as unsynced for later
    }
  }

  /// Transforms a raw file into a URL and leverages existing sync logic
  Future<void> changeProfilePicture(File imageFile) async {
    final currentUser = state.value;
    if (currentUser == null) return;

    try {
      // 1. Upload file to get the URL (This is the only 'new' step)
      final imageUrl = await _userService.uploadProfilePic(
        currentUser.uid,
        imageFile,
      );

      if (imageUrl != null) {
        // 2. Create the updated model with the new URL
        final updatedUser = currentUser.copyWith(profilePic: imageUrl);

        // 3. REUSE your existing logic!
        // This handles: Cache update -> UI state change -> Firestore sync
        await updateProfile(updatedUser);

        dev.log(
          "UserProvider: Profile picture synced via updateProfile",
          name: "UserProvider",
        );
      }
    } catch (e) {
      dev.log(
        "UserProvider: Change profile pic failed: $e",
        name: "UserProvider",
      );
    }
  }

  /// Manual Sync Trigger (Useful for "Pull to Refresh" or Network changes)
  Future<void> syncPendingUser() async {
    final currentUser = state.value;
    if (currentUser == null || currentUser.isSynced) return;

    try {
      await _userService.saveOrUpdateUser(currentUser);
      final syncedUser = currentUser.copyWith(isSynced: true);
      await UserTable.saveUser(syncedUser);
      state = AsyncData(syncedUser);
      dev.log("User data synced successfully");
    } catch (e) {
      dev.log("Background User Sync failed: $e");
    }
  }

  /// Permanent Delete (matches your Table logic)
  Future<void> deleteUserDataLocally() async {
    final uid = state.value?.uid;
    if (uid != null) {
      await UserTable.deleteUser(uid);
      state = const AsyncData(null);
    }
  }
}

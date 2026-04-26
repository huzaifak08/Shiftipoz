import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shiftipoz/services/auth_service.dart';
import 'dart:developer' as dev;

part 'auth_provider.g.dart';

@Riverpod(keepAlive: true)
class AuthController extends _$AuthController {
  // Access the service layer
  late final AuthService _authService;

  @override
  FutureOr<User?> build() {
    _authService = AuthService();
    // This returns the initial stream value (current user or null)
    return FirebaseAuth.instance.currentUser;
  }

  /// --- Sign In Logic ---
  Future<AuthResult?> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final result = await _authService.signInWithEmail(email, password);

      // Update the global state so other parts of the app know the user is here
      state = AsyncValue.data(FirebaseAuth.instance.currentUser);

      return result; // 🔥 Return the specific result to the UI
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return AuthResult.error;
    }
  }

  /// --- Registration Logic ---
  Future<AuthResult?> signUp(String name, String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await _authService.registerWithEmail(
        name: name,
        email: email,
        password: password,
      );

      // Refresh local state with the new user object
      final currentUser = FirebaseAuth.instance.currentUser;
      state = AsyncValue.data(currentUser);

      // Logic: New users are always unverified initially
      return AuthResult.unverified;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return AuthResult.error;
    }
  }

  /// --- Check Verification Status ---
  /// Updates the state if the user has verified their email
  Future<void> refreshUserStatus() async {
    final isVerified = await _authService.checkEmailVerified();
    if (isVerified) {
      // Trigger a rebuild by getting the updated user object
      state = AsyncValue.data(FirebaseAuth.instance.currentUser);
    }
  }

  Future<void> passwordReset(String email) async {
    state = const AsyncValue.loading();
    await AsyncValue.guard(() => _authService.resetPassword(email));
    state = AsyncValue.data(FirebaseAuth.instance.currentUser);
  }

  Future<void> resendVerification() async {
    // We don't necessarily want to set the whole app to a "loading" state
    // for a resend, so we just call the service.
    try {
      await _authService.sendVerificationEmail();
    } catch (e, st) {
      // You could optionally set the state to error here if you want
      // the global listener to catch it.
      dev.log("Resend error: $e $st");
    }
  }

  /// --- Sign Out ---
  Future<void> logout() async {
    state = const AsyncValue.loading();
    await _authService.logout();
    state = const AsyncValue.data(null);
  }
}

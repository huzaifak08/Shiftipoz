import 'package:firebase_auth/firebase_auth.dart';
import 'package:shiftipoz/models/user_model.dart';
import 'package:shiftipoz/services/user_service.dart';
import 'dart:developer' as dev;

enum AuthResult { success, unverified, error }

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();

  /// --- 1. SESSION MANAGEMENT ---

  /// Reactive stream to listen to login/logout events.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Returns the current Firebase User (if any)
  User? get currentUser => _auth.currentUser;

  /// Fetches the Firestore profile for the currently logged-in user.
  Future<UserModel?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user != null) {
      dev.log("Fetching Firestore profile: ${user.uid}", name: "AuthService");
      return await _userService.getUserData(user.uid);
    }
    return null;
  }

  /// --- 2. REGISTRATION & VERIFICATION FLOW ---

  /// Registers user, creates Firestore doc, and sends verification email.
  Future<AuthResult> registerWithEmail({
    required String name,
    required String email,
    required String password,
    required String profilePic,
  }) async {
    try {
      dev.log("Starting registration: $email", name: "AuthService");

      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // 1. Prepare the UserModel
        UserModel newUser = UserModel(
          uid: credential.user!.uid,
          name: name,
          email: email,
          password: password,
          profilePic: profilePic,
          createdAt: DateTime.now(),
          isEmailVerified: false,
          isSynced: true,
        );

        // 2. Save to Firestore
        await _userService.saveOrUpdateUser(newUser);

        // 3. Send verification link
        await credential.user!.sendEmailVerification();

        dev.log(
          "User registered. Verification email sent.",
          name: "AuthService",
        );

        // 🔥 Always return unverified for new registrations
        return AuthResult.unverified;
      }

      return AuthResult.error;
    } on FirebaseAuthException catch (e) {
      dev.log("Reg Error: ${e.code}", name: "AuthService", error: e);
      throw _handleAuthError(e);
    }
  }

  Future<void> sendVerificationEmail() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  /// Manually trigger a resend of the verification email
  Future<void> resendVerificationEmail() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
      dev.log("Verification email resent.", name: "AuthService");
    } catch (e) {
      throw Exception("Could not resend email. Try again later.");
    }
  }

  /// Forces a reload of the user to check if they have clicked the link
  Future<bool> checkEmailVerified() async {
    User? user = _auth.currentUser;
    if (user != null) {
      await user
          .reload(); // 🔥 Critical: Refresh local cache from Firebase server
      bool verified = _auth.currentUser!.emailVerified;

      if (verified) {
        dev.log("Email verified detected.", name: "AuthService");
        // Update the Firestore flag so the DB matches the Auth state
        UserModel? profile = await getCurrentUserProfile();
        if (profile != null && !profile.isEmailVerified) {
          await _userService.saveOrUpdateUser(
            profile.copyWith(isEmailVerified: true),
          );
        }
      }
      return verified;
    }
    return false;
  }

  /// --- 3. LOGIN & AUTH OPS ---

  Future<AuthResult> signInWithEmail(String email, String password) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 🔥 Check verification status immediately
      if (credential.user != null && !credential.user!.emailVerified) {
        return AuthResult.unverified;
      }

      return AuthResult.success;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e); // Keep your existing error handler
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      dev.log("Password reset sent to: $email", name: "AuthService");
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<void> logout() async {
    dev.log("Signing out.", name: "AuthService");
    await _auth.signOut();
  }

  /// --- 4. ERROR HANDLING ---

  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'weak-password':
        return 'The password is too weak.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      default:
        return e.message ?? 'Authentication failed.';
    }
  }
}

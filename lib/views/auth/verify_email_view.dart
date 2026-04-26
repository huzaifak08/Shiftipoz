import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shiftipoz/providers/auth_provider/auth_provider.dart';
import 'package:shiftipoz/views/home_view.dart';

class VerifyEmailView extends ConsumerStatefulWidget {
  const VerifyEmailView({super.key});

  @override
  ConsumerState<VerifyEmailView> createState() => _VerifyEmailViewState();
}

class _VerifyEmailViewState extends ConsumerState<VerifyEmailView>
    with WidgetsBindingObserver {
  bool _isResending = false;
  bool _isCheckingVerification = false;

  @override
  void initState() {
    super.initState();

    // Listen for app foreground/background changes
    WidgetsBinding.instance.addObserver(this);
    ref.read(authControllerProvider.notifier).resendVerification();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Called whenever app lifecycle changes.
  /// When user returns to app from email/browser,
  /// automatically re-check verification.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkVerificationStatus(fromLifecycle: true);
    }
  }

  Future<void> _checkVerificationStatus({bool fromLifecycle = false}) async {
    if (_isCheckingVerification || !mounted) return;

    _isCheckingVerification = true;

    try {
      // Reload firebase user through provider
      await ref.read(authControllerProvider.notifier).refreshUserStatus();

      final user = ref.read(authControllerProvider).value;

      if (!mounted) return;

      if (user != null && user.emailVerified) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeView()),
          (route) => false,
        );
        return;
      }

      // Only show snackbar if not verified
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            fromLifecycle
                ? "Email not verified yet. Please verify first."
                : "Still not verified. Please check your email.",
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Could not verify status. Try again."),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      _isCheckingVerification = false;
    }
  }

  Future<void> _handleResend() async {
    setState(() => _isResending = true);

    try {
      await ref.read(authControllerProvider.notifier).resendVerification();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Verification email resent!"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.mark_email_unread_rounded,
                  size: 80,
                  color: theme.colorScheme.primary,
                ),
              ),

              const SizedBox(height: 40),

              Text(
                "Verify your Email",
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              Text(
                "We've sent a verification link to your email address. Please click the link to secure your account.",
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.amber,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Note: If you don't see the email, please check your Spam or Junk folder.",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.orange.shade900,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isCheckingVerification
                      ? null
                      : () => _checkVerificationStatus(),
                  icon: _isCheckingVerification
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.verified_user_rounded),
                  label: Text(
                    _isCheckingVerification ? "CHECKING..." : "I'VE VERIFIED",
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              TextButton(
                onPressed: _isResending ? null : _handleResend,
                child: _isResending
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        "Resend Verification Email",
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),

              const SizedBox(height: 30),

              TextButton.icon(
                onPressed: () async {
                  await ref.read(authControllerProvider.notifier).logout();

                  if (!context.mounted) {
                    return;
                  }

                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text("Use a different email"),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.onSurface.withValues(
                    alpha: 0.5,
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

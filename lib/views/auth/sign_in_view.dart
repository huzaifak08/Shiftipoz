import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shiftipoz/components/custom_button.dart';
import 'package:shiftipoz/components/custom_text_field.dart';
import 'package:shiftipoz/providers/auth_provider/auth_provider.dart';
import 'package:shiftipoz/services/auth_service.dart';
import 'package:shiftipoz/views/auth/sign_up_view.dart';
import 'package:shiftipoz/views/auth/verify_email_view.dart';
import 'package:shiftipoz/views/main_navigation_wrapper.dart';

class SignInView extends ConsumerStatefulWidget {
  const SignInView({super.key});

  @override
  ConsumerState<SignInView> createState() => _SignInViewState();
}

class _SignInViewState extends ConsumerState<SignInView> {
  // --- CONTROLLERS & NODES ---
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  // --- LOGIC ---
  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;

    final result = await ref
        .read(authControllerProvider.notifier)
        .signIn(_emailController.text.trim(), _passwordController.text.trim());

    if (!mounted) return;

    if (result == AuthResult.unverified) {
      // 🚀 Requirement: Navigate to VerifyEmailView if not verified
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const VerifyEmailView()),
      );
    } else if (result == AuthResult.error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Login failed. Please check your credentials."),
        ),
      );
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => MainNavigationWrapper()),
        (route) => false,
      );
    }
  }

  void _showForgotPasswordDialog() {
    final forgotEmailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Reset Password"),
        content: TextField(
          controller: forgotEmailController,
          decoration: const InputDecoration(
            hintText: "Enter your registered email",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              ref
                  .read(authControllerProvider.notifier)
                  .passwordReset(forgotEmailController.text.trim());
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text("Reset link sent!")));
            },
            child: const Text("Send"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF0B132B), const Color(0xFF1C2541)]
                : [const Color(0xFFF8F9FA), const Color(0xFFE9ECEF)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60),
                  _buildHeader(theme),
                  const SizedBox(height: 48),

                  // Email Field
                  _buildLabel("Email Address", theme),
                  CustomTextField(
                    controller: _emailController,
                    focusNode: _emailFocus,
                    hint: "yourname@mail.com",
                    icon: Icons.alternate_email_rounded,
                    theme: theme,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) =>
                        !v!.contains("@") ? "Enter a valid email" : null,
                    onFieldSubmitted: (p0) {
                      FocusScope.of(context).requestFocus(_passwordFocus);
                    },
                  ),

                  const SizedBox(height: 24),

                  // Password Field
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildLabel("Password", theme),
                      GestureDetector(
                        onTap: _showForgotPasswordDialog,
                        child: Text(
                          "Forgot?",
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  CustomTextField(
                    controller: _passwordController,
                    focusNode: _passwordFocus,
                    hint: "••••••••",
                    icon: Icons.lock_outline_rounded,
                    theme: theme,
                    isPassword: true,
                    obscureText: _obscurePassword,
                    toggleObscure: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    validator: (v) => v!.isEmpty ? "Password required" : null,
                  ),

                  const SizedBox(height: 40),

                  // Sign In Button
                  CustomButton(
                    isLoading: authState.isLoading,
                    theme: theme,
                    title: "Sign in",
                    onPressed: _handleSignIn,
                  ),

                  const SizedBox(height: 32),

                  // Footer Link
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SignUpView(),
                        ),
                      ),
                      child: Text.rich(
                        TextSpan(
                          text: "Don't have an account? ",
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                          children: [
                            TextSpan(
                              text: "Create One",
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Welcome Back",
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Sign in to continue shifting books with Shiftipoz.",
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
        ),
      ),
    );
  }
}

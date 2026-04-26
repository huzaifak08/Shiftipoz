import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shiftipoz/components/custom_text_field.dart';
import 'package:shiftipoz/providers/auth_provider/auth_provider.dart'; // Adjust path
import 'package:shiftipoz/services/auth_service.dart';
import 'package:shiftipoz/views/auth/verify_email_view.dart';

class SignUpView extends ConsumerStatefulWidget {
  const SignUpView({super.key});

  @override
  ConsumerState<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends ConsumerState<SignUpView> {
  // --- CONTROLLERS & NODES ---
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  // --- LOGIC ---
  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    final result = await ref
        .read(authControllerProvider.notifier)
        .signUp(
          _nameController.text.trim(),
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

    if (result == AuthResult.unverified) {
      if (!mounted) return;
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(
      //     content: Text("Verification email sent! Please check your inbox."),
      //   ),
      // );

      // Navigate to VerificationView or Login
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => VerifyEmailView()),
      );
    }
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
                  const SizedBox(height: 40),
                  _buildHeader(theme),
                  const SizedBox(height: 48),

                  // Name Field
                  _buildLabel("Full Name", theme),
                  CustomTextField(
                    controller: _nameController,
                    focusNode: _nameFocus,
                    hint: "Enter your name",
                    icon: Icons.person_outline,
                    theme: theme,
                    validator: (v) => v!.isEmpty ? "Name is required" : null,
                    onFieldSubmitted: (value) {
                      FocusScope.of(context).requestFocus(_emailFocus);
                    },
                  ),

                  const SizedBox(height: 20),

                  // Email Field
                  _buildLabel("Email Address", theme),
                  CustomTextField(
                    controller: _emailController,
                    focusNode: _emailFocus,
                    hint: "example@mail.com",
                    icon: Icons.email_outlined,
                    theme: theme,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) =>
                        !v!.contains("@") ? "Invalid email" : null,
                    onFieldSubmitted: (p0) {
                      FocusScope.of(context).requestFocus(_passwordFocus);
                    },
                  ),

                  const SizedBox(height: 20),

                  // Password Field
                  _buildLabel("Password", theme),
                  CustomTextField(
                    controller: _passwordController,
                    focusNode: _passwordFocus,
                    hint: "John@78",
                    icon: Icons.lock_outline,
                    theme: theme,
                    isPassword: true,
                    obscureText: _obscurePassword,
                    toggleObscure: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    validator: (v) =>
                        v!.length < 6 ? "Minimum 6 characters" : null,
                  ),

                  const SizedBox(height: 40),

                  // Sign Up Button
                  _buildSignUpButton(authState.isLoading, theme),

                  const SizedBox(height: 24),

                  // Footer Link
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text.rich(
                        TextSpan(
                          text: "Already have an account? ",
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                          children: [
                            TextSpan(
                              text: "Login",
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
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.auto_awesome,
            color: theme.colorScheme.primary,
            size: 32,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          "Create Account",
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Join Shiftipoz and start shifting knowledge.",
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

  Widget _buildSignUpButton(bool isLoading, ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: isLoading ? null : _handleSignUp,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                "Register Now",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}

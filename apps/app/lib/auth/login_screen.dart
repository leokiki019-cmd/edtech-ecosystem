import 'package:edtech_app/auth/auth_provider.dart';
import 'package:edtech_app/theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.login(
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
    );
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Login failed'),
          backgroundColor: kError,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(kSpaceMd),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusMd)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(kSpaceMd),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                elevation: 0,
                color: kSurface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(kRadiusXl),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(kSpaceXxl),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: candyGradient,
                            borderRadius: BorderRadius.circular(kRadiusMd),
                          ),
                          child: const Center(
                            child: Icon(Icons.school_rounded, size: 40, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: kSpaceLg),
                        Text(
                          'Welcome Back',
                          style: context.h2.copyWith(
                            fontWeight: FontWeight.w900,
                            color: kTextPrimary,
                          ),
                        ),
                        const SizedBox(height: kSpaceXs),
                        Text(
                          'Sign in to continue your journey',
                          style: context.body2.copyWith(
                            color: kTextSecondary,
                          ),
                        ),
                        const SizedBox(height: kSpaceXxl),
                        TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number',
                            hintText: '+1555 000 1001',
                            prefixIcon: Icon(Icons.phone_rounded, color: kPrimary),
                          ),
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your phone number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: kSpaceMd),
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_rounded, color: kPrimary),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                                color: kTextSecondary,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: kSpaceLg),
                        SizedBox(
                          width: double.infinity,
                          height: kSpaceMd + 24,
                          child: Consumer<AuthProvider>(
                            builder: (context, auth, child) {
                              return FilledButton(
                                onPressed: auth.isLoading ? null : _submit,
                                child: auth.isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Sign In',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: kSpaceLg),
                        Row(
                          children: [
                            Expanded(
                              child: Divider(color: kDivider),
                            ),
                            const SizedBox(width: kSpaceSm),
                            Text(
                              'Or',
                              style: context.caption.copyWith(
                                color: kTextSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: kSpaceSm),
                            Expanded(
                              child: Divider(color: kDivider),
                            ),
                          ],
                        ),
                        const SizedBox(height: kSpaceLg),
                        OutlinedButton.icon(
                          onPressed: () {
                            context.push('/signup');
                          },
                          icon: const Icon(Icons.person_add_rounded, size: 18),
                          label: const Text(
                            "Don't have an account? Sign up",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: kPrimary,
                            padding: const EdgeInsets.symmetric(vertical: kSpaceMd),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(kRadiusMd),
                            ),
                            side: BorderSide(color: kBorder, width: 1),
                          ),
                        ),
                        const SizedBox(height: kSpaceSm),
                        TextButton(
                          onPressed: () {
                            context.push('/verify-sms');
                          },
                          child: Text(
                            'Forgot password? Verify via SMS',
                            style: context.caption.copyWith(
                              color: kTextSecondary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

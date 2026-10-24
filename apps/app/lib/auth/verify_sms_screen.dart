import 'package:edtech_app/auth/auth_provider.dart';
import 'package:edtech_app/theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class VerifySmsScreen extends StatefulWidget {
  const VerifySmsScreen({super.key});

  @override
  State<VerifySmsScreen> createState() => _VerifySmsScreenState();
}

class _VerifySmsScreenState extends State<VerifySmsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  bool _codeSent = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (_phoneController.text.trim().isEmpty) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.sendSmsCode(phone: _phoneController.text.trim());
    if (!mounted) return;
    if (success) {
      setState(() => _codeSent = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification code sent'),
          backgroundColor: kSuccess,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Could not send code'),
          backgroundColor: kError,
        ),
      );
    }
  }

  Future<void> _verify() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.verifySmsCode(
      phone: _phoneController.text.trim(),
      code: _codeController.text.trim(),
    );
    if (!mounted) return;
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Invalid code'),
          backgroundColor: kError,
        ),
      );
    }
    // On success the router redirect sends the user to the dashboard.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              elevation: 4,
              shadowColor: kPrimary.withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.sms, size: 64, color: kPrimary),
                      const SizedBox(height: 24),
                      Text(
                        'Verify via SMS',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: kTextPrimary,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Confirm your phone to recover access',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: kTextSecondary,
                            ),
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _phoneController,
                        enabled: !_codeSent,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          hintText: '+15550001002',
                          prefixIcon: Icon(Icons.phone, color: kPrimary),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your phone number';
                          }
                          return null;
                        },
                      ),
                      if (_codeSent) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _codeController,
                          decoration: const InputDecoration(
                            labelText: '6-digit code',
                            prefixIcon: Icon(Icons.pin, color: kPrimary),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.trim().length != 6) {
                              return 'Enter the 6-digit code';
                            }
                            return null;
                          },
                        ),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: Consumer<AuthProvider>(
                          builder: (context, auth, child) {
                            return ElevatedButton(
                              onPressed: auth.isLoading
                                  ? null
                                  : (_codeSent ? _verify : _sendCode),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kPrimary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: auth.isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      _codeSent ? 'Verify Code' : 'Send Code',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          if (_codeSent) {
                            setState(() {
                              _codeSent = false;
                              _codeController.clear();
                            });
                          } else {
                            context.pop();
                          }
                        },
                        child: Text(
                          _codeSent ? 'Change phone number' : 'Back to sign in',
                          style: const TextStyle(color: kPrimary),
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
    );
  }
}

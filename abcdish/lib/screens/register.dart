import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:abcdish/providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  String _name = '';
  String _email = '';
  String _otp = '';
  bool _otpRequested = false;

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _requestOtp() async {
    final isValid = _formKey.currentState!.validate();
    if (!isValid) return;

    _formKey.currentState!.save();

    final success = await ref
        .read(authProvider.notifier)
        .requestRegisterEmailOtp(name: _name, email: _email);

    if (!mounted) return;

    if (success) {
      setState(() {
        _otpRequested = true;
      });
      _showMessage('Email code sent');
    } else {
      _showMessage(
        ref.read(authProvider).errorMessage ?? 'Could not send code',
      );
    }
  }

  Future<void> _verifyOtp() async {
    final isValid = _formKey.currentState!.validate();
    if (!isValid) return;

    _formKey.currentState!.save();

    final success = await ref
        .read(authProvider.notifier)
        .verifyRegisterEmailOtp(email: _email, otp: _otp);

    if (!mounted) return;

    if (success) {
      _showMessage('Account created successfully');
      Navigator.of(context).pop();
    } else {
      _showMessage(ref.read(authProvider).errorMessage ?? 'Invalid code');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person_add_alt_1,
                          size: 56,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Join ABCDish',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create your account with your name and email code.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          initialValue: _name,
                          decoration: const InputDecoration(
                            labelText: 'Full name',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          textInputAction: TextInputAction.next,
                          enabled: !_otpRequested,
                          validator: (value) {
                            if (value == null || value.trim().length < 2) {
                              return 'Enter your full name';
                            }
                            return null;
                          },
                          onSaved: (value) {
                            _name = value!.trim();
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          initialValue: _email,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: _otpRequested
                              ? TextInputAction.next
                              : TextInputAction.done,
                          enabled: !_otpRequested,
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty ||
                                !value.contains('@')) {
                              return 'Enter a valid email address';
                            }
                            return null;
                          },
                          onSaved: (value) {
                            _email = value!.trim();
                          },
                          onFieldSubmitted: (_) {
                            if (!authState.isLoading && !_otpRequested) {
                              _requestOtp();
                            }
                          },
                        ),
                        if (_otpRequested) ...[
                          const SizedBox(height: 12),
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: '6-digit code',
                              prefixIcon: Icon(Icons.pin_outlined),
                            ),
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.done,
                            validator: (value) {
                              if (value == null || value.trim().length != 6) {
                                return 'Enter the 6-digit code';
                              }
                              return null;
                            },
                            onSaved: (value) {
                              _otp = value!.trim();
                            },
                            onFieldSubmitted: (_) {
                              if (!authState.isLoading) {
                                _verifyOtp();
                              }
                            },
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: authState.isLoading
                                ? null
                                : () {
                                    setState(() {
                                      _otpRequested = false;
                                      _otp = '';
                                    });
                                  },
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Edit details'),
                          ),
                        ],
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: authState.isLoading
                                ? null
                                : _otpRequested
                                ? _verifyOtp
                                : _requestOtp,
                            child: Text(
                              _otpRequested
                                  ? 'Verify & Create Account'
                                  : 'Send Code',
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
          if (authState.isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.25),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}

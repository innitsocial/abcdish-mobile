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
  String _mobileNumber = '';
  String _password = '';

  bool _useEmail = true;
  bool _useMobile = false;

  Future<void> _submit() async {
    final isValid = _formKey.currentState!.validate();
    if (!isValid) return;

    _formKey.currentState!.save();

    final success = await ref
        .read(authProvider.notifier)
        .register(
          name: _name,
          email: _useEmail ? _email : null,
          mobileNumber: _useMobile ? _mobileNumber : null,
          password: _useEmail ? _password : null,
        );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created successfully')),
      );

      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ref.read(authProvider).errorMessage ?? 'Registration failed',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: Center(
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
                      'Create your account using email, mobile, or both.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Full name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.trim().length < 2) {
                          return 'Enter your name';
                        }

                        return null;
                      },
                      onSaved: (value) {
                        _name = value!.trim();
                      },
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      value: _useEmail,
                      title: const Text('Use email'),
                      subtitle: const Text(
                        'Recommended for password login and recovery',
                      ),
                      onChanged: (value) {
                        setState(() {
                          _useEmail = value;
                          if (!_useEmail && !_useMobile) {
                            _useMobile = true;
                          }
                        });
                      },
                    ),
                    if (_useEmail) ...[
                      const SizedBox(height: 8),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (!_useEmail) return null;

                          if (value == null ||
                              value.trim().isEmpty ||
                              !value.contains('@')) {
                            return 'Enter a valid email address';
                          }

                          return null;
                        },
                        onSaved: (value) {
                          _email = value?.trim() ?? '';
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        obscureText: true,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (!_useEmail) return null;

                          if (value == null || value.trim().length < 6) {
                            return 'Password must be at least 6 characters';
                          }

                          return null;
                        },
                        onSaved: (value) {
                          _password = value?.trim() ?? '';
                        },
                      ),
                    ],
                    const SizedBox(height: 16),
                    SwitchListTile(
                      value: _useMobile,
                      title: const Text('Use mobile number'),
                      subtitle: const Text(
                        'Useful for OTP login and account recovery',
                      ),
                      onChanged: (value) {
                        setState(() {
                          _useMobile = value;
                          if (!_useEmail && !_useMobile) {
                            _useEmail = true;
                          }
                        });
                      },
                    ),
                    if (_useMobile) ...[
                      const SizedBox(height: 8),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Mobile number',
                          hintText: '+447123456789',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.done,
                        validator: (value) {
                          if (!_useMobile) return null;

                          if (value == null || value.trim().length < 8) {
                            return 'Enter a valid mobile number';
                          }

                          return null;
                        },
                        onSaved: (value) {
                          _mobileNumber = value?.trim() ?? '';
                        },
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: authState.isLoading ? null : _submit,
                        child: authState.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Create Account'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

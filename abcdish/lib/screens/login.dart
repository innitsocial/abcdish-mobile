import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:abcdish/providers/auth_provider.dart';
import 'package:abcdish/screens/forgot_password.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _emailPasswordFormKey = GlobalKey<FormState>();
  final _emailOtpFormKey = GlobalKey<FormState>();
  final _mobileOtpFormKey = GlobalKey<FormState>();

  String _email = '';
  String _password = '';
  String _emailOtp = '';
  String _mobileNumber = '';
  String _mobileOtp = '';

  bool _emailOtpRequested = false;
  bool _mobileOtpRequested = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _loginWithEmailPassword() async {
    final isValid = _emailPasswordFormKey.currentState!.validate();
    if (!isValid) return;

    _emailPasswordFormKey.currentState!.save();

    final success = await ref
        .read(authProvider.notifier)
        .login(identifier: _email, password: _password);

    if (!mounted) return;

    if (success) {
      _showMessage('Logged in successfully');
      Navigator.of(context).pop();
    } else {
      _showMessage(ref.read(authProvider).errorMessage ?? 'Login failed');
    }
  }

  Future<void> _requestEmailOtp() async {
    final isValid = _emailOtpFormKey.currentState!.validate();
    if (!isValid) return;

    _emailOtpFormKey.currentState!.save();

    final success = await ref
        .read(authProvider.notifier)
        .requestEmailOtp(_email);

    if (!mounted) return;

    if (success) {
      setState(() {
        _emailOtpRequested = true;
      });
      _showMessage('Email code sent. Check backend console for now.');
    } else {
      _showMessage(
        ref.read(authProvider).errorMessage ?? 'Could not send code',
      );
    }
  }

  Future<void> _verifyEmailOtp() async {
    final isValid = _emailOtpFormKey.currentState!.validate();
    if (!isValid) return;

    _emailOtpFormKey.currentState!.save();

    final success = await ref
        .read(authProvider.notifier)
        .verifyEmailOtp(email: _email, otp: _emailOtp);

    if (!mounted) return;

    if (success) {
      _showMessage('Logged in successfully');
      Navigator.of(context).pop();
    } else {
      _showMessage(ref.read(authProvider).errorMessage ?? 'Invalid code');
    }
  }

  Future<void> _requestMobileOtp() async {
    final isValid = _mobileOtpFormKey.currentState!.validate();
    if (!isValid) return;

    _mobileOtpFormKey.currentState!.save();

    final success = await ref
        .read(authProvider.notifier)
        .requestMobileOtp(_mobileNumber);

    if (!mounted) return;

    if (success) {
      setState(() {
        _mobileOtpRequested = true;
      });
      _showMessage('SMS code sent. Check backend console for now.');
    } else {
      _showMessage(
        ref.read(authProvider).errorMessage ?? 'Could not send code',
      );
    }
  }

  Future<void> _verifyMobileOtp() async {
    final isValid = _mobileOtpFormKey.currentState!.validate();
    if (!isValid) return;

    _mobileOtpFormKey.currentState!.save();

    final success = await ref
        .read(authProvider.notifier)
        .verifyMobileOtp(mobileNumber: _mobileNumber, otp: _mobileOtp);

    if (!mounted) return;

    if (success) {
      _showMessage('Logged in successfully');
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
      appBar: AppBar(
        title: const Text('Login'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Email'),
            Tab(text: 'Email Code'),
            Tab(text: 'Mobile'),
          ],
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              _buildEmailPasswordLogin(colorScheme, authState),
              _buildEmailOtpLogin(colorScheme, authState),
              _buildMobileOtpLogin(colorScheme, authState),
            ],
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

  Widget _buildEmailPasswordLogin(
    ColorScheme colorScheme,
    AuthState authState,
  ) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _emailPasswordFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.restaurant_menu,
                    size: 56,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Login with Email',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
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
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    validator: (value) {
                      if (value == null || value.trim().length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _password = value!.trim();
                    },
                    onFieldSubmitted: (_) {
                      if (!authState.isLoading) {
                        _loginWithEmailPassword();
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: authState.isLoading
                          ? null
                          : _loginWithEmailPassword,
                      child: const Text('Login'),
                    ),
                  ),

                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (ctx) => const ForgotPasswordScreen(),
                        ),
                      );
                    },
                    child: const Text('Forgot password?'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailOtpLogin(ColorScheme colorScheme, AuthState authState) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _emailOtpFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.mark_email_read_outlined,
                    size: 56,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Login with Email Code',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
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
                  ),
                  if (_emailOtpRequested) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: '6-digit code',
                        prefixIcon: Icon(Icons.pin_outlined),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (!_emailOtpRequested) return null;
                        if (value == null || value.trim().length != 6) {
                          return 'Enter the 6-digit code';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _emailOtp = value!.trim();
                      },
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: authState.isLoading
                          ? null
                          : _emailOtpRequested
                          ? _verifyEmailOtp
                          : _requestEmailOtp,
                      child: Text(
                        _emailOtpRequested ? 'Verify & Login' : 'Send Code',
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

  Widget _buildMobileOtpLogin(ColorScheme colorScheme, AuthState authState) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _mobileOtpFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.phone_iphone,
                    size: 56,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Login with Mobile',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Mobile number',
                      hintText: '+447123456789',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.trim().length < 8) {
                        return 'Enter a valid mobile number';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _mobileNumber = value!.trim();
                    },
                  ),
                  if (_mobileOtpRequested) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: '6-digit code',
                        prefixIcon: Icon(Icons.pin_outlined),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (!_mobileOtpRequested) return null;
                        if (value == null || value.trim().length != 6) {
                          return 'Enter the 6-digit code';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _mobileOtp = value!.trim();
                      },
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: authState.isLoading
                          ? null
                          : _mobileOtpRequested
                          ? _verifyMobileOtp
                          : _requestMobileOtp,
                      child: Text(
                        _mobileOtpRequested ? 'Verify & Login' : 'Send Code',
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
}

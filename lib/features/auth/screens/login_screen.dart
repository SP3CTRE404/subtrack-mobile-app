import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/auth_request.dart';
import '../providers/auth_provider.dart';
import '../services/auth_repository.dart';
import '../widgets/auth_background.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_divider.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_redirect.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/google_sign_in_button.dart';
import 'register_screen.dart';
import '../../../shared/widgets/custom_toast.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final request = LoginRequest(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      try {
        await ref.read(authProvider.notifier).login(request);
      } catch (e) {
        if (mounted) {
          final msg = e is AuthException ? e.message : 'Login failed. Please check your credentials.';
          CustomToast.show(context: context, message: msg, isError: true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: Stack(
        children: [
          const AuthBackground(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 24),
                      const AuthHeader(
                        title: 'Welcome',
                        subtitle: 'Sign in to manage your subscriptions.',
                      ),
                      const SizedBox(height: 48),
                      AuthTextField(
                        label: 'Email',
                        hint: 'Enter your email',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 20),
                      AuthTextField(
                        label: 'Password',
                        hint: 'Enter your password',
                        controller: _passwordController,
                        isPassword: true,
                      ),
                      const SizedBox(height: 16),
                      AuthButton(
                        onPressed: _submit,
                        label: 'Sign In',
                        isLoading: authState == AuthStatus.loading,
                      ),
                      const SizedBox(height: 32),
                      const AuthDivider(),
                      const SizedBox(height: 32),
                      GoogleSignInButton(
                        onPressed: () {
                          CustomToast.show(context: context, message: 'Google Sign-In coming soon!', isError: false);
                        },
                      ),
                      const SizedBox(height: 32),
                      AuthRedirect(
                        text: 'Don\'t have an account?',
                        buttonText: 'Sign Up',
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const RegisterScreen()),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

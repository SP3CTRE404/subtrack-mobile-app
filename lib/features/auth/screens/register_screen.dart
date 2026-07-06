import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
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
import '../../../shared/widgets/custom_toast.dart';
import '../../../features/settings/providers/currency_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _dobController = TextEditingController();
  final _householdNameController = TextEditingController();
  bool _createHousehold = false;
  DateTime? _selectedDob;
  String? _selectedCountry;
  String? _selectedCurrency;
  bool _agreedToTerms = false;
  bool _agreedToPrivacy = false;

  late final TapGestureRecognizer _termsToggleRecognizer;
  late final TapGestureRecognizer _termsLinkRecognizer;
  late final TapGestureRecognizer _privacyToggleRecognizer;
  late final TapGestureRecognizer _privacyLinkRecognizer;

  @override
  void initState() {
    super.initState();
    _termsToggleRecognizer = TapGestureRecognizer();
    _termsLinkRecognizer = TapGestureRecognizer();
    _privacyToggleRecognizer = TapGestureRecognizer();
    _privacyLinkRecognizer = TapGestureRecognizer();
  }


  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _dobController.dispose();
    _householdNameController.dispose();
    _termsToggleRecognizer.dispose();
    _termsLinkRecognizer.dispose();
    _privacyToggleRecognizer.dispose();
    _privacyLinkRecognizer.dispose();
    super.dispose();
  }

  void _showTermsDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => const TermsAndConditionsScreen(),
      ),
    );
  }

  void _launchPrivacyPolicy() async {
    final Uri url = Uri.parse('https://premio.app/privacy');
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (mounted) {
          CustomToast.show(
            context: context,
            message: 'Could not launch Privacy Policy webpage',
            isError: true,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context: context,
          message: 'Error opening web page',
          isError: true,
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.cobaltBlue,
              onPrimary: Colors.white,
              surface: Theme.of(context).colorScheme.surface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDob) {
      setState(() {
        _selectedDob = picked;
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
        
        // Calculate age and update toggle if needed
        final age = DateTime.now().year - picked.year;
        final isMinor = age < 18;
        if (isMinor) {
          _createHousehold = false;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        CustomToast.show(context: context, message: 'Passwords do not match', isError: true);
        return;
      }

      final password = _passwordController.text;
      if (password.length < 8 || !password.contains(RegExp(r'[A-Z]')) || !password.contains(RegExp(r'[^a-zA-Z0-9]'))) {
        CustomToast.show(
          context: context,
          message: 'Password must be at least 8 chars, with 1 uppercase & 1 special char',
          isError: true,
        );
        return;
      }

      if (_selectedDob == null) {
        CustomToast.show(context: context, message: 'Please select your Date of Birth', isError: true);
        return;
      }

      if (_selectedCountry == null) {
        CustomToast.show(context: context, message: 'Please select a country', isError: true);
        return;
      }

      if (_createHousehold && _householdNameController.text.trim().isEmpty) {
        CustomToast.show(context: context, message: 'Please enter a household name', isError: true);
        return;
      }

      final request = RegisterRequest(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _fullNameController.text.trim(),
        dateOfBirth: _selectedDob,
        createHousehold: _createHousehold,
        householdName:
            _createHousehold ? _householdNameController.text.trim() : '',
        country: _selectedCountry,
        currencySymbol: _selectedCurrency,
      );
      try {
        await ref.read(authProvider.notifier).register(request);
      } catch (e) {
        if (mounted) {
          final msg = e is AuthException ? e.message : 'Registration failed. Please try again.';
          CustomToast.show(context: context, message: msg, isError: true);
        }
      }
    }
  }

  int _calculateAge(DateTime? dob) {
    if (dob == null) return 0;
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  @override
  Widget build(BuildContext context) {
    final currenciesAsync = ref.watch(availableCurrenciesProvider);
    final authState = ref.watch(authProvider);
    final age = _calculateAge(_selectedDob);
    final isMinor = _selectedDob != null && age < 18;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
      ),
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
                      const AuthHeader(
                        title: 'Create Account',
                        subtitle: 'Start managing your subscriptions today.',
                      ),
                      const SizedBox(height: 32),
                      AuthTextField(
                        label: 'Full Name',
                        hint: 'Enter your full name',
                        controller: _fullNameController,
                      ),
                      const SizedBox(height: 16),
                      AuthTextField(
                        label: 'Email',
                        hint: 'Enter your email',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      AuthTextField(
                        label: 'Password',
                        hint: 'Create a password',
                        controller: _passwordController,
                        isPassword: true,
                      ),
                      const SizedBox(height: 16),
                      AuthTextField(
                        label: 'Confirm Password',
                        hint: 'Re-enter your password',
                        controller: _confirmPasswordController,
                        isPassword: true,
                      ),
                      const SizedBox(height: 16),
                      AuthTextField(
                        label: 'Date of Birth',
                        hint: 'YYYY-MM-DD',
                        controller: _dobController,
                        readOnly: true,
                        onTap: () => _selectDate(context),
                      ),
                      const SizedBox(height: 16),
                      
                      // Country Dropdown
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Country/Region',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                              ),
                            ),
                            child: currenciesAsync.when(
                              data: (currencies) => DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedCountry,
                                  hint: Text(
                                    'Select your region',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                                    ),
                                  ),
                                  isExpanded: true,
                                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                                  items: currencies.map((currency) {
                                    return DropdownMenuItem<String>(
                                      value: currency.name,
                                      child: Text(currency.name),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      _selectedCountry = newValue;
                                      if (newValue != null) {
                                        _selectedCurrency = currencies.firstWhere((c) => c.name == newValue).symbol;
                                      }
                                    });
                                  },
                                ),
                              ),
                              loading: () => const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12.0),
                                child: Center(child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                              ),
                              error: (err, stack) => const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12.0),
                                child: Text('Failed to load regions'),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Create New Household',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            Switch(
                              value: _createHousehold,
                              onChanged: isMinor
                                  ? null
                                  : (value) {
                                      setState(() {
                                        _createHousehold = value;
                                      });
                                    },
                              activeThumbColor: AppColors.cobaltBlue,
                            ),
                          ],
                        ),
                      ),
                      if (_createHousehold) ...[
                        const SizedBox(height: 16),
                        AuthTextField(
                          label: 'Household Name',
                          hint: 'Enter household name',
                          controller: _householdNameController,
                        ),
                      ],
                      const SizedBox(height: 24),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 24,
                            width: 24,
                            child: Checkbox(
                              value: _agreedToTerms,
                              activeColor: AppColors.cobaltBlue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              side: BorderSide(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                              onChanged: (val) {
                                setState(() {
                                  _agreedToTerms = val ?? false;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                      fontWeight: FontWeight.w500,
                                    ),
                                children: [
                                  TextSpan(
                                    text: 'I agree to the ',
                                    recognizer: _termsToggleRecognizer
                                      ..onTap = () {
                                        setState(() {
                                          _agreedToTerms = !_agreedToTerms;
                                        });
                                      },
                                  ),
                                  TextSpan(
                                    text: 'Terms and Conditions',
                                    style: const TextStyle(
                                      color: AppColors.cobaltBlue,
                                      decoration: TextDecoration.underline,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    recognizer: _termsLinkRecognizer
                                      ..onTap = _showTermsDialog,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 24,
                            width: 24,
                            child: Checkbox(
                              value: _agreedToPrivacy,
                              activeColor: AppColors.cobaltBlue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              side: BorderSide(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                              onChanged: (val) {
                                setState(() {
                                  _agreedToPrivacy = val ?? false;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                      fontWeight: FontWeight.w500,
                                    ),
                                children: [
                                  TextSpan(
                                    text: 'I have read and agree to the ',
                                    recognizer: _privacyToggleRecognizer
                                      ..onTap = () {
                                        setState(() {
                                          _agreedToPrivacy = !_agreedToPrivacy;
                                        });
                                      },
                                  ),
                                  TextSpan(
                                    text: 'Privacy Policy',
                                    style: const TextStyle(
                                      color: AppColors.cobaltBlue,
                                      decoration: TextDecoration.underline,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    recognizer: _privacyLinkRecognizer
                                      ..onTap = _launchPrivacyPolicy,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      AuthButton(
                        onPressed: (_agreedToTerms && _agreedToPrivacy) ? _submit : null,
                        label: 'Sign Up',
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
                        text: 'Already have an account?',
                        buttonText: 'Sign In',
                        onPressed: () => Navigator.pop(context),
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

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms & Conditions', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Premio Terms of Service',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Last Updated: May 2026',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
            ),
            const Divider(height: 32),
            _buildSection(
              context,
              '1. Acceptance of Terms',
              'By creating an account or using the Premio application ("Service"), you agree to be bound by these Terms and Conditions. If you do not agree to these terms, do not use the Service.',
            ),
            _buildSection(
              context,
              '2. Description of Service',
              'Premio is a subscription tracking and management tool. It allows you to log subscriptions, track billing cycles, set up manual-pay reminders, and coordinate household subscription budgets. Premio is NOT a payment processor, financial advisor, or direct subscription provider.',
            ),
            _buildSection(
              context,
              '3. No Financial Liability & Subscription Disclaimer',
              'YOU ACKNOWLEDGE AND AGREE THAT:\n'
              '• Premio does not pay, cancel, renew, or modify subscriptions on your behalf.\n'
              '• It is your sole responsibility to manage, pay, and cancel subscriptions directly with the respective service providers (e.g., Netflix, Spotify).\n'
              '• Premio is not responsible for any overdraft fees, missed cancellation deadlines, unwanted renewals, or billing discrepancies.',
            ),
            _buildSection(
              context,
              '4. Account Security & Verification',
              'You are responsible for safeguarding the credentials you use to access the Service. If you enable Biometric Lock (Face ID/Fingerprint) or set a PIN, you must keep these secure. Premio is not liable for unauthorized access resulting from compromised device security.',
            ),
            _buildSection(
              context,
              '5. Age Requirements & Household Rules',
              'Users under the age of 18 are not permitted to manage single/admin accounts and must join a household managed by an adult. Households are intended for individuals residing in the same household.',
            ),
            _buildSection(
              context,
              '6. Privacy & Data Use',
              'Your use of the Service is also governed by our Privacy Policy. We collect and store data to enable the tracking features, synchronize household lists, and authenticate your account. We encrypt sensitive data and do not sell your personal information.',
            ),
            _buildSection(
              context,
              '7. Modification of Service and Terms',
              'We reserve the right to modify or terminate the Service or change these Terms at any time. Continued use of the Service after modifications constitutes your acceptance of the updated Terms.',
            ),
            _buildSection(
              context,
              '8. Contact Us',
              'If you have any questions or feedback regarding these Terms, please contact us at support@premio.app.',
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'otp_verification_screen.dart'; // Import OtpPurpose

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final result = await authProvider.login(email, password);

    if (mounted) { // Check if the widget is still in the tree
      if (result['success'] == true) {
        Navigator.pushReplacementNamed(context, '/home');
      } else if (result['needsVerification'] == true) {
        Helpers.showSnackBar(context, result['error'] ?? 'Akun belum diverifikasi.', isError: true);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtpVerificationScreen(
              email: result['email'] ?? email, // Use email from provider if available
              purpose: OtpPurpose.emailVerification,
            ),
          ),
        );
      } else {
        Helpers.showSnackBar(
          context,
          result['error'] ?? 'Login gagal',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppSizes.paddingLarge),
          child: Form(
            key: _formKey,
            child: Center( // Added Center for better vertical alignment on various screens
              child: SingleChildScrollView( // Added SingleChildScrollView
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center, // Center content vertically
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo
                    Container(
                      alignment: Alignment.center,
                      child: Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.account_balance_wallet,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(height: 30),
                    
                    // Title
                    Text(
                      'Masuk ke Akun Anda',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Silakan masukkan email dan password Anda',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 40),

                    // Email Field
                    CustomTextField(
                      controller: _emailController,
                      labelText: 'Email',
                      hintText: 'Masukkan email Anda',
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.email,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Email harus diisi';
                        }
                        if (!Helpers.isValidEmail(value)) {
                          return 'Format email tidak valid';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),

                    // Password Field
                    CustomTextField(
                      controller: _passwordController,
                      labelText: 'Password',
                      hintText: 'Masukkan password Anda',
                      obscureText: _obscurePassword,
                      prefixIcon: Icons.lock,
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password harus diisi';
                        }
                        // Removed length check here as API handles it, but can be kept for UX
                        // if (value.length < 6) {
                        //   return 'Password minimal 6 karakter';
                        // }
                        return null;
                      },
                    ),
                    SizedBox(height: 10),
                     // Forgot Password Link
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/forgot-password');
                        },
                        child: Text(
                          'Lupa Password?',
                          style: TextStyle(color: AppColors.primary),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),


                    // Login Button
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, child) {
                        return CustomButton(
                          text: 'Masuk',
                          onPressed: authProvider.isLoading ? null : _login,
                          isLoading: authProvider.isLoading,
                        );
                      },
                    ),
                    SizedBox(height: 20),

                    // Register Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Belum punya akun? ',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, '/register');
                          },
                          child: Text(
                            'Daftar di sini',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
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

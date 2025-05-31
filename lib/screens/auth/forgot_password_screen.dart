import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'otp_verification_screen.dart'; // For OtpPurpose

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetOtp() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final email = _emailController.text.trim();
    final result = await authProvider.forgotPassword(email);

    if (result['success'] == true) {
      Helpers.showSnackBar(
          context, result['message'] ?? 'OTP berhasil dikirim');
      // Navigate to OTP screen for password reset
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => OtpVerificationScreen(
            email: email,
            purpose: OtpPurpose.passwordReset,
          ),
        ),
      );
    } else {
      Helpers.showSnackBar(context, result['error'] ?? 'Gagal mengirim OTP',
          isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lupa Password'),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppSizes.paddingLarge),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Reset Password Anda',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10),
                Text(
                  'Masukkan email akun Anda untuk menerima kode OTP.',
                  style:
                      TextStyle(fontSize: 16, color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 30),
                CustomTextField(
                  controller: _emailController,
                  labelText: 'Email',
                  hintText: 'Masukkan email terdaftar',
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
                SizedBox(height: 30),
                Consumer<AuthProvider>(
                  builder: (context, auth, child) {
                    return CustomButton(
                      text: 'Kirim OTP',
                      onPressed: auth.isLoading ? null : _sendResetOtp,
                      isLoading: auth.isLoading,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

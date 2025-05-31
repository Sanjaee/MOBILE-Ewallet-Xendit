import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final String otp; // OTP received from previous screen

  ResetPasswordScreen({required this.email, required this.otp});

  @override
  _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final newPassword = _newPasswordController.text;

    final result = await authProvider.resetPassword(widget.email, widget.otp, newPassword);

    if (result['success'] == true) {
      Helpers.showSnackBar(context, result['message'] ?? 'Password berhasil direset. Silakan login.');
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } else {
      Helpers.showSnackBar(context, result['error'] ?? 'Gagal mereset password.', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Atur Password Baru'),
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
                  'Masukkan Password Baru',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10),
                Text(
                  'Email: ${widget.email}', // Display email for confirmation
                  style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 30),
                CustomTextField(
                  controller: _newPasswordController,
                  labelText: 'Password Baru',
                  hintText: 'Masukkan password baru',
                  obscureText: _obscureNewPassword,
                  prefixIcon: Icons.lock,
                  suffixIcon: IconButton(
                    icon: Icon(_obscureNewPassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password baru harus diisi';
                    }
                    if (value.length < 6) {
                      return 'Password minimal 6 karakter';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                CustomTextField(
                  controller: _confirmPasswordController,
                  labelText: 'Konfirmasi Password Baru',
                  hintText: 'Masukkan ulang password baru',
                  obscureText: _obscureConfirmPassword,
                  prefixIcon: Icons.lock_outline,
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Konfirmasi password harus diisi';
                    }
                    if (value != _newPasswordController.text) {
                      return 'Password tidak sama';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 30),
                Consumer<AuthProvider>(
                  builder: (context, auth, child) {
                    return CustomButton(
                      text: 'Reset Password',
                      onPressed: auth.isLoading ? null : _resetPassword,
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

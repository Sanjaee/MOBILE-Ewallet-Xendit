import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Untuk Clipboard
import 'package:provider/provider.dart';
import 'package:pinput/pinput.dart'; // Import pinput

import '../../providers/auth_provider.dart';
import '../../utils/constants.dart'; // For AppColors, AppSizes
import '../../utils/helpers.dart'; // For Helpers.showSnackBar
import '../../widgets/custom_button.dart';

enum OtpPurpose { emailVerification, passwordReset }

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final OtpPurpose purpose;

  OtpVerificationScreen({required this.email, required this.purpose});

  @override
  _OtpVerificationScreenState createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _pinController = TextEditingController(); // Controller untuk Pinput
  final _focusNode = FocusNode(); // FocusNode untuk Pinput
  final _formKey = GlobalKey<FormState>();
  bool _isResendingOtp = false;

  @override
  void initState() {
    super.initState();
    // Minta fokus ke input OTP saat layar dimuat
    // dan coba paste dari clipboard jika ada
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      FocusScope.of(context).requestFocus(_focusNode);
      await _pasteOtpFromClipboard();
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _pasteOtpFromClipboard() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData != null && clipboardData.text != null) {
      final String pastedText = clipboardData.text!;
      // Cek apakah yang di-paste adalah 6 digit angka
      if (pastedText.length == 6 && int.tryParse(pastedText) != null) {
        setState(() {
          _pinController.setText(pastedText);
        });
        // Anda bisa langsung memanggil _verifyOtp() di sini jika diinginkan
        // atau biarkan pengguna menekan tombol verifikasi.
        // Misalnya:
        // Future.delayed(Duration(milliseconds: 100), _verifyOtp);
      }
    }
  }

  Future<void> _verifyOtp() async {
    _focusNode.unfocus(); // Tutup keyboard
    if (!_formKey.currentState!.validate()) {
      // Jika validasi pinput gagal, formKey mungkin tidak langsung menangkapnya
      // karena validator pinput berjalan terpisah.
      // Validator di Pinput akan menampilkan error di bawah fieldnya.
      // Kita bisa tambahkan pengecekan manual jika perlu.
      if (_pinController.length != 6) {
        Helpers.showSnackBar(context, 'OTP harus 6 digit', isError: true);
        return;
      }
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final otp = _pinController.text.trim();

    // Pastikan OTP adalah 6 digit sebelum mengirim
    if (otp.length != 6) {
      Helpers.showSnackBar(context, 'OTP harus 6 digit', isError: true);
      return;
    }

    Map<String, dynamic> result;
    if (widget.purpose == OtpPurpose.emailVerification) {
      result = await authProvider.verifyOtp(widget.email, otp);
      if (mounted) {
        // Pastikan widget masih ada di tree
        if (result['success'] == true) {
          Navigator.of(context)
              .pushNamedAndRemoveUntil('/home', (route) => false);
        } else {
          Helpers.showSnackBar(
              context, result['error'] ?? 'Verifikasi OTP gagal',
              isError: true);
        }
      }
    } else if (widget.purpose == OtpPurpose.passwordReset) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(
          '/reset-password',
          arguments: {'email': widget.email, 'otp': otp},
        );
      }
    }
  }

  Future<void> _resendOtp() async {
    setState(() {
      _isResendingOtp = true;
    });
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final type = widget.purpose == OtpPurpose.emailVerification
        ? "VERIFICATION"
        : "PASSWORD_RESET";
    final result = await authProvider.resendOtp(widget.email, type: type);

    if (mounted) {
      if (result['success'] == true) {
        Helpers.showSnackBar(
            context, result['message'] ?? 'OTP berhasil dikirim ulang');
        _pinController.clear();
        _focusNode.requestFocus();
      } else {
        Helpers.showSnackBar(
            context, result['error'] ?? 'Gagal mengirim ulang OTP',
            isError: true);
      }
      setState(() {
        _isResendingOtp = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tema default untuk Pinput
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 60,
      textStyle: TextStyle(
          fontSize: 22,
          color: AppColors.textPrimary, // Sesuaikan dengan AppColors Anda
          fontWeight: FontWeight.bold),
      decoration: BoxDecoration(
        color: AppColors.background, // Warna latar belakang kotak OTP
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.textPrimary), // Sesuaikan
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(color: AppColors.primary, width: 2), // Sesuaikan
      ),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        color: AppColors.primary.withOpacity(0.1), // Warna setelah diisi
        border: Border.all(color: AppColors.primary), // Sesuaikan
      ),
    );
    final errorPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(color: AppColors.error), // Warna border jika error
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Verifikasi OTP'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Provider.of<AuthProvider>(context, listen: false)
                .cancelOtpVerification();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          // Pusatkan konten
          child: SingleChildScrollView(
            // Agar bisa scroll jika konten melebihi layar
            padding: EdgeInsets.all(AppSizes.paddingLarge),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.phonelink_lock_outlined,
                      size: 80, color: AppColors.primary),
                  SizedBox(height: 24),
                  Text(
                    'Masukkan Kode OTP',
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Kode OTP 6 digit telah dikirim ke email:\n${widget.email}',
                    style: TextStyle(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                        height: 1.4),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 32),
                  // Pinput widget
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Pinput(
                      length: 6,
                      controller: _pinController,
                      focusNode: _focusNode,
                      defaultPinTheme: defaultPinTheme,
                      focusedPinTheme: focusedPinTheme,
                      submittedPinTheme: submittedPinTheme,
                      errorPinTheme: errorPinTheme,
                      pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
                      showCursor: true,
                      validator: (s) {
                        if (s == null || s.isEmpty) return 'OTP harus diisi';
                        if (s.length != 6) return 'OTP harus 6 digit';
                        return null; // null berarti valid
                      },
                      onCompleted: (pin) {
                        print('OTP Terisi: $pin');
                        _verifyOtp(); // Otomatis verifikasi saat 6 digit terisi
                      },
                      onTapOutside: (event) {
                        // Untuk menutup keyboard saat tap di luar
                        _focusNode.unfocus();
                      },
                      hapticFeedbackType: HapticFeedbackType.lightImpact,
                    ),
                  ),
                  SizedBox(height: 32),
                  Consumer<AuthProvider>(
                    builder: (context, auth, child) {
                      return CustomButton(
                        text: 'Verifikasi',
                        onPressed: auth.isLoading ? null : _verifyOtp,
                        isLoading: auth.isLoading,
                      );
                    },
                  ),
                  SizedBox(height: 20),
                  TextButton(
                    onPressed: _isResendingOtp ? null : _resendOtp,
                    child: _isResendingOtp
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.primary))
                        : Text(
                            'Kirim Ulang OTP',
                            style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 15),
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

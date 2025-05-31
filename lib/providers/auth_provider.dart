import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';

enum AuthStatus {
  uninitialized,
  authenticated,
  authenticating,
  unauthenticated,
  needsVerification, // New status
}

class AuthProvider with ChangeNotifier {
  User? _user;
  AuthStatus _status = AuthStatus.uninitialized;
  String? _error;
  String? _verificationEmail; // Email for OTP verification

  User? get user => _user;
  AuthStatus get status => _status;
  String? get error => _error;
  String? get verificationEmail => _verificationEmail;

  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.authenticating;
  bool get isUninitialized => _status == AuthStatus.uninitialized;


  AuthProvider() {
    loadUser();
  }

  Future<void> _saveUserToPrefs(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', user.token);
    await prefs.setString('userId', user.id);
    await prefs.setString('name', user.name);
    await prefs.setString('email', user.email);
    if (user.phoneNumber != null) {
      await prefs.setString('phoneNumber', user.phoneNumber!);
    } else {
      await prefs.remove('phoneNumber');
    }
    await prefs.setDouble('balance', user.balance);
    await prefs.setString('role', user.role);
    await prefs.setBool('isVerified', user.isVerified); // Menyimpan isVerified
    await prefs.setString('createdAt', user.createdAt.toIso8601String());
    await prefs.setString('updatedAt', user.updatedAt.toIso8601String());
  }

  Future<void> loadUser() async {
    _status = AuthStatus.authenticating;
    notifyListeners(); // Notify listeners at the beginning of an async operation

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    final userId = prefs.getString('userId');
    final name = prefs.getString('name');
    final email = prefs.getString('email');
    final phoneNumber = prefs.getString('phoneNumber');
    final balance = prefs.getDouble('balance');
    final role = prefs.getString('role');
    final isVerified = prefs.getBool('isVerified'); // Memuat isVerified
    final createdAtString = prefs.getString('createdAt');
    final updatedAtString = prefs.getString('updatedAt');

    if (userId != null && name != null && email != null && createdAtString != null && updatedAtString != null && isVerified != null) {
       try {
        _user = User(
          id: userId,
          name: name,
          email: email,
          token: token,
          phoneNumber: phoneNumber,
          balance: balance ?? 0.0,
          role: role ?? 'USER',
          isVerified: isVerified, // Menggunakan isVerified dari SharedPreferences
          createdAt: DateTime.parse(createdAtString),
          updatedAt: DateTime.parse(updatedAtString),
        );
        // Verifikasi token dengan server di sini akan lebih baik
        // Jika token valid, status authenticated, jika tidak unauthenticated
        _status = AuthStatus.authenticated;
      } catch (e) {
        print("Error loading user from prefs: $e");
        await logout(); // Clear corrupted prefs
        _status = AuthStatus.unauthenticated;
      }
    } else {
      // Jika ada data penting yang hilang dari SharedPreferences (selain token yang sudah dicek)
      // anggap sebagai tidak terautentikasi dan bersihkan data yang mungkin tidak lengkap.
      print("Incomplete user data in SharedPreferences. Logging out.");
      await logout();
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    _status = AuthStatus.authenticating;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.login(email: email, password: password);

      if (response['data'] != null && response['data']['token'] != null) {
        final userData = response['data'];
        _user = User.fromJson(userData); // User.fromJson sudah menangani isVerified
        
        if (_user!.isVerified) {
            await _saveUserToPrefs(_user!);
            _status = AuthStatus.authenticated;
             _verificationEmail = null;
        } else {
            // Jika API mengembalikan user data tapi isVerified false (misal setelah login gagal karena belum verify)
            _verificationEmail = _user!.email;
            _status = AuthStatus.needsVerification;
            _error = response['error'] ?? 'Account not verified. Please verify your email.';
            // Jangan simpan user ke prefs jika belum terverifikasi, atau simpan dengan tanda khusus
        }
        notifyListeners();
        // Sesuaikan respons berdasarkan status verifikasi
        return {'success': _user!.isVerified, 'needsVerification': !_user!.isVerified, 'email': _user!.email, 'error': _user!.isVerified ? null : _error, 'message': response['message']};

      } else if (response['needsVerification'] == true) { // Kasus dari API server.js
        _verificationEmail = response['email'] ?? email;
        _status = AuthStatus.needsVerification;
        _error = response['error'] ?? 'Account not verified.';
        notifyListeners();
        return {'success': false, 'needsVerification': true, 'email': _verificationEmail, 'error': _error};
      }
      
      _error = response['error'] ?? 'Login failed';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return {'success': false, 'error': _error};
    } catch (e) {
      _error = 'Network error: ${e.toString()}';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return {'success': false, 'error': _error};
    }
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String phoneNumber,
  }) async {
    _status = AuthStatus.authenticating;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.register(
        name: name,
        email: email,
        password: password,
        phoneNumber: phoneNumber,
      );

      if (response['data'] != null && response['data']['needsVerification'] == true) {
        _verificationEmail = response['data']['email'] ?? email;
        _status = AuthStatus.needsVerification; 
        _error = null; 
        notifyListeners();
        return {'success': true, 'needsVerification': true, 'email': _verificationEmail, 'message': response['message']};
      }
      _error = response['error'] ?? 'Registration failed';
      _status = AuthStatus.unauthenticated; 
      notifyListeners();
      return {'success': false, 'error': _error};
    } catch (e) {
      _error = 'Network error: ${e.toString()}';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return {'success': false, 'error': _error};
    }
  }

  Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
    _status = AuthStatus.authenticating;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.verifyOtp(email: email, otp: otp);

      if (response['data'] != null && response['data']['token'] != null) {
        final userData = response['data'];
        _user = User.fromJson(userData); // User.fromJson sudah menangani isVerified
        await _saveUserToPrefs(_user!);
        _status = AuthStatus.authenticated;
        _verificationEmail = null; 
        notifyListeners();
        return {'success': true, 'message': response['message']};
      }
      _error = response['error'] ?? 'OTP verification failed';
      _status = AuthStatus.needsVerification; 
      notifyListeners();
      return {'success': false, 'error': _error};
    } catch (e) {
      _error = 'Network error: ${e.toString()}';
      _status = AuthStatus.needsVerification; 
      notifyListeners();
      return {'success': false, 'error': _error};
    }
  }

  Future<Map<String, dynamic>> resendOtp(String email, {String type = "VERIFICATION"}) async {
    _error = null;
    // notifyListeners(); // Tidak perlu mengubah status utama untuk resend, mungkin loading spesifik di UI

    try {
      final response = await ApiService.resendOtp(email: email, type: type);
      if (response['message'] != null && response['message'].toLowerCase().contains('sent successfully')) {
         return {'success': true, 'message': response['message']};
      }
      _error = response['error'] ?? 'Failed to resend OTP';
      return {'success': false, 'error': _error};
    } catch (e) {
      _error = 'Network error: ${e.toString()}';
      return {'success': false, 'error': _error};
    }
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    _status = AuthStatus.authenticating; 
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.forgotPassword(email: email);
      if (response['message'] != null && response['message'].toLowerCase().contains('sent to your email')) {
        _verificationEmail = email; 
        _status = AuthStatus.unauthenticated; // Tetap unauthenticated, menunggu OTP reset
        notifyListeners();
        return {'success': true, 'message': response['message'], 'email': email};
      }
      _error = response['error'] ?? 'Failed to send password reset OTP.';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return {'success': false, 'error': _error};
    } catch (e) {
      _error = 'Network error: ${e.toString()}';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return {'success': false, 'error': _error};
    }
  }

  Future<Map<String, dynamic>> resetPassword(String email, String otp, String newPassword) async {
    _status = AuthStatus.authenticating;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.resetPassword(email: email, otp: otp, newPassword: newPassword);
      if (response['message'] != null && response['message'].toLowerCase().contains('reset successfully')) {
        _status = AuthStatus.unauthenticated; 
        _verificationEmail = null;
        notifyListeners();
        return {'success': true, 'message': response['message']};
      }
      _error = response['error'] ?? 'Password reset failed.';
      _status = AuthStatus.unauthenticated; 
      notifyListeners();
      return {'success': false, 'error': _error};
    } catch (e) {
      _error = 'Network error: ${e.toString()}';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return {'success': false, 'error': _error};
    }
  }

  Future<Map<String, dynamic>> changePassword(String oldPassword, String newPassword) async {
    if (_user == null || _user!.token.isEmpty) {
      return {'success': false, 'error': 'User not authenticated'};
    }
    _status = AuthStatus.authenticating;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.changePassword(
        token: _user!.token,
        oldPassword: oldPassword,
        newPassword: newPassword,
      );

      if (response['message'] != null && response['message'].toLowerCase().contains('updated successfully')) {
        _status = AuthStatus.authenticated; 
        // Pertimbangkan untuk memuat ulang data pengguna dari server atau memperbarui _user secara lokal jika ada perubahan data
        notifyListeners();
        return {'success': true, 'message': response['message']};
      }
      _error = response['error'] ?? 'Password change failed.';
      _status = AuthStatus.authenticated; 
      notifyListeners();
      return {'success': false, 'error': _error};
    } catch (e) {
      _error = 'Network error: ${e.toString()}';
      _status = AuthStatus.authenticated;
      notifyListeners();
      return {'success': false, 'error': _error};
    }
  }


  Future<void> logout() async {
    _user = null;
    _status = AuthStatus.unauthenticated;
    _verificationEmail = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('userId');
    await prefs.remove('name');
    await prefs.remove('email');
    await prefs.remove('phoneNumber');
    await prefs.remove('balance');
    await prefs.remove('role');
    await prefs.remove('isVerified'); // Menghapus isVerified saat logout
    await prefs.remove('createdAt');
    await prefs.remove('updatedAt');
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void cancelOtpVerification() {
    if (_status == AuthStatus.needsVerification) {
      _status = AuthStatus.unauthenticated;
      _verificationEmail = null;
      _error = null;
      notifyListeners();
    }
  }
}

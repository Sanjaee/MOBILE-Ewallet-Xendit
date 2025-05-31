import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userId = prefs.getString('userId');
    final name = prefs.getString('name');
    final email = prefs.getString('email');
    final phoneNumber = prefs.getString('phoneNumber');
    final balance = prefs.getDouble('balance') ?? 0;
    final role = prefs.getString('role') ?? 'USER';
    final createdAt = prefs.getString('createdAt');
    final updatedAt = prefs.getString('updatedAt');

    if (token != null &&
        userId != null &&
        name != null &&
        email != null &&
        createdAt != null &&
        updatedAt != null) {
      _user = User(
        id: userId,
        name: name,
        email: email,
        token: token,
        phoneNumber: phoneNumber,
        balance: balance,
        role: role,
        createdAt: DateTime.parse(createdAt),
        updatedAt: DateTime.parse(updatedAt),
      );
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.login(email: email, password: password);

      if (response['data'] != null) {
        final userData = response['data'];
        _user = User.fromJson(userData);

        // Save to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _user!.token);
        await prefs.setString('userId', _user!.id);
        await prefs.setString('name', _user!.name);
        await prefs.setString('email', _user!.email);
        await prefs.setString('phoneNumber', _user!.phoneNumber ?? '');
        await prefs.setDouble('balance', _user!.balance);
        await prefs.setString('role', _user!.role);
        await prefs.setString('createdAt', _user!.createdAt.toIso8601String());
        await prefs.setString('updatedAt', _user!.updatedAt.toIso8601String());

        _isLoading = false;
        notifyListeners();
        return true;
      }

      _error = response['error'] ?? 'Login failed';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Network error: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String phoneNumber,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.register(
        name: name,
        email: email,
        password: password,
        phoneNumber: phoneNumber,
      );

      if (response['data'] != null) {
        final userData = response['data'];
        _user = User.fromJson(userData);

        // Save to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _user!.token);
        await prefs.setString('userId', _user!.id);
        await prefs.setString('name', _user!.name);
        await prefs.setString('email', _user!.email);
        await prefs.setString('phoneNumber', _user!.phoneNumber ?? '');
        await prefs.setDouble('balance', _user!.balance);
        await prefs.setString('role', _user!.role);
        await prefs.setString('createdAt', _user!.createdAt.toIso8601String());
        await prefs.setString('updatedAt', _user!.updatedAt.toIso8601String());

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['error'] ?? 'Registration failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Network error: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/transaction_model.dart';
import '../models/payment_model.dart';

class WalletProvider with ChangeNotifier {
  double _balance = 0.0;
  List<Transaction> _transactions = [];
  bool _isLoading = false;
  String? _error;

  double get balance => _balance;
  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadTransactions(String token) async {
    print('🚀 Starting loadTransactions...');

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print(
          '🔄 Calling API with token: ${token.isNotEmpty ? "Token exists" : "No token"}');

      final response = await ApiService.getTransactions(token: token);

      print('📥 Full API Response: $response');

      // Check for API errors first
      if (response.containsKey('error')) {
        _error = response['error'];
        print('❌ API returned error: $_error');

        // Additional info for debugging
        if (response.containsKey('statusCode')) {
          print('📊 Status Code: ${response['statusCode']}');

          if (response['statusCode'] == 401) {
            _error = 'Authentication failed. Please login again.';
          } else if (response['statusCode'] == 403) {
            _error = 'Access denied. Please check your permissions.';
          }
        }

        _transactions = [];
      }
      // Check for successful response with data
      else if (response.containsKey('data') && response['data'] != null) {
        final data = response['data'];
        print('📊 Response data keys: ${data.keys.toList()}');

        if (data.containsKey('transactions') && data['transactions'] != null) {
          final transactionsList = data['transactions'] as List;
          print('📋 Found ${transactionsList.length} transactions in response');

          if (transactionsList.isNotEmpty) {
            print('📄 First transaction sample: ${transactionsList.first}');
          }

          try {
            _transactions = transactionsList.map((json) {
              print('🔧 Parsing transaction: ${json['id']} - ${json['type']}');
              return Transaction.fromJson(json as Map<String, dynamic>);
            }).toList();

            print('✅ Successfully parsed ${_transactions.length} transactions');
            _error = null;

            // Sort transactions by date (newest first)
            _transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          } catch (parseError) {
            _error = 'Failed to parse transactions: $parseError';
            print('❌ Parse Error: $parseError');
            _transactions = [];
          }
        } else {
          print('⚠️ No transactions array found in data');
          print('📊 Available data keys: ${data.keys.toList()}');
          _transactions = [];
          // Don't set error here, just empty list
        }

        // Log pagination info if available
        if (data.containsKey('pagination')) {
          final pagination = data['pagination'];
          print(
              '📖 Pagination: Page ${pagination['page']} of ${pagination['totalPages']}, Total: ${pagination['total']}');
        }
      }
      // Handle unexpected response format
      else {
        _error = 'Unexpected response format from server';
        print('❌ Unexpected response format: $response');
        _transactions = [];
      }
    } catch (e) {
      _error = 'Network error: ${e.toString()}';
      print('🌐 Network/Exception Error: $e');
      _transactions = [];
    }

    _isLoading = false;
    notifyListeners();

    print('🏁 loadTransactions completed');
    print(
        '📊 Final state: ${_transactions.length} transactions, error: $_error');
  }

  // Method to refresh transactions
  Future<void> refreshTransactions(String token) async {
    print('🔄 Refreshing transactions...');
    await loadTransactions(token);
  }

  // Method to load more transactions (for pagination)
  Future<void> loadMoreTransactions(String token, {int page = 2}) async {
    if (_isLoading) return; // Prevent multiple calls

    print('📖 Loading more transactions (page $page)...');

    try {
      final response = await ApiService.getTransactions(
        token: token,
        page: page,
        limit: 20,
      );

      if (response.containsKey('data') &&
          response['data'] != null &&
          response['data']['transactions'] != null) {
        final newTransactions = (response['data']['transactions'] as List)
            .map((json) => Transaction.fromJson(json as Map<String, dynamic>))
            .toList();

        _transactions.addAll(newTransactions);
        _transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        notifyListeners();
        print('✅ Loaded ${newTransactions.length} more transactions');
      }
    } catch (e) {
      print('❌ Error loading more transactions: $e');
    }
  }

  Future<void> loadBalance(String token) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.getBalance(token);
      if (response['data'] != null) {
        _balance = response['data']['balance'].toDouble();
        _error = null;
      } else {
        _error = response['error'];
      }
    } catch (e) {
      _error = 'Failed to load balance: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<PaymentResponse?> topUp({
    required String token,
    required int amount,
    required String paymentMethod,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.topUp(
        token: token,
        amount: amount,
        paymentMethod: paymentMethod,
      );

      _isLoading = false;
      notifyListeners();

      if (response['success'] == true) {
        return PaymentResponse.fromJson(response);
      } else {
        _error = response['error'] ?? 'Top up failed';
        notifyListeners();
        return null;
      }
    } catch (e) {
      _error = 'Network error: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<PaymentStatus?> checkPaymentStatus({
    required String token,
    required String referenceId,
  }) async {
    try {
      final response = await ApiService.checkPaymentStatus(
        token: token,
        referenceId: referenceId,
      );

      if (response['status'] != null) {
        return PaymentStatus.fromJson(response);
      } else {
        _error = response['error'];
        notifyListeners();
        return null;
      }
    } catch (e) {
      _error = 'Failed to check payment status: ${e.toString()}';
      notifyListeners();
      return null;
    }
  }

  Future<bool> transfer({
    required String token,
    required String recipientPhoneNumber,
    required int amount,
    String? description,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.transfer(
        token: token,
        recipientPhoneNumber: recipientPhoneNumber,
        amount: amount,
        description: description,
      );

      _isLoading = false;

      if (response['message'] != null && !response.containsKey('error')) {
        // Refresh transactions after successful transfer
        await loadTransactions(token);
        await loadBalance(token);
        notifyListeners();
        return true;
      } else {
        _error = response['error'] ?? 'Transfer failed';
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

  Future<bool> withdraw({
    required String token,
    required int amount,
    required String bankCode,
    required String accountNumber,
    required String accountHolderName,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.withdraw(
        token: token,
        amount: amount,
        bankCode: bankCode,
        accountNumber: accountNumber,
        accountHolderName: accountHolderName,
      );

      _isLoading = false;

      if (response['message'] != null && !response.containsKey('error')) {
        // Refresh transactions after successful withdrawal
        await loadTransactions(token);
        await loadBalance(token);
        notifyListeners();
        return true;
      } else {
        _error = response['error'] ?? 'Withdrawal failed';
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

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Debug method to check current state
  void debugState() {
    print('🔍 WalletProvider Debug State:');
    print('   - Balance: $_balance');
    print('   - Transactions count: ${_transactions.length}');
    print('   - Is loading: $_isLoading');
    print('   - Error: $_error');
    if (_transactions.isNotEmpty) {
      print(
          '   - Latest transaction: ${_transactions.first.type} - ${_transactions.first.amount}');
    }
  }
}

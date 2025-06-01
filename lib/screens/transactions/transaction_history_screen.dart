import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../../widgets/transaction_item.dart';

class TransactionHistoryScreen extends StatefulWidget {
  @override
  _TransactionHistoryScreenState createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  String? _selectedType;
  final List<String> _transactionTypes = [
    'Semua',
    'TOPUP',
    'TRANSFER',
    'WITHDRAW',
    'FEE'
  ];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);

    if (authProvider.user != null) {
      await walletProvider.loadTransactions(authProvider.user!.token);
    }
  }

  Future<void> _refreshTransactions() async {
    await _loadTransactions();
  }

  List<dynamic> get _filteredTransactions {
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    if (_selectedType == null || _selectedType == 'Semua') {
      return walletProvider.transactions;
    }
    return walletProvider.transactions
        .where((transaction) => transaction.type == _selectedType)
        .toList();
  }

  String _getTypeDisplayName(String type) {
    switch (type) {
      case 'TOPUP':
        return 'Top Up';
      case 'TRANSFER':
        return 'Transfer';
      case 'WITHDRAW':
        return 'Tarik Tunai';
      case 'FEE':
        return 'Biaya Admin';
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Riwayat Transaksi'),
        actions: [
          IconButton(
            onPressed: _refreshTransactions,
            icon: Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            padding: EdgeInsets.symmetric(horizontal: AppSizes.paddingMedium),
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _transactionTypes.length,
              itemBuilder: (context, index) {
                final type = _transactionTypes[index];
                final isSelected = _selectedType == type ||
                    (_selectedType == null && type == 'Semua');

                return Container(
                  margin: EdgeInsets.only(right: 8, top: 8, bottom: 8),
                  child: FilterChip(
                    label: Text(_getTypeDisplayName(type)),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedType =
                            selected ? (type == 'Semua' ? null : type) : null;
                      });
                    },
                    selectedColor: AppColors.primary.withOpacity(0.2),
                    checkmarkColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),

          // Transactions List
          Expanded(
            child: Consumer<WalletProvider>(
              builder: (context, walletProvider, child) {
                if (walletProvider.isLoading) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading transactions...'),
                      ],
                    ),
                  );
                }

                if (walletProvider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: AppColors.error,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Gagal memuat riwayat transaksi',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 8),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            walletProvider.error!,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _refreshTransactions,
                          child: Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  );
                }

                final filteredTransactions = _filteredTransactions;

                if (filteredTransactions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long,
                          size: 64,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Belum ada transaksi',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          _selectedType == null
                              ? 'Riwayat transaksi Anda akan muncul di sini'
                              : 'Tidak ada transaksi ${_getTypeDisplayName(_selectedType!).toLowerCase()}',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _refreshTransactions,
                  child: ListView.builder(
                    padding: EdgeInsets.all(AppSizes.paddingMedium),
                    itemCount: filteredTransactions.length,
                    itemBuilder: (context, index) {
                      final transaction = filteredTransactions[index];

                      // Add date separator
                      bool showDateSeparator = false;
                      if (index == 0) {
                        showDateSeparator = true;
                      } else {
                        final prevTransaction = filteredTransactions[index - 1];
                        final currentDate = DateTime(
                          transaction.createdAt.year,
                          transaction.createdAt.month,
                          transaction.createdAt.day,
                        );
                        final prevDate = DateTime(
                          prevTransaction.createdAt.year,
                          prevTransaction.createdAt.month,
                          prevTransaction.createdAt.day,
                        );
                        showDateSeparator =
                            !currentDate.isAtSameMomentAs(prevDate);
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (showDateSeparator) ...[
                            if (index > 0) SizedBox(height: 16),
                            Container(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                _formatDateSeparator(transaction.createdAt),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                          TransactionItem(transaction: transaction),
                        ],
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateSeparator(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(Duration(days: 1));
    final transactionDate = DateTime(date.year, date.month, date.day);

    if (transactionDate.isAtSameMomentAs(today)) {
      return 'Hari Ini';
    } else if (transactionDate.isAtSameMomentAs(yesterday)) {
      return 'Kemarin';
    } else {
      final months = [
        '',
        'Januari',
        'Februari',
        'Maret',
        'April',
        'Mei',
        'Juni',
        'Juli',
        'Agustus',
        'September',
        'Oktober',
        'November',
        'Desember'
      ];
      return '${date.day} ${months[date.month]} ${date.year}';
    }
  }
}

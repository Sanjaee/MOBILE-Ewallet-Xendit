import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class WithdrawScreen extends StatefulWidget {
  @override
  _WithdrawScreenState createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  final _amountController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _accountHolderNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _selectedBankCode;

  @override
  void dispose() {
    _amountController.dispose();
    _accountNumberController.dispose();
    _accountHolderNameController.dispose();
    super.dispose();
  }

  int _calculateFee(int amount) {
    if (amount > 250000000) {
      // More than 250 million
      return 10000;
    } else {
      return 2500;
    }
  }

  Future<void> _processWithdraw() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBankCode == null) {
      Helpers.showSnackBar(context, 'Pilih bank tujuan', isError: true);
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);

    final amount = int.parse(_amountController.text.replaceAll('.', ''));
    final fee = _calculateFee(amount);
    final totalAmount = amount + fee;

    // Check if user has sufficient balance
    if (walletProvider.balance < totalAmount) {
      Helpers.showSnackBar(
        context,
        'Saldo tidak mencukupi untuk penarikan + biaya admin',
        isError: true,
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Konfirmasi Tarik Tunai'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Bank: ${PaymentMethods.banks.entries.firstWhere((e) => e.value == _selectedBankCode).key}'),
            Text('Rekening: ${_accountNumberController.text}'),
            Text('Nama: ${_accountHolderNameController.text}'),
            Text(
                'Jumlah Penarikan: ${Helpers.formatCurrency(amount.toDouble())}'),
            Text('Biaya Admin: ${Helpers.formatCurrency(fee.toDouble())}'),
            Divider(),
            Text(
              'Total Dipotong: ${Helpers.formatCurrency(totalAmount.toDouble())}',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
            ),
            Text(
              'Yang Diterima: ${Helpers.formatCurrency(amount.toDouble())}',
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Tarik Tunai'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await walletProvider.withdraw(
      token: authProvider.user!.token,
      amount: amount,
      bankCode: _selectedBankCode!,
      accountNumber: _accountNumberController.text,
      accountHolderName: _accountHolderNameController.text,
    );

    if (success) {
      Helpers.showSnackBar(context, 'Penarikan berhasil diproses!');
      Navigator.pop(context);
    } else {
      Helpers.showSnackBar(
        context,
        walletProvider.error ?? 'Penarikan gagal',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tarik Tunai'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSizes.paddingLarge),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current Balance
              Consumer<WalletProvider>(
                builder: (context, walletProvider, child) {
                  return Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Saldo Saat Ini',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          Helpers.formatCurrency(walletProvider.balance),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              SizedBox(height: 24),

              // Bank Selection
              Text(
                'Bank Tujuan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedBankCode,
                decoration: InputDecoration(
                  labelText: 'Pilih Bank',
                  prefixIcon: Icon(Icons.account_balance),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                items: PaymentMethods.banks.entries.map((entry) {
                  return DropdownMenuItem<String>(
                    value: entry.value,
                    child: Text(entry.key),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedBankCode = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Pilih bank tujuan';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),

              // Account Number
              Text(
                'Nomor Rekening',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 8),
              CustomTextField(
                controller: _accountNumberController,
                labelText: 'Nomor Rekening',
                hintText: 'Masukkan nomor rekening',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.credit_card,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nomor rekening harus diisi';
                  }
                  if (value.length < 8) {
                    return 'Nomor rekening minimal 8 digit';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),

              // Account Holder Name
              Text(
                'Nama Pemilik Rekening',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 8),
              CustomTextField(
                controller: _accountHolderNameController,
                labelText: 'Nama Pemilik Rekening',
                hintText: 'Masukkan nama sesuai rekening',
                prefixIcon: Icons.person,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama pemilik rekening harus diisi';
                  }
                  if (value.length < 3) {
                    return 'Nama minimal 3 karakter';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),

              // Amount
              Text(
                'Jumlah Penarikan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 8),
              CustomTextField(
                controller: _amountController,
                labelText: 'Jumlah',
                hintText: 'Masukkan jumlah',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.money,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  TextInputFormatter.withFunction((oldValue, newValue) {
                    if (newValue.text.isEmpty) return newValue;
                    final number = int.parse(newValue.text);
                    final formatted = number.toString().replaceAllMapped(
                          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                          (Match m) => '${m[1]}.',
                        );
                    return TextEditingValue(
                      text: formatted,
                      selection:
                          TextSelection.collapsed(offset: formatted.length),
                    );
                  }),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Jumlah harus diisi';
                  }
                  final amount = int.parse(value.replaceAll('.', ''));
                  if (amount < 50000) {
                    return 'Minimal penarikan Rp 50.000';
                  }
                  if (amount > 10000000) {
                    return 'Maksimal penarikan Rp 10.000.000';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {}); // Refresh UI for fee calculation
                },
              ),
              SizedBox(height: 20),

              // Fee Information
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.orange, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Informasi Biaya',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Biaya admin: Rp 2.500 (Rp 10.000 jika > 250 juta)\n'
                      '• Biaya admin ditambahkan ke total penarikan\n'
                      '• Proses penarikan: 1-3 hari kerja\n'
                      '• Pastikan data rekening sudah benar',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade600,
                        height: 1.4,
                      ),
                    ),
                    if (_amountController.text.isNotEmpty) ...[
                      SizedBox(height: 8),
                      Divider(color: Colors.orange.shade300),
                      SizedBox(height: 8),
                      Builder(
                        builder: (context) {
                          final amount = int.tryParse(
                                  _amountController.text.replaceAll('.', '')) ??
                              0;
                          final fee = _calculateFee(amount);
                          final totalAmount = amount + fee;
                          return Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Jumlah penarikan:',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.orange.shade600),
                                  ),
                                  Text(
                                    Helpers.formatCurrency(amount.toDouble()),
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.orange.shade600),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Biaya admin:',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.orange.shade600),
                                  ),
                                  Text(
                                    Helpers.formatCurrency(fee.toDouble()),
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.orange.shade600),
                                  ),
                                ],
                              ),
                              Divider(
                                  color: Colors.orange.shade300, height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Total dipotong:',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red.shade600,
                                    ),
                                  ),
                                  Text(
                                    Helpers.formatCurrency(
                                        totalAmount.toDouble()),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Yang diterima:',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade600,
                                    ),
                                  ),
                                  Text(
                                    Helpers.formatCurrency(amount.toDouble()),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: 30),

              // Withdraw Button
              Consumer<WalletProvider>(
                builder: (context, walletProvider, child) {
                  return CustomButton(
                    text: 'Tarik Tunai',
                    onPressed:
                        walletProvider.isLoading ? null : _processWithdraw,
                    isLoading: walletProvider.isLoading,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

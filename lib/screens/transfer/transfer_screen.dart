import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class TransferScreen extends StatefulWidget {
  @override
  _TransferScreenState createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final _recipientPhoneNumberController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _recipientPhoneNumberController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
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

  Future<void> _processTransfer() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);

    final amount = int.parse(_amountController.text.replaceAll('.', ''));
    final fee = _calculateFee(amount);
    final totalAmount = amount + fee;

    // Check if user has sufficient balance
    if (walletProvider.balance < totalAmount) {
      Helpers.showSnackBar(
        context,
        'Saldo tidak mencukupi untuk transfer + biaya admin',
        isError: true,
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Konfirmasi Transfer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nomor Telepon: ${_recipientPhoneNumberController.text}'),
            Text(
                'Jumlah Transfer: ${Helpers.formatCurrency(amount.toDouble())}'),
            Text('Biaya Admin: ${Helpers.formatCurrency(fee.toDouble())}'),
            Divider(),
            Text(
              'Total Dipotong: ${Helpers.formatCurrency(totalAmount.toDouble())}',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
            ),
            Text(
              'Penerima Dapat: ${Helpers.formatCurrency(amount.toDouble())}',
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
            ),
            if (_descriptionController.text.isNotEmpty) ...[
              SizedBox(height: 8),
              Text('Keterangan: ${_descriptionController.text}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Transfer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await walletProvider.transfer(
      token: authProvider.user!.token,
      recipientPhoneNumber: _recipientPhoneNumberController.text,
      amount: amount,
      description: _descriptionController.text.isEmpty
          ? null
          : _descriptionController.text,
    );

    if (success) {
      Helpers.showSnackBar(context, 'Transfer berhasil!');
      Navigator.pop(context);
    } else {
      Helpers.showSnackBar(
        context,
        walletProvider.error ?? 'Transfer gagal',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Transfer Uang'),
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

              // Recipient Phone Number
              Text(
                'Nomor Telepon Penerima',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 8),
              CustomTextField(
                controller: _recipientPhoneNumberController,
                labelText: 'Nomor Telepon Penerima',
                hintText: 'Masukkan nomor telepon penerima',
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nomor telepon penerima harus diisi';
                  }
                  // Allow any number input
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
                      '• Biaya admin ditambahkan ke total transfer\n'
                      '• Penerima akan mendapat jumlah transfer penuh\n'
                      '• Pastikan nomor telepon penerima sudah benar',
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
                          // Note: Fee calculation should ideally come from backend response
                          // Using a placeholder calculation for UI display based on backend logic
                          final fee = amount > 250000000 ? 10000 : 2500;
                          final totalAmount = amount + fee;
                          return Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Jumlah transfer:',
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
                                    'Penerima dapat:',
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

              // Transfer Button
              Consumer<WalletProvider>(
                builder: (context, walletProvider, child) {
                  return CustomButton(
                    text: 'Transfer',
                    onPressed:
                        walletProvider.isLoading ? null : _processTransfer,
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

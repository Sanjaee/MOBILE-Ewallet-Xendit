import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'payment_screen.dart';

class TopupScreen extends StatefulWidget {
  @override
  _TopupScreenState createState() => _TopupScreenState();
}

class _TopupScreenState extends State<TopupScreen> {
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _selectedPaymentMethod;
  int? _selectedQuickAmount;

  final List<int> _quickAmounts = [100000, 200000, 500000, 1000000];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _selectQuickAmount(int amount) {
    setState(() {
      _selectedQuickAmount = amount;
    });
    _amountController.text = _formatNumberWithDots(amount);
  }

  String _formatNumberWithDots(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  String _formatQuickAmountText(int amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(0)}jt';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}rb';
    }
    return amount.toString();
  }

  Future<void> _processTopup() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPaymentMethod == null) {
      Helpers.showSnackBar(context, 'Pilih metode pembayaran', isError: true);
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);

    final amount = int.parse(_amountController.text.replaceAll('.', ''));

    final paymentResponse = await walletProvider.topUp(
      token: authProvider.user!.token,
      amount: amount,
      paymentMethod: _selectedPaymentMethod!,
    );

    if (paymentResponse != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentScreen(
            paymentResponse: paymentResponse,
            amount: amount,
          ),
        ),
      );
    } else {
      Helpers.showSnackBar(
        context,
        walletProvider.error ?? 'Gagal memproses top up',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Top Up Saldo'),
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

              // Amount Input
              Text(
                'Jumlah Top Up',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 8),
              CustomTextField(
                controller: _amountController,
                labelText: 'Nominal',
                hintText: 'Masukkan jumlah',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.money,
                onChanged: (value) {
                  // Reset selected quick amount when user types manually
                  if (_selectedQuickAmount != null) {
                    setState(() {
                      _selectedQuickAmount = null;
                    });
                  }
                },
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  TextInputFormatter.withFunction((oldValue, newValue) {
                    if (newValue.text.isEmpty) return newValue;
                    final number = int.parse(newValue.text);
                    final formatted = _formatNumberWithDots(number);
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
                  if (amount < 10000) {
                    return 'Minimal top up Rp 10.000';
                  }
                  if (amount > 10000000) {
                    return 'Maksimal top up Rp 10.000.000';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),

              // Quick Amount Cards
              Text(
                'Pilih Nominal',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.5,
                ),
                itemCount: _quickAmounts.length,
                itemBuilder: (context, index) {
                  final amount = _quickAmounts[index];
                  final isSelected = _selectedQuickAmount == amount;

                  return GestureDetector(
                    onTap: () => _selectQuickAmount(amount),
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withOpacity(0.1)
                            : Colors.white,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Rp ${_formatQuickAmountText(amount)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Rp ${_formatNumberWithDots(amount)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: isSelected
                                  ? AppColors.primary.withOpacity(0.8)
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 24),

              // Payment Method Selection
              Text(
                'Metode Pembayaran',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 8),

              // E-Wallet Options
              Text(
                'E-Wallet',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 8),
              ...PaymentMethods.eWallets.entries.map((entry) {
                return Container(
                  margin: EdgeInsets.only(bottom: 8),
                  child: RadioListTile<String>(
                    value: entry.value,
                    groupValue: _selectedPaymentMethod,
                    onChanged: (value) {
                      setState(() {
                        _selectedPaymentMethod = value;
                      });
                    },
                    title: Text(entry.key),
                    tileColor: Colors.grey.shade50,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 8),
                  ),
                );
              }).toList(),

              SizedBox(height: 30),

              // Process Button
              Consumer<WalletProvider>(
                builder: (context, walletProvider, child) {
                  return CustomButton(
                    text: 'Lanjutkan Pembayaran',
                    onPressed: walletProvider.isLoading ? null : _processTopup,
                    isLoading: walletProvider.isLoading,
                  );
                },
              ),

              SizedBox(height: 16),

              // Info
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Top up akan diproses melalui gateway pembayaran Xendit. Pastikan data Anda benar.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

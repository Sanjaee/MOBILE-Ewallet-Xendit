import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../models/payment_model.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/custom_button.dart';
import '../../config/app_config.dart';

class PaymentScreen extends StatefulWidget {
  final PaymentResponse paymentResponse;
  final int amount;

  const PaymentScreen({
    Key? key,
    required this.paymentResponse,
    required this.amount,
  }) : super(key: key);

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with WidgetsBindingObserver {
  bool _isCheckingStatus = false;
  PaymentStatus? _paymentStatus;
  Timer? _statusCheckTimer;
  int _checkAttempts = 0;
  static const int _maxCheckAttempts = 60; // 5 minutes (60 * 5 seconds)

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startStatusCheck();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _statusCheckTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      // App returned from background, check payment status immediately
      if (mounted) {
        _checkPaymentStatus();
      }
    }
  }

  void _startStatusCheck() {
    // Initial check after 2 seconds
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        _checkPaymentStatus();
      }
    });
  }

  void _scheduleNextCheck() {
    if (_checkAttempts < _maxCheckAttempts && mounted) {
      _statusCheckTimer?.cancel();
      _statusCheckTimer = Timer(Duration(seconds: 5), () {
        if (mounted) {
          _checkPaymentStatus();
        }
      });
    } else if (_checkAttempts >= _maxCheckAttempts) {
      // Maximum attempts reached, show timeout message
      _showPaymentTimeout();
    }
  }

  Future<void> _checkPaymentStatus() async {
    if (_isCheckingStatus || !mounted) return;

    setState(() {
      _isCheckingStatus = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final walletProvider =
          Provider.of<WalletProvider>(context, listen: false);

      final status = await walletProvider.checkPaymentStatus(
        token: authProvider.user!.token,
        referenceId: widget.paymentResponse.referenceId,
      );

      if (mounted) {
        setState(() {
          _isCheckingStatus = false;
          _paymentStatus = status;
          _checkAttempts++;
        });

        if (status != null) {
          if (status.status.toUpperCase() == 'COMPLETED') {
            // Payment successful
            _statusCheckTimer?.cancel();
            _showPaymentSuccess();
          } else if (status.status.toUpperCase() == 'FAILED' ||
              status.status.toUpperCase() == 'CANCELLED') {
            // Payment failed
            _statusCheckTimer?.cancel();
            _showPaymentFailed();
          } else {
            // Still pending, schedule next check
            _scheduleNextCheck();
          }
        } else {
          // Error checking status, retry
          _scheduleNextCheck();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingStatus = false;
          _checkAttempts++;
        });

        if (AppConfig.enableLogging) {
          print('Error checking payment status: $e');
        }

        // Retry on error
        _scheduleNextCheck();
      }
    }
  }

  void _showPaymentSuccess() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success Animation
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 64,
                ),
              ),
              SizedBox(height: 24),

              // Success Title
              Text(
                '🎉 Pembayaran Berhasil!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),

              // Amount Info dengan GRATIS badge
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      'Top Up Berhasil!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      Helpers.formatCurrency(widget.amount.toDouble()),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'telah ditambahkan ke saldo Anda',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.green.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),

              // New Balance
              if (_paymentStatus != null) ...[
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Saldo Terbaru',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        Helpers.formatCurrency(_paymentStatus!.currentBalance),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
              ],

              // GRATIS Confirmation
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '✨ Yang Anda bayar = Yang Anda terima\nTanpa potongan biaya apapun!',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.amber.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Close all dialogs and screens until we reach home screen
                  Navigator.of(context).popUntil((route) => route.isFirst);

                  // Use Future.microtask to refresh data after navigation
                  Future.microtask(() {
                    final authProvider =
                        Provider.of<AuthProvider>(context, listen: false);
                    final walletProvider =
                        Provider.of<WalletProvider>(context, listen: false);

                    // Refresh wallet data
                    walletProvider.loadBalance(authProvider.user!.token);
                    walletProvider.loadTransactions(authProvider.user!.token);
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Selesai',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentFailed() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error,
                  color: AppColors.error,
                  size: 64,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Pembayaran Gagal',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Text(
                'Pembayaran tidak dapat diproses. Silakan coba lagi dengan metode pembayaran yang berbeda.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close dialog
                      Navigator.of(context).pop(); // Back to topup screen
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Coba Lagi',
                      style: TextStyle(color: AppColors.error),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close dialog
                      Navigator.of(context).pop(); // Back to topup screen
                      Navigator.of(context).pop(); // Back to home screen
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.textSecondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('Kembali'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentTimeout() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.access_time,
                  color: AppColors.warning,
                  size: 64,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Waktu Habis',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Text(
                'Tidak dapat memverifikasi status pembayaran. Silakan cek riwayat transaksi atau hubungi customer service.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close dialog
                      _checkPaymentStatus(); // Try checking again
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.warning),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Cek Lagi',
                      style: TextStyle(color: AppColors.warning),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close dialog
                      Navigator.of(context).pop(); // Back to topup screen
                      Navigator.of(context).pop(); // Back to home screen
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.textSecondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('Kembali'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============ WEBVIEW POPUP LOGIC ============

  Future<void> _openPaymentWebView() async {
    if (widget.paymentResponse.checkoutUrl == null) {
      Helpers.showSnackBar(
        context,
        'URL pembayaran tidak tersedia',
        isError: true,
      );
      return;
    }

    print(
        '🌐 Opening WebView popup for: ${widget.paymentResponse.checkoutUrl}');

    // Navigate to WebView popup
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => XenditWebViewPopup(
          checkoutUrl: widget.paymentResponse.checkoutUrl!,
          referenceId: widget.paymentResponse.referenceId,
        ),
        fullscreenDialog: true, // Makes it appear as popup
      ),
    );

    print('🔄 WebView popup result: $result');

    // Handle result from WebView
    if (result == 'payment_completed') {
      // Payment completed, check status and show success
      _handlePaymentCompletionFromWebView();
    } else if (result == 'payment_failed') {
      _showPaymentFailed();
    }
    // If result is null, user cancelled - do nothing
  }

  Future<void> _handlePaymentCompletionFromWebView() async {
    print('🎉 Handling payment completion from WebView');

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.green),
            SizedBox(height: 16),
            Text('Memverifikasi pembayaran...'),
            SizedBox(height: 8),
            Text(
              'Mohon tunggu sebentar',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );

    // Wait a bit for webhook processing
    await Future.delayed(Duration(seconds: 2));

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final walletProvider =
          Provider.of<WalletProvider>(context, listen: false);

      final status = await walletProvider.checkPaymentStatus(
        token: authProvider.user!.token,
        referenceId: widget.paymentResponse.referenceId,
      );

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (status != null) {
        setState(() {
          _paymentStatus = status;
        });

        if (status.status.toUpperCase() == 'COMPLETED') {
          print('✅ Payment confirmed as COMPLETED!');
          _statusCheckTimer?.cancel();
          _showPaymentSuccess();
        } else if (status.status.toUpperCase() == 'FAILED' ||
            status.status.toUpperCase() == 'CANCELLED') {
          _showPaymentFailed();
        } else {
          // Still pending, show message and continue polling
          _showPaymentPending();
          _scheduleNextCheck();
        }
      } else {
        _showPaymentError('Tidak dapat memverifikasi status pembayaran');
      }
    } catch (e) {
      print('❌ Error checking payment status: $e');

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      _showPaymentError('Error: ${e.toString()}');
    }
  }

  void _showPaymentPending() {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Pembayaran Dalam Proses'),
        content: Text(
          'Pembayaran masih dalam proses verifikasi. '
          'Status akan diperbarui otomatis atau Anda dapat mengecek riwayat transaksi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPaymentError(String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error Verifikasi'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  // Fallback method for external app launch (kept for compatibility)
  Future<void> _openPaymentUrl() async {
    // Check if we should use WebView popup or external app
    if (widget.paymentResponse.checkoutUrl != null &&
        widget.paymentResponse.checkoutUrl!
            .contains('ewallet-mock-connector')) {
      // Use WebView popup for mock connector
      await _openPaymentWebView();
      return;
    }

    // Fallback to external app launch
    if (widget.paymentResponse.checkoutUrl != null) {
      try {
        final url = Uri.parse(widget.paymentResponse.checkoutUrl!);
        if (await canLaunchUrl(url)) {
          await launchUrl(
            url,
            mode: LaunchMode.externalApplication,
          );

          // Show instruction after opening payment URL
          _showPaymentInstructions();
        } else {
          Helpers.showSnackBar(
            context,
            'Tidak dapat membuka halaman pembayaran',
            isError: true,
          );
        }
      } catch (e) {
        Helpers.showSnackBar(
          context,
          'Error membuka halaman pembayaran: ${e.toString()}',
          isError: true,
        );
      }
    } else {
      Helpers.showSnackBar(
        context,
        'URL pembayaran tidak tersedia',
        isError: true,
      );
    }
  }

  void _showPaymentInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('🎉 Instruksi Pembayaran'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Setelah menyelesaikan pembayaran di aplikasi e-wallet:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• Kembali ke aplikasi ini'),
            Text('• Status akan diperbarui otomatis'),
            Text('• Saldo akan bertambah 100% tanpa potongan'),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '✨ Pembayaran ini tanpa biaya tambahan!',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  String _getStatusText() {
    if (_paymentStatus != null) {
      switch (_paymentStatus!.status.toUpperCase()) {
        case 'COMPLETED':
          return 'Berhasil';
        case 'PENDING':
          return 'Menunggu Pembayaran';
        case 'FAILED':
          return 'Gagal';
        case 'CANCELLED':
          return 'Dibatalkan';
        default:
          return _paymentStatus!.status;
      }
    }
    return 'Menunggu Pembayaran';
  }

  Color _getStatusColor() {
    if (_paymentStatus != null) {
      switch (_paymentStatus!.status.toUpperCase()) {
        case 'COMPLETED':
          return Colors.green;
        case 'FAILED':
        case 'CANCELLED':
          return AppColors.error;
        default:
          return AppColors.warning;
      }
    }
    return AppColors.warning;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Show confirmation before leaving payment screen
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Keluar dari Pembayaran?'),
            content: Text(
              'Apakah Anda yakin ingin keluar? Pembayaran mungkin masih dalam proses.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Keluar'),
              ),
            ],
          ),
        );
        return shouldPop ?? false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Pembayaran'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.close),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(AppSizes.paddingLarge),
          child: Column(
            children: [
              // GRATIS Banner
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green, Colors.green.shade700],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'TANPA BIAYA TAMBAHAN',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 16),

              // Payment Status Card
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Payment icon
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.payment,
                        size: 48,
                        color: Colors.green,
                      ),
                    ),
                    SizedBox(height: 16),

                    Text(
                      'Pembayaran Top Up',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 8),

                    Text(
                      Helpers.formatCurrency(widget.amount.toDouble()),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    SizedBox(height: 8),

                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'TANPA BIAYA',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 12),

                    // Status badge
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _getStatusColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _getStatusColor(),
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            _getStatusText(),
                            style: TextStyle(
                              color: _getStatusColor(),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 16),

                    // Reference ID
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'ID Transaksi',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            widget.paymentResponse.referenceId,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Instructions Card
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.green,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Instruksi Pembayaran',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      '1. Klik tombol "Bayar Sekarang" di bawah ini\n'
                      '2. Halaman pembayaran akan terbuka dalam popup\n'
                      '3. Klik "Process to Pay" untuk menyelesaikan\n'
                      '4. Popup akan tertutup otomatis setelah selesai\n'
                      '5. Popup sukses akan muncul otomatis',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.green,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Status checking indicator
              if (_isCheckingStatus) ...[
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SpinKitThreeBounce(
                        color: Colors.green,
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Mengecek status pembayaran...',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),
              ],

              // Action Buttons
              Column(
                children: [
                  // Pay Now Button (WebView or External)
                  if (widget.paymentResponse.isRedirectRequired &&
                      widget.paymentResponse.checkoutUrl != null)
                    CustomButton(
                      text: 'Bayar Sekarang',
                      onPressed:
                          _openPaymentUrl, // This will route to WebView popup for mock connector
                    ),

                  if (widget.paymentResponse.isRedirectRequired &&
                      widget.paymentResponse.checkoutUrl != null)
                    SizedBox(height: 12),

                  // Check Status & Back buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed:
                              _isCheckingStatus ? null : _checkPaymentStatus,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.green),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isCheckingStatus
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.green,
                                    ),
                                  ),
                                )
                              : Text(
                                  'Cek Status',
                                  style: TextStyle(color: Colors.green),
                                ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).pop();
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            'Kembali',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              SizedBox(height: 16),

              // Help text
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Icon(Icons.help_outline, color: Colors.blue, size: 20),
                    SizedBox(height: 4),
                    Text(
                      'Butuh bantuan dengan pembayaran?',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      'Hubungi customer service kami',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blue.shade600,
                      ),
                      textAlign: TextAlign.center,
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

// ============ XENDIT WEBVIEW POPUP COMPONENT ============

class XenditWebViewPopup extends StatefulWidget {
  final String checkoutUrl;
  final String referenceId;

  const XenditWebViewPopup({
    Key? key,
    required this.checkoutUrl,
    required this.referenceId,
  }) : super(key: key);

  @override
  _XenditWebViewPopupState createState() => _XenditWebViewPopupState();
}

class _XenditWebViewPopupState extends State<XenditWebViewPopup> {
  late WebViewController _webViewController;
  bool _isLoading = true;
  bool _isProcessingPayment = false;
  bool _paymentCompleted = false;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            print('🌐 WebView page started: $url');
            setState(() {
              _isLoading = true;
            });

            _handleUrlChange(url);
          },
          onPageFinished: (String url) {
            print('✅ WebView page finished: $url');
            setState(() {
              _isLoading = false;
            });

            _checkIfPaymentCompleted(url);
          },
          onWebResourceError: (WebResourceError error) {
            print('❌ WebView error: ${error.description}');

            // Jika error loading halaman, mungkin payment sudah selesai
            if (error.errorCode == -2 || error.errorCode == -6) {
              // NET::ERR_NAME_NOT_RESOLVED or ERR_CONNECTION_REFUSED
              print(
                  '🎉 Connection error detected - assuming payment completed');
              _handlePaymentCompletion();
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            print('🔄 Navigation request: ${request.url}');

            // Check for completion patterns
            if (_isPaymentCompletionUrl(request.url)) {
              print('🎉 Payment completion URL detected: ${request.url}');
              _handlePaymentCompletion();
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.checkoutUrl));
  }

  void _handleUrlChange(String url) {
    print('📍 URL changed to: $url');

    // Detect if user is interacting with payment process
    if (url.contains('process') ||
        url.contains('pay') ||
        url.contains('confirm') ||
        url.contains('submit')) {
      setState(() {
        _isProcessingPayment = true;
      });
      print('💳 Payment processing detected');
    }
  }

  bool _isPaymentCompletionUrl(String url) {
    // Patterns that indicate payment completion
    List<String> completionPatterns = [
      'success',
      'completed',
      'finish',
      'done',
      'return',
      'callback',
      'localhost:3001', // success_redirect_url
      'thank',
      'confirmed'
    ];

    String lowerUrl = url.toLowerCase();
    return completionPatterns.any((pattern) => lowerUrl.contains(pattern));
  }

  void _checkIfPaymentCompleted(String url) {
    // Specific check for ewallet-mock-connector disappearing
    if (!url.contains('ewallet-mock-connector') && !url.contains('xendit.co')) {
      print('🎉 Mock connector page disappeared - payment likely completed');
      _handlePaymentCompletion();
      return;
    }

    // Check for completion URLs
    if (_isPaymentCompletionUrl(url)) {
      print('🎉 Payment completion URL detected in page finish: $url');
      _handlePaymentCompletion();
      return;
    }

    // Check for specific Xendit success indicators
    if (url.contains('status=success') ||
        url.contains('result=success') ||
        url.contains('payment_status=completed')) {
      print('🎉 Payment success parameters detected');
      _handlePaymentCompletion();
    }
  }

  void _handlePaymentCompletion() {
    if (_paymentCompleted) return; // Prevent multiple calls

    setState(() {
      _paymentCompleted = true;
      _isProcessingPayment = true;
    });

    print(
        '🎉 Handling payment completion for reference: ${widget.referenceId}');

    // Add small delay to let any final processing complete
    Future.delayed(Duration(milliseconds: 1000), () {
      if (mounted) {
        Navigator.of(context).pop('payment_completed');
      }
    });
  }

  void _handlePaymentFailure() {
    if (_paymentCompleted) return;

    setState(() {
      _paymentCompleted = true;
    });

    print('❌ Handling payment failure for reference: ${widget.referenceId}');

    if (mounted) {
      Navigator.of(context).pop('payment_failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pembayaran'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: () {
            if (_isProcessingPayment && !_paymentCompleted) {
              // Show confirmation if payment is in progress
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Batalkan Pembayaran?'),
                  content: Text(
                      'Pembayaran sedang diproses. Apakah Anda yakin ingin membatalkan?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Tidak'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close dialog
                        Navigator.of(context)
                            .pop('payment_cancelled'); // Close webview
                      },
                      child: Text('Ya, Batalkan'),
                    ),
                  ],
                ),
              );
            } else {
              Navigator.of(context).pop('payment_cancelled');
            }
          },
        ),
      ),
      body: Stack(
        children: [
          // WebView
          WebViewWidget(controller: _webViewController),

          // Loading Indicator
          if (_isLoading)
            Container(
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.green),
                    SizedBox(height: 16),
                    Text(
                      'Memuat halaman pembayaran...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Tanpa biaya tambahan',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Processing Payment Overlay
          if (_isProcessingPayment && !_paymentCompleted)
            Container(
              color: Colors.black54,
              child: Center(
                child: Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.green),
                      SizedBox(height: 16),
                      Text(
                        'Memproses pembayaran...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Mohon tunggu sebentar',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '✨ Tanpa biaya tambahan',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Payment Completed Overlay
          if (_paymentCompleted)
            Container(
              color: Colors.black54,
              child: Center(
                child: Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 48,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Pembayaran Selesai!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Memverifikasi status...',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

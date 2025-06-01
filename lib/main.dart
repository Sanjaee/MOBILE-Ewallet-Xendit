import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/wallet_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/auth/otp_verification_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'utils/constants.dart';
import 'services/notification_service.dart'; // Import NotificationService

Future<void> main() async {
  // Ubah menjadi Future<void> dan tambahkan async
  WidgetsFlutterBinding.ensureInitialized(); // Pastikan binding siap
  await NotificationService().initialize(); // Inisialisasi NotificationService
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
      ],
      child: MaterialApp(
        title: 'Zacode E-Wallet App',
        theme: ThemeData(
          primaryColor: AppColors.primary,
          scaffoldBackgroundColor: AppColors.background,
          fontFamily: 'Poppins',
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
          appBarTheme: AppBarTheme(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            titleTextStyle: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.w600),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(vertical: 16),
              textStyle: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w500),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            textStyle:
                TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
          )),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            labelStyle: TextStyle(
                color: AppColors.textSecondary, fontFamily: 'Poppins'),
            hintStyle: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.7),
                fontFamily: 'Poppins'),
          ),
        ),
        home: SplashScreen(),
        routes: {
          '/login': (context) => LoginScreen(),
          '/register': (context) => RegisterScreen(),
          '/home': (context) => HomeScreen(),
          '/forgot-password': (context) => ForgotPasswordScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/otp-verification') {
            final args = settings.arguments as Map<String, dynamic>?;
            if (args != null &&
                args['email'] is String &&
                args['purpose'] is OtpPurpose) {
              return MaterialPageRoute(
                builder: (context) {
                  return OtpVerificationScreen(
                    email: args['email'],
                    purpose: args['purpose'],
                  );
                },
              );
            }
          }
          if (settings.name == '/reset-password') {
            final args = settings.arguments as Map<String, dynamic>?;
            if (args != null &&
                args['email'] is String &&
                args['otp'] is String) {
              return MaterialPageRoute(
                builder: (context) {
                  return ResetPasswordScreen(
                    email: args['email'],
                    otp: args['otp'],
                  );
                },
              );
            }
          }
          return null;
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

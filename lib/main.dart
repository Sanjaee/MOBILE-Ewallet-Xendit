import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/wallet_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/auth/otp_verification_screen.dart'; // Import new screen
import 'screens/auth/forgot_password_screen.dart'; // Import new screen
import 'screens/auth/reset_password_screen.dart'; // Import new screen
import 'utils/constants.dart';

void main() {
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
        title: 'E-Wallet App',
        theme: ThemeData(
          primaryColor: AppColors.primary,
          scaffoldBackgroundColor: AppColors.background,
          fontFamily:
              'Poppins', // Make sure this font is added to pubspec.yaml and assets
          colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary), // Modern way to set theme colors
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
            // Consistent styling for text fields
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
        home: SplashScreen(), // Initial screen
        // Define routes
        routes: {
          '/login': (context) => LoginScreen(),
          '/register': (context) => RegisterScreen(),
          '/home': (context) => HomeScreen(),
          '/forgot-password': (context) => ForgotPasswordScreen(),
          // OTP Verification and Reset Password screens might take arguments,
          // so using onGenerateRoute is more flexible if direct named routes are not enough.
          // However, for simplicity, we can pass arguments via MaterialPageRoute if not using named routes with args directly.
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/otp-verification') {
            final args = settings.arguments
                as Map<String, dynamic>?; // Or a specific class
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
          // Handle other routes or return null for default handling
          return null;
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

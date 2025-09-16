import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // <-- Add Firebase Auth import
import 'package:provider/provider.dart';
import 'package:zesty_app/providers/order_provider.dart';

import 'firebase_options.dart';
import 'providers/cart_provider.dart';// <-- Add OrdersProvider import
import 'providers/connectivity_provider.dart';
import 'screens/home_screen.dart';
import 'screens/no_internet_screen.dart';
import 'screens/signup_page.dart';
import 'theme/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => CartProvider()),
        ChangeNotifierProvider(create: (context) => OrdersProvider()), // <-- Restored OrdersProvider
        ChangeNotifierProvider(create: (context) => ConnectivityProvider()),
      ],
      child: const SmartCanteenApp(),
    ),
  );
}

class SmartCanteenApp extends StatelessWidget {
  const SmartCanteenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zesty Smart Canteen',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: AppColors.primaryOrange,
        primaryColor: AppColors.primaryOrange,
        scaffoldBackgroundColor: AppColors.lightGrey,
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: AppColors.primaryOrange,
          accentColor: AppColors.primaryPurple,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.black,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryOrange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primaryOrange,
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: Colors.grey[200],
          selectedColor: AppColors.primaryOrange,
          labelStyle: const TextStyle(color: Colors.black),
          secondaryLabelStyle: const TextStyle(color: Colors.white),
        ),
      ),
      // The AuthWrapper now decides which screen to show first.
      home: const AuthWrapper(),
    );
  }
}

//--- NEW WIDGET ---
/// Listens to Firebase Auth state and directs the user accordingly.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // Listen to the user's login state
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show a loading indicator while checking
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // If the user is logged in (snapshot has data)
        if (snapshot.hasData) {
          // Go to the main app content, which handles connectivity
          return const ConnectivityWrapper();
        }

        // If the user is not logged in
        return const SignupPage();
      },
    );
  }
}


// This "Gatekeeper" widget for internet remains the same.
class ConnectivityWrapper extends StatelessWidget {
  const ConnectivityWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final connectivity = context.watch<ConnectivityProvider>();

    if (connectivity.isConnected) {
      // If there's internet, show the main HomeScreen.
      return const HomeScreen();
    } else {
      // If not, show the NoInternetScreen.
      return NoInternetScreen(
        onRetry: () => Provider.of<ConnectivityProvider>(context, listen: false).checkConnectivity(),
      );
    }
  }
}
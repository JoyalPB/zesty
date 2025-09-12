import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/cart_provider.dart';
import 'providers/connectivity_provider.dart';
import 'screens/home_screen.dart';
import 'screens/no_internet_screen.dart';
import 'theme/app_colors.dart';
// Note: The import for splash_screen.dart is no longer needed.

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => CartProvider()),
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
      // --- THIS IS THE ONLY CHANGE ---
      // We start directly with the ConnectivityWrapper now.
      home: const ConnectivityWrapper(),
    );
  }
}

// The "Gatekeeper" widget that decides which screen to show FIRST.
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


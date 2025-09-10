import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/cart_provider.dart';
import 'providers/connectivity_provider.dart'; // <-- Import the new provider
import 'screens/home_screen.dart';
import 'screens/no_internet_screen.dart'; // <-- Import the new screen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    // MultiProvider allows us to provide multiple "brains" to our app.
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
      title: 'Smart Canteen',
      theme: ThemeData(primarySwatch: Colors.teal),
      // The home is now a "ConnectivityWrapper" that decides which screen to show.
      home: const ConnectivityWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// This is our new "Gatekeeper" widget.
class ConnectivityWrapper extends StatelessWidget {
  const ConnectivityWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // It watches for changes in the connectivity status.
    final connectivity = context.watch<ConnectivityProvider>();

    // If connected, show the main HomeScreen.
    if (connectivity.isConnected) {
      return const HomeScreen();
    }
    // If not connected, show the NoInternetScreen.
    else {
      return NoInternetScreen(
        // Pass the checkConnectivity function to the "Retry" button.
        onRetry: () => connectivity.checkConnectivity(),
      );
    }
  }
}
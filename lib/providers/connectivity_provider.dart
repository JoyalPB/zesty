import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityProvider with ChangeNotifier {
  bool _isConnected = true;
  late StreamSubscription<List<ConnectivityResult>> _subscription;

  bool get isConnected => _isConnected;

  ConnectivityProvider() {
    // Start listening to connectivity changes as soon as the provider is created.
    _subscription = Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
    checkConnectivity(); // Check the initial status
  }

  // A public method to allow manual re-checking of the connection.
  Future<void> checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    _updateConnectionStatus(result);
  }

  void _updateConnectionStatus(List<ConnectivityResult> result) {
    final hasConnection = !result.contains(ConnectivityResult.none);
    if (hasConnection != _isConnected) {
      _isConnected = hasConnection;
      notifyListeners(); // Notify listeners only if the status has changed.
    }
  }

  @override
  void dispose() {
    // It's crucial to cancel the subscription to prevent memory leaks.
    _subscription.cancel();
    super.dispose();
  }
}
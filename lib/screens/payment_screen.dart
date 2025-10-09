// payment_screen.dart (Updated with Payment Options)

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

// Enum to represent different payment methods
enum PaymentMethod {
  card,
  upi,
  netBanking,
  wallet,
}

class PaymentScreen extends StatefulWidget {
  final double totalAmount;
  final VoidCallback onSuccessfulPayment; // A function to call on success

  const PaymentScreen({
    super.key,
    required this.totalAmount,
    required this.onSuccessfulPayment,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  PaymentMethod? _selectedMethod = PaymentMethod.upi; // Default selection
  bool _isProcessing = false; // To show loading state on button

  Future<void> _processFakePayment() async {
    if (_selectedMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a payment method.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true; // Show loading indicator
    });

    // Simulate a network delay of 3 seconds
    await Future.delayed(const Duration(seconds: 3));

    // Randomly determine if the payment succeeds or fails
    final isSuccess = Random().nextDouble() < 0.9; // 90% success chance

    // Ensure the widget is still mounted before proceeding
    if (!mounted) return;

    setState(() {
      _isProcessing = false; // Hide loading indicator
    });

    if (isSuccess) {
      // If payment is successful, call the function that was passed in
      widget.onSuccessfulPayment();
    } else {
      // If payment fails, show an error and go back to the cart
      Navigator.of(context).pop(); // Go back
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment via ${_selectedMethod!.name.toUpperCase()} failed. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Payment'),
        // Allow user to go back if they haven't started processing
        automaticallyImplyLeading: !_isProcessing,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Amount: ₹${widget.totalAmount.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            Text(
              'Choose Payment Method:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),

            // UPI Option
            RadioListTile<PaymentMethod>(
              title: const Text('UPI (Google Pay, PhonePe, Paytm)'),
              value: PaymentMethod.upi,
              groupValue: _selectedMethod,
              onChanged: _isProcessing ? null : (PaymentMethod? value) {
                setState(() {
                  _selectedMethod = value;
                });
              },
            ),

            // Card Option
            RadioListTile<PaymentMethod>(
              title: const Text('Credit / Debit Card'),
              value: PaymentMethod.card,
              groupValue: _selectedMethod,
              onChanged: _isProcessing ? null : (PaymentMethod? value) {
                setState(() {
                  _selectedMethod = value;
                });
              },
            ),

            // Net Banking Option
            RadioListTile<PaymentMethod>(
              title: const Text('Net Banking'),
              value: PaymentMethod.netBanking,
              groupValue: _selectedMethod,
              onChanged: _isProcessing ? null : (PaymentMethod? value) {
                setState(() {
                  _selectedMethod = value;
                });
              },
            ),

            // Wallet Option
            RadioListTile<PaymentMethod>(
              title: const Text('Wallets (Paytm, MobiKwik, Freecharge)'),
              value: PaymentMethod.wallet,
              groupValue: _selectedMethod,
              onChanged: _isProcessing ? null : (PaymentMethod? value) {
                setState(() {
                  _selectedMethod = value;
                });
              },
            ),

            const Spacer(), // Pushes the button to the bottom

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _processFakePayment,
                child: _isProcessing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                  'Pay ₹${widget.totalAmount.toStringAsFixed(2)} Now',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(height: 10), // For bottom padding
          ],
        ),
      ),
    );
  }
}
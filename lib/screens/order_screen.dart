import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  // --- 1. _showReviewDialog method is UNCHANGED ---
  void _showReviewDialog(
      BuildContext context,
      String orderId,
      String userId, // Pass in userId
      List<dynamic> orderItems, // Pass in orderItems
      ) {
    double _rating = 0;
    final _reviewController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Rate Your Order'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ... (Star rating and TextField are unchanged) ...
                    const Text('How was your experience?', style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          icon: Icon(
                            index < _rating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 30,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              _rating = index + 1.0;
                            });
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _reviewController,
                      decoration: const InputDecoration(
                        hintText: 'Add a written review (optional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                ),
                ElevatedButton(
                  child: const Text('Submit'),
                  onPressed: () async {
                    if (_rating == 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select a star rating.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    Navigator.of(dialogContext).pop();

                    try {
                      // --- UPDATED SUBMIT CALL (unchanged) ---
                      await _submitReview(
                        orderId: orderId,
                        rating: _rating,
                        reviewText: _reviewController.text,
                        userId: userId,
                        orderItems: orderItems,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Review submitted! Thank you.'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to submit review: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- 2. _submitReview METHOD IS NOW MODIFIED ---
  Future<void> _submitReview({
    required String orderId,
    required double rating,
    required String reviewText,
    required String userId,
    required List<dynamic> orderItems,
  }) async {

    // --- (A) FETCH THE USER'S DOCUMENT TO GET THEIR NAME ---
    final userData = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    // Make sure 'fullName' matches the field name in your 'users' collection
    final fullName = userData.data()?['fullName'] ?? 'Anonymous User';
    // --- END OF CHANGE (A) ---

    // Get a batch write instance for an atomic operation
    final batch = FirebaseFirestore.instance.batch();

    // 1. Create a new document in the 'reviews' collection
    final newReviewRef = FirebaseFirestore.instance.collection('reviews').doc();

    // --- (B) ADD 'fullName' TO THE REVIEW DATA ---
    batch.set(newReviewRef, {
      'orderId': orderId,
      'userId': userId,
      'fullName': fullName, // <-- HERE IS THE NEW FIELD
      'rating': rating,
      'text': reviewText,
      'items': orderItems, // Store a copy of the items that were reviewed
      'timestamp': FieldValue.serverTimestamp(),
    });
    // --- END OF CHANGE (B) ---

    // 2. Update the 'orders' document with a flag
    final orderRef = FirebaseFirestore.instance.collection('orders').doc(orderId);
    batch.update(orderRef, {'hasReview': true});

    // Commit both operations at once
    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // ... (unchanged login check) ...
      return Scaffold(
        appBar: AppBar(
          title: const Text('Your Orders'),
        ),
        body: const Center(
          child: Text('Please log in to see your orders.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Orders'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('userId', isEqualTo: user.uid)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (ctx, orderSnapshot) {
          // ... (unchanged loading/error/empty states) ...
          if (orderSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (orderSnapshot.hasError) {
            return const Center(child: Text('Something went wrong.'));
          }
          final orderDocs = orderSnapshot.data?.docs;
          if (orderDocs == null || orderDocs.isEmpty) {
            return const Center(child: Text('You have no orders yet!'));
          }

          return ListView.builder(
            itemCount: orderDocs.length,
            itemBuilder: (ctx, i) {
              final orderData = orderDocs[i].data() as Map<String, dynamic>;
              final orderId = orderDocs[i].id;
              final orderItems = orderData['items'] as List<dynamic>;
              final timestamp = orderData['timestamp'] as Timestamp?;
              final status = orderData['status'] ?? 'Unknown';

              // --- 3. CHECK FOR THE 'hasReview' FLAG (unchanged) ---
              final bool hasReview = orderData['hasReview'] ?? false;

              // --- 4. BUILD THE LIST OF CHILDREN FOR THE TILE (unchanged) ---
              List<Widget> childrenWidgets = orderItems.map<Widget>((item) {
                final product = item as Map<String, dynamic>;
                return ListTile(
                  leading: CircleAvatar(
                    child: Text('${product['quantity']}x'),
                  ),
                  title: Text(product['name'] ?? 'Unnamed Item'),
                  trailing: Text('₹${(product['price'] * product['quantity']).toStringAsFixed(2)}'),
                );
              }).toList();

              // --- 5. CONDITIONALLY ADD THE REVIEW BUTTON OR THE REVIEW ITSELF (unchanged) ---
              if (status.toLowerCase() == 'delivered' && !hasReview) {
                // If delivered and not reviewed, add the button
                childrenWidgets.add(
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        minimumSize: const Size(double.infinity, 40),
                      ),
                      icon: const Icon(Icons.star_outline),
                      label: const Text('Provide Review'),
                      onPressed: () {
                        // --- PASS THE REQUIRED DATA TO THE DIALOG (unchanged) ---
                        _showReviewDialog(context, orderId, user.uid, orderItems);
                      },
                    ),
                  ),
                );
              } else if (hasReview) {
                // --- 6. IF REVIEWED, FETCH AND DISPLAY THE REVIEW (unchanged) ---
                childrenWidgets.add(
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('reviews')
                        .where('orderId', isEqualTo: orderId)
                        .limit(1) // We only expect one review per order
                        .snapshots(),
                    builder: (ctx, reviewSnapshot) {
                      if (reviewSnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(),
                        ));
                      }
                      if (!reviewSnapshot.hasData || reviewSnapshot.data!.docs.isEmpty) {
                        return const ListTile(
                          leading: Icon(Icons.error_outline, color: Colors.red),
                          title: Text('Could not load review'),
                        );
                      }

                      // We found the review
                      final reviewData = reviewSnapshot.data!.docs.first.data() as Map<String, dynamic>;
                      final double rating = (reviewData['rating'] ?? 0.0).toDouble();
                      final String reviewText = reviewData['text'] ?? '';

                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your Review',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: List.generate(5, (index) {
                                return Icon(
                                  index < rating ? Icons.star : Icons.star_border,
                                  color: Colors.amber,
                                  size: 20,
                                );
                              }),
                            ),
                            if (reviewText.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                reviewText,
                                style: const TextStyle(fontStyle: FontStyle.italic),
                              ),
                            ]
                          ],
                        ),
                      );
                    },
                  ),
                );
              }

              return Card(
                margin: const EdgeInsets.all(10),
                child: ExpansionTile(
                  // ... (RichText title is unchanged) ...
                  title: RichText(
                    text: TextSpan(
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      children: [
                        const TextSpan(text: 'Order '),
                        TextSpan(
                          text: '#${orderId.toUpperCase()}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        TextSpan(
                          text: ' - ₹${(orderData['totalAmount'] ?? 0.0).toStringAsFixed(2)}',
                        ),
                      ],
                    ),
                  ),
                  subtitle: Text(
                    timestamp != null
                        ? DateFormat('dd/MM/yyyy hh:mm a').format(timestamp.toDate())
                        : 'No date',
                  ),
                  trailing: Chip(
                    label: Text(
                      status,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: _getStatusColor(status),
                  ),
                  // --- 7. USE THE DYNAMIC LIST OF CHILDREN (unchanged) ---
                  children: childrenWidgets,
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ... (_getStatusColor method is unchanged) ...
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'cooking':
        return Colors.blue;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
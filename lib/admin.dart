import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'track.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: const Color.fromARGB(255, 181, 219, 255),
        actions: [],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color.fromARGB(255, 179, 217, 252), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection('orders')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            var orders = snapshot.data!.docs;

            orders =
                orders.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  String status = data['status'] ?? 'Processing';
                  return status != 'Delivered';
                }).toList();

            if (orders.isEmpty) {
              return const Center(
                child: Text('No orders currently available.'),
              );
            }

            List<String> statusOptions = [
              'Processing',
              'Preparation',
              'Ready',
              'Delivered',
            ];

            Map<String, String> statusLabels = {
              'Processing': 'Processing',
              'Preparation': 'Preparation',
              'Ready': 'Ready',
              'Delivered': 'Delivered',
            };

            return ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, index) {
                var order = orders[index].data() as Map<String, dynamic>;
                String orderId = orders[index].id;
                String seat = order['seatNumber'] ?? '';
                String status = order['status'] ?? 'Processing';

                if (!statusOptions.contains(status)) {
                  status = 'Processing';
                }

                return Card(
                  color: Colors.white,
                  margin: const EdgeInsets.all(10),
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  OrderTrackingScreen(orderId: orderId),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Order #${orderId.substring(0, 6)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.blueGrey,
                                ),
                              ),
                              Text(
                                '${order['totalAmount']} SAR',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('Seat: $seat'),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Text('Status: '),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(status),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: DropdownButton<String>(
                                  value: status,
                                  underline: const SizedBox(),
                                  icon: const Icon(
                                    Icons.arrow_drop_down,
                                    size: 18,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black,
                                  ),
                                  items:
                                      statusOptions
                                          .map(
                                            (statusKey) => DropdownMenuItem(
                                              value: statusKey,
                                              child: Text(
                                                statusLabels[statusKey]! ??
                                                    statusKey,
                                              ),
                                            ),
                                          )
                                          .toList(),
                                  onChanged: (newStatus) async {
                                    if (newStatus == null) return;

                                    await FirebaseFirestore.instance
                                        .collection('orders')
                                        .doc(orderId)
                                        .update({'status': newStatus});
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Processing':
        return Colors.orange[100]!;
      case 'Preparation':
        return const Color.fromARGB(255, 247, 252, 179);
      case 'Ready':
        return const Color.fromARGB(255, 230, 211, 200);
      case 'Delivered':
        return const Color.fromARGB(255, 159, 255, 180);
      default:
        return Colors.white;
    }
  }
}

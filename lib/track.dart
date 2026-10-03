import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderTrackingScreen extends StatelessWidget {
  final String orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color.fromARGB(255, 213, 230, 255), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: StreamBuilder<DocumentSnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection('orders')
                  .doc(orderId)
                  .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const _NoOrderFoundView();
            }

            final data = snapshot.data!.data() as Map<String, dynamic>;
            final status = data['status'] ?? 'Processing';
            final items = data['items'] ?? [];
            final paymentMethod = data['paymentMethod'] ?? 'Not specified';
            final totalAmount = data['totalAmount'] ?? 0;
            final timestamp = data['timestamp'] as Timestamp?;
            final driverPhone = data['driverPhone'] ?? 'Not assigned';
            final seat = data['seatNumber'] ?? 'Unknown';

            final steps = ['Processing', 'Preparation', 'Ready', 'Delivered'];
            final icons = [
              Icons.lock_clock,
              Icons.kitchen,
              Icons.delivery_dining,
              Icons.check_circle,
            ];
            final colors = [
              const Color.fromARGB(255, 93, 100, 139),
              const Color.fromARGB(255, 255, 177, 94),
              const Color.fromARGB(255, 100, 184, 195),
              const Color.fromARGB(255, 107, 175, 76),
            ];

            int currentStep = steps.indexOf(status);
            if (currentStep == -1) currentStep = 0;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  _buildStepper(steps, icons, colors, currentStep),
                  const SizedBox(height: 30),
                  Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    color: const Color.fromARGB(244, 195, 218, 255),
                    shadowColor: const Color.fromARGB(150, 5, 44, 128),
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Seat: $seat',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Order ID: ${orderId.substring(0, 6)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color.fromARGB(255, 0, 52, 174),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Text(
                    'Order Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 43, 82, 145),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    color: const Color.fromARGB(255, 255, 255, 255),
                    child: Column(
                      children: [
                        ...items.map<Widget>((item) {
                          return ListTile(
                            title: Text(
                              item['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color.fromARGB(255, 131, 174, 255),
                              ),
                            ),
                            subtitle: Text(
                              '${item['quantity']} × ${item['price']}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color.fromARGB(255, 0, 0, 180),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            trailing: Text(
                              '${item['quantity'] * item['price']} SAR',
                              style: const TextStyle(
                                fontSize: 15,
                                color: Color.fromARGB(255, 0, 52, 174),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }).toList(),
                        const Divider(height: 1),
                        ListTile(
                          title: const Text(
                            'Total',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 131, 174, 255),
                            ),
                          ),
                          trailing: Text(
                            '$totalAmount SAR',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 0, 0, 180),
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Payment Method:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color.fromARGB(255, 131, 174, 255),
                                ),
                              ),
                              Text(
                                paymentMethod,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Color.fromARGB(255, 0, 52, 174),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (timestamp != null)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Order Time:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color.fromARGB(255, 131, 174, 255),
                                  ),
                                ),
                                Text(
                                  _formatTimestamp(timestamp),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color.fromARGB(255, 0, 52, 174),
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 10),
                          const Divider(height: 1),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Delivery Contact:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color.fromARGB(255, 131, 174, 255),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.phone,
                                  color: Color.fromARGB(255, 131, 174, 255),
                                ),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder:
                                        (context) => AlertDialog(
                                          title: const Text('Driver Contact'),
                                          content: Text('Phone: $driverPhone'),
                                          actions: [
                                            TextButton(
                                              child: const Text('Close'),
                                              onPressed:
                                                  () => Navigator.pop(context),
                                            ),
                                          ],
                                        ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStepper(
    List<String> steps,
    List<IconData> icons,
    List<Color> colors,
    int currentStep,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: List.generate(steps.length, (index) {
          final isActive = index <= currentStep;
          return Row(
            children: [
              Column(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor:
                        isActive
                            ? colors[index]
                            : const Color.fromARGB(255, 202, 202, 202),
                    child: Icon(
                      icons[index],
                      size: 18,
                      color: isActive ? Colors.white : Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    steps[index],
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          isActive
                              ? colors[index]
                              : const Color.fromARGB(255, 51, 51, 51),
                    ),
                  ),
                ],
              ),
              if (index < steps.length - 1)
                Container(
                  width: 30,
                  height: 2,
                  color:
                      index < currentStep
                          ? colors[index]
                          : Colors.grey.shade300,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                ),
            ],
          );
        }),
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')} - ${date.day}/${date.month}/${date.year}';
  }
}

class _NoOrderFoundView extends StatelessWidget {
  const _NoOrderFoundView();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: CustomPaint(
        painter: BlueCircleBackgroundPainter(),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.hourglass_empty, size: 60, color: Colors.blueGrey),
              SizedBox(height: 10),
              Text(
                'No current order',
                style: TextStyle(fontSize: 18, color: Colors.blueGrey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BlueCircleBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = const Color(0x554497FF);
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 150, paint);

    paint.color = const Color(0x334497FF);
    canvas.drawCircle(
      Offset(size.width / 2 + 60, size.height / 2 - 40),
      100,
      paint,
    );

    paint.color = const Color(0x224497FF);
    canvas.drawCircle(
      Offset(size.width / 2 - 80, size.height / 2 + 30),
      120,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

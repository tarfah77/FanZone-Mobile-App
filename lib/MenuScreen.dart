import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MenuScreen extends StatefulWidget {
  final String? seatNumber;
  final Function(String)? onOrderCreated;

  const MenuScreen({Key? key, this.seatNumber, this.onOrderCreated})
    : super(key: key);

  @override
  _MenuScreenState createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final TextEditingController _seatController = TextEditingController();
  Map<String, int> quantities = {};
  String? selectedPaymentMethod;
  List<String> lowStockItems = [];
  final List<String> paymentMethods = ['Cash', 'Card'];
  Map<String, Map<String, dynamic>> _menuItems = {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.seatNumber != null && widget.seatNumber!.isNotEmpty) {
      _seatController.text = widget.seatNumber!;
    }
    _fetchMenuItems();
  }

  Future<void> _fetchMenuItems() async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance
              .collection('items')
              .where('quantity', isGreaterThan: 0)
              .get();

      Map<String, Map<String, dynamic>> fetchedItems = {};
      List<String> lowStock = [];

      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        fetchedItems[doc.id] = {
          'itemn': data['itemn'],
          'price': data['price'],
          'quantity': data['quantity'],
          'image': data['image'],
        };
        quantities[doc.id] = 0;
        if (data['quantity'] < 3) {
          lowStock.add(data['itemn']);
        }
      }

      setState(() {
        _menuItems = fetchedItems;
        lowStockItems = lowStock;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load menu: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  int get totalAmount {
    int total = 0;
    quantities.forEach((key, quantity) {
      if (_menuItems.containsKey(key) && quantity > 0) {
        total += (_menuItems[key]!['price'] as int) * quantity;
      }
    });
    return total;
  }

  Future<void> _placeOrder() async {
    final seatNumber = _seatController.text.trim();
    if (seatNumber.isEmpty || seatNumber == '') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a seat number before placing an order'),
        ),
      );
      return;
    }

    if (totalAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one item')),
      );
      return;
    }

    if (selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a payment method')),
      );
      return;
    }

    List<Map<String, dynamic>> orderedItems = [];
    quantities.forEach((key, quantity) {
      if (quantity > 0) {
        orderedItems.add({
          'name': _menuItems[key]!['itemn'],
          'price': _menuItems[key]!['price'],
          'quantity': quantity,
        });
      }
    });

    try {
      setState(() => _isLoading = true);

      DocumentReference orderRef = await FirebaseFirestore.instance
          .collection('orders')
          .add({
            'seatNumber': seatNumber,
            'items': orderedItems,
            'totalAmount': totalAmount,
            'paymentMethod': selectedPaymentMethod,
            'status': 'Pending',
            'timestamp': FieldValue.serverTimestamp(),
            'driverPhone': '0535697788',
          });

      for (var item in orderedItems) {
        String itemId =
            _menuItems.entries
                .firstWhere((e) => e.value['itemn'] == item['name'])
                .key;
        int newQuantity = _menuItems[itemId]!['quantity'] - item['quantity'];
        await FirebaseFirestore.instance.collection('items').doc(itemId).update(
          {'quantity': newQuantity},
        );
      }

      if (widget.onOrderCreated != null) {
        widget.onOrderCreated!(orderRef.id);
      }

      setState(() {
        quantities.updateAll((key, value) => 0);
        selectedPaymentMethod = null;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order placed successfully')),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Order failed: ${e.toString()}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFCAE3FF), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child:
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                  ? Center(child: Text(_errorMessage!))
                  : ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      if (lowStockItems.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 255, 235, 206),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                color: Color.fromARGB(255, 255, 156, 7),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Low stock: ${lowStockItems.join('  ')}',
                                  style: const TextStyle(color: Colors.orange),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ..._menuItems.entries
                          .map(
                            (entry) => _buildMenuItem(entry.key, entry.value),
                          )
                          .toList(),
                      const Divider(height: 30),
                      _buildOrderSection(),
                    ],
                  ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(String itemId, Map<String, dynamic> item) {
    String itemName = item['itemn'];
    int price = item['price'];
    int stock = item['quantity'];
    int quantity = quantities[itemId] ?? 0;
    String? imagePath = item['image'];

    return Card(
      color: const Color.fromARGB(255, 247, 250, 255),
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            imagePath != null
                ? ClipRRect(
                  borderRadius: BorderRadius.circular(17),
                  child: Image.asset(
                    imagePath,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                )
                : const Icon(
                  Icons.fastfood_outlined,
                  size: 40,
                  color: Colors.white70,
                ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    itemName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 73, 92, 160),
                    ),
                  ),
                  Text(
                    'SAR $price',
                    style: const TextStyle(
                      color: Color.fromARGB(153, 79, 120, 255),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.remove_circle,
                    color: Color(0xFF9BB0FF),
                  ),
                  onPressed:
                      quantity > 0
                          ? () =>
                              setState(() => quantities[itemId] = quantity - 1)
                          : null,
                ),
                Text(
                  '$quantity',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 102, 119, 201),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Color(0xFF9BB0FF)),
                  onPressed:
                      quantity < stock
                          ? () =>
                              setState(() => quantities[itemId] = quantity + 1)
                          : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

 
  Widget _buildOrderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text('Total:', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 190, 209, 255),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Text(
                    ' ${totalAmount.toString()} SR',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: const Text("Enter Seat Number"),
                        content: TextField(
                          controller: _seatController,
                          decoration: const InputDecoration(
                            hintText: "Example: A12",
                          ),
                          onChanged: (value) {
                            setState(() {}); // لتحديث الواجهة عند إدخال المقعد
                          },
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              setState(() {}); 
                            },
                            child: const Text("Enter"),
                          ),
                        ],
                      ),
                );
              },
              child: Row(
                children: [
                  const Icon(
                    Icons.event_seat,
                    color: Color.fromARGB(255, 155, 180, 255),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _seatController.text.isNotEmpty ? _seatController.text : '',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(230, 97, 122, 210),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

       
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(35),
              color: const Color.fromARGB(255, 255, 255, 255),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedPaymentMethod,
                isExpanded: true,
                borderRadius: BorderRadius.circular(20),
                items:
                    paymentMethods.map((method) {
                      return DropdownMenuItem(
                        value: method,
                        child: Row(
                          children: [
                            Container(
                              decoration: const BoxDecoration(
                                color: Color(0xFFE3F2FD),
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(8),
                              child: Icon(
                                method == 'Cash'
                                    ? Icons.attach_money_rounded
                                    : Icons.credit_card_rounded,
                                color: const Color.fromARGB(255, 121, 163, 255),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              method,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                onChanged: (val) => setState(() => selectedPaymentMethod = val),
                hint: const Text(
                  "Payment method ",
                  style: TextStyle(
                    fontSize: 15,
                    color: Color.fromARGB(180, 85, 125, 255),
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

      
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _placeOrder,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
                backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 4,
              ),
              child:
                  _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                        "Place Order",
                        style: TextStyle(
                          fontSize: 15,
                          color: Color.fromARGB(180, 85, 125, 255),
                        ),
                      ),
            ),
          ),
        ),
      ],
    );
  }
}

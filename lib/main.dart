import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'MenuScreen.dart';
import 'event.dart';
import 'log.dart';
import 'map.dart';
import 'news.dart';
import 'track.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

final GoRouter _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      redirect: (context, state) {
        final seat = state.uri.queryParameters['seat'];
        if (seat != null && seat.isNotEmpty) {
          return '/menu?seat=$seat';
        }
        return '/menu';
      },
    ),
    GoRoute(
      path: '/menu',
      builder: (context, state) {
        final seatNumber = state.uri.queryParameters['seat'] ?? '';
        return MainNavigation(seatNumber: seatNumber);
      },
    ),
    GoRoute(
      path: '/admin-login',
      builder: (context, state) => const AdminLoginScreen(),
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
    );
  }
}

class MainNavigation extends StatefulWidget {
  final String seatNumber;

  const MainNavigation({super.key, required this.seatNumber});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  String? _currentOrderId;

  void _onOrderCreated(String orderId) {
    setState(() {
      _currentOrderId = orderId;
      _selectedIndex = 1; // الانتقال التلقائي لشاشة التتبع عند الطلب
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildTrackingScreen() {
    if (_currentOrderId == null) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color.fromARGB(255, 213, 230, 255), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _CircleBackgroundPainter()),
            ),
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart,
                    size: 60,
                    color: Color.fromARGB(255, 109, 141, 255),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'No current order :(',
                    style: TextStyle(
                      fontSize: 20,
                      color: Color.fromARGB(255, 74, 90, 143),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return OrderTrackingScreen(orderId: _currentOrderId!);
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      MenuScreen(
        seatNumber: widget.seatNumber,
        onOrderCreated: _onOrderCreated,
      ),
      _buildTrackingScreen(),
      LastNewsPage(),
      StadiumMap(),
      ScheduledMatchesScreen(),
    ];

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          backgroundColor: const Color.fromARGB(255, 202, 227, 255),
          elevation: 1,
          centerTitle: true,
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset('images/iicon.png', width: 200, height: 150),
          ),
          title: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: const Color.fromARGB(195, 127, 157, 255),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              'Seat ${widget.seatNumber}',
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.security_sharp),
              onPressed: () => context.push('/admin-login'),
            ),
          ],
        ),
      ),
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color.fromARGB(255, 202, 227, 255),
        selectedItemColor: const Color.fromARGB(255, 3, 17, 113),
        unselectedItemColor: Colors.white,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 14,
        unselectedFontSize: 12,
        items: [
          BottomNavigationBarItem(
            icon: _buildNavIcon(Icons.restaurant_menu, 0),
            label: 'Menu',
          ),
          BottomNavigationBarItem(
            icon: _buildNavIcon(Icons.local_shipping, 1),
            label: 'Track',
          ),
          BottomNavigationBarItem(
            icon: _buildNavIcon(Icons.article, 2),
            label: 'News',
          ),
          BottomNavigationBarItem(
            icon: _buildNavIcon(Icons.map, 3),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: _buildNavIcon(Icons.sports_baseball, 4),
            label: 'Event',
          ),
        ],
      ),
    );
  }

  Widget _buildNavIcon(IconData icon, int index) {
    bool isSelected = _selectedIndex == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(4),
      child: Icon(icon, size: isSelected ? 30 : 24),
    );
  }
}

class _CircleBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = const Color.fromARGB(124, 255, 255, 255);
    canvas.drawCircle(Offset(size.width / 2, size.height / 6), 200, paint);

    paint.color = const Color.fromARGB(112, 189, 209, 255);
    canvas.drawCircle(
      Offset(size.width / 2 + 100, size.height / 2 - 60),
      200,
      paint,
    );

    paint.color = const Color.fromARGB(32, 55, 111, 255);
    canvas.drawCircle(
      Offset(size.width / 2 - 100, size.height / 2 + 80),
      200,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
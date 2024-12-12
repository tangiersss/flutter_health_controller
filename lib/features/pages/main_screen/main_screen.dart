import 'package:flutter/material.dart';
import 'package:health_controller_app/features/bluetooth_service/bluetooth_service.dart';
import 'package:health_controller_app/features/database/databasehelper.dart';
import 'package:health_controller_app/features/pages/analyses_screen/analyses_screen.dart';
import 'package:intl/intl.dart';
import 'package:health_controller_app/features/pages/profile_screen/profile_screen.dart';
import 'package:flutter/services.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  DatabaseHelper dbHelper = DatabaseHelper();
  final bluetoothService = BluetoothService();
  String errorMessage = '';

  final List<Widget> _pages = [
    const HomePage(),
    const AnalysesScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _connectToBluetoothDevice() async {
    try {
      final isConnected = await bluetoothService.checkBluetoothConnection();
      if (isConnected) {
      } else {
        final result = await bluetoothService.connectToDevice();

        if (result == 'A2DP connected successfully') {
          await Future.delayed(const Duration(milliseconds: 300));
        } else {
          _setErrorMessage('Connection failed: $result');
          _showConnectionFailedDialog();
        }
      }
    } catch (e) {
      _setErrorMessage('Error: $e');
      _showConnectionFailedDialog();
    }
  }

  void _setErrorMessage(String message) {
    setState(() {
      errorMessage = message;
    });
  }

  void _showConnectionFailedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Connection Failed'),
          content: Text(
              'Failed to connect to Bluetooth device. Error: $errorMessage\nWould you like to try again?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Retry'),
              onPressed: () {
                Navigator.of(context).pop();
                _connectToBluetoothDevice();
              },
            ),
            TextButton(
              child: const Text('Exit'),
              onPressed: () {
                SystemNavigator.pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red.shade100,
      appBar: AppBar(
        title: Image.asset(
          'assets/images/main_icon.png',
          height: 35,
          width: 35,
        ),
        centerTitle: true,
        backgroundColor: Colors.black54,
        titleTextStyle: const TextStyle(
          fontSize: 25,
          color: Colors.white,
          letterSpacing: 7.0,
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            label: "Analyses",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_2_outlined),
            label: "Profile",
          ),
        ],
        backgroundColor: Colors.red.shade200,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.redAccent.shade700,
        unselectedItemColor: Colors.black,
        onTap: _onItemTapped,
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final String day = DateFormat('dd').format(now);
    final String monthYear = DateFormat('MMMM yyyy').format(now);

    final List<String> recommendations = [
      "Set a daily goal!",
      "Drink more water",
      "Get enough sleep",
    ];

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 20),
          Center(
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(55),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(4, 5),
                  ),
                ],
              ),
              child: Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.red.shade200,
                  borderRadius: BorderRadius.circular(55),
                ),
                child: Column(
                  children: [
                    Text(
                      day,
                      style: const TextStyle(
                        fontSize: 60,
                        fontFamily: 'WorkSans',
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      monthYear,
                      style: const TextStyle(
                        fontSize: 18,
                        fontFamily: 'WorkSans',
                        fontWeight: FontWeight.normal,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
          const Text(
            "YOUR ACTIVITY",
            style: TextStyle(
              fontSize: 22,
              fontFamily: 'WorkSans',
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 1.9,
              ),
              itemCount: 6,
              itemBuilder: (context, index) {
                final indicators = [
                  _buildIndicator("assets/images/temperature.png",
                      "Temperature", "36.6 °C"),
                  _buildIndicator("assets/images/heart.png", "Heart", "80 BPM"),
                  _buildIndicator(
                      "assets/images/pressure.png", "Pressure", "125/70 mmHg"),
                  _buildIndicator(
                      "assets/images/weight.png", "Weight", "85 kg"),
                  _buildIndicator(
                      "assets/images/sleep.png", "Time sleep", "9 h"),
                  _buildIndicator("assets/images/steps.png", "Steps", "14753"),
                ];
                return indicators[index];
              },
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "TODAY'S TIPS",
            style: TextStyle(
              fontSize: 22,
              fontFamily: 'WorkSans',
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recommendations.length,
            itemBuilder: (context, index) {
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0),
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.red.shade200,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(4, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    recommendations[index],
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildIndicator(String imagePath, String title, String value) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red.shade200,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(4, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Image.asset(imagePath, width: 40, height: 40),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

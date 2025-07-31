import 'package:flutter/material.dart';
import 'SlotManager.dart';
import 'CTUsageResetManager.dart';
import 'usb_detection_page.dart';
import 'background_wrapper.dart';
import 'About&Help.dart';



class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final CTUsageResetManager _resetManager = CTUsageResetManager();


  @override
  void initState(){
    super.initState();
    _resetManager.checkAndResetIfNewDay();

  }

  void _showDevelopmentSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Development is in progress, maybe it is available in future updates.',
          style: TextStyle(color: Colors.white),
        ),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
      ),
    );
  }



  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,

        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: AppBar(
            backgroundColor: Colors.transparent, // Transparent AppBar
            elevation: 0,
            shadowColor: Colors.transparent, // No shadow cast
            centerTitle: false,
            automaticallyImplyLeading: false, // Remove back arrow if not needed
            titleSpacing: 16,
            title: null,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: PopupMenuButton<String>(
                  tooltip: 'Options',
                  onSelected: (value) {
                    if (value == 'About') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AboutPage()),
                      );
                    } else if (value == 'Help') {
                      _showDevelopmentSnackbar(context);
                    }
                  },
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'About',
                      child: Text('About'),
                    ),
                    const PopupMenuItem(
                      value: 'Help',
                      child: Text('Help'),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.2), // Glowing color
                          blurRadius: 6,
                          spreadRadius: 0.5,
                        ),
                      ],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.menu, color: Colors.white), // Icon stays white
                        SizedBox(width: 4),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),


        body: BackgroundWrapper(
    child: Padding(
    padding: const EdgeInsets.only(top: 80),
        child: Column(
          children: [
            const SizedBox(height: 50), // Space below AppBar
            const Text(
              'Coupling Together',
              style: TextStyle(
                fontSize: 34, // Slightly larger
                fontWeight: FontWeight.bold,
                color: Colors.white, // Use white for strong contrast
                shadows: [
                  Shadow(
                    blurRadius: 6.0,
                    color: Colors.black87, // Creates a glowing outline
                    offset: Offset(2.0, 2.0),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  children: [
                    _buildCard(context, Icons.usb, 'USB', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => USBDetectionPage()),
                      );
                    }),
                    _buildCard(context, Icons.wifi, 'Wi-Fi', () {
                      _showDevelopmentSnackbar(context);
                    }),
                    _buildCard(context, Icons.bluetooth, 'Bluetooth', () {
                      _showDevelopmentSnackbar(context);
                    }),
                    _buildCard(context, Icons.devices, 'Manage Paired Devices', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => CTSlotManagerScreen()),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),)
    );
  }

  Widget _buildCard(
      BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 8,
              offset: Offset(0, 4),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.blueAccent),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}


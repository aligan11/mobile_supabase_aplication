import 'package:flutter/material.dart';
import 'package:healthmobile/pages/home_page.dart';
import 'package:healthmobile/pages/doctor_page.dart';
import 'package:healthmobile/pages/schedule_page.dart';
import 'package:healthmobile/pages/map_page.dart';
import 'package:healthmobile/pages/profile_page.dart';
import 'package:healthmobile/pages/scan_qr_page.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),
    DoctorPage(),
    SchedulePage(),
    MapPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),

      // =========================
      // QR BUTTON
      // =========================
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ScanQRPage()),
          );
        },
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        elevation: 4,
        child: const Icon(Icons.qr_code_scanner, size: 28),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // =========================
      // BOTTOM NAVIGATION
      // =========================
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        height: 72,
        padding: EdgeInsets.zero,

        child: Row(
          children: [
            Expanded(
              child: _buildNavItem(0, Icons.home_outlined, Icons.home, 'Home'),
            ),

            Expanded(
              child: _buildNavItem(
                1,
                Icons.people_outline,
                Icons.people,
                'Dokter',
              ),
            ),

            const SizedBox(width: 64),

            Expanded(
              child: _buildNavItem(
                2,
                Icons.calendar_month_outlined,
                Icons.calendar_month,
                'Jadwal',
              ),
            ),

            Expanded(
              child: _buildNavItem(
                3,
                Icons.location_on_outlined,
                Icons.location_on,
                'Map',
              ),
            ),

            Expanded(
              child: _buildNavItem(
                4,
                Icons.person_outline,
                Icons.person,
                'Profile',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
  ) {
    final isSelected = _currentIndex == index;

    return InkWell(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(12),

      child: SizedBox(
        height: 72,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? const Color(0xFF1976D2) : Colors.grey,
              size: 24,
            ),

            const SizedBox(height: 2),

            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? const Color(0xFF1976D2) : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

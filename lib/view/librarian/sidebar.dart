import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _activeTab = 'books';

  Widget _buildNavItem(String id, IconData icon) {
    final isActive = _activeTab == id;
    final bgColor = isActive ? const Color(0xFF37373D) : Colors.transparent;
    final iconColor = isActive ? Colors.white : const Color(0xFF999999);
    final indicatorColor = isActive
        ? const Color(0xFF007ACC)
        : Colors.transparent;

    return Material(
      color: bgColor,
      child: InkWell(
        onTap: () {
          setState(() {
            _activeTab = id;
          });
        },
        hoverColor: const Color(0xFF2A2D31),
        child: SizedBox(
          height: 48,
          child: Row(
            children: [
              Container(
                width: 3,
                height: double.infinity,
                color: indicatorColor,
              ),
              Expanded(
                child: Center(child: Icon(icon, color: iconColor, size: 20)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 64.0,
            decoration: const BoxDecoration(
              color: Color(0xFF252526),
              border: Border(
                right: BorderSide(color: Color(0xFF333333), width: 1),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 16),
                const Icon(Icons.favorite, color: Color(0xFFCCCCCC), size: 24),
                const SizedBox(height: 32),
                _buildNavItem('books', Icons.book_outlined),
                _buildNavItem('members', Icons.people_outline),
                _buildNavItem('settings', Icons.settings_outlined),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dashboard',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Currently viewing the '$_activeTab' tab.",
                    style: const TextStyle(
                      color: Color(0xFF888888),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

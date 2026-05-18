import 'package:flutter/material.dart';
import 'package:librarymanagementsystem/src/shared/widgets/app_sidebar.dart';
import 'package:librarymanagementsystem/src/core/theme.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:librarymanagementsystem/src/core/session_manager.dart';
import 'package:go_router_modular/go_router_modular.dart';

class MainLayout extends StatefulWidget {
  final Widget child;
  final List<SidebarItem> sidebarItems;
  final String title;

  const MainLayout({
    super.key,
    required this.child,
    required this.sidebarItems,
    required this.title,
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  String _currentTime = "";
  String _currentDate = "";
  Timer? _timer;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) => _updateTime(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      _currentTime = DateFormat('HH:mm:ss').format(now);
      _currentDate = DateFormat('EEEE, MMMM d, y').format(now);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          AppSidebar(
            items: widget.sidebarItems,
            selectedIndex: _selectedIndex,
            onItemSelected: (index) {
              setState(() => _selectedIndex = index);
              final routes = widget.sidebarItems
                  .map((e) => e.title.toLowerCase().replaceAll(" ", "_"))
                  .toList();
              final path = "/${widget.title.toLowerCase()}/${routes[index]}";
              context.go(path);
            },
            onLogout: () async {
              await SessionManager.logout();
              if (!mounted) return;
              context.go('/auth/signin');
            },
          ),
          Expanded(
            child: Container(
              color: AppColors.background,
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(child: widget.child),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _currentDate,
                style: const TextStyle(
                  color: AppColors.textLight,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _currentTime,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: AppColors.primary,
                child: Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Text(
                "${widget.title} User",
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

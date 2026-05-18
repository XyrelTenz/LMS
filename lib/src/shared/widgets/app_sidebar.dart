import 'package:flutter/material.dart';
import 'package:librarymanagementsystem/src/core/theme.dart';

class AppSidebar extends StatelessWidget {
  final List<SidebarItem> items;
  final Function(int) onItemSelected;
  final int selectedIndex;
  final VoidCallback onLogout;

  const AppSidebar({
    super.key,
    required this.items,
    required this.onItemSelected,
    required this.selectedIndex,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),
          // Logo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Image.asset(
              'assets/logo/jhcsc.png',
              height: 40,
              width: 40,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.library_books, color: AppColors.primary, size: 32),
            ),
          ),
          
          const SizedBox(height: 32),
          const Divider(height: 1, indent: 12, endIndent: 12),
          const SizedBox(height: 16),
          
          // Nav Items
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = selectedIndex == index;
                final activeColor = Colors.green;
                final inactiveColor = AppColors.textDark.withOpacity(0.7);

                return Tooltip(
                  message: item.title,
                  child: InkWell(
                    onTap: () => onItemSelected(index),
                    borderRadius: BorderRadius.zero, // Force sharp corners for hover/splash
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? activeColor.withOpacity(0.1) : Colors.transparent,
                        border: isSelected 
                          ? Border(left: BorderSide(color: activeColor, width: 4))
                          : null,
                      ),
                      child: Icon(
                        item.icon,
                        color: isSelected ? activeColor : inactiveColor,
                        size: 24,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Logout Button
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Tooltip(
              message: "Logout",
              child: InkWell(
                onTap: onLogout,
                borderRadius: BorderRadius.zero,
                child: const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Icon(Icons.logout, color: Colors.redAccent, size: 24),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SidebarItem {
  final String title;
  final IconData icon;
  const SidebarItem({required this.title, required this.icon});
}

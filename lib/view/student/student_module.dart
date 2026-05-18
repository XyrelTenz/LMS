import 'package:go_router_modular/go_router_modular.dart';
import 'package:flutter/material.dart';
import 'package:librarymanagementsystem/view/shared/main_layout.dart';
import 'package:librarymanagementsystem/src/shared/widgets/app_sidebar.dart';
import 'package:librarymanagementsystem/view/student/presentation/screens/book_catalog_screen.dart';
import 'package:librarymanagementsystem/view/student/presentation/screens/my_borrowings_screen.dart';

class StudentModule extends Module {
  @override
  List<ModularRoute> get routes => [
    ShellModularRoute(
      builder: (context, state, child) => MainLayout(
        title: "Student",
        sidebarItems: const [
          SidebarItem(title: "Library Catalog", icon: Icons.search),
          SidebarItem(title: "My Borrowings", icon: Icons.history),
        ],
        child: child,
      ),
      routes: [
        ChildRoute('/library_catalog', child: (context, state) => const BookCatalogScreen()),
        ChildRoute('/my_borrowings', child: (context, state) => const MyBorrowingsScreen()),
      ],
    ),
  ];
}

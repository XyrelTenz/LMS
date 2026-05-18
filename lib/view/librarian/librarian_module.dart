import 'package:go_router_modular/go_router_modular.dart';
import 'package:flutter/material.dart';
import 'package:librarymanagementsystem/view/shared/main_layout.dart';
import 'package:librarymanagementsystem/src/shared/widgets/app_sidebar.dart';
import 'package:librarymanagementsystem/view/librarian/presentation/screens/overview_screen.dart';
import 'package:librarymanagementsystem/view/librarian/presentation/screens/book_management_screen.dart';
import 'package:librarymanagementsystem/view/librarian/presentation/screens/borrowers_screen.dart';
import 'package:librarymanagementsystem/view/librarian/presentation/screens/reports_screen.dart';
import 'package:librarymanagementsystem/view/librarian/presentation/screens/approvals_screen.dart';

class LibrarianModule extends Module {
  @override
  List<ModularRoute> get routes => [
    ShellModularRoute(
      builder: (context, state, child) => MainLayout(
        title: "Librarian",
        sidebarItems: const [
          SidebarItem(title: "Overview", icon: Icons.dashboard),
          SidebarItem(title: "Books Management", icon: Icons.book),
          SidebarItem(title: "Borrowers", icon: Icons.people),
          SidebarItem(title: "Approvals", icon: Icons.how_to_reg),
          SidebarItem(title: "Reports", icon: Icons.bar_chart),
        ],
        child: child,
      ),
      routes: [
        ChildRoute(
          '/overview',
          child: (context, state) => const OverviewScreen(),
        ),
        ChildRoute(
          '/books_management',
          child: (context, state) => const BookManagementScreen(),
        ),
        ChildRoute(
          '/borrowers',
          child: (context, state) => const BorrowersScreen(),
        ),
        ChildRoute(
          '/approvals',
          child: (context, state) => const ApprovalsScreen(),
        ),
        ChildRoute(
          '/reports',
          child: (context, state) => const ReportsScreen(),
        ),
      ],
    ),
  ];
}

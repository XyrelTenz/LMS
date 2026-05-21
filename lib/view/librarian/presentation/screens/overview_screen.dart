import 'package:flutter/material.dart';
import 'package:librarymanagementsystem/src/core/theme.dart';
import 'package:librarymanagementsystem/src/rust/api/mod.dart' as api;
import 'package:librarymanagementsystem/src/rust/domain.dart' as domain;
import 'package:go_router_modular/go_router_modular.dart';

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({super.key});

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  domain.LibraryReport? _report;
  List<domain.Book> _recentBooks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final report = await api.generateReport();
      final books = await api.getAllBooks(limit: 10000, offset: 0);
      final users = await api.getAllUsers();
      setState(() {
        _report = report;
        _recentBooks = books.take(5).toList(); // Just take top 5 for recent
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_report == null) {
      return const Center(child: Text("Unable to load overview data."));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeHeader(),
          const SizedBox(height: 32),
          _buildQuickStats(),
          const SizedBox(height: 48),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: _buildRecentBooks()),
              const SizedBox(width: 32),
              Expanded(flex: 2, child: _buildQuickActions()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Dashboard Overview",
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Manage your library operations and view real-time statistics.",
          style: TextStyle(color: AppColors.textLight, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        _buildStatCard(
          "Total Books",
          _report!.totalBooks.toString(),
          Icons.book,
          Colors.blue,
        ),
        const SizedBox(width: 24),
        _buildStatCard(
          "Available",
          _report!.availableBooks.toString(),
          Icons.check_circle,
          Colors.green,
        ),
        const SizedBox(width: 24),
        _buildStatCard(
          "Borrowed",
          _report!.borrowedBooks.toString(),
          Icons.bookmark,
          Colors.orange,
        ),
        const SizedBox(width: 24),
        _buildStatCard(
          "Total Users",
          _report!.totalUsers.toString(),
          Icons.people,
          Colors.purple,
        ),
        const SizedBox(width: 24),
        _buildStatCard(
          "Popular Genre",
          _report!.mostlyBorrowedGenre,
          Icons.star,
          Colors.red,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.zero,
          border: Border.all(color: Colors.grey.shade200),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, color.withOpacity(0.02)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.zero,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 24),
            Text(
              value,
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark,
                letterSpacing: -1,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                color: AppColors.textLight,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentBooks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Recently Added Books",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
                letterSpacing: -0.5,
              ),
            ),
            TextButton(
              onPressed: () => context.go('/librarian/books_management'),
              child: const Text("View All"),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.zero,
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              if (_recentBooks.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(48.0),
                  child: Text("No books added yet."),
                )
              else
                ..._recentBooks.asMap().entries.map(
                  (entry) => Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.05),
                            borderRadius: BorderRadius.zero,
                          ),
                          child: const Icon(Icons.book_rounded, color: AppColors.primary),
                        ),
                        title: Text(
                          entry.value.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Text("${entry.value.author} • ${entry.value.genre}"),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.zero,
                          ),
                          child: Text(
                            entry.value.publicationYear.toString(),
                            style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      if (entry.key < _recentBooks.length - 1)
                        const Divider(height: 1, indent: 80),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Quick Actions",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 16),
        _buildActionButton("Add New Book", Icons.add_box, Colors.green, () {
          context.go('/librarian/books_management');
        }),
        const SizedBox(height: 12),
        _buildActionButton(
          "Manage Approvals",
          Icons.how_to_reg,
          Colors.red,
          () {
            context.go('/librarian/approvals');
          },
        ),
        const SizedBox(height: 12),
        _buildActionButton("View Reports", Icons.bar_chart, Colors.blue, () {
          context.go('/librarian/reports');
        }),
        const SizedBox(height: 12),
        _buildActionButton("Manage Borrowers", Icons.people, Colors.orange, () {
          context.go('/librarian/borrowers');
        }),
      ],
    );
  }

  Widget _buildActionButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.zero,
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }
}

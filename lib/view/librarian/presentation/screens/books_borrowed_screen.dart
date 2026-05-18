import 'package:flutter/material.dart';
import 'package:librarymanagementsystem/src/core/theme.dart';
import 'package:librarymanagementsystem/src/rust/api/mod.dart' as api;
import 'package:librarymanagementsystem/src/rust/domain.dart' as domain;
import 'package:librarymanagementsystem/src/core/feedback_utils.dart';
import 'package:intl/intl.dart';

class BooksBorrowedScreen extends StatefulWidget {
  const BooksBorrowedScreen({super.key});

  @override
  State<BooksBorrowedScreen> createState() => _BooksBorrowedScreenState();
}

class _BooksBorrowedScreenState extends State<BooksBorrowedScreen> {
  List<domain.Borrowing> _borrowedBooks = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();
  late List<domain.Borrowing> _filteredBooks;

  @override
  void initState() {
    super.initState();
    _filteredBooks = [];
    _loadBorrowedBooks();
  }

  Future<void> _loadBorrowedBooks() async {
    setState(() => _isLoading = true);
    try {
      final allBorrowings = await api.getAllBorrowings();
      // Filter for approved and not returned borrowings
      final borrowed = allBorrowings
          .where(
            (b) => b.status == domain.BorrowStatus.approved && !b.isReturned,
          )
          .toList();
      setState(() {
        _borrowedBooks = borrowed;
        _applySearch();
      });
    } catch (e) {
      if (!mounted) return;
      FeedbackUtils.show(
        context,
        title: "Error",
        message: e.toString(),
        type: FeedbackType.error,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _applySearch() {
    final searchTerm = _searchController.text.toLowerCase();
    if (searchTerm.isEmpty) {
      _filteredBooks = _borrowedBooks;
    } else {
      _filteredBooks = _borrowedBooks.where((book) {
        return book.bookId.toLowerCase().contains(searchTerm) ||
            book.borrowerName.toLowerCase().contains(searchTerm) ||
            book.userId.toLowerCase().contains(searchTerm);
      }).toList();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 32),
          _buildSearchBar(),
          const SizedBox(height: 24),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredBooks.isEmpty
                ? _buildEmptyState()
                : _buildBorrowedBooksList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Books Borrowed",
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "View all books currently borrowed by students.",
          style: TextStyle(color: AppColors.textLight, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search by book ID, student name, or student ID...",
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                filled: true,
                fillColor: AppColors.background.withOpacity(0.5),
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: Colors.grey),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (val) => setState(() {
                _applySearch();
              }),
            ),
          ),
          const SizedBox(width: 16),
          _buildActionButton(
            "Refresh",
            Icons.refresh,
            Colors.blue,
            _loadBorrowedBooks,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.library_books_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isEmpty
                ? "No books currently borrowed"
                : "No matching books found",
            style: TextStyle(color: Colors.grey[500], fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isEmpty
                ? "All books have been returned or are pending approval."
                : "Try adjusting your search criteria.",
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildBorrowedBooksList() {
    return ListView.builder(
      itemCount: _filteredBooks.length,
      itemBuilder: (context, index) {
        final borrowing = _filteredBooks[index];
        final isOverdue = DateTime.now().isAfter(borrowing.dueDate.toLocal());

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
            side: BorderSide(
              color: isOverdue
                  ? AppColors.error.withOpacity(0.3)
                  : Colors.grey[200]!,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isOverdue
                        ? AppColors.error.withOpacity(0.1)
                        : AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.zero,
                  ),
                  child: Icon(
                    Icons.book,
                    color: isOverdue ? AppColors.error : AppColors.primary,
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        borrowing.borrowerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Book ID: ${borrowing.bookId}",
                        style: TextStyle(color: AppColors.textLight),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Student ID: ${borrowing.userId}",
                        style: TextStyle(
                          color: AppColors.textLight,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Borrowed: ${DateFormat('MMM dd, yyyy').format(borrowing.borrowDate)}",
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.schedule,
                            size: 14,
                            color: isOverdue
                                ? AppColors.error
                                : Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Due: ${DateFormat('MMM dd, yyyy').format(borrowing.dueDate.toLocal())}",
                            style: TextStyle(
                              color: isOverdue
                                  ? AppColors.error
                                  : Colors.grey[500],
                              fontSize: 12,
                              fontWeight: isOverdue
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      if (isOverdue) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.zero,
                          ),
                          child: Text(
                            "Overdue",
                            style: TextStyle(
                              color: AppColors.error,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  borrowing.hasReminder
                      ? Icons.notifications_active
                      : Icons.check_circle_outline,
                  color: borrowing.hasReminder
                      ? Colors.orange
                      : AppColors.primary,
                  size: 24,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style:
          ElevatedButton.styleFrom(
            backgroundColor: color.withOpacity(0.1),
            foregroundColor: color,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            ),
          ).copyWith(
            overlayColor: WidgetStateProperty.all(color.withOpacity(0.05)),
          ),
    );
  }
}

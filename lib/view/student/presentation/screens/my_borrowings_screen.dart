import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:librarymanagementsystem/src/core/theme.dart';
import 'package:librarymanagementsystem/src/rust/api/mod.dart' as api;
import 'package:librarymanagementsystem/src/rust/domain.dart' as domain;
import 'package:librarymanagementsystem/src/core/session_manager.dart';
import 'package:librarymanagementsystem/src/core/feedback_utils.dart';

class MyBorrowingsScreen extends StatefulWidget {
  const MyBorrowingsScreen({super.key});

  @override
  State<MyBorrowingsScreen> createState() => _MyBorrowingsScreenState();
}

class _MyBorrowingsScreenState extends State<MyBorrowingsScreen> {
  List<domain.Borrowing> _borrowings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBorrowings();
  }

  Future<void> _loadBorrowings() async {
    final user = await SessionManager.getUser();
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      final borrowings = await api.getUserBorrowings(userId: user['id']);
      setState(() => _borrowings = borrowings);
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

  Future<void> _requestReturn(String borrowingId) async {
    try {
      await api.requestReturn(borrowingId: borrowingId);
      if (!mounted) return;
      FeedbackUtils.show(
        context,
        title: "Return Requested",
        message: "You have requested to return the book. Please bring it to the librarian.",
        type: FeedbackType.success,
      );
      _loadBorrowings();
    } catch (e) {
      if (!mounted) return;
      FeedbackUtils.show(
        context,
        title: "Error",
        message: e.toString(),
        type: FeedbackType.error,
      );
    }
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
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _borrowings.isEmpty
                ? _buildEmptyState()
                : _buildBorrowingList(),
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
          "My Borrowings",
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Track your borrowed books, due dates, and return reminders.",
          style: TextStyle(color: AppColors.textLight, fontSize: 16),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.zero,
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          ),
          child: Text(
            "You currently have ${_borrowings.where((b) => !b.isReturned && b.status == domain.BorrowStatus.approved).length} active borrowings.",
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            "No borrowing history found.",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildBorrowingList() {
    return ListView.builder(
      itemCount: _borrowings.length,
      itemBuilder: (context, index) {
        final borrowing = _borrowings[index];
        return _buildBorrowingCard(borrowing);
      },
    );
  }

  Widget _buildBorrowingCard(domain.Borrowing borrowing) {
    final bool isOverdue =
        !borrowing.isReturned && DateTime.now().isAfter(borrowing.dueDate.toLocal());

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.zero,
        border: Border.all(
          color: borrowing.hasReminder
              ? Colors.orange.withOpacity(0.5)
              : Colors.grey.shade200,
          width: borrowing.hasReminder ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          if (borrowing.hasReminder && !borrowing.isReturned)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.zero,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.notifications_active,
                    color: Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      "Reminder: The librarian has requested the return of this book.",
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getStatusColor(borrowing).withOpacity(0.1),
                  borderRadius: BorderRadius.zero,
                ),
                child: Icon(
                  _getStatusIcon(borrowing),
                  color: _getStatusColor(borrowing),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      borrowing.bookTitle ?? "Unknown Title",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Book ID: ${borrowing.bookId}",
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textLight.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          "Due: ${DateFormat('MMM dd, yyyy').format(borrowing.dueDate.toLocal())}",
                          style: TextStyle(
                            color: isOverdue
                                ? AppColors.error
                                : AppColors.textLight,
                            fontSize: 13,
                            fontWeight: isOverdue
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        if (isOverdue)
                          const Padding(
                            padding: EdgeInsets.only(left: 8.0),
                            child: Text(
                              "OVERDUE",
                              style: TextStyle(
                                color: AppColors.error,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              _buildStatusBadge(borrowing),
              const SizedBox(width: 20),
              if (!borrowing.isReturned &&
                  borrowing.status == domain.BorrowStatus.approved &&
                  borrowing.returnStatus == domain.ReturnStatus.none)
                ElevatedButton(
                  onPressed: () => _requestReturn(borrowing.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  child: const Text("REQUEST RETURN"),
                )
              else if (!borrowing.isReturned &&
                  borrowing.status == domain.BorrowStatus.approved &&
                  borrowing.returnStatus == domain.ReturnStatus.pending)
                const Text(
                  "Return Pending\nPlease see Librarian",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                )
              else if (!borrowing.isReturned &&
                  borrowing.status == domain.BorrowStatus.approved &&
                  borrowing.returnStatus == domain.ReturnStatus.rejected)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      "Return Rejected",
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    if (borrowing.conditionNotes != null)
                      Text(
                        borrowing.conditionNotes!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 10,
                        ),
                      ),
                    const SizedBox(height: 4),
                    ElevatedButton(
                      onPressed: () => _requestReturn(borrowing.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      child: const Text("REQUEST AGAIN", style: TextStyle(fontSize: 12)),
                    )
                  ],
                )
              else if (borrowing.isReturned)
                const Text(
                  "Returned",
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(domain.Borrowing borrowing) {
    String label = "Pending";
    Color color = Colors.orange;

    if (borrowing.status == domain.BorrowStatus.approved) {
      if (borrowing.isReturned) {
        label = "Returned";
        color = Colors.green;
      } else {
        return const SizedBox.shrink();
      }
    } else if (borrowing.status == domain.BorrowStatus.rejected) {
      label = "Rejected";
      color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.zero,
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getStatusColor(domain.Borrowing b) {
    if (b.status == domain.BorrowStatus.rejected) return Colors.red;
    if (b.status == domain.BorrowStatus.pending) return Colors.orange;
    return AppColors.primary;
  }

  IconData _getStatusIcon(domain.Borrowing b) {
    if (b.isReturned) return Icons.check_circle_outline;
    if (b.status == domain.BorrowStatus.rejected) return Icons.cancel_outlined;
    if (b.status == domain.BorrowStatus.pending) return Icons.hourglass_empty;
    return Icons.menu_book;
  }
}

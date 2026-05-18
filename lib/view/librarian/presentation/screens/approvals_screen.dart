import 'package:flutter/material.dart';
import 'package:librarymanagementsystem/src/core/theme.dart';
import 'package:librarymanagementsystem/src/rust/api/mod.dart' as api;
import 'package:librarymanagementsystem/src/rust/domain.dart' as domain;
import 'package:librarymanagementsystem/src/core/feedback_utils.dart';
import 'package:intl/intl.dart';

class ApprovalsScreen extends StatefulWidget {
  const ApprovalsScreen({super.key});

  @override
  State<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

class _ApprovalsScreenState extends State<ApprovalsScreen> {
  List<domain.Borrowing> _pendingRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPendingRequests();
  }

  Future<void> _loadPendingRequests() async {
    setState(() => _isLoading = true);
    try {
      final requests = await api.getPendingBorrowings();
      setState(() => _pendingRequests = requests);
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

  Future<void> _handleApproval(
    String id,
    bool approve, [
    DateTime? dueDate,
  ]) async {
    try {
      if (approve) {
        final dateStr = dueDate != null
            ? dueDate.toUtc().toIso8601String()
            : DateTime.now()
                  .add(const Duration(days: 1))
                  .toUtc()
                  .toIso8601String();
        await api.approveBorrowing(borrowingId: id, dueDate: dateStr);
      } else {
        await api.rejectBorrowing(borrowingId: id);
      }
      _loadPendingRequests();
      if (!mounted) return;
      FeedbackUtils.show(
        context,
        title: approve ? "Approved" : "Rejected",
        message: approve
            ? "The borrow request has been successfully approved."
            : "The borrow request has been rejected.",
        type: approve ? FeedbackType.success : FeedbackType.info,
      );
    } catch (e) {
      if (!mounted) return;
      FeedbackUtils.show(
        context,
        title: "Action Error",
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
                : _pendingRequests.isEmpty
                ? _buildEmptyState()
                : _buildRequestsList(),
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
          "Borrow Approvals",
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Manage and respond to student book borrow requests.",
          style: TextStyle(color: AppColors.textLight, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "No pending approvals",
            style: TextStyle(color: Colors.grey[500], fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsList() {
    return ListView.builder(
      itemCount: _pendingRequests.length,
      itemBuilder: (context, index) {
        final request = _pendingRequests[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
            side: BorderSide(color: Colors.grey),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.zero,
                  ),
                  child: const Icon(Icons.book, color: AppColors.primary),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.borrowerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Book ID: ${request.bookId}",
                        style: TextStyle(color: AppColors.textLight),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Requested: ${DateFormat('MMM dd, yyyy • hh:mm a').format(request.borrowDate)}",
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () => _handleApproval(request.id, false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[50],
                        foregroundColor: Colors.red,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      child: const Text("Reject"),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () async {
                        final now = DateTime.now();
                        final defaultDueDate = now.add(const Duration(days: 1));
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: defaultDueDate,
                          firstDate: now,
                          lastDate: now.add(const Duration(days: 365)),
                          helpText: "SELECT DUE DATE",
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: AppColors.primary,
                                  onPrimary: Colors.white,
                                  onSurface: AppColors.textDark,
                                ),
                                textButtonTheme: TextButtonThemeData(
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.primary,
                                  ),
                                ),
                                dialogTheme: const DialogThemeData(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.zero,
                                  ),
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          _handleApproval(request.id, true, picked);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      child: const Text("Approve"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

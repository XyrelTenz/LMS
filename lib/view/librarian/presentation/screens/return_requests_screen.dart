import 'package:flutter/material.dart';
import 'package:librarymanagementsystem/src/core/theme.dart';
import 'package:librarymanagementsystem/src/rust/api/mod.dart' as api;
import 'package:librarymanagementsystem/src/rust/domain.dart' as domain;
import 'package:librarymanagementsystem/src/core/feedback_utils.dart';
import 'package:intl/intl.dart';

class ReturnRequestsScreen extends StatefulWidget {
  const ReturnRequestsScreen({super.key});

  @override
  State<ReturnRequestsScreen> createState() => _ReturnRequestsScreenState();
}

class _ReturnRequestsScreenState extends State<ReturnRequestsScreen> {
  List<domain.Borrowing> _pendingReturns = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPendingReturns();
  }

  Future<void> _loadPendingReturns() async {
    setState(() => _isLoading = true);
    try {
      final allBorrowings = await api.getAllBorrowings();
      final returns = allBorrowings
          .where((b) => b.returnStatus == domain.ReturnStatus.pending)
          .toList();
      setState(() => _pendingReturns = returns);
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

  Future<void> _handleReturnAction(
    String borrowingId,
    bool approve,
    String? conditionNotes,
    double? feeAmount,
  ) async {
    try {
      await api.processReturn(
        borrowingId: borrowingId,
        isApproved: approve,
        conditionNotes: conditionNotes,
        feeAmount: feeAmount,
      );
      _loadPendingReturns();
      if (!mounted) return;
      FeedbackUtils.show(
        context,
        title: approve ? "Return Approved" : "Return Rejected",
        message: approve
            ? "Book marked as returned."
            : "Return rejected with condition notes.",
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

  void _showRejectDialog(String borrowingId) {
    final TextEditingController notesController = TextEditingController();
    final TextEditingController feeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          title: const Text("Reject Return"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Specify the reason for rejecting the return (e.g., damaged pages).",
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: "Condition Notes / Reason",
                  border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: feeController,
                decoration: const InputDecoration(
                  labelText: "Penalty Fee Amount (₱)",
                  border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                final notes = notesController.text.trim();
                final fee = double.tryParse(feeController.text.trim());
                if (notes.isEmpty) {
                  FeedbackUtils.show(
                    context,
                    title: "Validation Error",
                    message: "Condition notes are required.",
                    type: FeedbackType.error,
                  );
                  return;
                }
                Navigator.pop(context);
                _handleReturnAction(borrowingId, false, notes, fee);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
              child: const Text("Reject"),
            ),
          ],
        );
      },
    );
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
                : _pendingReturns.isEmpty
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
          "Return Requests",
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Review books returned by students and assess their condition.",
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
          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "No pending return requests",
            style: TextStyle(color: Colors.grey[500], fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsList() {
    return ListView.builder(
      itemCount: _pendingReturns.length,
      itemBuilder: (context, index) {
        final request = _pendingReturns[index];
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
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.zero,
                  ),
                  child: const Icon(
                    Icons.keyboard_return,
                    color: Colors.orange,
                  ),
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
                        "Borrowed: ${DateFormat('MMM dd, yyyy').format(request.borrowDate)}",
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () => _showRejectDialog(request.id),
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
                      child: const Text("Decline"),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () =>
                          _handleReturnAction(request.id, true, null, null),
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

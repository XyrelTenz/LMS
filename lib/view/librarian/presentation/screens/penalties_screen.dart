import 'package:flutter/material.dart';
import 'package:librarymanagementsystem/src/core/theme.dart';
import 'package:librarymanagementsystem/src/rust/api/mod.dart' as api;
import 'package:librarymanagementsystem/src/rust/domain.dart' as domain;
import 'package:librarymanagementsystem/src/core/feedback_utils.dart';
import 'package:intl/intl.dart';

class PenaltiesScreen extends StatefulWidget {
  const PenaltiesScreen({super.key});

  @override
  State<PenaltiesScreen> createState() => _PenaltiesScreenState();
}

class _PenaltiesScreenState extends State<PenaltiesScreen> {
  List<domain.Penalty> _penalties = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPenalties();
  }

  Future<void> _loadPenalties() async {
    setState(() => _isLoading = true);
    try {
      final penalties = await api.getAllPenalties();
      setState(() => _penalties = penalties);
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

  Future<void> _markAsPaid(String penaltyId) async {
    try {
      await api.payPenalty(penaltyId: penaltyId);
      _loadPenalties();
      if (!mounted) return;
      FeedbackUtils.show(
        context,
        title: "Payment Recorded",
        message: "The penalty fee has been marked as paid.",
        type: FeedbackType.success,
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
                : _penalties.isEmpty
                ? _buildEmptyState()
                : _buildPenaltiesList(),
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
          "Student Penalties & Fees",
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Track unpaid fees for damaged books or late returns.",
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
          Icon(Icons.money_off, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "No penalties found",
            style: TextStyle(color: Colors.grey[500], fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildPenaltiesList() {
    return ListView.builder(
      itemCount: _penalties.length,
      itemBuilder: (context, index) {
        final penalty = _penalties[index];
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
                    color: penalty.isPaid ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.zero,
                  ),
                  child: Icon(
                    penalty.isPaid ? Icons.check_circle : Icons.warning,
                    color: penalty.isPaid ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Amount: \$${penalty.amount.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Reason: ${penalty.reason}",
                        style: TextStyle(color: AppColors.textDark),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "User ID: ${penalty.userId}",
                        style: TextStyle(color: AppColors.textLight),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Issued: ${DateFormat('MMM dd, yyyy').format(penalty.createdAt)}",
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (!penalty.isPaid)
                  ElevatedButton(
                    onPressed: () => _markAsPaid(penalty.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
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
                    child: const Text("Mark as Paid"),
                  )
                else
                  const Text(
                    "PAID",
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

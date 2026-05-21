import 'package:flutter/material.dart';
import 'package:librarymanagementsystem/src/core/theme.dart';
import 'package:librarymanagementsystem/src/rust/api/mod.dart' as api;
import 'package:librarymanagementsystem/src/rust/domain.dart' as domain;
import 'package:librarymanagementsystem/src/core/feedback_utils.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:intl/intl.dart';
import 'package:librarymanagementsystem/src/core/print_report_utils.dart';

class BorrowersScreen extends StatefulWidget {
  const BorrowersScreen({super.key});

  @override
  State<BorrowersScreen> createState() => _BorrowersScreenState();
}

class _BorrowersScreenState extends State<BorrowersScreen> {
  List<domain.User> _users = [];
  List<domain.Borrowing> _allBorrowings = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();
  late BorrowerDataSource _borrowerDataSource;

  @override
  void initState() {
    super.initState();
    _borrowerDataSource = BorrowerDataSource(
      borrowings: [], 
      onRemind: (_) {}, 
      onForceReturn: (_) {}
    );
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final users = await api.getAllUsers();
      final borrowings = await api.getAllBorrowings();
      setState(() {
        _users = users;
        _allBorrowings = borrowings;
        _updateDataSource();
      });
    } catch (e) {
      if (!mounted) return;
      FeedbackUtils.show(context, title: "Load Error", message: e.toString(), type: FeedbackType.error);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _updateDataSource() {
    // Filter: Only students who have active (not returned) borrowings
    final studentBorrowings = _allBorrowings.where((b) {
      final user = _users.firstWhere((u) => u.id == b.userId, orElse: () => _users[0]);
      final matchesSearch = b.borrowerName.toLowerCase().contains(_searchController.text.toLowerCase()) || 
                           b.userId.toLowerCase().contains(_searchController.text.toLowerCase());
      return user.role == domain.UserRole.student && !b.isReturned && b.status == domain.BorrowStatus.approved && matchesSearch;
    }).toList();

    _borrowerDataSource = BorrowerDataSource(
      borrowings: studentBorrowings,
      onRemind: (borrowing) => _remindStudent(borrowing),
      onForceReturn: (borrowing) => _forceReturn(borrowing),
    );
  }

  void _printBorrowersReport() {
    final activeBorrowings = _allBorrowings.where((b) => 
      !b.isReturned && b.status == domain.BorrowStatus.approved
    ).toList();

    PrintReportUtils.showPrintPreview(
      context,
      title: "Active Borrowers List",
      subtitle: "List of all students with unreturned books as of ${DateFormat('MMM dd, yyyy').format(DateTime.now())}",
      columns: ["Student Name", "Student ID", "Book ID", "Borrow Date", "Due Date"],
      data: activeBorrowings.map((b) => [
        b.borrowerName,
        b.userId,
        b.bookId,
        DateFormat('MMM dd, yyyy').format(b.borrowDate.toLocal()),
        DateFormat('MMM dd, yyyy').format(b.dueDate.toLocal()),
      ]).toList(),
    );
  }

  Future<void> _remindStudent(domain.Borrowing borrowing) async {
    try {
      await api.sendReminder(borrowingId: borrowing.id);
      if (!mounted) return;
      FeedbackUtils.show(
        context,
        title: "Reminder Sent",
        message: "A return reminder has been successfully sent to ${borrowing.borrowerName}.",
        type: FeedbackType.success,
      );
      _loadData();
    } catch (e) {
      if (!mounted) return;
      FeedbackUtils.show(context, title: "Reminder Failed", message: e.toString(), type: FeedbackType.error);
    }
  }

  Future<void> _forceReturn(domain.Borrowing borrowing) async {
    if (borrowing.returnStatus == domain.ReturnStatus.rejected) {
      FeedbackUtils.show(
        context,
        title: "Force Return Blocked",
        message:
            "This return request was rejected.\nReason: ${borrowing.conditionNotes ?? 'Unknown'}\nPlease resolve the issue with the student before returning.",
        type: FeedbackType.error,
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: const Text("Force Return Book"),
        content: const Text(
            "Are you sure you want to force return this book? This will bypass the student request flow."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Force Return"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await api.processReturn(
        borrowingId: borrowing.id,
        isApproved: true,
        conditionNotes: "Forced return by librarian",
      );
      if (!mounted) return;
      FeedbackUtils.show(
        context,
        title: "Book Returned",
        message: "The book has been successfully marked as returned.",
        type: FeedbackType.success,
      );
      _loadData();
    } catch (e) {
      if (!mounted) return;
      FeedbackUtils.show(
        context,
        title: "Return Failed",
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
          _buildSearchAndFilter(),
          const SizedBox(height: 24),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.zero,
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.zero,
                      child: SfDataGrid(
                        source: _borrowerDataSource,
                        columnWidthMode: ColumnWidthMode.fill,
                        headerGridLinesVisibility: GridLinesVisibility.none,
                        selectionMode: SelectionMode.single,
                        columns: [
                          GridColumn(
                            columnName: 'name',
                            label: Container(
                                padding: const EdgeInsets.all(16),
                                alignment: Alignment.centerLeft,
                                child: const Text('Student Name',
                                    style: TextStyle(fontWeight: FontWeight.bold))),
                          ),
                          GridColumn(
                            columnName: 'id',
                            label: Container(
                                padding: const EdgeInsets.all(16),
                                alignment: Alignment.centerLeft,
                                child: const Text('Student ID',
                                    style: TextStyle(fontWeight: FontWeight.bold))),
                          ),
                          GridColumn(
                            columnName: 'bookId',
                            label: Container(
                                padding: const EdgeInsets.all(16),
                                alignment: Alignment.centerLeft,
                                child: const Text('Book ID',
                                    style: TextStyle(fontWeight: FontWeight.bold))),
                          ),
                          GridColumn(
                            columnName: 'borrowDate',
                            label: Container(
                                padding: const EdgeInsets.all(16),
                                alignment: Alignment.centerLeft,
                                child: const Text('Borrow Date',
                                    style: TextStyle(fontWeight: FontWeight.bold))),
                          ),
                          GridColumn(
                            columnName: 'dueDate',
                            label: Container(
                                padding: const EdgeInsets.all(16),
                                alignment: Alignment.centerLeft,
                                child: const Text('Due Date',
                                    style: TextStyle(fontWeight: FontWeight.bold))),
                          ),
                          GridColumn(
                            columnName: 'action',
                            label: Container(
                                padding: const EdgeInsets.all(16),
                                alignment: Alignment.center,
                                child: const Text('Actions',
                                    style: TextStyle(fontWeight: FontWeight.bold))),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Borrowers Management",
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              "Manage active borrowings and send reminders to students.",
              style: TextStyle(color: AppColors.textLight, fontSize: 16),
            ),
          ],
        ),
        InkWell(
          onTap: _printBorrowersReport,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.textDark,
              borderRadius: BorderRadius.zero,
            ),
            child: const Icon(Icons.print_outlined, color: Colors.white, size: 24),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilter() {
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
                hintText: "Search by student name or ID...",
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                filled: true,
                fillColor: AppColors.background.withOpacity(0.5),
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: Colors.grey),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (val) => setState(() {
                _updateDataSource();
              }),
            ),
          ),
          const SizedBox(width: 16),
          _buildActionButton("Refresh", Icons.refresh, Colors.blue, _loadData),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ).copyWith(
        overlayColor: WidgetStateProperty.all(color.withOpacity(0.05)),
      ),
    );
  }
}

class BorrowerDataSource extends DataGridSource {
  BorrowerDataSource({
    required List<domain.Borrowing> borrowings,
    required this.onRemind,
    required this.onForceReturn,
  }) {
    _dataGridRows = borrowings.map<DataGridRow>((b) {
      return DataGridRow(cells: [
        DataGridCell<String>(columnName: 'name', value: b.borrowerName),
        DataGridCell<String>(columnName: 'id', value: b.userId),
        DataGridCell<String>(columnName: 'bookId', value: b.bookId),
        DataGridCell<String>(
            columnName: 'borrowDate',
            value: DateFormat('MMM dd, yyyy').format(b.borrowDate.toLocal())),
        DataGridCell<DateTime>(columnName: 'dueDate', value: b.dueDate.toLocal()),
        DataGridCell<domain.Borrowing>(columnName: 'action', value: b),
      ]);
    }).toList();
  }

  final Function(domain.Borrowing) onRemind;
  final Function(domain.Borrowing) onForceReturn;
  List<DataGridRow> _dataGridRows = [];

  @override
  List<DataGridRow> get rows => _dataGridRows;

  @override
  DataGridRowAdapter? buildRow(DataGridRow row) {
    final domain.Borrowing borrowing = row.getCells()[5].value;
    final DateTime dueDate = row.getCells()[4].value;
    final bool isOverdue = DateTime.now().isAfter(dueDate);

    return DataGridRowAdapter(
      cells: [
        Container(
          padding: const EdgeInsets.all(16),
          alignment: Alignment.centerLeft,
          child: Text(row.getCells()[0].value.toString()),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          alignment: Alignment.centerLeft,
          child: Text(row.getCells()[1].value.toString()),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          alignment: Alignment.centerLeft,
          child: Text(row.getCells()[2].value.toString()),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          alignment: Alignment.centerLeft,
          child: Text(row.getCells()[3].value.toString()),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          alignment: Alignment.centerLeft,
          child: Text(
            DateFormat('MMM dd, yyyy').format(dueDate),
            style: TextStyle(
              color: isOverdue ? AppColors.error : AppColors.textDark,
              fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        Container(
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  borrowing.hasReminder ? Icons.notifications_active : Icons.notifications_active_outlined,
                  color: borrowing.hasReminder ? Colors.orange : AppColors.primary,
                ),
                tooltip: borrowing.hasReminder ? "Reminder Sent" : "Send Reminder",
                onPressed: () => onRemind(borrowing),
              ),
              IconButton(
                icon: const Icon(Icons.assignment_return_outlined, color: Colors.green),
                tooltip: "Force Return",
                onPressed: () => onForceReturn(borrowing),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

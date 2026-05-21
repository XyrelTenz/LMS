import 'package:flutter/material.dart';
import 'package:librarymanagementsystem/src/core/theme.dart';
import 'package:librarymanagementsystem/src/rust/api/mod.dart' as api;
import 'package:librarymanagementsystem/src/rust/domain.dart' as domain;
import 'package:librarymanagementsystem/src/core/feedback_utils.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:intl/intl.dart';
import 'package:librarymanagementsystem/src/core/print_report_utils.dart';

class ReturnHistoryScreen extends StatefulWidget {
  const ReturnHistoryScreen({super.key});

  @override
  State<ReturnHistoryScreen> createState() => _ReturnHistoryScreenState();
}

class _ReturnHistoryScreenState extends State<ReturnHistoryScreen> {
  List<domain.Borrowing> _history = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();
  late ReturnHistoryDataSource _dataSource;

  @override
  void initState() {
    super.initState();
    _dataSource = ReturnHistoryDataSource(history: []);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final borrowings = await api.getAllBorrowings();
      setState(() {
        _history = borrowings.where((b) => b.isReturned || b.status == domain.BorrowStatus.rejected).toList();
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
    final filteredHistory = _history.where((b) {
      final query = _searchController.text.toLowerCase();
      return b.borrowerName.toLowerCase().contains(query) || 
             b.userId.toLowerCase().contains(query) ||
             (b.bookTitle ?? b.bookId).toLowerCase().contains(query);
    }).toList();

    // Sort by return date descending
    filteredHistory.sort((a, b) {
      final aDate = a.returnDate ?? a.borrowDate;
      final bDate = b.returnDate ?? b.borrowDate;
      return bDate.compareTo(aDate);
    });

    _dataSource = ReturnHistoryDataSource(history: filteredHistory);
  }

  void _printReport() {
    PrintReportUtils.showPrintPreview(
      context,
      title: "Return & Audit History",
      subtitle: "Historical log of returns and rejections as of ${DateFormat('MMM dd, yyyy').format(DateTime.now())}",
      columns: ["Student", "Book", "Status", "Date", "Notes"],
      data: _history.map((b) => [
        b.borrowerName,
        b.bookTitle ?? b.bookId,
        b.isReturned ? "Returned" : "Rejected",
        DateFormat('MMM dd, yyyy').format((b.returnDate ?? b.borrowDate).toLocal()),
        b.conditionNotes ?? "None",
      ]).toList(),
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
                        source: _dataSource,
                        columnWidthMode: ColumnWidthMode.fill,
                        headerGridLinesVisibility: GridLinesVisibility.none,
                        selectionMode: SelectionMode.single,
                        columns: [
                          GridColumn(
                            columnName: 'date',
                            label: Container(
                                padding: const EdgeInsets.all(16),
                                alignment: Alignment.centerLeft,
                                child: const Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                          ),
                          GridColumn(
                            columnName: 'name',
                            label: Container(
                                padding: const EdgeInsets.all(16),
                                alignment: Alignment.centerLeft,
                                child: const Text('Student', style: TextStyle(fontWeight: FontWeight.bold))),
                          ),
                          GridColumn(
                            columnName: 'book',
                            label: Container(
                                padding: const EdgeInsets.all(16),
                                alignment: Alignment.centerLeft,
                                child: const Text('Book', style: TextStyle(fontWeight: FontWeight.bold))),
                          ),
                          GridColumn(
                            columnName: 'status',
                            label: Container(
                                padding: const EdgeInsets.all(16),
                                alignment: Alignment.centerLeft,
                                child: const Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                          ),
                          GridColumn(
                            columnName: 'notes',
                            label: Container(
                                padding: const EdgeInsets.all(16),
                                alignment: Alignment.centerLeft,
                                child: const Text('Condition / Notes', style: TextStyle(fontWeight: FontWeight.bold))),
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
              "Return History Log",
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              "Audit log of all completed returns and rejected borrow requests.",
              style: TextStyle(color: AppColors.textLight, fontSize: 16),
            ),
          ],
        ),
        InkWell(
          onTap: _printReport,
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
                hintText: "Search by student name or book...",
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

class ReturnHistoryDataSource extends DataGridSource {
  ReturnHistoryDataSource({
    required List<domain.Borrowing> history,
  }) {
    _dataGridRows = history.map<DataGridRow>((b) {
      final date = b.returnDate ?? b.borrowDate;
      return DataGridRow(cells: [
        DataGridCell<DateTime>(columnName: 'date', value: date.toLocal()),
        DataGridCell<String>(columnName: 'name', value: b.borrowerName),
        DataGridCell<String>(columnName: 'book', value: b.bookTitle ?? b.bookId),
        DataGridCell<String>(
            columnName: 'status',
            value: b.isReturned ? 'Returned' : 'Rejected'),
        DataGridCell<String>(columnName: 'notes', value: b.conditionNotes ?? "-"),
      ]);
    }).toList();
  }

  List<DataGridRow> _dataGridRows = [];

  @override
  List<DataGridRow> get rows => _dataGridRows;

  @override
  DataGridRowAdapter? buildRow(DataGridRow row) {
    final DateTime date = row.getCells()[0].value;
    final String status = row.getCells()[3].value;
    
    final statusColor = status == 'Returned' ? Colors.green : Colors.red;

    return DataGridRowAdapter(
      cells: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.centerLeft,
          child: Text(DateFormat('MMM dd, yyyy HH:mm').format(date)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.centerLeft,
          child: Text(row.getCells()[1].value.toString()),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.centerLeft,
          child: Text(row.getCells()[2].value.toString()),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.zero,
              border: Border.all(color: statusColor.withOpacity(0.3)),
            ),
            child: Text(
              status.toUpperCase(),
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.centerLeft,
          child: Text(row.getCells()[4].value.toString()),
        ),
      ],
    );
  }
}

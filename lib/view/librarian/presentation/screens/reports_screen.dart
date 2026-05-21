import 'package:flutter/material.dart';
import 'package:librarymanagementsystem/src/core/theme.dart';
import 'package:librarymanagementsystem/src/rust/api/mod.dart' as api;
import 'package:librarymanagementsystem/src/rust/domain.dart' as domain;
import 'package:librarymanagementsystem/src/core/feedback_utils.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:librarymanagementsystem/src/core/print_report_utils.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  domain.LibraryReport? _report;
  bool _isLoading = true;
  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() => _isLoading = true);
    try {
      final report = await api.generateReport();
      setState(() => _report = report);
    } catch (e) {
      if (!mounted) return;
      FeedbackUtils.show(
        context,
        title: "Report Error",
        message: e.toString(),
        type: FeedbackType.error,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _printGenreReport() {
    if (_report == null) return;

    PrintReportUtils.showPrintPreview(
      context,
      title: "Genre Distribution Analysis",
      subtitle:
          "Breakdown of library collection by genre as of ${DateFormat('MMM dd, yyyy').format(DateTime.now())}",
      columns: ["Book Genre", "Number of Books", "Percentage of Stock"],
      data: _report!.genreDistribution.entries.map((e) {
        final percentage = (e.value / _report!.totalBooks * 100)
            .toStringAsFixed(1);
        return [e.key, e.value.toString(), "$percentage%"];
      }).toList(),
    );
  }

  void _printActiveBorrowersReport() {
    if (_report == null) return;

    PrintReportUtils.showPrintPreview(
      context,
      title: "Active Borrower List",
      subtitle:
          "List of all students currently holding borrowed books as of ${DateFormat('MMM dd, yyyy').format(DateTime.now())}",
      columns: ["Student Name", "Student ID", "Book Title", "Due Date"],
      data: _report!.activeBorrowers
          .map(
            (b) => [
              b.borrowerName,
              b.userId,
              b.bookTitle,
              _formatReportDate(b.dueDate),
            ],
          )
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_report == null) {
      return const Center(child: Text("Failed to generate report."));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 32),
          _buildStatSummary(),
          const SizedBox(height: 48),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: _buildGenrePieChart()),
              const SizedBox(width: 32),
              Expanded(flex: 2, child: _buildStatusBarChart()),
            ],
          ),
          const SizedBox(height: 48),
          _buildBorrowedBooksList(),
          const SizedBox(height: 48),
          _buildActiveBorrowersList(),
        ],
      ),
    );
  }

  Widget _buildBorrowedBooksList() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.zero,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Currently Borrowed Books",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _printBorrowedBooksReport,
                icon: const Icon(Icons.print),
                label: const Text("Print List"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.textDark,
                  foregroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_report!.borrowedBooksList.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text("No books are currently borrowed."),
              ),
            )
          else
            Table(
              columnWidths: const {
                0: FlexColumnWidth(3),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(2),
                3: FlexColumnWidth(2),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  children: const [
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        "Title",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        "Author",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        "Genre",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        "ISBN",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                ..._report!.borrowedBooksList.map(
                  (book) => TableRow(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade100),
                      ),
                    ),
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(book.title),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(book.author),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(book.genre),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(book.isbn),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildActiveBorrowersList() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.zero,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Active Borrowers",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _printActiveBorrowersReport,
                icon: const Icon(Icons.print),
                label: const Text("Print List"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.textDark,
                  foregroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_report!.activeBorrowers.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text("No active borrowers."),
              ),
            )
          else
            Table(
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(3),
                3: FlexColumnWidth(2),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  children: const [
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        "Name",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        "Student ID",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        "Book Title",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        "Due Date",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                ..._report!.activeBorrowers.map(
                  (borrower) => TableRow(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade100),
                      ),
                    ),
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(borrower.borrowerName),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(borrower.userId),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(borrower.bookTitle),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(_formatReportDate(borrower.dueDate)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _printBorrowedBooksReport() {
    if (_report == null) return;

    PrintReportUtils.showPrintPreview(
      context,
      title: "Currently Borrowed Books Report",
      subtitle:
          "List of all books currently held by borrowers as of ${DateFormat('MMM dd, yyyy').format(DateTime.now())}",
      columns: ["Book Title", "Author", "Genre", "ISBN"],
      data: _report!.borrowedBooksList
          .map((b) => [b.title, b.author, b.genre, b.isbn])
          .toList(),
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
              "Library Analytics",
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.textDark,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Visual insights into library stock, availability, and user engagement.",
              style: TextStyle(color: AppColors.textLight, fontSize: 16),
            ),
          ],
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'genre':
                _printGenreReport();
                break;
              case 'borrowers':
                _printActiveBorrowersReport();
                break;
              case 'books':
                _printBorrowedBooksReport();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'genre',
              child: ListTile(
                leading: Icon(Icons.pie_chart_outline),
                title: Text('Genre Distribution'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'borrowers',
              child: ListTile(
                leading: Icon(Icons.people_outline),
                title: Text('Active Borrower List'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'books',
              child: ListTile(
                leading: Icon(Icons.book_outlined),
                title: Text('Borrowed Books List'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.textDark,
              borderRadius: BorderRadius.zero,
            ),
            child: const Row(
              children: [
                Icon(Icons.print_outlined, color: Colors.white, size: 24),
                SizedBox(width: 8),
                Text(
                  "Print Report",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(Icons.arrow_drop_down, color: Colors.white),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatSummary() {
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
          "Most Popular Genre",
          _report!.mostlyBorrowedGenre,
          Icons.star,
          Colors.red,
        ),
      ],
    );
  }

  Widget _buildGenrePieChart() {
    final List<Color> colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.red,
      Colors.indigo,
      Colors.amber,
    ];

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.zero,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Genre Distribution",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            height: 300,
            child: Row(
              children: [
                Expanded(
                  child: PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              _touchedIndex = -1;
                              return;
                            }
                            _touchedIndex = pieTouchResponse
                                .touchedSection!
                                .touchedSectionIndex;
                          });
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      sectionsSpace: 0,
                      centerSpaceRadius: 60,
                      sections: _report!.genreDistribution.entries
                          .toList()
                          .asMap()
                          .entries
                          .map((entry) {
                            final index = entry.key;
                            final data = entry.value;
                            final isTouched = index == _touchedIndex;
                            final fontSize = isTouched ? 20.0 : 14.0;
                            final radius = isTouched ? 90.0 : 80.0;
                            final color = colors[index % colors.length];

                            return PieChartSectionData(
                              color: color,
                              value: data.value.toDouble(),
                              title:
                                  '${(data.value / _report!.totalBooks * 100).toStringAsFixed(0)}%',
                              radius: radius,
                              titleStyle: TextStyle(
                                fontSize: fontSize,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            );
                          })
                          .toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 32),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _report!.genreDistribution.entries
                      .toList()
                      .asMap()
                      .entries
                      .map((entry) {
                        final index = entry.key;
                        final data = entry.value;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: colors[index % colors.length],
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                data.key,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ],
                          ),
                        );
                      })
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBarChart() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.zero,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Book Status Overview",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            height: 300,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _report!.totalBooks.toDouble(),
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        const style = TextStyle(
                          color: AppColors.textLight,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        );
                        Widget text;
                        switch (value.toInt()) {
                          case 0:
                            text = const Text('Total', style: style);
                            break;
                          case 1:
                            text = const Text('Available', style: style);
                            break;
                          case 2:
                            text = const Text('Borrowed', style: style);
                            break;
                          default:
                            text = const Text('', style: style);
                            break;
                        }
                        return SideTitleWidget(
                          meta: meta,
                          space: 16,
                          child: text,
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 5,
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: _report!.totalBooks.toDouble(),
                        color: Colors.blue,
                        width: 25,
                        borderRadius: BorderRadius.zero,
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: _report!.availableBooks.toDouble(),
                        color: Colors.green,
                        width: 25,
                        borderRadius: BorderRadius.zero,
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 2,
                    barRods: [
                      BarChartRodData(
                        toY: _report!.borrowedBooks.toDouble(),
                        color: Colors.orange,
                        width: 25,
                        borderRadius: BorderRadius.zero,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.zero,
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.zero,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            Text(
              title,
              style: TextStyle(color: AppColors.textLight, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  String _formatReportDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return DateFormat('MMM dd, yyyy').format(dt);
    } catch (_) {
      return dateStr;
    }
  }
}

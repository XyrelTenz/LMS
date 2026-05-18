import 'dart:io';
import 'package:flutter/material.dart';
import 'package:librarymanagementsystem/src/core/theme.dart';
import 'package:librarymanagementsystem/src/rust/api/mod.dart' as api;
import 'package:librarymanagementsystem/src/rust/domain.dart' as domain;
import 'package:librarymanagementsystem/src/core/session_manager.dart';
import 'package:librarymanagementsystem/src/core/feedback_utils.dart';

class BookCatalogScreen extends StatefulWidget {
  const BookCatalogScreen({super.key});

  @override
  State<BookCatalogScreen> createState() => _BookCatalogScreenState();
}

class _BookCatalogScreenState extends State<BookCatalogScreen> {
  List<domain.Book> _books = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();
  String _sortBy = 'Title';

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    setState(() => _isLoading = true);
    try {
      final books = await api.getAllBooks();
      setState(() => _books = books);
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

  Future<void> _searchBooks(String query) async {
    if (query.isEmpty) {
      _loadBooks();
      return;
    }
    setState(() => _isLoading = true);
    try {
      final books = await api.searchBooks(query: query);
      setState(() => _books = books);
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

  Future<void> _borrowBook(domain.Book book) async {
    final user = await SessionManager.getUser();
    if (user == null) {
      FeedbackUtils.show(
        context,
        title: "Session Expired",
        message:
            "Your user session was not found. Please log in again to continue.",
        type: FeedbackType.warning,
      );
      return;
    }

    try {
      await api.borrowBook(
        userId: user['id'],
        userName: user['full_name'],
        bookId: book.id,
      );
      if (!mounted) return;
      FeedbackUtils.show(
        context,
        title: "Request Submitted",
        message:
            "Your borrow request for '${book.title}' has been submitted for approval.",
        type: FeedbackType.success,
      );
      _loadBooks();
    } catch (e) {
      if (!mounted) return;
      FeedbackUtils.show(
        context,
        title: "Borrow Failed",
        message: e.toString(),
        type: FeedbackType.error,
      );
    }
  }

  void _showBookDetails(domain.Book book) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        contentPadding: EdgeInsets.zero,
        content: Container(
          width: 500,
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.zero,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Book Cover Top
              Container(
                height: 250,
                width: double.infinity,
                color: AppColors.background,
                child: Hero(
                  tag: 'book-${book.id}',
                  child: _buildImageWidget(
                    book.imageUrl,
                    height: 250,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // Details Bottom
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                book.title,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "by ${book.author}",
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: AppColors.textLight,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildCopiesStatus(book),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Divider(height: 1),
                    const SizedBox(height: 24),
                    _buildDetailRow(
                      Icons.category_outlined,
                      "Genre",
                      book.genre,
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      Icons.calendar_today_outlined,
                      "Published",
                      book.publicationYear.toString(),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(Icons.qr_code_outlined, "ISBN", book.isbn),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (book.isAvailable && book.copies > 1)
                            ? () {
                                Navigator.pop(context);
                                _borrowBook(book);
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                          backgroundColor: AppColors.primary,
                          disabledBackgroundColor: Colors.grey.shade300,
                        ),
                        child: Text(
                          (book.copies <= 1 && book.isAvailable)
                              ? "LAST COPY IN USE"
                              : (book.isAvailable
                                    ? "REQUEST TO BORROW"
                                    : "CURRENTLY UNAVAILABLE"),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Text(
          "$label: ",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textLight,
          ),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(color: AppColors.textDark)),
        ),
      ],
    );
  }

  Widget _buildImageWidget(
    String? pathOrUrl, {
    double? height,
    double? width,
    BoxFit fit = BoxFit.cover,
  }) {
    if (pathOrUrl == null || pathOrUrl.isEmpty) {
      return Container(
        height: height,
        width: width,
        color: Colors.grey[200],
        child: Icon(Icons.book, size: 48, color: Colors.grey[400]),
      );
    }

    if (pathOrUrl.startsWith('http')) {
      return Image.network(
        pathOrUrl,
        height: height,
        width: width,
        fit: fit,
        errorBuilder: (context, _, __) => Container(
          height: height,
          width: width,
          color: Colors.grey[200],
          child: Icon(Icons.broken_image, size: 32, color: Colors.grey[400]),
        ),
      );
    } else {
      final file = File(pathOrUrl);
      if (file.existsSync()) {
        return Image.file(
          file,
          height: height,
          width: width,
          fit: fit,
          errorBuilder: (context, _, __) => Container(
            height: height,
            width: width,
            color: Colors.grey[200],
            child: Icon(Icons.broken_image, size: 32, color: Colors.grey[400]),
          ),
        );
      }
    }
    return Container(
      height: height,
      width: width,
      color: Colors.grey[200],
      child: Icon(Icons.book, size: 48, color: Colors.grey[400]),
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
          const SizedBox(height: 40),
          _buildSearchAndActions(),
          const SizedBox(height: 32),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : _books.isEmpty
                ? _buildEmptyState()
                : _buildBooksGrid(),
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
          "Library Catalog",
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 32,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          "Browse and borrow from our extensive collection of books.",
          style: TextStyle(
            color: AppColors.textLight,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndActions() {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.zero,
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search for books...",
                hintStyle: TextStyle(color: Colors.grey.shade400),
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        color: Colors.grey.shade600,
                        onPressed: () {
                          _searchController.clear();
                          _loadBooks();
                          setState(() {});
                        },
                      )
                    : null,
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: Colors.grey),
                ),
                enabledBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              onChanged: (value) => setState(() {}),
              onSubmitted: _searchBooks,
            ),
          ),
        ),
        const SizedBox(width: 16),
        _buildSortDropdown(),
      ],
    );
  }

  Widget _buildSortDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: Colors.grey),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _sortBy,
          icon: const Icon(
            Icons.filter_list,
            size: 20,
            color: AppColors.primary,
          ),
          items: [
            "Title",
            "Author",
            "Year",
          ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _sortBy = val;
                if (val == "Title")
                  _books.sort((a, b) => a.title.compareTo(b.title));
                if (val == "Author")
                  _books.sort((a, b) => a.author.compareTo(b.author));
                if (val == "Year")
                  _books.sort(
                    (a, b) => a.publicationYear.compareTo(b.publicationYear),
                  );
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 24),
          Text(
            "No books found matching your criteria.",
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Try adjusting your search or browse all books.",
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildBooksGrid() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 300,
        mainAxisExtent: 450,
        crossAxisSpacing: 28,
        mainAxisSpacing: 28,
      ),
      itemCount: _books.length,
      itemBuilder: (context, index) {
        final book = _books[index];
        return _buildBookCard(book);
      },
    );
  }

  Widget _buildBookCard(domain.Book book) {
    final canBorrow = book.isAvailable && book.copies > 1;

    return InkWell(
      onTap: () => _showBookDetails(book),
      borderRadius: BorderRadius.zero,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.zero,
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image with overlay
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.zero,
                child: Stack(
                  children: [
                    Hero(
                      tag: 'book-${book.id}',
                      child: _buildImageWidget(
                        book.imageUrl,
                        width: double.infinity,
                      ),
                    ),
                    // Overlay for unavailable books
                    if (!canBorrow)
                      Container(
                        color: Colors.black.withOpacity(0.3),
                        child: const Center(
                          child: Icon(
                            Icons.lock,
                            color: Colors.white,
                            size: 48,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Info Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Copies status badge
                  _buildCopiesStatus(book, small: true),
                  const SizedBox(height: 10),
                  // Title
                  Text(
                    book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Author
                  Text(
                    book.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textLight,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: canBorrow
                          ? () => _showBookDetails(book)
                          : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: AppColors.primary,
                        disabledBackgroundColor: Colors.grey.shade300,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      child: Text(
                        canBorrow ? "VIEW DETAILS" : "UNAVAILABLE",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCopiesStatus(domain.Book book, {bool small = false}) {
    final copies = book.copies ?? 1;
    final isLastCopy = copies == 1;
    final isUnavailable = !book.isAvailable || copies <= 1;

    Color bgColor;
    Color textColor;
    String text;

    if (isLastCopy && book.isAvailable) {
      bgColor = Colors.red.withOpacity(0.1);
      textColor = Colors.red;
      text = "Last copy";
    } else if (isUnavailable) {
      bgColor = Colors.orange.withOpacity(0.1);
      textColor = Colors.orange;
      text = "Borrowed";
    } else {
      bgColor = Colors.green.withOpacity(0.1);
      textColor = Colors.green;
      text = "Available: $copies copies";
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 10 : 12,
        vertical: small ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: textColor.withOpacity(0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: small ? 11 : 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

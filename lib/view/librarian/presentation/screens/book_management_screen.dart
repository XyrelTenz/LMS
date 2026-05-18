import 'dart:io';
import 'package:flutter/material.dart';
import 'package:librarymanagementsystem/src/core/theme.dart';
import 'package:librarymanagementsystem/src/rust/api/mod.dart' as api;
import 'package:librarymanagementsystem/src/rust/domain.dart' as domain;
import 'package:file_picker/file_picker.dart';
import 'package:librarymanagementsystem/src/core/feedback_utils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:librarymanagementsystem/src/core/print_report_utils.dart';
import 'package:intl/intl.dart';

class BookManagementScreen extends StatefulWidget {
  const BookManagementScreen({super.key});

  @override
  State<BookManagementScreen> createState() => _BookManagementScreenState();
}

class _BookManagementScreenState extends State<BookManagementScreen> {
  List<domain.Book> _books = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();
  String _sortBy = 'Title';

  static const List<String> GENRES = [
    'Science',
    'Mathematics',
    'Fiction',
    'History',
    'Technology',
  ];

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  /// Fetches the full list of books from the backend.
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

  void _printBookCatalog() {
    PrintReportUtils.showPrintPreview(
      context,
      title: "Library Book Catalog",
      subtitle:
          "Complete list of books in library collection as of ${DateFormat('MMM dd, yyyy').format(DateTime.now())}",
      columns: [
        "Book Title",
        "Author",
        "Genre",
        "Year",
        "ISBN",
        "Copies",
        "Status",
      ],
      data: _books
          .map(
            (b) => [
              b.title,
              b.author,
              b.genre,
              b.publicationYear.toString(),
              b.isbn,
              (b.copies ?? 1).toString(),
              b.isAvailable ? "Available" : "Borrowed",
            ],
          )
          .toList(),
    );
  }

  /// Searches for books using a title, author, or ISBN query.
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

  /// Opens a native file picker to select an image and copies it to the app's local storage.
  Future<String?> _pickAndSaveImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final appDir = await getApplicationDocumentsDirectory();
        final coversDir = Directory(p.join(appDir.path, 'book_covers'));

        if (!await coversDir.exists()) {
          await coversDir.create(recursive: true);
        }

        final fileName =
            "${DateTime.now().millisecondsSinceEpoch}_${p.basename(file.path)}";
        final savedFile = await file.copy(p.join(coversDir.path, fileName));
        return savedFile.path;
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
    return null;
  }

  /// Helper widget to render book images from either network URLs or local file paths.
  Widget _buildImageWidget(
    String? pathOrUrl, {
    double? height,
    double? width,
    BoxFit fit = BoxFit.cover,
  }) {
    if (pathOrUrl == null || pathOrUrl.isEmpty)
      return _buildImagePlaceholder(height: height, width: width);

    if (pathOrUrl.startsWith('http')) {
      return Image.network(
        pathOrUrl,
        height: height,
        width: width,
        fit: fit,
        errorBuilder: (context, _, __) =>
            _buildImagePlaceholder(height: height, width: width),
      );
    } else {
      final file = File(pathOrUrl);
      if (file.existsSync()) {
        return Image.file(
          file,
          height: height,
          width: width,
          fit: fit,
          errorBuilder: (context, _, __) =>
              _buildImagePlaceholder(height: height, width: width),
        );
      }
    }
    return _buildImagePlaceholder(height: height, width: width);
  }

  /// Displays the modal dialog for adding a new book or editing an existing one.
  void _showAddEditDialog([domain.Book? book]) {
    final titleController = TextEditingController(text: book?.title);
    final authorController = TextEditingController(text: book?.author);
    final yearController = TextEditingController(
      text: book?.publicationYear.toString(),
    );
    final isbnController = TextEditingController(text: book?.isbn);
    final genreController = TextEditingController(text: book?.genre);
    final copiesController = TextEditingController(
      text: (book?.copies ?? 1).toString(),
    );
    final imageController = TextEditingController(text: book?.imageUrl);
    String selectedGenre = book != null && GENRES.contains(book.genre) ? book.genre : GENRES.first;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
          titlePadding: EdgeInsets.zero,
          contentPadding: EdgeInsets.zero,
          content: Container(
            width: 700,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.zero,
            ),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    color: AppColors.background,
                    padding: const EdgeInsets.only(top: 48, bottom: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.zero,
                          child: _buildImageWidget(
                            imageController.text,
                            height: 300,
                            width: 500,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "Book Cover Preview",
                          style: TextStyle(
                            color: AppColors.textLight,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 24),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final path = await _pickAndSaveImage();
                            if (path != null) {
                              setModalState(() {
                                imageController.text = path;
                              });
                            }
                          },
                          icon: const Icon(Icons.upload_file),
                          label: const Text("Upload Photo"),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                            ),
                            side: const BorderSide(color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          book == null
                              ? "Register New Book"
                              : "Edit Book Details",
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          book == null
                              ? "Add a new book to the library catalog"
                              : "Update the book information",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 28),
                        _buildInputField(
                          titleController,
                          "Book Title",
                          Icons.title,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildInputField(
                                authorController,
                                "Author",
                                Icons.person_outline,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.zero,
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButtonFormField<String>(
                                    value: selectedGenre,
                                    decoration: const InputDecoration(
                                      labelText: "Genre",
                                      border: InputBorder.none,
                                      prefixIcon: Icon(Icons.category_outlined, size: 20, color: AppColors.primary),
                                    ),
                                    items: GENRES.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setModalState(() {
                                          selectedGenre = val;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildInputField(
                                yearController,
                                "Publication Year",
                                Icons.calendar_today_outlined,
                                isNumber: true,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildInputField(
                                isbnController,
                                "ISBN",
                                Icons.qr_code_scanner_outlined,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildInputField(
                          copiesController,
                          "Number of Copies",
                          Icons.inventory_2_outlined,
                          isNumber: true,
                        ),
                        const SizedBox(height: 16),
                        _buildInputField(
                          imageController,
                          "Cover Image URL or Local Path",
                          Icons.image_outlined,
                          onChanged: (_) => setModalState(() {}),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                              child: const Text("Cancel"),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: () async {
                                try {
                                  if (book == null) {
                                    await api.addBook(
                                      title: titleController.text,
                                      author: authorController.text,
                                      publicationYear:
                                          int.tryParse(yearController.text) ??
                                          2024,
                                      isbn: isbnController.text,
                                      genre: selectedGenre,
                                      copies:
                                          int.tryParse(copiesController.text) ??
                                          1,
                                      imageUrl: imageController.text.isEmpty
                                          ? null
                                          : imageController.text,
                                    );
                                  } else {
                                    await api.updateBook(
                                      book: domain.Book(
                                        id: book.id,
                                        title: titleController.text,
                                        author: authorController.text,
                                        publicationYear:
                                            int.tryParse(yearController.text) ??
                                            book.publicationYear,
                                        isbn: isbnController.text,
                                        genre: selectedGenre,
                                        isAvailable: book.isAvailable,
                                        copies:
                                            int.tryParse(
                                              copiesController.text,
                                            ) ??
                                            book.copies,
                                        imageUrl: imageController.text.isEmpty
                                            ? null
                                            : imageController.text,
                                      ),
                                    );
                                  }
                                  if (!mounted) return;
                                  Navigator.pop(context);
                                  _loadBooks();
                                } catch (e) {
                                  if (!mounted) return;
                                  FeedbackUtils.show(
                                    context,
                                    title: "Save Error",
                                    message: e.toString(),
                                    type: FeedbackType.error,
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                backgroundColor: AppColors.primary,
                              ),
                              child: const Text(
                                "Save Book",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Returns a placeholder widget when no book cover image is available.
  Widget _buildImagePlaceholder({double? height, double? width}) {
    return Container(
      height: height ?? 300,
      width: width ?? 200,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.zero,
      ),
      child: Icon(Icons.file_upload, size: 64, color: Colors.grey[400]),
    );
  }

  /// Standard input field for book details with icon and consistent styling.
  Widget _buildInputField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isNumber = false,
    Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: AppColors.primary),
        filled: true,
        fillColor: Colors.grey[50],
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
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        labelStyle: const TextStyle(color: AppColors.textLight),
      ),
    );
  }

  /// Removes a book from the catalog after confirmation.
  Future<void> _deleteBook(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        title: const Text("Delete Book"),
        content: const Text(
          "Are you sure you want to delete this book? This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Delete",
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await api.deleteBook(id: id);
        _loadBooks();
      } catch (e) {
        if (!mounted) return;
        FeedbackUtils.show(
          context,
          title: "Delete Error",
          message: e.toString(),
          type: FeedbackType.error,
        );
      }
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Books Management",
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.textDark,
                fontWeight: FontWeight.bold,
                fontSize: 32,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Organize and manage the library's book collection.",
              style: TextStyle(
                color: AppColors.textLight,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        InkWell(
          onTap: _printBookCatalog,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.textDark,
              borderRadius: BorderRadius.zero,
            ),
            child: const Icon(
              Icons.print_outlined,
              color: Colors.white,
              size: 24,
            ),
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
                hintText: "Search by title, author, or ISBN...",
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
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: () => _showAddEditDialog(),
          icon: const Icon(Icons.add),
          label: const Text("Add New Book"),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            ),
            backgroundColor: AppColors.primary,
          ),
        ),
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
            "Add a new book to get started.",
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildBooksGrid() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 550,
        mainAxisExtent: 240,
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Book Cover
          Container(
            width: 120,
            height: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.zero,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.zero,
              child: _buildImageWidget(
                book.imageUrl,
                height: double.infinity,
                width: 120,
              ),
            ),
          ),
          const SizedBox(width: 20),
          // Book Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              book.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              book.author,
                              style: const TextStyle(
                                color: AppColors.textLight,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${book.genre} • ${book.publicationYear}",
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          _buildAvailabilityChip(book.isAvailable),
                          const SizedBox(height: 8),
                          _buildCopiesChip(book),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _showAddEditDialog(book),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text("Edit"),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          backgroundColor: AppColors.primary,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () => _deleteBook(book.id),
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: AppColors.error,
                        ),
                        label: const Text(
                          "Delete",
                          style: TextStyle(color: AppColors.error),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          side: const BorderSide(color: AppColors.error),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }

  Widget _buildAvailabilityChip(bool isAvailable) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isAvailable
            ? Colors.green.withOpacity(0.1)
            : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.zero,
        border: Border.all(
          color: isAvailable
              ? Colors.green.withOpacity(0.3)
              : Colors.orange.withOpacity(0.3),
        ),
      ),
      child: Text(
        isAvailable ? "Available" : "Borrowed",
        style: TextStyle(
          color: isAvailable ? Colors.green : Colors.orange,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCopiesChip(domain.Book book) {
    final copies = book.copies ?? 1;
    Color bgColor;
    Color textColor;
    String text;

    if (copies <= 1) {
      bgColor = Colors.red.withOpacity(0.1);
      textColor = Colors.red;
      text = "Last copy";
    } else if (copies <= 3) {
      bgColor = Colors.amber.withOpacity(0.1);
      textColor = Colors.amber[700]!;
      text = "$copies copies";
    } else {
      bgColor = Colors.blue.withOpacity(0.1);
      textColor = Colors.blue;
      text = "$copies copies";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

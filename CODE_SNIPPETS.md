# Implementation Code Snippets

This file contains ready-to-use code snippets for each TODO implementation.

---

## TODO #4: Remove "Approved" Status (EASIEST - Start Here!)

### Current Code Location:
`lib/view/student/presentation/screens/my_borrowings_screen.dart` (lines ~165-177)

### Current Code:
```dart
Widget _buildStatusBadge(domain.Borrowing borrowing) {
    String label = "Pending";
    Color color = Colors.orange;

    if (borrowing.status == domain.BorrowStatus.approved) {
      label = borrowing.isReturned ? "Returned" : "Approved";
      color = Colors.green;
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
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
}
```

### New Code (REPLACE ABOVE):
```dart
Widget _buildStatusBadge(domain.Borrowing borrowing) {
    // Hide "Approved" status for active borrowed books
    if (borrowing.status == domain.BorrowStatus.approved && !borrowing.isReturned) {
      return const SizedBox.shrink();  // Don't show any badge
    }
    
    String label = "Pending";
    Color color = Colors.orange;

    if (borrowing.status == domain.BorrowStatus.approved && borrowing.isReturned) {
      label = "Returned";
      color = Colors.green;
    } else if (borrowing.status == domain.BorrowStatus.rejected) {
      label = "Rejected";
      color = Colors.red;
    }
    // If pending, use default label and color

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.zero,
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
}
```

### What Changed:
- Line 2-3: Added check to hide badge for approved non-returned books
- Line 4: Return empty widget if approved and not returned
- Line 8: Changed condition to explicitly check `isReturned` for approved status

---

## TODO #5: Librarian Sets Due Date

### Step 1: Update Rust Backend API

**File**: `rust/src/api/borrowing_api.rs`

```rust
// REPLACE THIS:
pub fn approve_borrowing(borrowing_id: String) -> Result<(), String> {
    borrowing_service::approve_borrowing(borrowing_id)
}

// WITH THIS:
pub fn approve_borrowing(borrowing_id: String, due_date: Option<String>) -> Result<(), String> {
    borrowing_service::approve_borrowing(borrowing_id, due_date)
}
```

### Step 2: Update Rust Backend Service

**File**: `rust/src/application/borrowing_service.rs`

```rust
// REPLACE THIS:
pub fn approve_borrowing(borrowing_id: String) -> Result<(), String> {
    let conn = sqlite::init_db().map_err(|e| e.to_string())?;
    conn.execute(
        "UPDATE borrowings SET status = 'Approved' WHERE id = ?1",
        params![borrowing_id],
    ).map_err(|e| e.to_string())?;
    Ok(())
}

// WITH THIS:
pub fn approve_borrowing(borrowing_id: String, due_date: Option<String>) -> Result<(), String> {
    let conn = sqlite::init_db().map_err(|e| e.to_string())?;
    
    let new_due_date = match due_date {
        Some(date_str) => date_str,  // Use librarian-provided date
        None => {
            // If not provided, keep existing due_date
            let existing_date: String = conn.query_row(
                "SELECT due_date FROM borrowings WHERE id = ?1",
                params![borrowing_id],
                |row| row.get(0),
            ).map_err(|_| "Borrowing record not found".to_string())?;
            existing_date
        }
    };
    
    conn.execute(
        "UPDATE borrowings SET status = 'Approved', due_date = ?1 WHERE id = ?2",
        params![new_due_date, borrowing_id],
    ).map_err(|e| e.to_string())?;
    Ok(())
}
```

### Step 3: Update Flutter UI

**File**: `lib/view/librarian/presentation/screens/approvals_screen.dart`

Add this new method to `_ApprovalsScreenState` class:

```dart
Future<void> _showApprovalDialog(domain.Borrowing request) async {
    DateTime selectedDueDate = request.dueDate;
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(request.dueDate);
    
    final result = await showDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
            builder: (context, setState) => AlertDialog(
                title: const Text('Approve Borrow Request'),
                content: SingleChildScrollView(
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            Text(
                                'Student: ${request.borrowerName}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text('Book ID: ${request.bookId}'),
                            const SizedBox(height: 24),
                            const Text(
                                'Set Due Date & Time:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            // Date Picker Button
                            ElevatedButton.icon(
                                icon: const Icon(Icons.calendar_today),
                                label: Text(
                                    DateFormat('MMM dd, yyyy').format(selectedDueDate),
                                ),
                                onPressed: () async {
                                    final date = await showDatePicker(
                                        context: context,
                                        initialDate: selectedDueDate,
                                        firstDate: DateTime.now(),
                                        lastDate: DateTime.now().add(const Duration(days: 30)),
                                    );
                                    if (date != null) {
                                        setState(() => selectedDueDate = date);
                                    }
                                },
                            ),
                            const SizedBox(height: 12),
                            // Time Picker Button
                            ElevatedButton.icon(
                                icon: const Icon(Icons.schedule),
                                label: Text(selectedTime.format(context)),
                                onPressed: () async {
                                    final time = await showTimePicker(
                                        context: context,
                                        initialTime: selectedTime,
                                    );
                                    if (time != null) {
                                        setState(() => selectedTime = time);
                                    }
                                },
                            ),
                            const SizedBox(height: 12),
                            // Summary
                            Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                    'Due: ${DateFormat('MMM dd, yyyy • ').format(selectedDueDate)}${selectedTime.format(context)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                            ),
                        ],
                    ),
                ),
                actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Approve'),
                    ),
                ],
            ),
        ),
    );
    
    if (result == true) {
        try {
            // Combine date and time
            final dueDatetime = DateTime(
                selectedDueDate.year,
                selectedDueDate.month,
                selectedDueDate.day,
                selectedTime.hour,
                selectedTime.minute,
            );
            
            await api.approveBorrowing(
                borrowingId: request.id,
                dueDate: dueDatetime.toIso8601String(),
            );
            
            if (!mounted) return;
            FeedbackUtils.show(
                context,
                title: "Approved",
                message: "The borrow request has been approved.",
                type: FeedbackType.success,
            );
            _loadPendingRequests();
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
}
```

Now update the button handler:

```dart
// REPLACE THIS:
Future<void> _handleApproval(String id, bool approve) async {
    try {
      if (approve) {
        await api.approveBorrowing(borrowingId: id);
      } else {
        await api.rejectBorrowing(borrowingId: id);
      }
      _loadPendingRequests();
      // ... rest of code
    }
}

// WITH THIS:
Future<void> _handleApproval(domain.Borrowing request, bool approve) async {
    try {
      if (approve) {
        await _showApprovalDialog(request);  // Show dialog instead
      } else {
        await api.rejectBorrowing(borrowingId: request.id);
        _loadPendingRequests();
        if (!mounted) return;
        FeedbackUtils.show(
          context,
          title: "Rejected",
          message: "The borrow request has been rejected.",
          type: FeedbackType.info,
        );
      }
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
```

Update the button call in the ListView builder:

```dart
// REPLACE THIS:
ElevatedButton(
  onPressed: () => _handleApproval(request.id, true),
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
  ),
  child: const Text("Approve"),
),

// WITH THIS:
ElevatedButton(
  onPressed: () => _handleApproval(request, true),  // Pass request object
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
  ),
  child: const Text("Approve"),
),
```

---

## TODO #1: Number of Copies

### Step 1: Update Database Schema

**File**: `rust/src/infrastructure/sqlite/mod.rs`

Add this to the migrations section (around line 40-50):

```rust
// Migration: Add copies columns for book inventory tracking
let _ = conn.execute(
    "ALTER TABLE books ADD COLUMN copies_total INTEGER NOT NULL DEFAULT 1",
    [],
);
let _ = conn.execute(
    "ALTER TABLE books ADD COLUMN copies_available INTEGER NOT NULL DEFAULT 1",
    [],
);
```

### Step 2: Update Domain Model

**File**: `rust/src/domain/book.rs`

```rust
// REPLACE:
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Book {
    pub id: String,
    pub title: String,
    pub author: String,
    pub publication_year: i32,
    pub isbn: String,
    pub genre: String,
    pub is_available: bool,
    pub image_url: Option<String>,
}

// WITH:
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Book {
    pub id: String,
    pub title: String,
    pub author: String,
    pub publication_year: i32,
    pub isbn: String,
    pub genre: String,
    pub is_available: bool,
    pub image_url: Option<String>,
    pub copies_total: i32,
    pub copies_available: i32,
}
```

### Step 3: Update Book Service

**File**: `rust/src/application/book_service.rs`

Update `add_book()`:

```rust
// REPLACE:
pub fn add_book(title: String, author: String, publication_year: i32, isbn: String, genre: String, image_url: Option<String>) -> Result<(), String> {
    let conn = sqlite::init_db().map_err(|e| e.to_string())?;
    let id = Uuid::new_v4().to_string();
    conn.execute(
        "INSERT INTO books (id, title, author, publication_year, isbn, genre, is_available, image_url) VALUES (?1, ?2, ?3, ?4, ?5, ?6, 1, ?7)",
        params![id, title, author, publication_year, isbn, genre, image_url],
    ).map_err(|e| e.to_string())?;
    Ok(())
}

// WITH:
pub fn add_book(title: String, author: String, publication_year: i32, isbn: String, genre: String, image_url: Option<String>, copies: Option<i32>) -> Result<(), String> {
    let conn = sqlite::init_db().map_err(|e| e.to_string())?;
    let id = Uuid::new_v4().to_string();
    let total_copies = copies.unwrap_or(1);
    
    conn.execute(
        "INSERT INTO books (id, title, author, publication_year, isbn, genre, is_available, image_url, copies_total, copies_available) VALUES (?1, ?2, ?3, ?4, ?5, ?6, 1, ?7, ?8, ?9)",
        params![id, title, author, publication_year, isbn, genre, image_url, total_copies, total_copies],
    ).map_err(|e| e.to_string())?;
    Ok(())
}
```

Update `get_all_books()`:

```rust
// UPDATE SELECT FROM:
"SELECT id, title, author, publication_year, isbn, genre, is_available, image_url FROM books"

// TO:
"SELECT id, title, author, publication_year, isbn, genre, is_available, image_url, copies_total, copies_available FROM books"

// And add to the mapping:
Ok(Book {
    id: row.get(0)?,
    title: row.get(1)?,
    author: row.get(2)?,
    publication_year: row.get(3)?,
    isbn: row.get(4)?,
    genre: row.get(5)?,
    is_available: row.get::<_, i32>(6)? == 1,
    image_url: row.get(7)?,
    copies_total: row.get(8)?,
    copies_available: row.get(9)?,
})
```

Do the same for `search_books()`.

### Step 4: Update Borrowing Service

**File**: `rust/src/application/borrowing_service.rs`

Update `borrow_book()`:

```rust
// REPLACE the availability check:
let is_available: i32 = conn.query_row(
    "SELECT is_available FROM books WHERE id = ?1",
    params![book_id],
    |row| row.get(0),
).map_err(|_| "Book not found".to_string())?;

if is_available == 0 {
    return Err("Book is already borrowed or pending approval".to_string());
}

// WITH THIS:
let copies_available: i32 = conn.query_row(
    "SELECT copies_available FROM books WHERE id = ?1",
    params![book_id],
    |row| row.get(0),
).map_err(|_| "Book not found".to_string())?;

if copies_available <= 0 {
    return Err("No copies of this book are available".to_string());
}

// Then decrement copies:
conn.execute(
    "UPDATE books SET copies_available = copies_available - 1, is_available = CASE WHEN copies_available - 1 > 0 THEN 1 ELSE 0 END WHERE id = ?1",
    params![book_id],
).map_err(|e| e.to_string())?;
```

Update `return_book()`:

```rust
// Add at end before Ok(()):
conn.execute(
    "UPDATE books SET copies_available = copies_available + 1, is_available = 1 WHERE id = ?1",
    params![book_id],
).map_err(|e| e.to_string())?;
```

---

## TODO #3: List of Books That Borrow (Simple Approach)

### Create New Screen

**New File**: `lib/view/librarian/presentation/screens/books_borrowed_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:librarymanagementsystem/src/core/theme.dart';
import 'package:librarymanagementsystem/src/rust/api/mod.dart' as api;
import 'package:librarymanagementsystem/src/rust/domain.dart' as domain;
import 'package:librarymanagementsystem/src/core/feedback_utils.dart';

class BooksBorrowedScreen extends StatefulWidget {
  const BooksBorrowedScreen({super.key});

  @override
  State<BooksBorrowedScreen> createState() => _BooksBorrowedScreenState();
}

class _BooksBorrowedScreenState extends State<BooksBorrowedScreen> {
  List<domain.Borrowing> _borrowedBooks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBorrowedBooks();
  }

  Future<void> _loadBorrowedBooks() async {
    setState(() => _isLoading = true);
    try {
      final allBorrowings = await api.getAllBorrowings();
      // Filter: Only approved, not returned books
      final borrowed = allBorrowings
          .where((b) => b.status == domain.BorrowStatus.approved && !b.isReturned)
          .toList();
      setState(() => _borrowedBooks = borrowed);
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
                : _borrowedBooks.isEmpty
                    ? _buildEmptyState()
                    : _buildBorrowedList(),
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
          "Books Currently Borrowed",
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.textDark,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          "Overview of all books currently borrowed by students",
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
          Icon(Icons.checkmark_circle_outline, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "All books are returned",
            style: TextStyle(color: Colors.grey[500], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildBorrowedList() {
    return ListView.builder(
      itemCount: _borrowedBooks.length,
      itemBuilder: (context, index) {
        final borrowing = _borrowedBooks[index];
        final isOverdue = DateTime.now().isAfter(borrowing.dueDate);

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        borrowing.bookId,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text("Borrowed by: ${borrowing.borrowerName}"),
                      const SizedBox(height: 4),
                      Text(
                        "Borrow: ${DateFormat('MMM dd, yyyy').format(borrowing.borrowDate)}",
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Due: ${DateFormat('MMM dd, yyyy').format(borrowing.dueDate)}",
                        style: TextStyle(
                          color: isOverdue ? Colors.red : Colors.green,
                          fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      if (isOverdue)
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            "OVERDUE",
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isOverdue ? Colors.red[50] : Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isOverdue ? "OVERDUE" : "ON TIME",
                    style: TextStyle(
                      color: isOverdue ? Colors.red : Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
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
```

### Add to Sidebar

**File**: `lib/view/librarian/sidebar.dart` (find the sidebar and add):

```dart
ListTile(
  title: const Text("Books Borrowed"),
  leading: const Icon(Icons.book_outlined),
  onTap: () {
    Modular.to.pushNamed('/librarian/books-borrowed/');
  },
),
```

---

## TODO #2: Add Categories (More Complex)

See `ANALYSIS.md` for detailed implementation of categories system.

Key changes:
1. Create `categories` table in database
2. Add `category_id` foreign key to books table
3. Create `category_service.rs`
4. Update book service to JOIN with categories
5. Update Flutter UI with category dropdowns

---

## Testing the Changes

### After TODO #4:
```bash
# Students should NOT see "APPROVED" badge
# Only see "PENDING", "REJECTED", or nothing for active books
```

### After TODO #5:
```bash
# Librarian should see date picker dialog when clicking Approve
# Librarian can select date and time
# Due date gets updated in database
```

### After TODO #1:
```bash
# Books should show "X of Y copies available"
# All copies borrowed → book becomes unavailable
# Return book → increments copy count
```

---

## Important Notes

1. **Flutter-Rust Bridge**: After changing Rust API signatures, you may need to regenerate:
   ```bash
   cd librarymanagementsystem
   flutter clean
   flutter pub get
   cargo build
   ```

2. **Database Migrations**: Migrations use `ALTER TABLE ... ADD COLUMN` which work on existing databases

3. **Backward Compatibility**: All new fields have DEFAULT values, so old code continues to work

4. **Testing**: Always test with an existing database, not a fresh one

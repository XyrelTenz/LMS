# Library Management System - TODO Implementation Analysis

## Executive Summary
This document provides a detailed analysis of the 5 TODO items from `main.dart`, examining the current implementation and providing step-by-step implementation strategies without breaking existing functionality.

---

## TODO 1: "Number of copies of book"
### Current State
- **Database Schema**: `books` table in `library.db` does NOT have a `copies_count` field
- **Domain Model**: `Book` struct in `rust/src/domain/book.rs` does NOT have copies field
- **Current Fields**: id, title, author, publication_year, isbn, genre, is_available, image_url
- **Availability Tracking**: Currently only has a boolean `is_available` flag, not a count-based system

### Impact Analysis
- **Breaking Changes**: Moderate - Will require database migration
- **Affected Components**:
  - Database schema (`rust/src/infrastructure/sqlite/mod.rs`)
  - Domain model (`rust/src/domain/book.rs`)
  - Book service (`rust/src/application/book_service.rs`)
  - Book API (`rust/src/api/book_api.rs`)
  - Flutter UI (book displays)

### Implementation Strategy

#### Step 1: Update Database Schema
**File**: `rust/src/infrastructure/sqlite/mod.rs`
- Add migration to add `copies_available INTEGER DEFAULT 1` and `copies_total INTEGER DEFAULT 1` columns
- Use ALTER TABLE in migration section (already present)
- Migration example:
```rust
let _ = conn.execute("ALTER TABLE books ADD COLUMN copies_total INTEGER NOT NULL DEFAULT 1", []);
let _ = conn.execute("ALTER TABLE books ADD COLUMN copies_available INTEGER NOT NULL DEFAULT 1", []);
```

#### Step 2: Update Domain Model
**File**: `rust/src/domain/book.rs`
- Add two new fields:
```rust
pub struct Book {
    // ... existing fields
    pub copies_total: i32,
    pub copies_available: i32,
}
```
- Keep `is_available` field for backward compatibility (set to true if copies_available > 0)

#### Step 3: Update Database Operations
**File**: `rust/src/application/book_service.rs`
- Modify `add_book()` to accept optional copies parameter (default to 1)
- Update `get_all_books()` and `search_books()` to SELECT the new columns
- Update `update_book()` to handle copies in UPDATE statement

**File**: `rust/src/application/borrowing_service.rs`
- Modify `borrow_book()` to:
  - Check `copies_available > 0` instead of `is_available == 1`
  - Decrement `copies_available` by 1
  - Set `is_available = 0` only when `copies_available` reaches 0
- Modify `return_book()` to:
  - Increment `copies_available` by 1
  - Set `is_available = 1` if copies become available

#### Step 4: Update API Layer
**File**: `rust/src/api/book_api.rs`
- Update `add_book()` signature to include copies parameter
- Other functions adapt automatically from service changes

#### Step 5: Update Flutter UI
- Update book display widgets to show:
  - "Copies Available: X of Y" instead of just availability status
  - Disable borrow button if copies_available = 0
  - Show copy count in book management and catalog views

### Non-Breaking Implementation
- Keep `is_available` field in database and domain model
- It will be automatically set based on `copies_available > 0`
- Existing code continues to work, new code uses copy counts
- Default value of 1 copy for existing books

---

## TODO 2: "Add category 5"
### Current State
- **Database Schema**: `books` table has `genre TEXT NOT NULL` field
- **Domain Model**: `Book` struct has `genre: String`
- **Categories**: Currently only one category field (genre) exists
- **Possible Interpretation**: Add 5 different category types OR Add a 5th genre category

### Impact Analysis
- **Breaking Changes**: Low to Moderate depending on interpretation
- **Affected Components**:
  - Database schema (might need new table or columns)
  - Domain model
  - Book service/API
  - Flutter UI (filtering/display)

### Implementation Strategy (Assuming "Add 5 different categories")

#### Step 1: Create Categories Table
**File**: `rust/src/infrastructure/sqlite/mod.rs`
```rust
conn.execute(
    "CREATE TABLE IF NOT EXISTS categories (
        id TEXT PRIMARY KEY,
        name TEXT UNIQUE NOT NULL,
        description TEXT,
        type TEXT NOT NULL
    )",
    [],
)?;
```

#### Step 2: Update Books Table
**File**: `rust/src/infrastructure/sqlite/mod.rs`
- Modify books table to include category_id:
```rust
let _ = conn.execute(
    "ALTER TABLE books ADD COLUMN category_id TEXT",
    []
);
let _ = conn.execute(
    "ALTER TABLE books ADD FOREIGN KEY(category_id) REFERENCES categories(id)",
    []
);
```

#### Step 3: Update Domain Model
**File**: `rust/src/domain/book.rs`
```rust
pub struct Book {
    // ... existing fields
    pub category_id: Option<String>,
    pub category_name: Option<String>,  // denormalized for convenience
}
```

#### Step 4: Create Category Service
**New File**: `rust/src/application/category_service.rs`
- `get_all_categories()`
- `add_category(name, description, type)`
- `get_books_by_category(category_id)`

#### Step 5: Update Book Operations
**File**: `rust/src/application/book_service.rs`
- Modify `add_book()` to accept category_id
- Update SELECT statements to JOIN with categories table
- Update Flutter to show both genre and category dropdowns

### Non-Breaking Implementation
- Keep `genre` field in database (backward compatible)
- Add new category system alongside genre
- Allow books to have both genre and category
- UI shows both if they exist, gracefully handles missing category

---

## TODO 3: "List of books that borrow"
### Current State
- **Database**: Borrowings table exists with book_id, user_id, status fields
- **Book Borrowing Endpoints**:
  - `get_user_borrowings(user_id)` - Shows borrowings for specific user
  - `get_all_borrowings()` - Shows all borrowings (Librarian only)
  - `get_pending_borrowings()` - Shows pending approval requests
- **Current Display Locations**:
  - Students see: `MyBorrowingsScreen` (only their own borrowings)
  - Librarians see: `BorrowersScreen` (active borrowings by students)

### Impact Analysis
- **Breaking Changes**: None - Feature is mostly already implemented
- **Gap**: No consolidated "show which specific books are currently borrowed" view
- **Affected Components**:
  - Possibly new API endpoint
  - New Flutter screen or enhancement to existing screens

### Implementation Strategy

#### Option A: Add New Endpoint (Recommended)
**File**: `rust/src/api/borrowing_api.rs`
```rust
/// Lists all books currently borrowed across the library
pub fn get_books_currently_borrowed() -> Result<Vec<BorrowedBookInfo>, String> {
    borrowing_service::get_books_currently_borrowed()
}
```

**File**: `rust/src/domain/borrowing.rs` (add new struct)
```rust
pub struct BorrowedBookInfo {
    pub book_id: String,
    pub book_title: String,  // Denormalized for convenience
    pub borrowed_by: String,
    pub borrower_id: String,
    pub borrow_date: DateTime<Utc>,
    pub due_date: DateTime<Utc>,
    pub borrowing_id: String,
}
```

**File**: `rust/src/application/borrowing_service.rs`
```rust
pub fn get_books_currently_borrowed() -> Result<Vec<BorrowedBookInfo>, String> {
    // SELECT FROM borrowings
    // WHERE status = 'Approved' AND is_returned = 0
    // JOIN with books to get book info
}
```

#### Option B: Enhance Existing Endpoint (Non-Breaking)
Use existing `get_all_borrowings()` but filter on client side to show only active borrowings

#### Step 1: Create New UI Screen
**New File**: `lib/view/librarian/presentation/screens/books_borrowed_screen.dart`
- Display table of books currently borrowed
- Columns: Book Title, Borrowed By, Borrow Date, Due Date, Days Until Due
- Filter by status and return status
- Show book cover thumbnails

#### Step 2: Add to Librarian Sidebar
**File**: `lib/view/librarian/sidebar.dart`
- Add menu item for "Books Currently Borrowed"
- Route to new screen

#### Step 3: Display Options
- Table/Grid view showing:
  - Book information (title, author, ISBN)
  - Student information (name, ID)
  - Borrowing dates and due date
  - Number of days until due
  - Overdue indicator if applicable

### Non-Breaking Implementation
- Reuse existing borrowing data
- Add new display screen without modifying existing endpoints
- Can also add to existing "BorrowersScreen" as a secondary view

---

## TODO 4: "Remove Approved status on students"
### Current State
- **Status Enum**: `BorrowStatus` in `rust/src/domain/borrowing.rs` has three values:
  - Pending
  - Approved
  - Rejected
- **Current Student View**: `MyBorrowingsScreen` shows ALL statuses (Pending, Approved, Rejected)
- **Status Display**: Shows status badge with "PENDING", "APPROVED", "REJECTED" labels
- **Business Logic Issue**: Students see approval status, which violates privacy/UX principle

### Impact Analysis
- **Breaking Changes**: None - UI-only change
- **Affected Components**:
  - Flutter: `lib/view/student/presentation/screens/my_borrowings_screen.dart`
  - No backend changes needed

### Implementation Strategy

#### Current Code Analysis
**File**: `lib/view/student/presentation/screens/my_borrowings_screen.dart` (Lines: 165-177)
```dart
Widget _buildStatusBadge(domain.Borrowing borrowing) {
    String label = "Pending";
    Color color = Colors.orange;

    if (borrowing.status == domain.BorrowStatus.approved) {
      label = borrowing.isReturned ? "Returned" : "Approved";  // <-- REMOVE "Approved"
      color = Colors.green;
    } else if (borrowing.status == domain.BorrowStatus.rejected) {
      label = "Rejected";
      color = Colors.red;
    }
    // ...
}
```

#### Step 1: Modify Status Display Logic
**File**: `lib/view/student/presentation/screens/my_borrowings_screen.dart`
- Change `_buildStatusBadge()` function to NOT show "Approved" status
- Instead show:
  - If approved & not returned: Show nothing or show "Active" / "Borrowed"
  - If approved & returned: Show "Returned"
  - If rejected: Show "Rejected"
  - If pending: Show "Pending"

#### Step 2: Update Status Badge Widget
Replace the status badge logic:
```dart
Widget _buildStatusBadge(domain.Borrowing borrowing) {
    // Hide "Approved" status from students
    if (borrowing.status == domain.BorrowStatus.approved && !borrowing.isReturned) {
      return const SizedBox.shrink();  // Don't show badge for active approved books
    }
    
    String label = "Pending";
    Color color = Colors.orange;

    if (borrowing.status == domain.BorrowStatus.approved) {
      label = "Returned";
      color = Colors.green;
    } else if (borrowing.status == domain.BorrowStatus.rejected) {
      label = "Rejected";
      color = Colors.red;
    }
    
    // Show badge for pending and rejected only
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

#### Step 3: Alternative - Conditional Display
Show different information based on status for approved books:
- Instead of "Approved" badge, show a "Return this book" CTA
- Show the due date prominently
- Hide the status indication

#### Step 4: Update Borrowing Card Logic
**Lines 137-159**: Modify to show more user-friendly information:
- Show "Due: [date]" for approved books
- Show icon indicating action needed (return button)
- Show "Pending" for pending requests
- Show "Rejected" for rejected requests

### Non-Breaking Implementation
- Only UI-level changes
- No database or backend changes
- Students still have access to their borrowing history
- Information is still shown but in a more user-friendly format
- Librarian view remains unchanged

---

## TODO 5: "Librarian can set due date time or set day when approving borrow request"
### Current State
- **Due Date Creation**: Set in `borrow_book()` as borrow_date + 24 hours (hardcoded)
- **Approval Process**: `approve_borrowing()` only sets status to "Approved", doesn't touch due_date
- **Current Flow**:
  1. Student requests book → due_date = now + 24 hours
  2. Librarian approves → status changed, due_date stays the same
- **UI**: `ApprovalsScreen` has Approve/Reject buttons with no due date input

### Impact Analysis
- **Breaking Changes**: Low - Backward compatible
- **Affected Components**:
  - Backend API (`rust/src/api/borrowing_api.rs`)
  - Service layer (`rust/src/application/borrowing_service.rs`)
  - Flutter UI (`lib/view/librarian/presentation/screens/approvals_screen.dart`)

### Implementation Strategy

#### Step 1: Update API Signature
**File**: `rust/src/api/borrowing_api.rs`
```rust
/// Approves a pending borrow request with optional custom due date.
pub fn approve_borrowing(borrowing_id: String, due_date: Option<String>) -> Result<(), String> {
    borrowing_service::approve_borrowing(borrowing_id, due_date)
}
```

#### Step 2: Update Service Logic
**File**: `rust/src/application/borrowing_service.rs`
```rust
pub fn approve_borrowing(borrowing_id: String, due_date: Option<String>) -> Result<(), String> {
    let conn = sqlite::init_db().map_err(|e| e.to_string())?;
    
    let new_due_date = match due_date {
        Some(date_str) => date_str,  // Use librarian-provided date
        None => {
            // If not provided, use existing due_date (already set to now + 24 hours)
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

#### Step 3: Update Flutter UI - Approval Dialog
**File**: `lib/view/librarian/presentation/screens/approvals_screen.dart`
- Modify `_handleApproval()` method
- Create new dialog for approval with due date picker
- Allow librarian to:
  - Accept default due date (24 hours from now or from borrow_date)
  - Set custom due date with date picker
  - Optionally set specific time

#### Step 4: Create Approval Dialog Widget
**In ApprovalsScreen file**:
```dart
Future<void> _showApprovalDialog(domain.Borrowing request) async {
    DateTime selectedDueDate = request.dueDate;
    
    final result = await showDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
            builder: (context, setState) => AlertDialog(
                title: const Text('Approve Borrow Request'),
                content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Text('Student: ${request.borrowerName}'),
                        const SizedBox(height: 16),
                        Text('Book ID: ${request.bookId}'),
                        const SizedBox(height: 24),
                        const Text('Set Due Date:'),
                        const SizedBox(height: 12),
                        // Date picker
                        ElevatedButton.icon(
                            icon: const Icon(Icons.calendar_today),
                            label: Text(
                                'Due: ${DateFormat("MMM dd, yyyy • hh:mm").format(selectedDueDate)}',
                            ),
                            onPressed: () async {
                                final date = await showDatePicker(
                                    context: context,
                                    initialDate: selectedDueDate,
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(Duration(days: 30)),
                                );
                                if (date != null) {
                                    setState(() => selectedDueDate = date);
                                }
                            },
                        ),
                    ],
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
        await api.approveBorrowing(
            borrowingId: request.id,
            dueDate: selectedDueDate.toIso8601String(),
        );
    }
}
```

#### Step 5: Update Button Handler
**Current `_handleApproval()` in ApprovalsScreen**:
```dart
Future<void> _handleApproval(String id, bool approve) async {
    try {
      if (approve) {
        // Open dialog with date picker instead of immediate approval
        await _showApprovalDialog(request);
      } else {
        await api.rejectBorrowing(borrowingId: id);
      }
      // ...
    }
}
```

#### Step 6: Update Flutter-Rust Bridge Binding
- The `frb_generated.rs` file will auto-update if using flutter_rust_bridge
- If manual, update the FFI binding for new `approve_borrowing` signature

### Alternative Simpler Implementation (Quick Win)
- Don't change API signature
- Add a separate API call to update due date before approval
```rust
pub fn set_borrowing_due_date(borrowing_id: String, due_date: String) -> Result<(), String> {
    // Update only the due_date field
}
```
This allows librarian to set date, then approve separately

### Non-Breaking Implementation
- Make `due_date` parameter optional (defaults to None)
- If None, uses existing due_date behavior
- Existing approvals without date parameter continue to work
- New approvals can optionally include custom due date
- Backward compatible: old code still works, new UI takes advantage

---

## Summary Table of Changes

| TODO | Priority | Breaking | Files Affected | Complexity |
|------|----------|----------|----------------|-----------|
| 1. Copies Count | High | Moderate | 5-6 Rust + 3 Flutter | High |
| 2. Categories | Medium | Low | 4-5 Rust + 3 Flutter | Medium |
| 3. Books Borrowed | Low | None | 1-2 Rust + 1-2 Flutter | Low |
| 4. Remove Approved Status | High | None | 1 Flutter | Very Low |
| 5. Due Date Selection | High | None | 2 Rust + 1 Flutter | Medium |

---

## Implementation Order Recommendation

1. **Start with #4** (Remove Approved Status) - Immediate, high value, no risk
2. **Then #5** (Due Date Selection) - Important business feature, minimal risk
3. **Then #3** (Books Borrowed) - Nice-to-have feature, adds value
4. **Then #1** (Copies Count) - Significant feature, requires more refactoring
5. **Finally #2** (Categories) - Can wait, lower priority than others

---

## Key Files Reference

### Backend (Rust)
- Domain Models: `rust/src/domain/book.rs`, `rust/src/domain/borrowing.rs`
- Services: `rust/src/application/book_service.rs`, `rust/src/application/borrowing_service.rs`
- APIs: `rust/src/api/book_api.rs`, `rust/src/api/borrowing_api.rs`
- Database: `rust/src/infrastructure/sqlite/mod.rs`

### Frontend (Flutter)
- Student Views: `lib/view/student/presentation/screens/`
  - `my_borrowings_screen.dart`
  - `book_catalog_screen.dart`
- Librarian Views: `lib/view/librarian/presentation/screens/`
  - `approvals_screen.dart`
  - `borrowers_screen.dart`
  - `book_management_screen.dart`

### Data Models
- Flutter Domain: `lib/src/rust/domain.dart` (auto-generated from Rust)
- Flutter APIs: `lib/src/rust/api/mod.dart` (auto-generated from Rust)

---

## Database Schema Changes Summary

### Current Schema
```sql
-- users table (unchanged)
CREATE TABLE users (...)

-- books table (needs updates for #1 and #2)
CREATE TABLE books (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    author TEXT NOT NULL,
    publication_year INTEGER NOT NULL,
    isbn TEXT UNIQUE NOT NULL,
    genre TEXT NOT NULL,
    is_available INTEGER NOT NULL DEFAULT 1,
    image_url TEXT
    -- ADD FOR #1: copies_total, copies_available
    -- ADD FOR #2: category_id
)

-- borrowings table (ok as-is, maybe enhance for #5)
CREATE TABLE borrowings (
    id TEXT PRIMARY KEY,
    book_id TEXT NOT NULL,
    user_id TEXT NOT NULL,
    borrower_name TEXT NOT NULL,
    borrow_date TEXT NOT NULL,
    due_date TEXT NOT NULL,
    return_date TEXT,
    is_returned INTEGER NOT NULL DEFAULT 0,
    status TEXT NOT NULL DEFAULT 'Approved',
    has_reminder INTEGER NOT NULL DEFAULT 0,
    FOREIGN KEY(book_id) REFERENCES books(id),
    FOREIGN KEY(user_id) REFERENCES users(id)
)

-- NEW FOR #2: categories table
-- (optional, if implementing full category system)
```

---

## Testing Recommendations

1. **Test Backward Compatibility**: Ensure new fields have sensible defaults
2. **Test Database Migrations**: Verify migrations work on existing databases
3. **Test UI Changes**: Verify students don't see "Approved" status
4. **Test Permissions**: Ensure only librarians can access new features
5. **Test Edge Cases**: 
   - What if all copies are borrowed?
   - What if due date is set to past date?
   - What if user session expires during approval?

---

## Notes
- All changes maintain the current architecture and patterns
- Use existing error handling and Result types
- Follow current code style (Rust doc comments, Flutter naming conventions)
- Test incrementally, commit frequently
- Consider database migration strategy for production databases

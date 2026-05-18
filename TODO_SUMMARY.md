# TODO Items Quick Reference

## Overview
5 feature requests identified in `lib/main.dart`. See `ANALYSIS.md` for detailed breakdown.

---

## TODO #1: Number of copies of book ⭐⭐⭐ HIGH PRIORITY

**Current:** Books tracked as Available/Unavailable (boolean)  
**Needed:** Track quantity (e.g., 5 copies total, 2 available)  

### Files to Modify:
- ✅ `rust/src/infrastructure/sqlite/mod.rs` - Add migration for `copies_total`, `copies_available`
- ✅ `rust/src/domain/book.rs` - Add fields: `copies_total: i32`, `copies_available: i32`
- ✅ `rust/src/application/book_service.rs` - Update all queries to handle copies
- ✅ `rust/src/application/borrowing_service.rs` - Decrement on borrow, increment on return
- ✅ `rust/src/api/book_api.rs` - Update add_book() signature
- ✅ Flutter UI - Show "2 of 5 copies available"

### Risk Level: MODERATE - Database migration needed
### Complexity: HIGH
---

## TODO #2: Add category 5 🟡 MEDIUM PRIORITY

**Current:** Only `genre` field exists (Fiction, Non-fiction, etc.)  
**Needed:** Add category system (possibly 5 categories)  

### Interpretation Options:
- **Option A**: Add 5th genre option to dropdown
- **Option B**: Create separate Category table with foreign key
- **Option C**: Add 5 category types/fields to Book

### Files to Modify (if Option B):
- ✅ `rust/src/infrastructure/sqlite/mod.rs` - Create `categories` table
- ✅ `rust/src/domain/book.rs` - Add `category_id` field
- ✅ Create `rust/src/application/category_service.rs` (new)
- ✅ `rust/src/application/book_service.rs` - Update queries with JOIN
- ✅ `rust/src/api/book_api.rs` - Expose category operations
- ✅ Flutter UI - Add category dropdown

### Risk Level: LOW - Genre field remains for backward compatibility
### Complexity: MEDIUM
---

## TODO #3: List of books that borrow ✅ LOW PRIORITY

**Current:** 
- Students see: "My Borrowings" (only their books)
- Librarians see: "Borrowers Management" (students with active borrowings)

**Needed:** Consolidated view of which books are currently borrowed by whom

### Implementation Options:
- **Simple**: Add new screen "Books Currently Borrowed" - filter existing data
- **Better**: Add new API endpoint `get_books_currently_borrowed()`

### Files to Modify:
- ✅ `rust/src/application/borrowing_service.rs` - Add new function (optional)
- ✅ `lib/view/librarian/presentation/screens/` - Create `books_borrowed_screen.dart` (new)
- ✅ `lib/view/librarian/sidebar.dart` - Add menu item

### Risk Level: NONE - Pure addition
### Complexity: LOW - Data already exists, just need new display
---

## TODO #4: Remove "Approved" status from student view 🔥 HIGHEST PRIORITY

**Current:** Students see status badges: "PENDING", "APPROVED", "REJECTED"  
**Need:** Hide "Approved" status - students don't need to see it  
**Reason:** Better UX - approved books = active books, not "approved" books

### File to Modify:
- ✅ `lib/view/student/presentation/screens/my_borrowings_screen.dart`
  - Function: `_buildStatusBadge()` (around line 165-177)
  - Change: Don't show badge for approved non-returned books
  - Instead: Show nothing (empty widget) or show "Active"

### What to Show Instead:
| Status | Show |
|--------|------|
| Pending | "PENDING" badge |
| Approved (not returned) | Nothing / hide status |
| Approved (returned) | "RETURNED" badge |
| Rejected | "REJECTED" badge |

### Risk Level: NONE - UI only, no backend changes
### Complexity: VERY LOW (10 lines of code)
---

## TODO #5: Librarian sets due date when approving ⭐ HIGH PRIORITY

**Current:** 
- Student requests book → due_date = borrow_date + 24 hours (automatic)
- Librarian clicks "Approve" → nothing changes, due_date stays fixed

**Needed:** When approving, librarian can:
- Keep default due date, OR
- Pick custom due date (with date picker)

### Files to Modify:
- ✅ `rust/src/api/borrowing_api.rs` - Change `approve_borrowing(id)` → `approve_borrowing(id, due_date?)`
- ✅ `rust/src/application/borrowing_service.rs` - Update logic to accept optional due_date
- ✅ `lib/view/librarian/presentation/screens/approvals_screen.dart`
  - Replace direct "Approve" button
  - Add dialog with date picker
  - Send due_date to backend

### Backend Change (Simple):
```rust
// Before: fn approve_borrowing(borrowing_id: String)
// After: fn approve_borrowing(borrowing_id: String, due_date: Option<String>)
//
// If due_date provided, use it
// If not, use existing due_date from database
```

### UI Change (Medium):
```dart
// Before: onPressed: () => api.approveBorrowing(id)
// After: onPressed: () => showApprovalDialog(request)
//        Dialog lets librarian pick date, then calls api
```

### Risk Level: LOW - Optional parameter makes it backward compatible
### Complexity: MEDIUM
---

## Implementation Roadmap

### Phase 1: Quick Wins (No Risk)
1. **TODO #4** - Remove Approved status (15 min, 0 risk)

### Phase 2: Important Features (Low-Medium Risk)
2. **TODO #5** - Due date selection (2-3 hours, low risk)
3. **TODO #3** - Books borrowed view (1-2 hours, no risk)

### Phase 3: Significant Changes (Plan Carefully)
4. **TODO #1** - Copies count (4-6 hours, moderate risk - database migration)
5. **TODO #2** - Categories (3-5 hours, low risk - migration-safe)

---

## Database Changes Summary

### Additions Needed:
```sql
-- For TODO #1:
ALTER TABLE books ADD COLUMN copies_total INTEGER NOT NULL DEFAULT 1;
ALTER TABLE books ADD COLUMN copies_available INTEGER NOT NULL DEFAULT 1;

-- For TODO #2 (optional):
CREATE TABLE categories (
    id TEXT PRIMARY KEY,
    name TEXT UNIQUE NOT NULL,
    description TEXT
);
ALTER TABLE books ADD COLUMN category_id TEXT;
ALTER TABLE books ADD FOREIGN KEY(category_id) REFERENCES categories(id);

-- For TODO #5:
-- No database changes needed! Just API enhancement
```

---

## Existing Related Code Locations

### Student Views:
- `lib/view/student/presentation/screens/my_borrowings_screen.dart` - Shows their borrowings
- `lib/view/student/presentation/screens/book_catalog_screen.dart` - Browse & borrow books

### Librarian Views:
- `lib/view/librarian/presentation/screens/approvals_screen.dart` - Approve/reject requests
- `lib/view/librarian/presentation/screens/borrowers_screen.dart` - Manage active borrowings
- `lib/view/librarian/presentation/screens/book_management_screen.dart` - Add/edit books

### Backend:
- `rust/src/domain/book.rs` - Book model
- `rust/src/domain/borrowing.rs` - Borrowing model
- `rust/src/application/book_service.rs` - Book business logic
- `rust/src/application/borrowing_service.rs` - Borrowing business logic
- `rust/src/api/book_api.rs` - Book API (FFI to Flutter)
- `rust/src/api/borrowing_api.rs` - Borrowing API (FFI to Flutter)
- `rust/src/infrastructure/sqlite/mod.rs` - Database init & migrations

---

## Notes
- All implementations should be backward compatible
- Database migrations already have pattern (see sqlite/mod.rs)
- Use `Option<T>` for optional parameters in Rust
- Test with existing database (migration should work)
- Commit frequently, test incrementally

---

See `ANALYSIS.md` for detailed implementation steps for each TODO item.

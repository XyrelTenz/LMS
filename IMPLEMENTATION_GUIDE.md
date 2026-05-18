# Library Management System - TODO Analysis Summary

## 📋 Document Overview

This analysis examines 5 TODO items from `lib/main.dart` for the Library Management System (Rust backend + Flutter frontend). Three comprehensive documents have been created:

1. **ANALYSIS.md** - Detailed analysis of each TODO item with implementation strategies
2. **TODO_SUMMARY.md** - Quick reference guide with priorities and file lists
3. **CODE_SNIPPETS.md** - Ready-to-use code samples for each implementation

---

## 🎯 Executive Summary

| TODO # | Title | Priority | Risk | Complexity | Est. Time |
|--------|-------|----------|------|-----------|-----------|
| 1 | Number of copies of book | ⭐⭐⭐ HIGH | MODERATE | HIGH | 4-6 hrs |
| 2 | Add category 5 | 🟡 MEDIUM | LOW | MEDIUM | 3-5 hrs |
| 3 | List of books that borrow | ✅ LOW | NONE | LOW | 1-2 hrs |
| 4 | Remove "Approved" status | 🔥 CRITICAL | NONE | VERY LOW | 15 min |
| 5 | Set due date on approval | ⭐ HIGH | LOW | MEDIUM | 2-3 hrs |

---

## 📊 Current System Architecture

### Backend (Rust)
- **Database**: SQLite (`library.db`)
- **Structure**: Domain → Service → API → Flutter FFI
- **Key Components**:
  - Domain models: `Book`, `Borrowing`, `User`
  - Services: `book_service`, `borrowing_service`, `auth_service`
  - APIs: Exposed via `flutter_rust_bridge`
  - Database: Migrations via `ALTER TABLE`

### Frontend (Flutter)
- **Student Views**: Browse books, view their borrowings
- **Librarian Views**: Manage books, approve requests, track borrowers
- **Architecture**: Screen → API calls → Domain models

---

## ✨ What Each TODO Requires

### TODO #1: Number of Copies ⭐⭐⭐
**What it does**: Track multiple copies of the same book (e.g., "5 copies total, 2 available")

**Current**: Boolean `is_available` (available or not)  
**Needed**: `copies_total` and `copies_available` integers

**Affected Areas**:
- ✅ Database: Add 2 columns to `books` table
- ✅ Rust domain: Add 2 fields to `Book` struct
- ✅ Rust services: Update borrow/return logic
- ✅ Flutter UI: Display copy counts

**Backward Compatibility**: ✅ YES (default to 1 copy)

---

### TODO #2: Add Category 5 🟡
**What it does**: Add category system alongside existing genre field

**Current**: Only `genre` field (Fiction, Non-fiction, etc.)  
**Needed**: Optional category system with potentially 5 categories

**Possible Interpretations**:
- Add 5th genre option to dropdown
- Create separate `categories` table
- Add category field to Book model

**Recommended**: Create `categories` table for flexibility

**Affected Areas**:
- ✅ Database: New `categories` table + foreign key
- ✅ Rust domain: Add `category_id` to Book
- ✅ Rust services: New category service + updated queries
- ✅ Flutter UI: Category dropdown in forms

**Backward Compatibility**: ✅ YES (genre remains, category is optional)

---

### TODO #3: List of Books That Borrow ✅
**What it does**: Show which books are currently borrowed by whom

**Current**: Librarians can see borrowers, but no consolidated "books" view

**Needed**: Dedicated screen showing currently borrowed books

**Why Easy**: Data already exists in `borrowings` table

**Affected Areas**:
- ✅ Rust: Optional new endpoint (can reuse `get_all_borrowings()`)
- ✅ Flutter: New screen `books_borrowed_screen.dart`
- ✅ UI: Add to librarian sidebar

**Backward Compatibility**: ✅ YES (pure addition)

---

### TODO #4: Remove "Approved" Status 🔥
**What it does**: Hide "Approved" badge from students in their borrowing list

**Current**: Students see "PENDING", "APPROVED", "REJECTED" status badges  
**Needed**: Hide "APPROVED" badge - it's not useful info for students

**Why Easy**: UI-only change, no backend needed

**Affected Areas**:
- ✅ Flutter: Update `_buildStatusBadge()` method in MyBorrowingsScreen

**Status Display After Change**:
| Situation | Show |
|-----------|------|
| Book pending approval | "PENDING" |
| Book approved & active | Nothing (or "Active") |
| Book returned | "RETURNED" |
| Request rejected | "REJECTED" |

**Backward Compatibility**: ✅ YES (UI only)

---

### TODO #5: Librarian Sets Due Date ⭐
**What it does**: Let librarian pick custom due date when approving requests

**Current**: Due date set to borrow_date + 24 hours automatically  
**Needed**: Librarian can override during approval with date/time picker

**Flow**:
1. Student requests book
2. Librarian clicks "Approve" → dialog appears
3. Librarian picks due date/time (or accepts default)
4. Click "Approve" → sends to backend

**Affected Areas**:
- ✅ Rust API: Add optional `due_date` parameter
- ✅ Rust service: Accept and use optional due_date
- ✅ Flutter UI: Show date/time picker dialog

**Backward Compatibility**: ✅ YES (optional parameter)

---

## 🗂️ Key Files Location Reference

### Database & Infrastructure
```
rust/src/infrastructure/sqlite/mod.rs          ← Database schema & migrations
```

### Rust Domain Models
```
rust/src/domain/book.rs                        ← Book model
rust/src/domain/borrowing.rs                   ← Borrowing model & status enum
rust/src/domain/user.rs                        ← User model & role enum
```

### Rust Services (Business Logic)
```
rust/src/application/book_service.rs           ← Book CRUD & search
rust/src/application/borrowing_service.rs      ← Borrowing logic
rust/src/application/auth_service.rs           ← User auth & management
```

### Rust APIs (Exposed to Flutter)
```
rust/src/api/book_api.rs                       ← Book API functions
rust/src/api/borrowing_api.rs                  ← Borrowing API functions
rust/src/api/auth_api.rs                       ← Auth API functions
```

### Flutter Student Views
```
lib/view/student/presentation/screens/my_borrowings_screen.dart     ← TODO #4 is here!
lib/view/student/presentation/screens/book_catalog_screen.dart      ← Browse books
```

### Flutter Librarian Views
```
lib/view/librarian/presentation/screens/approvals_screen.dart       ← TODO #5 is here!
lib/view/librarian/presentation/screens/borrowers_screen.dart       ← Active borrowers
lib/view/librarian/presentation/screens/book_management_screen.dart ← Add/edit books
lib/view/librarian/presentation/screens/books_borrowed_screen.dart  ← TODO #3 goes here (new)
lib/view/librarian/sidebar.dart                                     ← Navigation
```

### Auto-Generated Bindings (Do Not Edit)
```
lib/src/rust/domain.dart                       ← Generated from Rust domain
lib/src/rust/api/mod.dart                      ← Generated from Rust APIs
rust/src/frb_generated.rs                      ← Generated FFI bindings
```

---

## 🚀 Implementation Roadmap

### Phase 1: Quick Wins (30 minutes, no risk)
**TODO #4**: Remove "Approved" status from students
- File: `lib/view/student/presentation/screens/my_borrowings_screen.dart`
- Change: 5-10 lines in `_buildStatusBadge()` method
- Risk: NONE (UI only)

### Phase 2: Core Features (3-4 hours, low risk)
**TODO #5**: Librarian sets due date
- Files: Backend API, service, + Flutter UI
- Risk: LOW (optional parameter makes backward compatible)
- Value: HIGH (important business feature)

**TODO #3**: List of books that borrow
- Files: Possibly 1-2 Rust files + new Flutter screen
- Risk: NONE (pure addition)
- Value: MEDIUM (nice-to-have)

### Phase 3: Major Changes (9-11 hours, plan carefully)
**TODO #1**: Number of copies
- Files: Database, domain, services (multiple)
- Risk: MODERATE (database migration)
- Value: HIGH (inventory management)

**TODO #2**: Add categories
- Files: Database, domain, services, API
- Risk: LOW (genre stays, category is optional)
- Value: MEDIUM (better organization)

---

## 🔍 Database Changes Needed

### Current Schema (Relevant Tables)
```sql
CREATE TABLE books (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    author TEXT NOT NULL,
    publication_year INTEGER NOT NULL,
    isbn TEXT UNIQUE NOT NULL,
    genre TEXT NOT NULL,
    is_available INTEGER NOT NULL DEFAULT 1,
    image_url TEXT
    -- NEED TO ADD FOR #1: copies_total, copies_available
    -- NEED TO ADD FOR #2: category_id
);

CREATE TABLE borrowings (
    id TEXT PRIMARY KEY,
    book_id TEXT NOT NULL,
    user_id TEXT NOT NULL,
    borrower_name TEXT NOT NULL,
    borrow_date TEXT NOT NULL,
    due_date TEXT NOT NULL,              -- Already supports #5!
    return_date TEXT,
    is_returned INTEGER NOT NULL DEFAULT 0,
    status TEXT NOT NULL DEFAULT 'Approved',
    has_reminder INTEGER NOT NULL DEFAULT 0,
    -- No changes needed for #5
);
```

### Migrations to Add
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
```

---

## 🛠️ Development Tips

### Before You Start
1. Review the corresponding section in `ANALYSIS.md` for detailed strategy
2. Check `CODE_SNIPPETS.md` for ready-to-use code
3. Understand the current implementation in the relevant files

### For Rust Changes
- Keep error messages descriptive: `"No copies available"` vs generic errors
- Use `Option<T>` for optional parameters (backward compatibility)
- Always add database migrations in the migration section
- Test with existing database, not fresh one

### For Flutter Changes
- Maintain consistent UI with existing code (see `AppColors`, `TextStyle`)
- Use `FeedbackUtils.show()` for user messages
- Ensure proper state management with `setState()`
- Test navigation changes thoroughly

### Database Migrations
- Migrations are in `rust/src/infrastructure/sqlite/mod.rs`
- Pattern already exists: `let _ = conn.execute(...)`
- New fields need DEFAULT values for existing rows
- Migrations run every time `init_db()` is called (safe to ignore errors)

### Flutter-Rust Bridge
- After changing Rust API signatures, the bridge auto-generates Flutter bindings
- May need to run: `flutter clean` && `flutter pub get`
- The generated code in `lib/src/rust/` is auto-generated (don't edit)

---

## ⚠️ Important Considerations

### Backward Compatibility
✅ All implementations maintain backward compatibility:
- New database fields have DEFAULT values
- New API parameters are Optional
- Old code continues to work alongside new code

### Testing Strategy
1. Test with existing database (check migrations work)
2. Test with fresh database (check full initialization)
3. Test UI changes on both student and librarian accounts
4. Test edge cases:
   - What if all copies borrowed? → Book unavailable
   - What if due date is in past? → Should reject or warn
   - What if session expires mid-approval? → Show error

### Performance Considerations
- `get_all_borrowings()` currently loads all records (consider pagination later)
- Database queries should use WHERE clauses effectively
- JOIN operations with categories should include indexes eventually

---

## 📚 Document Navigation

- **ANALYSIS.md**: Read this for deep understanding of each TODO
  - Current state analysis
  - Impact assessment
  - Step-by-step implementation guide
  - Non-breaking strategies
  - Database schema details
  
- **TODO_SUMMARY.md**: Use this for quick reference
  - Quick overview of each TODO
  - Files to modify list
  - Risk/complexity matrix
  - Implementation roadmap
  
- **CODE_SNIPPETS.md**: Use this while coding
  - Ready-to-copy code blocks
  - Before/after comparisons
  - Specific line numbers
  - Testing recommendations

---

## 🎓 Learning Resources in Codebase

### Existing Patterns to Follow

**Database Migration Pattern**:
```rust
let _ = conn.execute("ALTER TABLE tablename ADD COLUMN newcol TYPE DEFAULT value", []);
```
See: `rust/src/infrastructure/sqlite/mod.rs` (lines 30-35)

**Rust Service Pattern**:
```rust
pub fn function_name(params) -> Result<ReturnType, String> {
    let conn = sqlite::init_db().map_err(|e| e.to_string())?;
    // ... database operations ...
    Ok(result)
}
```
See: `rust/src/application/book_service.rs`

**Rust API Wrapper Pattern**:
```rust
pub fn api_function(params) -> Result<Type, String> {
    service::function(params)
}
```
See: `rust/src/api/book_api.rs`

**Flutter Screen Pattern**:
```dart
class MyScreen extends StatefulWidget {
    @override
    State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
    void initState() { _loadData(); }
    Future<void> _loadData() async { ... }
    @override
    Widget build(BuildContext context) { ... }
}
```
See: `lib/view/student/presentation/screens/my_borrowings_screen.dart`

---

## ✅ Checklist for Implementation

### Before Starting
- [ ] Read relevant section in ANALYSIS.md
- [ ] Review current code in the files to modify
- [ ] Check CODE_SNIPPETS.md for examples
- [ ] Create git branch for your changes

### During Implementation
- [ ] Follow existing code style and patterns
- [ ] Add error handling (don't ignore errors)
- [ ] Test incrementally (don't wait until end)
- [ ] Keep commit messages clear
- [ ] Document any new functions with comments

### After Implementation
- [ ] Test with existing database
- [ ] Test happy path and error cases
- [ ] Check UI looks consistent
- [ ] Review code before committing
- [ ] Test on different screen sizes (Flutter)

### For Each TODO
- [ ] Create git branch: `feature/TODO-#-description`
- [ ] Implement changes
- [ ] Test thoroughly
- [ ] Create PR with detailed description
- [ ] Get code review if working with team

---

## 🤝 Questions?

Refer to the three documents:
1. **Need strategic overview?** → Read ANALYSIS.md
2. **Need quick facts?** → Check TODO_SUMMARY.md
3. **Need code examples?** → Look at CODE_SNIPPETS.md

Each document is self-contained but cross-references the others.

---

**Generated**: Analysis of Library Management System TODOs  
**Scope**: 5 TODO items from `lib/main.dart`  
**Architecture**: Rust backend + Flutter frontend  
**Database**: SQLite with migrations

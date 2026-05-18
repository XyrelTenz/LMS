# Rust Implementation Guide - Task 1

## Quick Implementation Reference

This guide shows the exact code changes needed for the Rust backend.

---

## File 1: `rust/src/domain/book.rs` ✅

### Current Code (BEFORE)
```rust
use serde::{Deserialize, Serialize};

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
```

### Updated Code (AFTER)
```rust
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Book {
    pub id: String,
    pub title: String,
    pub author: String,
    pub publication_year: i32,
    pub isbn: String,
    pub genre: String,
    pub is_available: bool,
    pub copies: i32,                    // ✅ ADD THIS LINE
    pub image_url: Option<String>,
}
```

**Change:** Add `pub copies: i32,` field before `image_url`

---

## File 2: `rust/src/infrastructure/sqlite/mod.rs` ✅

### Current Code (BEFORE)
```rust
pub fn init_db() -> rusqlite::Result<Connection> {
    let conn = Connection::open("library.db")?;

    conn.execute(
        "CREATE TABLE IF NOT EXISTS users (
            ...
        )",
        [],
    )?;

    conn.execute(
        "CREATE TABLE IF NOT EXISTS books (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            author TEXT NOT NULL,
            publication_year INTEGER NOT NULL,
            isbn TEXT UNIQUE NOT NULL,
            genre TEXT NOT NULL,
            is_available INTEGER NOT NULL DEFAULT 1,
            image_url TEXT
        )",
        [],
    )?;

    // ... existing migrations ...
    let _ = conn.execute("ALTER TABLE borrowings ADD COLUMN status TEXT NOT NULL DEFAULT 'Approved'", []);
    let _ = conn.execute("ALTER TABLE books ADD COLUMN image_url TEXT", []);
    let _ = conn.execute("ALTER TABLE borrowings ADD COLUMN due_date TEXT", []);
    let _ = conn.execute("ALTER TABLE borrowings ADD COLUMN has_reminder INTEGER NOT NULL DEFAULT 0", []);
    
    // Fix existing due_dates if null (migration helper)
    let _ = conn.execute("UPDATE borrowings SET due_date = borrow_date WHERE due_date IS NULL", []);

    Ok(conn)
}
```

### Updated Code (AFTER)
```rust
pub fn init_db() -> rusqlite::Result<Connection> {
    let conn = Connection::open("library.db")?;

    conn.execute(
        "CREATE TABLE IF NOT EXISTS users (
            ...
        )",
        [],
    )?;

    conn.execute(
        "CREATE TABLE IF NOT EXISTS books (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            author TEXT NOT NULL,
            publication_year INTEGER NOT NULL,
            isbn TEXT UNIQUE NOT NULL,
            genre TEXT NOT NULL,
            is_available INTEGER NOT NULL DEFAULT 1,
            copies INTEGER NOT NULL DEFAULT 1,         // ✅ ADD THIS LINE
            image_url TEXT
        )",
        [],
    )?;

    // ... existing migrations ...
    let _ = conn.execute("ALTER TABLE borrowings ADD COLUMN status TEXT NOT NULL DEFAULT 'Approved'", []);
    let _ = conn.execute("ALTER TABLE books ADD COLUMN image_url TEXT", []);
    let _ = conn.execute("ALTER TABLE borrowings ADD COLUMN due_date TEXT", []);
    let _ = conn.execute("ALTER TABLE borrowings ADD COLUMN has_reminder INTEGER NOT NULL DEFAULT 0", []);
    
    // ✅ ADD THIS MIGRATION
    let _ = conn.execute("ALTER TABLE books ADD COLUMN copies INTEGER NOT NULL DEFAULT 1", []);
    
    // Fix existing due_dates if null (migration helper)
    let _ = conn.execute("UPDATE borrowings SET due_date = borrow_date WHERE due_date IS NULL", []);

    Ok(conn)
}
```

**Changes:**
1. Add `copies INTEGER NOT NULL DEFAULT 1,` to the CREATE TABLE statement
2. Add migration: `let _ = conn.execute("ALTER TABLE books ADD COLUMN copies INTEGER NOT NULL DEFAULT 1", []);`

---

## File 3: `rust/src/api/book_api.rs` 📝

### Current Code (BEFORE)
```rust
use crate::application::book_service;
pub use crate::domain::book::Book;

/// Adds a new book to the library catalog.
pub fn add_book(title: String, author: String, publication_year: i32, isbn: String, genre: String, image_url: Option<String>) -> Result<(), String> {
    book_service::add_book(title, author, publication_year, isbn, genre, image_url)
}

/// Retrieves the complete list of books in the library.
pub fn get_all_books() -> Result<Vec<Book>, String> {
    book_service::get_all_books()
}

/// Searches for books matching the given title, author, or ISBN.
pub fn search_books(query: String) -> Result<Vec<Book>, String> {
    book_service::search_books(query)
}

/// Updates the metadata and availability status of a book.
pub fn update_book(book: Book) -> Result<(), String> {
    book_service::update_book(book)
}

/// Removes a book from the system using its unique identifier.
pub fn delete_book(id: String) -> Result<(), String> {
    book_service::delete_book(id)
}
```

### Updated Code (AFTER)
```rust
use crate::application::book_service;
pub use crate::domain::book::Book;

/// Adds a new book to the library catalog.
pub fn add_book(title: String, author: String, publication_year: i32, isbn: String, genre: String, copies: Option<i32>, image_url: Option<String>) -> Result<(), String> {  // ✅ ADD copies parameter
    book_service::add_book(title, author, publication_year, isbn, genre, copies, image_url)  // ✅ PASS copies
}

/// Retrieves the complete list of books in the library.
pub fn get_all_books() -> Result<Vec<Book>, String> {
    book_service::get_all_books()
}

/// Searches for books matching the given title, author, or ISBN.
pub fn search_books(query: String) -> Result<Vec<Book>, String> {
    book_service::search_books(query)
}

/// Updates the metadata and availability status of a book.
pub fn update_book(book: Book) -> Result<(), String> {
    book_service::update_book(book)
}

/// Removes a book from the system using its unique identifier.
pub fn delete_book(id: String) -> Result<(), String> {
    book_service::delete_book(id)
}
```

**Changes:**
1. Add parameter: `copies: Option<i32>` to `add_book` function signature
2. Pass it to service: `book_service::add_book(..., copies, ...)`

---

## File 4: `rust/src/application/book_service.rs` 📝

### Current `add_book` Function (BEFORE)
```rust
pub fn add_book(title: String, author: String, publication_year: i32, isbn: String, genre: String, image_url: Option<String>) -> Result<(), String> {
    let conn = sqlite::init_db().map_err(|e| e.to_string())?;
    let id = Uuid::new_v4().to_string();
    conn.execute(
        "INSERT INTO books (id, title, author, publication_year, isbn, genre, is_available, image_url) VALUES (?1, ?2, ?3, ?4, ?5, ?6, 1, ?7)",
        params![id, title, author, publication_year, isbn, genre, image_url],
    ).map_err(|e| e.to_string())?;
    Ok(())
}
```

### Updated `add_book` Function (AFTER)
```rust
pub fn add_book(title: String, author: String, publication_year: i32, isbn: String, genre: String, copies: Option<i32>, image_url: Option<String>) -> Result<(), String> {  // ✅ ADD copies parameter
    let conn = sqlite::init_db().map_err(|e| e.to_string())?;
    let id = Uuid::new_v4().to_string();
    let copies = copies.unwrap_or(1);  // ✅ DEFAULT TO 1 IF NOT PROVIDED
    conn.execute(
        "INSERT INTO books (id, title, author, publication_year, isbn, genre, is_available, copies, image_url) VALUES (?1, ?2, ?3, ?4, ?5, ?6, 1, ?7, ?8)",  // ✅ ADD copies column
        params![id, title, author, publication_year, isbn, genre, copies, image_url],  // ✅ ADD copies value
    ).map_err(|e| e.to_string())?;
    Ok(())
}
```

**Changes:**
1. Add parameter: `copies: Option<i32>` to function signature
2. Add line: `let copies = copies.unwrap_or(1);`
3. Add `copies` to INSERT statement column list
4. Add `copies` to INSERT statement values
5. Update params macro to include `copies`

---

### Current `get_all_books` Function (BEFORE)
```rust
pub fn get_all_books() -> Result<Vec<Book>, String> {
    let conn = sqlite::init_db().map_err(|e| e.to_string())?;
    let mut stmt = conn.prepare("SELECT id, title, author, publication_year, isbn, genre, is_available, image_url FROM books")
        .map_err(|e| e.to_string())?;
    
    let books = stmt.query_map([], |row| {
        Ok(Book {
            id: row.get(0)?,
            title: row.get(1)?,
            author: row.get(2)?,
            publication_year: row.get(3)?,
            isbn: row.get(4)?,
            genre: row.get(5)?,
            is_available: row.get::<_, i32>(6)? == 1,
            image_url: row.get(7)?,
        })
    }).map_err(|e| e.to_string())?
    .collect::<Result<Vec<_>, _>>().map_err(|e| e.to_string())?;

    Ok(books)
}
```

### Updated `get_all_books` Function (AFTER)
```rust
pub fn get_all_books() -> Result<Vec<Book>, String> {
    let conn = sqlite::init_db().map_err(|e| e.to_string())?;
    let mut stmt = conn.prepare("SELECT id, title, author, publication_year, isbn, genre, is_available, copies, image_url FROM books")  // ✅ ADD copies column
        .map_err(|e| e.to_string())?;
    
    let books = stmt.query_map([], |row| {
        Ok(Book {
            id: row.get(0)?,
            title: row.get(1)?,
            author: row.get(2)?,
            publication_year: row.get(3)?,
            isbn: row.get(4)?,
            genre: row.get(5)?,
            is_available: row.get::<_, i32>(6)? == 1,
            copies: row.get(7)?,  // ✅ ADD THIS LINE
            image_url: row.get(8)?,  // ✅ CHANGE INDEX FROM 7 TO 8
        })
    }).map_err(|e| e.to_string())?
    .collect::<Result<Vec<_>, _>>().map_err(|e| e.to_string())?;

    Ok(books)
}
```

**Changes:**
1. Add `copies` to SELECT statement: `..., is_available, copies, image_url FROM books`
2. Add field to Book struct: `copies: row.get(7)?,`
3. Update image_url index from `row.get(7)?` to `row.get(8)?`

---

### Current `search_books` Function (BEFORE)
```rust
pub fn search_books(query: String) -> Result<Vec<Book>, String> {
    let conn = sqlite::init_db().map_err(|e| e.to_string())?;
    let search_pattern = format!("%{}%", query);
    let mut stmt = conn.prepare("SELECT id, title, author, publication_year, isbn, genre, is_available, image_url FROM books WHERE title LIKE ?1 OR author LIKE ?1 OR isbn LIKE ?1")
        .map_err(|e| e.to_string())?;
    
    let books = stmt.query_map(params![search_pattern], |row| {
        Ok(Book {
            id: row.get(0)?,
            title: row.get(1)?,
            author: row.get(2)?,
            publication_year: row.get(3)?,
            isbn: row.get(4)?,
            genre: row.get(5)?,
            is_available: row.get::<_, i32>(6)? == 1,
            image_url: row.get(7)?,
        })
    }).map_err(|e| e.to_string())?
    .collect::<Result<Vec<_>, _>>().map_err(|e| e.to_string())?;

    Ok(books)
}
```

### Updated `search_books` Function (AFTER)
```rust
pub fn search_books(query: String) -> Result<Vec<Book>, String> {
    let conn = sqlite::init_db().map_err(|e| e.to_string())?;
    let search_pattern = format!("%{}%", query);
    let mut stmt = conn.prepare("SELECT id, title, author, publication_year, isbn, genre, is_available, copies, image_url FROM books WHERE title LIKE ?1 OR author LIKE ?1 OR isbn LIKE ?1")  // ✅ ADD copies column
        .map_err(|e| e.to_string())?;
    
    let books = stmt.query_map(params![search_pattern], |row| {
        Ok(Book {
            id: row.get(0)?,
            title: row.get(1)?,
            author: row.get(2)?,
            publication_year: row.get(3)?,
            isbn: row.get(4)?,
            genre: row.get(5)?,
            is_available: row.get::<_, i32>(6)? == 1,
            copies: row.get(7)?,  // ✅ ADD THIS LINE
            image_url: row.get(8)?,  // ✅ CHANGE INDEX FROM 7 TO 8
        })
    }).map_err(|e| e.to_string())?
    .collect::<Result<Vec<_>, _>>().map_err(|e| e.to_string())?;

    Ok(books)
}
```

**Changes:** Same as get_all_books

---

### `update_book` Function (OPTIONAL)

If you want to allow updating copies count:

```rust
pub fn update_book(book: Book) -> Result<(), String> {
    let conn = sqlite::init_db().map_err(|e| e.to_string())?;
    conn.execute(
        "UPDATE books SET title = ?1, author = ?2, publication_year = ?3, isbn = ?4, genre = ?5, copies = ?6, image_url = ?7 WHERE id = ?8",  // ✅ ADD copies parameter
        params![book.title, book.author, book.publication_year, book.isbn, book.genre, book.copies, book.image_url, book.id],  // ✅ ADD copies value
    ).map_err(|e| e.to_string())?;
    Ok(())
}
```

If you only want to update other fields (not copies):
```rust
// Keep original - copies stays unchanged unless explicitly updated elsewhere
pub fn update_book(book: Book) -> Result<(), String> {
    let conn = sqlite::init_db().map_err(|e| e.to_string())?;
    conn.execute(
        "UPDATE books SET title = ?1, author = ?2, publication_year = ?3, isbn = ?4, genre = ?5, image_url = ?6 WHERE id = ?7",
        params![book.title, book.author, book.publication_year, book.isbn, book.genre, book.image_url, book.id],
    ).map_err(|e| e.to_string())?;
    Ok(())
}
```

---

## Summary of Changes

| File | Change | Type |
|------|--------|------|
| `book.rs` | Add `copies: i32` field | ✅ Done |
| `sqlite/mod.rs` | Add `copies` column to CREATE TABLE and migration | ✅ Done |
| `book_api.rs` | Add `copies: Option<i32>` parameter to `add_book` | 📝 Needed |
| `book_service.rs` | Update `add_book`, `get_all_books`, `search_books` to handle copies | 📝 Needed |

---

## Column Indices Reference

After adding `copies` column:
```
SELECT id, title, author, publication_year, isbn, genre, is_available, copies, image_url
       0    1      2       3                  4     5      6             7       8
```

So in query_map:
- `row.get(0)?` = id
- `row.get(1)?` = title
- `row.get(2)?` = author
- `row.get(3)?` = publication_year
- `row.get(4)?` = isbn
- `row.get(5)?` = genre
- `row.get(6)?` = is_available
- `row.get(7)?` = **copies** (NEW)
- `row.get(8)?` = image_url (was 7, now 8)

---

## Next Steps

1. Apply changes to `book.rs` and `sqlite/mod.rs`
2. Apply changes to `book_api.rs` and `book_service.rs`
3. Rebuild the Rust bridge: `flutter_rust_bridge_codegen generate`
4. The Dart files will automatically update
5. Test the implementation

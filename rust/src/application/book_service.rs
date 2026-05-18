use crate::domain::book::Book;
use crate::infrastructure::sqlite;
use rusqlite::params;
use uuid::Uuid;

/// Adds a new book to the database with a unique ID and initial available status.
pub fn add_book(title: String, author: String, publication_year: i32, isbn: String, genre: String, copies: i32, image_url: Option<String>) -> Result<(), String> {
    let conn = sqlite::init_db().map_err(|e| e.to_string())?;
    let id = Uuid::new_v4().to_string();
    conn.execute(
        "INSERT INTO books (id, title, author, publication_year, isbn, genre, copies, is_available, image_url) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, 1, ?8)",
        params![id, title, author, publication_year, isbn, genre, copies, image_url],
    ).map_err(|e| e.to_string())?;
    Ok(())
}

/// Retrieves all books from the library catalog.
pub fn get_all_books() -> Result<Vec<Book>, String> {
    let conn = sqlite::init_db().map_err(|e| e.to_string())?;
    let mut stmt = conn.prepare("SELECT id, title, author, publication_year, isbn, genre, copies, is_available, image_url FROM books")
        .map_err(|e| e.to_string())?;
    
    let books = stmt.query_map([], |row| {
        Ok(Book {
            id: row.get(0)?,
            title: row.get(1)?,
            author: row.get(2)?,
            publication_year: row.get(3)?,
            isbn: row.get(4)?,
            genre: row.get(5)?,
            copies: row.get(6)?,
            is_available: row.get::<_, i32>(7)? == 1,
            image_url: row.get(8)?,
        })
    }).map_err(|e| e.to_string())?
    .collect::<Result<Vec<_>, _>>().map_err(|e| e.to_string())?;

    Ok(books)
}

/// Searches the catalog for books matching a title, author, or ISBN pattern.
pub fn search_books(query: String) -> Result<Vec<Book>, String> {
    let conn = sqlite::init_db().map_err(|e| e.to_string())?;
    let search_pattern = format!("%{}%", query);
    let mut stmt = conn.prepare("SELECT id, title, author, publication_year, isbn, genre, copies, is_available, image_url FROM books WHERE title LIKE ?1 OR author LIKE ?1 OR isbn LIKE ?1")
        .map_err(|e| e.to_string())?;
    
    let books = stmt.query_map(params![search_pattern], |row| {
        Ok(Book {
            id: row.get(0)?,
            title: row.get(1)?,
            author: row.get(2)?,
            publication_year: row.get(3)?,
            isbn: row.get(4)?,
            genre: row.get(5)?,
            copies: row.get(6)?,
            is_available: row.get::<_, i32>(7)? == 1,
            image_url: row.get(8)?,
        })
    }).map_err(|e| e.to_string())?
    .collect::<Result<Vec<_>, _>>().map_err(|e| e.to_string())?;

    Ok(books)
}

/// Updates an existing book's details in the database.
pub fn update_book(book: Book) -> Result<(), String> {
    let conn = sqlite::init_db().map_err(|e| e.to_string())?;
    conn.execute(
        "UPDATE books SET title = ?1, author = ?2, publication_year = ?3, isbn = ?4, genre = ?5, copies = ?6, image_url = ?7 WHERE id = ?8",
        params![book.title, book.author, book.publication_year, book.isbn, book.genre, book.copies, book.image_url, book.id],
    ).map_err(|e| e.to_string())?;
    Ok(())
}

/// Permanently removes a book from the catalog.
pub fn delete_book(id: String) -> Result<(), String> {
    let conn = sqlite::init_db().map_err(|e| e.to_string())?;
    conn.execute("DELETE FROM books WHERE id = ?1", params![id]).map_err(|e| e.to_string())?;
    Ok(())
}

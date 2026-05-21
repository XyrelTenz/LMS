use crate::domain::book::Book;
use crate::domain::report::{ActiveBorrower, LibraryReport};
use crate::infrastructure::sqlite;
use std::collections::HashMap;

pub fn generate_report() -> Result<LibraryReport, String> {
    let conn = sqlite::init_db().map_err(|e| e.to_string())?;

    let total_books: i32 = conn
        .query_row("SELECT COUNT(*) FROM books", [], |row| row.get(0))
        .unwrap_or(0);
    let available_books: i32 = conn
        .query_row("SELECT COUNT(*) FROM books WHERE copies > 1", [], |row| {
            row.get(0)
        })
        .unwrap_or(0);
    let borrowed_books: i32 = conn
        .query_row(
            "SELECT COUNT(*) FROM borrowings WHERE is_returned = 0 AND status = 'Approved'",
            [],
            |row| row.get(0),
        )
        .unwrap_or(0);
    let total_users: i32 = conn
        .query_row("SELECT COUNT(*) FROM users", [], |row| row.get(0))
        .unwrap_or(0);

    let mut stmt = conn
        .prepare("SELECT genre, COUNT(*) FROM books GROUP BY genre")
        .map_err(|e| e.to_string())?;
    let genre_iter = stmt
        .query_map([], |row| {
            Ok((row.get::<_, String>(0)?, row.get::<_, i32>(1)?))
        })
        .map_err(|e| e.to_string())?;

    let mut genre_distribution = HashMap::new();
    for genre in genre_iter {
        let (name, count) = genre.map_err(|e| e.to_string())?;
        genre_distribution.insert(name, count);
    }

    // Mostly borrowed genre
    let mostly_borrowed_genre: String = conn.query_row(
        "SELECT genre FROM books b JOIN borrowings br ON b.id = br.book_id GROUP BY genre ORDER BY COUNT(*) DESC LIMIT 1",
        [],
        |row| row.get(0)
    ).unwrap_or_else(|_| "None".to_string());

    // Borrowed books list
    let mut stmt = conn.prepare(
        "SELECT DISTINCT b.id, b.title, b.author, b.publication_year, b.isbn, b.genre, b.copies, b.is_available, b.image_url, b.fine_fee, b.max_borrow_days 
         FROM books b JOIN borrowings br ON b.id = br.book_id 
         WHERE br.is_returned = 0 AND br.status = 'Approved'"
    ).map_err(|e| e.to_string())?;

    let borrowed_books_list = stmt
        .query_map([], |row| {
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
                fine_fee: row.get(9)?,
                max_borrow_days: row.get(10)?,
            })
        })
        .map_err(|e| e.to_string())?
        .collect::<Result<Vec<_>, _>>()
        .map_err(|e| e.to_string())?;

    // Active borrowers list
    let mut stmt = conn
        .prepare(
            "SELECT br.user_id, br.borrower_name, b.title, br.borrow_date, br.due_date 
         FROM borrowings br JOIN books b ON br.book_id = b.id 
         WHERE br.is_returned = 0 AND br.status = 'Approved'",
        )
        .map_err(|e| e.to_string())?;

    let active_borrowers = stmt
        .query_map([], |row| {
            Ok(ActiveBorrower {
                user_id: row.get(0)?,
                borrower_name: row.get(1)?,
                book_title: row.get(2)?,
                borrow_date: row.get(3)?,
                due_date: row
                    .get::<_, Option<String>>(4)?
                    .unwrap_or_else(|| "N/A".to_string()),
            })
        })
        .map_err(|e| e.to_string())?
        .collect::<Result<Vec<_>, _>>()
        .map_err(|e| e.to_string())?;

    Ok(LibraryReport {
        total_books,
        available_books,
        borrowed_books,
        total_users,
        genre_distribution,
        mostly_borrowed_genre,
        borrowed_books_list,
        active_borrowers,
    })
}

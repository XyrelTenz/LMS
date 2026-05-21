use crate::domain::borrowing::Borrowing;
use crate::infrastructure::sqlite;
use chrono::{DateTime, Utc};
use rusqlite::params;
use uuid::Uuid;

pub fn borrow_book(
    user_id: String,
    user_name: String,
    book_id: String,
    borrow_days: i32,
) -> Result<(), String> {
    let conn = sqlite::init_db().map_err(|e| e.to_string())?;

    // Check if user already has an active or pending borrowing
    let active_count: i32 = conn.query_row(
        "SELECT COUNT(*) FROM borrowings WHERE user_id = ?1 AND (status = 'Pending' OR (status = 'Approved' AND is_returned = 0))",
        params![user_id],
        |row| row.get(0),
    ).unwrap_or(0);

    if active_count > 0 {
        return Err("You already have an active borrowing or pending request. Please return your current book before requesting another.".to_string());
    }

    let copies: i32 = conn
        .query_row(
            "SELECT copies FROM books WHERE id = ?1",
            params![book_id],
            |row| row.get(0),
        )
        .map_err(|_| "Book not found".to_string())?;

    if copies <= 1 {
        return Err(
            "Book is not available for borrowing. At least one copy must remain in the library."
                .to_string(),
        );
    }

    let id = Uuid::new_v4().to_string();
    let borrow_date_dt = Utc::now();
    let due_date_dt = borrow_date_dt + chrono::Duration::days(borrow_days as i64);

    conn.execute(
        "INSERT INTO borrowings (id, book_id, user_id, borrower_name, borrow_date, due_date, is_returned, status, has_reminder, return_status) VALUES (?1, ?2, ?3, ?4, ?5, ?6, 0, 'Pending', 0, 'None')",
        params![id, book_id, user_id, user_name, borrow_date_dt.to_rfc3339(), due_date_dt.to_rfc3339()],
    ).map_err(|e| e.to_string())?;

    conn.execute(
        "UPDATE books SET copies = copies - 1, is_available = CASE WHEN copies - 1 > 1 THEN 1 ELSE 0 END WHERE id = ?1",
        params![book_id],
    ).map_err(|e| e.to_string())?;
    Ok(())
}

pub fn approve_borrowing(borrowing_id: String, due_date: String) -> Result<(), String> {
    let conn = sqlite::init_db().map_err(|e| e.to_string())?;
    conn.execute(
        "UPDATE borrowings SET status = 'Approved', due_date = ?2 WHERE id = ?1",
        params![borrowing_id, due_date],
    )
    .map_err(|e| e.to_string())?;
    Ok(())
}

pub fn reject_borrowing(borrowing_id: String) -> Result<(), String> {
    let conn = sqlite::init_db().map_err(|e| e.to_string())?;

    let book_id: String = conn
        .query_row(
            "SELECT book_id FROM borrowings WHERE id = ?1",
            params![borrowing_id],
            |row| row.get(0),
        )
        .map_err(|_| "Borrowing record not found".to_string())?;

    conn.execute(
        "UPDATE borrowings SET status = 'Rejected' WHERE id = ?1",
        params![borrowing_id],
    )
    .map_err(|e| e.to_string())?;

    conn.execute(
        "UPDATE books SET copies = copies + 1, is_available = CASE WHEN copies + 1 > 1 THEN 1 ELSE 0 END WHERE id = ?1",
        params![book_id],
    ).map_err(|e| e.to_string())?;
    Ok(())
}

/// Student requests to return a book, which needs librarian approval.
pub fn request_return(borrowing_id: String) -> Result<(), String> {
    let conn = sqlite::init_db().map_err(|e| e.to_string())?;
    conn.execute(
        "UPDATE borrowings SET return_status = 'Pending' WHERE id = ?1",
        params![borrowing_id],
    )
    .map_err(|e| e.to_string())?;
    Ok(())
}

/// Librarian processes the return request.
pub fn process_return(
    borrowing_id: String,
    is_approved: bool,
    condition_notes: Option<String>,
    fee_amount: Option<f64>,
) -> Result<(), String> {
    let conn = sqlite::init_db().map_err(|e| e.to_string())?;

    let (user_id, book_id): (String, String) = conn
        .query_row(
            "SELECT user_id, book_id FROM borrowings WHERE id = ?1",
            params![borrowing_id],
            |row| Ok((row.get(0)?, row.get(1)?)),
        )
        .map_err(|_| "Borrowing record not found".to_string())?;

    if is_approved {
        conn.execute(
            "UPDATE borrowings SET is_returned = 1, return_date = ?1, return_status = 'Approved', condition_notes = ?2 WHERE id = ?3",
            params![Utc::now().to_rfc3339(), condition_notes.clone(), borrowing_id],
        )
        .map_err(|e| e.to_string())?;

        conn.execute(
            "UPDATE books SET copies = copies + 1, is_available = CASE WHEN copies + 1 > 1 THEN 1 ELSE 0 END WHERE id = ?1",
            params![book_id],
        ).map_err(|e| e.to_string())?;
    } else {
        conn.execute(
            "UPDATE borrowings SET return_status = 'Rejected', condition_notes = ?1 WHERE id = ?2",
            params![condition_notes.clone(), borrowing_id],
        )
        .map_err(|e| e.to_string())?;

        if let Some(amount) = fee_amount {
            if amount > 0.0 {
                crate::application::penalty_service::create_penalty(
                    user_id,
                    Some(borrowing_id),
                    amount,
                    condition_notes.unwrap_or_else(|| "Book returned in bad condition".to_string()),
                )?;
            }
        }
    }

    Ok(())
}

/// Flags a borrowing record with a reminder notification for the student.
pub fn send_reminder(borrowing_id: String) -> Result<(), String> {
    let conn = sqlite::init_db().map_err(|e| e.to_string())?;
    conn.execute(
        "UPDATE borrowings SET has_reminder = 1 WHERE id = ?1",
        params![borrowing_id],
    )
    .map_err(|e| e.to_string())?;
    Ok(())
}

/// Retrieves all borrowing history for a specific user ID.
pub fn get_user_borrowings(user_id: String) -> Result<Vec<Borrowing>, String> {
    let conn = sqlite::init_db().map_err(|e| e.to_string())?;
    let mut stmt = conn.prepare("SELECT borrowings.id, borrowings.book_id, borrowings.user_id, borrowings.borrower_name, borrowings.borrow_date, borrowings.return_date, borrowings.is_returned, borrowings.status, borrowings.due_date, borrowings.has_reminder, borrowings.return_status, borrowings.condition_notes, books.title, books.isbn FROM borrowings LEFT JOIN books ON books.id = borrowings.book_id WHERE borrowings.user_id = ?1")
        .map_err(|e| e.to_string())?;

    let borrowings = stmt
        .query_map(params![user_id], |row| {
            Ok(Borrowing {
                id: row.get(0)?,
                book_id: row.get(1)?,
                user_id: row.get(2)?,
                borrower_name: row.get(3)?,
                borrow_date: row
                    .get::<_, String>(4)?
                    .parse::<DateTime<Utc>>()
                    .unwrap_or(Utc::now()),
                return_date: row
                    .get::<_, Option<String>>(5)?
                    .map(|s| s.parse::<DateTime<Utc>>().unwrap_or(Utc::now())),
                is_returned: row.get::<_, i32>(6)? == 1,
                status: row.get::<_, String>(7)?.into(),
                due_date: row
                    .get::<_, String>(8)?
                    .parse::<DateTime<Utc>>()
                    .unwrap_or(Utc::now()),
                has_reminder: row.get::<_, i32>(9)? == 1,
                return_status: row.get::<_, String>(10)?.into(),
                condition_notes: row.get(11)?,
                book_title: row.get(12)?,
                book_isbn: row.get(13)?,
            })
        })
        .map_err(|e| e.to_string())?
        .collect::<Result<Vec<_>, _>>()
        .map_err(|e| e.to_string())?;

    Ok(borrowings)
}

/// Lists all currently pending borrow requests for librarian review.
pub fn get_pending_borrowings() -> Result<Vec<Borrowing>, String> {
    let conn = sqlite::init_db().map_err(|e| e.to_string())?;
    let mut stmt = conn.prepare("SELECT borrowings.id, borrowings.book_id, borrowings.user_id, borrowings.borrower_name, borrowings.borrow_date, borrowings.return_date, borrowings.is_returned, borrowings.status, borrowings.due_date, borrowings.has_reminder, borrowings.return_status, borrowings.condition_notes, books.title, books.isbn FROM borrowings LEFT JOIN books ON books.id = borrowings.book_id WHERE borrowings.status = 'Pending'")
        .map_err(|e| e.to_string())?;

    let borrowings = stmt
        .query_map([], |row| {
            Ok(Borrowing {
                id: row.get(0)?,
                book_id: row.get(1)?,
                user_id: row.get(2)?,
                borrower_name: row.get(3)?,
                borrow_date: row
                    .get::<_, String>(4)?
                    .parse::<DateTime<Utc>>()
                    .unwrap_or(Utc::now()),
                return_date: row
                    .get::<_, Option<String>>(5)?
                    .map(|s| s.parse::<DateTime<Utc>>().unwrap_or(Utc::now())),
                is_returned: row.get::<_, i32>(6)? == 1,
                status: row.get::<_, String>(7)?.into(),
                due_date: row
                    .get::<_, String>(8)?
                    .parse::<DateTime<Utc>>()
                    .unwrap_or(Utc::now()),
                has_reminder: row.get::<_, i32>(9)? == 1,
                return_status: row.get::<_, String>(10)?.into(),
                condition_notes: row.get(11)?,
                book_title: row.get(12)?,
                book_isbn: row.get(13)?,
            })
        })
        .map_err(|e| e.to_string())?
        .collect::<Result<Vec<_>, _>>()
        .map_err(|e| e.to_string())?;

    Ok(borrowings)
}

/// Retrieves all borrowing records across the entire library system.
pub fn get_all_borrowings() -> Result<Vec<Borrowing>, String> {
    let conn = sqlite::init_db().map_err(|e| e.to_string())?;
    let mut stmt = conn.prepare("SELECT borrowings.id, borrowings.book_id, borrowings.user_id, borrowings.borrower_name, borrowings.borrow_date, borrowings.return_date, borrowings.is_returned, borrowings.status, borrowings.due_date, borrowings.has_reminder, borrowings.return_status, borrowings.condition_notes, books.title, books.isbn FROM borrowings LEFT JOIN books ON books.id = borrowings.book_id")
        .map_err(|e| e.to_string())?;

    let borrowings = stmt
        .query_map([], |row| {
            Ok(Borrowing {
                id: row.get(0)?,
                book_id: row.get(1)?,
                user_id: row.get(2)?,
                borrower_name: row.get(3)?,
                borrow_date: row
                    .get::<_, String>(4)?
                    .parse::<DateTime<Utc>>()
                    .unwrap_or(Utc::now()),
                return_date: row
                    .get::<_, Option<String>>(5)?
                    .map(|s| s.parse::<DateTime<Utc>>().unwrap_or(Utc::now())),
                is_returned: row.get::<_, i32>(6)? == 1,
                status: row.get::<_, String>(7)?.into(),
                due_date: row
                    .get::<_, String>(8)?
                    .parse::<DateTime<Utc>>()
                    .unwrap_or(Utc::now()),
                has_reminder: row.get::<_, i32>(9)? == 1,
                return_status: row.get::<_, String>(10)?.into(),
                condition_notes: row.get(11)?,
                book_title: row.get(12)?,
                book_isbn: row.get(13)?,
            })
        })
        .map_err(|e| e.to_string())?
        .collect::<Result<Vec<_>, _>>()
        .map_err(|e| e.to_string())?;

    Ok(borrowings)
}

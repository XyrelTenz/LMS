use rusqlite::Connection;

pub fn init_db() -> rusqlite::Result<Connection> {
    let conn = Connection::open("library.db")?;

    conn.execute(
        "CREATE TABLE IF NOT EXISTS users (
            id TEXT PRIMARY KEY,
            username TEXT UNIQUE NOT NULL,
            password_hash TEXT NOT NULL,
            full_name TEXT NOT NULL,
            role TEXT NOT NULL,
            contact_details TEXT,
            security_question TEXT NOT NULL,
            security_answer TEXT NOT NULL
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
            copies INTEGER NOT NULL DEFAULT 1,
            is_available INTEGER NOT NULL DEFAULT 1,
            image_url TEXT
        )",
        [],
    )?;

    conn.execute(
        "CREATE TABLE IF NOT EXISTS borrowings (
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
        )",
        [],
    )?;

    // Migration: Add status column to borrowings if it doesn't exist
    let _ = conn.execute(
        "ALTER TABLE borrowings ADD COLUMN status TEXT NOT NULL DEFAULT 'Approved'",
        [],
    );

    let _ = conn.execute("ALTER TABLE books ADD COLUMN image_url TEXT", []);

    let _ = conn.execute(
        "ALTER TABLE books ADD COLUMN copies INTEGER NOT NULL DEFAULT 1",
        [],
    );

    let _ = conn.execute("ALTER TABLE borrowings ADD COLUMN due_date TEXT", []);

    let _ = conn.execute(
        "ALTER TABLE borrowings ADD COLUMN has_reminder INTEGER NOT NULL DEFAULT 0",
        [],
    );

    // Fix existing due_dates if null
    let _ = conn.execute(
        "UPDATE borrowings SET due_date = borrow_date WHERE due_date IS NULL",
        [],
    );

    // Fix existing is_available values based on copies count
    let _ = conn.execute(
        "UPDATE books SET is_available = CASE WHEN copies > 1 THEN 1 ELSE 0 END",
        [],
    );

    Ok(conn)
}

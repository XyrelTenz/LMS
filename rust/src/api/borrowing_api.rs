use crate::application::borrowing_service;
pub use crate::domain::borrowing::{Borrowing, BorrowStatus};

/// Initiates a borrow request for a book by a student.
pub fn borrow_book(user_id: String, user_name: String, book_id: String) -> Result<(), String> {
    borrowing_service::borrow_book(user_id, user_name, book_id)
}

/// Finalizes the return of a borrowed book.
pub fn return_book(borrowing_id: String) -> Result<(), String> {
    borrowing_service::return_book(borrowing_id)
}

/// Fetches all borrowing records for a specific user.
pub fn get_user_borrowings(user_id: String) -> Result<Vec<Borrowing>, String> {
    borrowing_service::get_user_borrowings(user_id)
}

/// Retrieves all borrowing records in the system.
pub fn get_all_borrowings() -> Result<Vec<Borrowing>, String> {
    borrowing_service::get_all_borrowings()
}

/// Lists all borrowings that are currently awaiting librarian approval.
pub fn get_pending_borrowings() -> Result<Vec<Borrowing>, String> {
    borrowing_service::get_pending_borrowings()
}

/// Approves a pending borrow request.
pub fn approve_borrowing(borrowing_id: String, due_date: String) -> Result<(), String> {
    borrowing_service::approve_borrowing(borrowing_id, due_date)
}

/// Rejects a pending borrow request.
pub fn reject_borrowing(borrowing_id: String) -> Result<(), String> {
    borrowing_service::reject_borrowing(borrowing_id)
}

/// Sends a return reminder notification to a student.
pub fn send_reminder(borrowing_id: String) -> Result<(), String> {
    borrowing_service::send_reminder(borrowing_id)
}

use crate::application::borrowing_service;
pub use crate::domain::borrowing::{Borrowing, BorrowStatus};

/// Submits a request for a student to borrow a specific book.
pub fn borrow_book(user_id: String, user_name: String, book_id: String, borrow_days: i32) -> Result<(), String> {
    borrowing_service::borrow_book(user_id, user_name, book_id, borrow_days)
}

/// Initiates a return request for a borrowed book.
pub fn request_return(borrowing_id: String) -> Result<(), String> {
    borrowing_service::request_return(borrowing_id)
}

/// Librarian processes the return request, either approving or rejecting with condition notes and potential fees.
pub fn process_return(borrowing_id: String, is_approved: bool, condition_notes: Option<String>, fee_amount: Option<f64>) -> Result<(), String> {
    borrowing_service::process_return(borrowing_id, is_approved, condition_notes, fee_amount)
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

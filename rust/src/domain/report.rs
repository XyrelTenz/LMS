use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use crate::domain::book::Book;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ActiveBorrower {
    pub user_id: String,
    pub borrower_name: String,
    pub book_title: String,
    pub borrow_date: String,
    pub due_date: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LibraryReport {
    pub total_books: i32,
    pub available_books: i32,
    pub borrowed_books: i32,
    pub total_users: i32,
    pub genre_distribution: HashMap<String, i32>,
    pub mostly_borrowed_genre: String,
    pub borrowed_books_list: Vec<Book>,
    pub active_borrowers: Vec<ActiveBorrower>,
}

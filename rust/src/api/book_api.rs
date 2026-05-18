use crate::application::book_service;
pub use crate::domain::book::Book;

/// Adds a new book to the library catalog.
pub fn add_book(title: String, author: String, publication_year: i32, isbn: String, genre: String, copies: i32, image_url: Option<String>) -> Result<(), String> {
    book_service::add_book(title, author, publication_year, isbn, genre, copies, image_url)
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

use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Book {
    pub id: String,
    pub title: String,
    pub author: String,
    pub publication_year: i32,
    pub isbn: String,
    pub genre: String,
    pub copies: i32,
    pub is_available: bool,
    pub image_url: Option<String>,
    pub fine_fee: f64,
    pub max_borrow_days: i32,
}

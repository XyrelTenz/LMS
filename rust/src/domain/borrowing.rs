use serde::{Deserialize, Serialize};
use chrono::{DateTime, Utc};

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum BorrowStatus {
    Pending,
    Approved,
    Rejected,
}

impl ToString for BorrowStatus {
    fn to_string(&self) -> String {
        match self {
            BorrowStatus::Pending => "Pending".to_string(),
            BorrowStatus::Approved => "Approved".to_string(),
            BorrowStatus::Rejected => "Rejected".to_string(),
        }
    }
}

impl From<String> for BorrowStatus {
    fn from(s: String) -> Self {
        match s.as_str() {
            "Approved" => BorrowStatus::Approved,
            "Rejected" => BorrowStatus::Rejected,
            _ => BorrowStatus::Pending,
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Borrowing {
    pub id: String,
    pub book_id: String,
    pub user_id: String,
    pub borrower_name: String,
    pub borrow_date: DateTime<Utc>,
    pub due_date: DateTime<Utc>,
    pub return_date: Option<DateTime<Utc>>,
    pub is_returned: bool,
    pub status: BorrowStatus,
    pub has_reminder: bool,
}

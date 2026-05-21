use serde::{Deserialize, Serialize};
use chrono::{DateTime, Utc};

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum ReturnStatus {
    None,
    Pending,
    Approved,
    Rejected,
}

impl ToString for ReturnStatus {
    fn to_string(&self) -> String {
        match self {
            ReturnStatus::None => "None".to_string(),
            ReturnStatus::Pending => "Pending".to_string(),
            ReturnStatus::Approved => "Approved".to_string(),
            ReturnStatus::Rejected => "Rejected".to_string(),
        }
    }
}

impl From<String> for ReturnStatus {
    fn from(s: String) -> Self {
        match s.as_str() {
            "Pending" => ReturnStatus::Pending,
            "Approved" => ReturnStatus::Approved,
            "Rejected" => ReturnStatus::Rejected,
            _ => ReturnStatus::None,
        }
    }
}

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
    pub return_status: ReturnStatus,
    pub condition_notes: Option<String>,
    pub book_title: Option<String>,
}

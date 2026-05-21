use serde::{Deserialize, Serialize};
use chrono::{DateTime, Utc};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Penalty {
    pub id: String,
    pub user_id: String,
    pub borrowing_id: Option<String>,
    pub amount: f64,
    pub reason: String,
    pub is_paid: bool,
    pub created_at: DateTime<Utc>,
}

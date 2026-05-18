use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum UserRole {
    Student,
    Librarian,
}

impl ToString for UserRole {
    fn to_string(&self) -> String {
        match self {
            UserRole::Student => "Student".to_string(),
            UserRole::Librarian => "Librarian".to_string(),
        }
    }
}

impl From<String> for UserRole {
    fn from(s: String) -> Self {
        match s.as_str() {
            "Librarian" => UserRole::Librarian,
            _ => UserRole::Student,
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct User {
    pub id: String,
    pub username: String,
    pub password_hash: String,
    pub full_name: String,
    pub role: UserRole,
    pub contact_details: Option<String>,
    pub security_question: String,
    pub security_answer: String,
}

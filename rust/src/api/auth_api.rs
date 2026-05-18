use crate::application::auth_service;
pub use crate::domain::user::{User, UserRole};

/// Registers a new user in the system.
pub fn register_user(
    username: String,
    password_plain: String,
    full_name: String,
    role: String,
    security_question: String,
    security_answer: String,
) -> Result<String, String> {
    auth_service::register(username, password_plain, full_name, role, security_question, security_answer)
}

/// Authenticates a user and returns their profile information.
pub fn login_user(identifier: String, password_plain: String) -> Result<User, String> {
    auth_service::login(identifier, password_plain)
}

/// Updates an existing user's profile information.
pub fn update_user(user: User) -> Result<(), String> {
    auth_service::update_user(user)
}

/// Retrieves all registered users in the system.
pub fn get_all_users() -> Result<Vec<User>, String> {
    auth_service::get_all_users()
}

/// Resets a user's password if the security answer is correct.
pub fn reset_password(username: String, security_answer: String, new_password_plain: String) -> Result<(), String> {
    auth_service::reset_password(username, security_answer, new_password_plain)
}
/// Retrieves a user by their ID.
pub fn get_user_by_id(id: String) -> Result<User, String> {
    auth_service::get_user_by_id(id)
}

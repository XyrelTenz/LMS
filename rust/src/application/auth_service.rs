use crate::domain::user::{User, UserRole};
use crate::infrastructure::sqlite;
use bcrypt::{hash, verify, DEFAULT_COST};
use rusqlite::{params, OptionalExtension};

pub fn register(
    username: String,
    password_plain: String,
    full_name: String,
    role: String,
    security_question: String,
    security_answer: String,
) -> Result<String, String> {
    let conn = sqlite::init_db().map_err(|e| e.to_string())?;

    if password_plain.len() < 6 {
        return Err("Password must be at least 6 characters long".to_string());
    }
    let special_chars = "@#$%&*!";
    if !password_plain.chars().any(|c| special_chars.contains(c)) {
        return Err("Password must contain at least one special character".to_string());
    }

    let password_hash =
        hash(password_plain, DEFAULT_COST).map_err(|_| "Hashing error".to_string())?;

    // Use user-provided username as the ID
    let id = username.clone();

    conn.execute(
        "INSERT INTO users (id, username, password_hash, full_name, role, security_question, security_answer) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7)",
        params![id, username, password_hash, full_name, role, security_question, security_answer],
    ).map_err(|e| if e.to_string().contains("UNIQUE") { "ID/Email already exists".to_string() } else { e.to_string() })?;

    Ok(id)
}

pub fn login(identifier: String, password_plain: String) -> Result<User, String> {
    let conn = sqlite::init_db().map_err(|e| e.to_string())?;
    let mut stmt = conn.prepare("SELECT id, username, password_hash, full_name, role, contact_details, security_question, security_answer FROM users WHERE id = ?1")
        .map_err(|e| e.to_string())?;

    let user_row = stmt
        .query_row(params![identifier], |row| {
            Ok(User {
                id: row.get(0)?,
                username: row.get(1)?,
                password_hash: row.get(2)?,
                full_name: row.get(3)?,
                role: UserRole::from(row.get::<_, String>(4)?),
                contact_details: row.get(5)?,
                security_question: row.get(6)?,
                security_answer: row.get(7)?,
            })
        })
        .optional()
        .map_err(|e| e.to_string())?;

    if let Some(user) = user_row {
        if verify(password_plain, &user.password_hash)
            .map_err(|_| "Verification error".to_string())?
        {
            return Ok(user);
        }
    }

    Err("Invalid Credentials".to_string())
}

pub fn update_user(user: User) -> Result<(), String> {
    let conn = sqlite::init_db().map_err(|e| e.to_string())?;
    conn.execute(
        "UPDATE users SET username = ?1, full_name = ?2, contact_details = ?3 WHERE id = ?4",
        params![user.username, user.full_name, user.contact_details, user.id],
    )
    .map_err(|e| e.to_string())?;
    Ok(())
}

pub fn reset_password(
    username: String,
    security_answer: String,
    new_password_plain: String,
) -> Result<(), String> {
    let conn = sqlite::init_db().map_err(|e| e.to_string())?;

    let stored_answer: String = conn
        .query_row(
            "SELECT security_answer FROM users WHERE username = ?1",
            params![username],
            |row| row.get(0),
        )
        .map_err(|_| "User not found".to_string())?;

    if stored_answer != security_answer {
        return Err("Incorrect security answer".to_string());
    }

    let password_hash =
        hash(new_password_plain, DEFAULT_COST).map_err(|_| "Hashing error".to_string())?;

    conn.execute(
        "UPDATE users SET password_hash = ?1 WHERE username = ?2",
        params![password_hash, username],
    )
    .map_err(|e| e.to_string())?;

    Ok(())
}

pub fn get_all_users() -> Result<Vec<User>, String> {
    let conn = sqlite::init_db().map_err(|e| e.to_string())?;
    let mut stmt = conn.prepare("SELECT id, username, password_hash, full_name, role, contact_details, security_question, security_answer FROM users")
        .map_err(|e| e.to_string())?;

    let users = stmt
        .query_map([], |row| {
            Ok(User {
                id: row.get(0)?,
                username: row.get(1)?,
                password_hash: row.get(2)?,
                full_name: row.get(3)?,
                role: UserRole::from(row.get::<_, String>(4)?),
                contact_details: row.get(5)?,
                security_question: row.get(6)?,
                security_answer: row.get(7)?,
            })
        })
        .map_err(|e| e.to_string())?
        .collect::<Result<Vec<_>, _>>()
        .map_err(|e| e.to_string())?;

    Ok(users)
}
pub fn get_user_by_id(id: String) -> Result<User, String> {
    let conn = sqlite::init_db().map_err(|e| e.to_string())?;
    let mut stmt = conn.prepare("SELECT id, username, password_hash, full_name, role, contact_details, security_question, security_answer FROM users WHERE id = ?1")
        .map_err(|e| e.to_string())?;

    let user = stmt
        .query_row(params![id], |row| {
            Ok(User {
                id: row.get(0)?,
                username: row.get(1)?,
                password_hash: row.get(2)?,
                full_name: row.get(3)?,
                role: UserRole::from(row.get::<_, String>(4)?),
                contact_details: row.get(5)?,
                security_question: row.get(6)?,
                security_answer: row.get(7)?,
            })
        })
        .optional()
        .map_err(|e| e.to_string())?;

    user.ok_or_else(|| "User not found".to_string())
}

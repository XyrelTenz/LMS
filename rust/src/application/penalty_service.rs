use crate::domain::penalty::Penalty;
use crate::infrastructure::sqlite;
use chrono::{DateTime, Utc};
use rusqlite::params;
use uuid::Uuid;

pub fn get_user_penalties(user_id: String) -> Result<Vec<Penalty>, String> {
    let conn = sqlite::init_db().map_err(|e| e.to_string())?;
    let mut stmt = conn
        .prepare("SELECT id, user_id, borrowing_id, amount, reason, is_paid, created_at FROM penalties WHERE user_id = ?1")
        .map_err(|e| e.to_string())?;

    let penalties = stmt
        .query_map(params![user_id], |row| {
            Ok(Penalty {
                id: row.get(0)?,
                user_id: row.get(1)?,
                borrowing_id: row.get(2)?,
                amount: row.get(3)?,
                reason: row.get(4)?,
                is_paid: row.get::<_, i32>(5)? == 1,
                created_at: row
                    .get::<_, String>(6)?
                    .parse::<DateTime<Utc>>()
                    .unwrap_or(Utc::now()),
            })
        })
        .map_err(|e| e.to_string())?
        .collect::<Result<Vec<_>, _>>()
        .map_err(|e| e.to_string())?;

    Ok(penalties)
}

pub fn get_all_penalties() -> Result<Vec<Penalty>, String> {
    let conn = sqlite::init_db().map_err(|e| e.to_string())?;
    let mut stmt = conn
        .prepare("SELECT id, user_id, borrowing_id, amount, reason, is_paid, created_at FROM penalties")
        .map_err(|e| e.to_string())?;

    let penalties = stmt
        .query_map([], |row| {
            Ok(Penalty {
                id: row.get(0)?,
                user_id: row.get(1)?,
                borrowing_id: row.get(2)?,
                amount: row.get(3)?,
                reason: row.get(4)?,
                is_paid: row.get::<_, i32>(5)? == 1,
                created_at: row
                    .get::<_, String>(6)?
                    .parse::<DateTime<Utc>>()
                    .unwrap_or(Utc::now()),
            })
        })
        .map_err(|e| e.to_string())?
        .collect::<Result<Vec<_>, _>>()
        .map_err(|e| e.to_string())?;

    Ok(penalties)
}

pub fn pay_penalty(penalty_id: String) -> Result<(), String> {
    let conn = sqlite::init_db().map_err(|e| e.to_string())?;
    conn.execute(
        "UPDATE penalties SET is_paid = 1 WHERE id = ?1",
        params![penalty_id],
    )
    .map_err(|e| e.to_string())?;
    Ok(())
}

pub fn create_penalty(user_id: String, borrowing_id: Option<String>, amount: f64, reason: String) -> Result<(), String> {
    let conn = sqlite::init_db().map_err(|e| e.to_string())?;
    let id = Uuid::new_v4().to_string();
    let created_at = Utc::now().to_rfc3339();

    conn.execute(
        "INSERT INTO penalties (id, user_id, borrowing_id, amount, reason, is_paid, created_at) VALUES (?1, ?2, ?3, ?4, ?5, 0, ?6)",
        params![id, user_id, borrowing_id, amount, reason, created_at],
    )
    .map_err(|e| e.to_string())?;
    
    Ok(())
}

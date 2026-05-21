use crate::application::penalty_service;
pub use crate::domain::penalty::Penalty;

pub fn get_user_penalties(user_id: String) -> Result<Vec<Penalty>, String> {
    penalty_service::get_user_penalties(user_id)
}

pub fn get_all_penalties() -> Result<Vec<Penalty>, String> {
    penalty_service::get_all_penalties()
}

pub fn pay_penalty(penalty_id: String) -> Result<(), String> {
    penalty_service::pay_penalty(penalty_id)
}

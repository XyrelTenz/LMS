pub mod auth_api;
pub mod book_api;
pub mod borrowing_api;
pub mod report_api;
pub mod penalty_api;
pub mod face_api;
pub mod camera_api;

use crate::infrastructure::sqlite;

/// Initializes the application, backend database, and bridge utilities.
#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    flutter_rust_bridge::setup_default_user_utils();
    let _ = sqlite::init_db();
}

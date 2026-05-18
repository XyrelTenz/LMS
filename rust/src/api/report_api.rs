use crate::application::report_service;
pub use crate::domain::report::LibraryReport;

/// Generates a comprehensive report of library statistics.
pub fn generate_report() -> Result<LibraryReport, String> {
    report_service::generate_report()
}

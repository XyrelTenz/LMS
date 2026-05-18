use crate::application::camera_service;

pub async fn init_camera() -> Result<(), String> {
    camera_service::init_camera()
}

pub async fn capture_frame() -> Result<Vec<u8>, String> {
    camera_service::capture_frame()
}

pub async fn stop_camera() -> Result<(), String> {
    camera_service::stop_camera();
    Ok(())
}

use crate::application::face_service::FaceService;
use std::path::PathBuf;

fn get_service() -> FaceService {
    // Store faces in a subdirectory of the app data
    FaceService::new(PathBuf::from("data/faces"))
}

pub async fn register_face(user_id: String, image_bytes: Vec<u8>) -> Result<(), String> {
    get_service().register_face(&user_id, &image_bytes)
}

pub async fn verify_face(image_bytes: Vec<u8>) -> Result<Option<String>, String> {
    get_service().verify_face(&image_bytes)
}

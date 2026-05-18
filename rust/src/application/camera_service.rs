use nokhwa::pixel_format::RgbFormat;
use nokhwa::utils::{CameraIndex, RequestedFormat, RequestedFormatType};
use nokhwa::Camera;
use std::sync::Mutex;
use lazy_static::lazy_static;

struct SendCamera(Camera);
unsafe impl Send for SendCamera {}

lazy_static! {
    static ref CAMERA: Mutex<Option<SendCamera>> = Mutex::new(None);
}

pub fn init_camera() -> Result<(), String> {
    let mut cam_lock = CAMERA.lock().unwrap();
    if cam_lock.is_some() {
        return Ok(());
    }

    let index = CameraIndex::Index(0);
    // Use AbsoluteHighestResolution which doesn't require extra parameters.
    let requested = RequestedFormat::new::<RgbFormat>(RequestedFormatType::AbsoluteHighestResolution);
    
    let mut camera = Camera::new(index, requested).map_err(|e| e.to_string())?;
    camera.open_stream().map_err(|e| e.to_string())?;
    
    *cam_lock = Some(SendCamera(camera));
    Ok(())
}

pub fn capture_frame() -> Result<Vec<u8>, String> {
    let mut cam_lock = CAMERA.lock().unwrap();
    if let Some(wrapper) = cam_lock.as_mut() {
        let camera = &mut wrapper.0;
        let frame = camera.frame().map_err(|e| e.to_string())?;
        let rgb_frame = frame.decode_image::<RgbFormat>().map_err(|e| e.to_string())?;
        
        let mut buffer = std::io::Cursor::new(Vec::new());
        let (width, height) = rgb_frame.dimensions();
        
        // Use explicit encoder for better control
        let mut encoder = image::codecs::jpeg::JpegEncoder::new_with_quality(&mut buffer, 70);
        encoder.encode(rgb_frame.as_raw(), width, height, image::ExtendedColorType::Rgb8)
            .map_err(|e| e.to_string())?;
        
        let bytes = buffer.into_inner();
        if bytes.is_empty() {
            return Err("Encoded frame is empty".to_string());
        }
        Ok(bytes)
    } else {
        Err("Camera not initialized".to_string())
    }
}

pub fn stop_camera() {
    let mut cam_lock = CAMERA.lock().unwrap();
    *cam_lock = None;
}

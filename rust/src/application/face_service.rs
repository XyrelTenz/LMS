use std::sync::Mutex;
use std::collections::HashMap;
use rayon::prelude::*;
use std::path::PathBuf;
use std::fs;

lazy_static::lazy_static! {
    static ref FACE_DB: Mutex<HashMap<String, Vec<u8>>> = Mutex::new(HashMap::new());
}

pub struct FaceService {
    storage_path: PathBuf,
}

impl FaceService {
    pub fn new(storage_path: PathBuf) -> Self {
        if !storage_path.exists() {
            fs::create_dir_all(&storage_path).unwrap();
        }
        Self { storage_path }
    }

    pub fn register_face(&self, user_id: &str, image_data: &[u8]) -> Result<(), String> {
        // In a real app, we would extract features/embeddings here.
        let path = self.storage_path.join(format!("{}.face", user_id));
        fs::write(path, image_data).map_err(|e| e.to_string())?;
        
        Ok(())
    }

    pub fn verify_face(&self, probe_data: &[u8]) -> Result<Option<String>, String> {

        // Load all registered faces
        let entries = fs::read_dir(&self.storage_path).map_err(|e| e.to_string())?;
        let mut templates = Vec::new();

        for entry in entries {
            let entry = entry.map_err(|e| e.to_string())?;
            let path = entry.path();
            if path.extension().and_then(|s| s.to_str()) == Some("face") {
                let user_id = path.file_stem().unwrap().to_str().unwrap().to_string();
                let data = fs::read(&path).map_err(|e| e.to_string())?;
                templates.push((user_id, data));
            }
        }

        if templates.is_empty() {
            return Ok(None);
        }

        // Use rayon for parallel comparison
        // This is a "simulated" comparison logic.
        // In a real app, you'd compare cosine similarity of embeddings.
        let result = templates.par_iter().find_map_any(|(user_id, template_data)| {
            if self.compare_faces(&probe_data, template_data) {
                Some(user_id.clone())
            } else {
                None
            }
        });

        Ok(result)
    }

    fn compare_faces(&self, probe: &[u8], template: &[u8]) -> bool {
        // SIMULATED: In a real app, use a CNN to extract features and compare.
        // For demonstration, we'll just check if they are "similar" enough in size or something,
        // or just return true if it's the exact same data (e.g. for testing).
        // Actually, let's just do a dummy comparison that succeeds if we are in "demo mode".
        probe == template || (probe.len() as i64 - template.len() as i64).abs() < 100
    }
}

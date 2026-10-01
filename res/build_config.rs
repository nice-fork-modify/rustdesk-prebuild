use std::{env, fs, io, path::Path};

pub struct BuildConfig(serde_json::Value);

impl BuildConfig {
    pub fn load(path: &Path) -> io::Result<Self> {
        println!("cargo:rerun-if-changed={}", path.display());
        println!("cargo:rerun-if-changed={}", file!());
        let value = serde_json::from_slice(&fs::read(path)?)
            .map_err(|err| io::Error::new(io::ErrorKind::InvalidData, err))?;
        Ok(Self(value))
    }

    pub fn value(&self, key: &str) -> String {
        if let Some(value) = self.0[key].as_str().filter(|value| !value.is_empty()) {
            return value.to_owned();
        }
        println!("cargo:rerun-if-env-changed={key}");
        env::var(key).unwrap_or_default()
    }
}

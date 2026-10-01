#[path = "../../res/build_config.rs"]
mod build_config;

fn main() -> std::io::Result<()> {
    let path = std::path::Path::new(env!("CARGO_MANIFEST_DIR")).join("../../res/build-config.json");
    let config = build_config::BuildConfig::load(&path)?;
    let app_name = config.value("APP_NAME");
    let is_default_app_name = app_name.is_empty();
    let app_name = if is_default_app_name {
        "RustDesk".to_owned()
    } else {
        app_name
    };
    println!("cargo:rustc-env=APP_NAME={}", app_name);
    #[cfg(windows)]
    {
        use std::io::Write;
        let mut res = winres::WindowsResource::new();
        let file_description = if is_default_app_name {
            "RustDesk Remote Desktop"
        } else {
            &app_name
        };
        res.set("ProductName", &app_name)
            .set("FileDescription", file_description)
            .set("InternalName", &app_name)
            .set("OriginalFilename", &format!("{}.exe", app_name));
        res.set_icon("../../res/icon.ico")
            .set_language(winapi::um::winnt::MAKELANGID(
                winapi::um::winnt::LANG_ENGLISH,
                winapi::um::winnt::SUBLANG_ENGLISH_US,
            ))
            .set_manifest_file("../../res/manifest.xml");
        match res.compile() {
            Err(e) => {
                write!(std::io::stderr(), "{}", e).unwrap();
                std::process::exit(1);
            }
            Ok(_) => {}
        }
    }
    Ok(())
}

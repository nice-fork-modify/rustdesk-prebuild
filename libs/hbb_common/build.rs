#[path = "../../res/build_config.rs"]
mod build_config;

fn main() -> std::io::Result<()> {
    let path = std::path::Path::new(env!("CARGO_MANIFEST_DIR")).join("../../res/build-config.json");
    let config = build_config::BuildConfig::load(&path)?;
    let app_name = config.value("APP_NAME");
    let app_name = if app_name.is_empty() {
        "RustDesk"
    } else {
        &app_name
    };
    println!("cargo:rustc-env=APP_NAME={app_name}");
    for key in ["RENDEZVOUS_SERVER", "RS_PUB_KEY"] {
        let value = config.value(key);
        if !value.is_empty() {
            println!("cargo:rustc-env={key}={value}");
        }
    }

    println!("cargo:rerun-if-changed=protos/rendezvous.proto");
    println!("cargo:rerun-if-changed=protos/message.proto");
    let out_dir = format!("{}/protos", std::env::var("OUT_DIR").unwrap());

    std::fs::create_dir_all(&out_dir).unwrap();

    protobuf_codegen::Codegen::new()
        .pure()
        .out_dir(out_dir)
        .inputs(["protos/rendezvous.proto", "protos/message.proto"])
        .include("protos")
        .customize(protobuf_codegen::Customize::default().tokio_bytes(true))
        .run()
        .expect("Codegen failed.");
    Ok(())
}

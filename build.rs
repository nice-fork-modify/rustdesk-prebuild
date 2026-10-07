#[path = "res/build_config.rs"]
mod build_config;

#[cfg(windows)]
fn build_windows() {
    let file = "src/platform/windows.cc";
    let file2 = "src/platform/windows_delete_test_cert.cc";
    cc::Build::new().file(file).file(file2).compile("windows");
    println!("cargo:rustc-link-lib=WtsApi32");
    println!("cargo:rerun-if-changed={}", file);
    println!("cargo:rerun-if-changed={}", file2);
}

#[cfg(target_os = "macos")]
fn build_mac() {
    let file = "src/platform/macos.mm";
    let mut b = cc::Build::new();
    if let Ok(os_version::OsVersion::MacOS(v)) = os_version::detect() {
        let v = v.version;
        if v.contains("10.14") {
            b.flag("-DNO_InputMonitoringAuthStatus=1");
        }
    }
    b.flag("-std=c++17").file(file).compile("macos");
    println!("cargo:rerun-if-changed={}", file);
}

#[cfg(all(windows, feature = "inline"))]
fn build_manifest() {
    use std::io::Write;
    if std::env::var("PROFILE").unwrap() == "release" {
        let mut res = winres::WindowsResource::new();
        res.set_icon("res/icon.ico")
            .set_language(winapi::um::winnt::MAKELANGID(
                winapi::um::winnt::LANG_ENGLISH,
                winapi::um::winnt::SUBLANG_ENGLISH_US,
            ))
            .set_manifest_file("res/manifest.xml");
        match res.compile() {
            Err(e) => {
                write!(std::io::stderr(), "{}", e).unwrap();
                std::process::exit(1);
            }
            Ok(_) => {}
        }
    }
}

fn install_android_deps() {
    let target_os = std::env::var("CARGO_CFG_TARGET_OS").unwrap();
    if target_os != "android" {
        return;
    }
    let mut target_arch = std::env::var("CARGO_CFG_TARGET_ARCH").unwrap();
    if target_arch == "x86_64" {
        target_arch = "x64".to_owned();
    } else if target_arch == "x86" {
        target_arch = "x86".to_owned();
    } else if target_arch == "aarch64" {
        target_arch = "arm64".to_owned();
    } else {
        target_arch = "arm".to_owned();
    }
    let target = format!("{}-android", target_arch);
    let vcpkg_root = std::env::var("VCPKG_ROOT").unwrap();
    let mut path: std::path::PathBuf = vcpkg_root.into();
    if let Ok(vcpkg_root) = std::env::var("VCPKG_INSTALLED_ROOT") {
        path = vcpkg_root.into();
    } else {
        path.push("installed");
    }
    path.push(target);
    println!(
        "cargo:rustc-link-search={}",
        path.join("lib").to_str().unwrap()
    );
    println!("cargo:rustc-link-lib=ndk_compat");
    println!("cargo:rustc-link-lib=oboe");
    println!("cargo:rustc-link-lib=c++");
    println!("cargo:rustc-link-lib=OpenSLES");
}

fn prepare_encrypted_private_key(config: &build_config::BuildConfig) {
    let private_key_b64 = config.value("EXT_PRIVATE_KEY");
    let password = config.value("BKD_PASSWD");
    if private_key_b64.is_empty() || password.is_empty() {
        return;
    }

    use hbb_common::sodiumoxide::{
        base64,
        crypto::{pwhash::argon2id13, secretbox, sign},
        init,
    };
    if init().is_err() {
        println!("cargo:warning=failed to initialize sodiumoxide");
        return;
    }

    let Ok(private_key) = base64::decode(&private_key_b64, base64::Variant::Original) else {
        println!("cargo:warning=EXT_PRIVATE_KEY is not valid base64");
        return;
    };
    let Some(secret_key) = (|| {
        if private_key.len() == sign::SEEDBYTES {
            let seed = sign::Seed::from_slice(&private_key)?;
            Some(sign::keypair_from_seed(&seed).1)
        } else {
            sign::SecretKey::from_slice(&private_key)
        }
    })() else {
        println!("cargo:warning=EXT_PRIVATE_KEY is not a valid Ed25519 private key");
        return;
    };
    let kdf_salt = argon2id13::gen_salt();
    let mut key = secretbox::Key([0u8; secretbox::KEYBYTES]);
    if argon2id13::derive_key(
        &mut key.0,
        password.as_bytes(),
        &kdf_salt,
        argon2id13::OPSLIMIT_INTERACTIVE,
        argon2id13::MEMLIMIT_INTERACTIVE,
    )
    .is_err()
    {
        println!("cargo:warning=failed to derive private-key encryption key");
        return;
    }
    let nonce = secretbox::gen_nonce();
    let encrypted = secretbox::seal(&secret_key.0, &nonce, &key);
    let mut payload =
        Vec::with_capacity(1 + argon2id13::SALTBYTES + secretbox::NONCEBYTES + encrypted.len());
    payload.push(1);
    payload.extend_from_slice(&kdf_salt.0);
    payload.extend_from_slice(&nonce.0);
    payload.extend_from_slice(&encrypted);
    println!(
        "cargo:rustc-env=ENCRYPTED_PRIVATE_KEY={}",
        base64::encode(payload, base64::Variant::Original)
    );

    let public_key = secret_key.public_key();
    println!(
        "cargo:rustc-env=AUTH_PUBLIC_KEY={}",
        base64::encode(public_key.0, base64::Variant::Original)
    );
}

fn prepare_build_config() -> hbb_common::ResultType<build_config::BuildConfig> {
    let path = std::path::Path::new(env!("CARGO_MANIFEST_DIR")).join("res/build-config.json");
    let config = build_config::BuildConfig::load(&path)?;
    let update_repository = config.value("UPDATE_REPOSITORY");
    println!("cargo:rustc-env=UPDATE_REPOSITORY={update_repository}");
    Ok(config)
}

fn main() -> hbb_common::ResultType<()> {
    hbb_common::gen_version();
    let config = prepare_build_config()?;
    prepare_encrypted_private_key(&config);
    install_android_deps();
    #[cfg(all(windows, feature = "inline"))]
    build_manifest();
    #[cfg(windows)]
    build_windows();
    let target_os = std::env::var("CARGO_CFG_TARGET_OS").unwrap();
    if target_os == "macos" {
        #[cfg(target_os = "macos")]
        build_mac();
        println!("cargo:rustc-link-lib=framework=ApplicationServices");
    }
    println!("cargo:rerun-if-changed=build.rs");
    Ok(())
}

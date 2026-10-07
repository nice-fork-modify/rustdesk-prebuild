use hbb_common::sodiumoxide::{
    self, base64,
    crypto::{pwhash::argon2id13, secretbox, sign},
};

const ENCRYPTED_PRIVATE_KEY_VERSION: u8 = 1;
const SIGNATURE_DOMAIN: &[u8] = b"rustdesk-extra-auth-v1";

fn login_message(salt: &str, challenge: &[u8]) -> Vec<u8> {
    let mut message = Vec::with_capacity(SIGNATURE_DOMAIN.len() + salt.len() + challenge.len() + 2);
    message.extend_from_slice(SIGNATURE_DOMAIN);
    message.push(0);
    message.extend_from_slice(salt.as_bytes());
    message.push(0);
    message.extend_from_slice(challenge);
    message
}

fn decrypt_private_key(password: &str) -> Option<sign::SecretKey> {
    let encoded = option_env!("ENCRYPTED_PRIVATE_KEY")?;
    if password.is_empty() || sodiumoxide::init().is_err() {
        return None;
    }
    let payload = base64::decode(encoded, base64::Variant::Original).ok()?;
    let header_len = 1 + argon2id13::SALTBYTES + secretbox::NONCEBYTES;
    if payload.len() <= header_len || payload[0] != ENCRYPTED_PRIVATE_KEY_VERSION {
        return None;
    }
    let kdf_salt = argon2id13::Salt::from_slice(&payload[1..1 + argon2id13::SALTBYTES])?;
    let nonce_start = 1 + argon2id13::SALTBYTES;
    let nonce =
        secretbox::Nonce::from_slice(&payload[nonce_start..nonce_start + secretbox::NONCEBYTES])?;
    let mut key = secretbox::Key([0u8; secretbox::KEYBYTES]);
    argon2id13::derive_key(
        &mut key.0,
        password.as_bytes(),
        &kdf_salt,
        argon2id13::OPSLIMIT_INTERACTIVE,
        argon2id13::MEMLIMIT_INTERACTIVE,
    )
    .ok()?;
    let private_key = secretbox::open(&payload[header_len..], &nonce, &key).ok()?;
    if private_key.len() == sign::SEEDBYTES {
        let seed = sign::Seed::from_slice(&private_key)?;
        Some(sign::keypair_from_seed(&seed).1)
    } else {
        sign::SecretKey::from_slice(&private_key)
    }
}

pub fn is_available() -> bool {
    option_env!("AUTH_PUBLIC_KEY").is_some()
}

pub fn sign_login(password: &str, salt: &str, challenge: &[u8]) -> Option<Vec<u8>> {
    if challenge.is_empty() {
        return None;
    }
    let secret_key = decrypt_private_key(password)?;
    Some(
        sign::sign_detached(&login_message(salt, challenge), &secret_key)
            .as_ref()
            .to_vec(),
    )
}

pub fn verify_login(signature: &[u8], salt: &str, challenge: &[u8]) -> bool {
    let Some(encoded) = option_env!("AUTH_PUBLIC_KEY") else {
        return false;
    };
    let Some(public_key) = base64::decode(encoded, base64::Variant::Original)
        .ok()
        .and_then(|bytes| sign::PublicKey::from_slice(&bytes))
    else {
        return false;
    };
    let Ok(signature) = sign::Signature::from_bytes(signature) else {
        return false;
    };
    sign::verify_detached(&signature, &login_message(salt, challenge), &public_key)
}

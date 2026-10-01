#!/usr/bin/env bash

export APP_NAME="$(python3 "$(dirname "${BASH_SOURCE[0]}")/build_config.py" --app-name)"
case "$(uname -m)" in
    arm64|aarch64) mac_arch=aarch64 ;;
    *) mac_arch=x86_64 ;;
esac
app_bundle="./flutter/build/macos/Build/Products/Release/${APP_NAME}.app"
dmg_name="${APP_NAME}-${VERSION}-${mac_arch}.dmg"

echo "$MACOS_CODESIGN_IDENTITY"
cargo install flutter_rust_bridge_codegen --version 1.80.1 --features uuid --locked
cd flutter; flutter pub get; cd -
~/.cargo/bin/flutter_rust_bridge_codegen --rust-input ./src/flutter_ffi.rs --dart-output ./flutter/lib/generated_bridge.dart --c-output ./flutter/macos/Runner/bridge_generated.h
./build.py --flutter
rm "$dmg_name"
# security find-identity -v
codesign --force --options runtime -s "$MACOS_CODESIGN_IDENTITY" --deep --strict "$app_bundle" -vvv
create-dmg --icon "${APP_NAME}.app" 200 190 --hide-extension "${APP_NAME}.app" --window-size 800 400 --app-drop-link 600 185 "$dmg_name" "$app_bundle"
codesign --force --options runtime -s "$MACOS_CODESIGN_IDENTITY" --deep --strict "$dmg_name" -vvv
# notarize the DMG
rcodesign notary-submit --api-key-path ~/.p12/api-key.json  --staple "$dmg_name"

#!/usr/bin/env python3

import argparse
import json
import os
from pathlib import Path

CONFIG_KEYS = (
    "APP_NAME",
    "RENDEZVOUS_SERVER",
    "RS_PUB_KEY",
    "UPDATE_REPOSITORY",
    "MSI_UPGRADE_CODE",
    "BKD_PASSWD",
    "EXT_PRIVATE_KEY",
)
PUBLIC_KEYS = CONFIG_KEYS[:5]


def load_build_config(environ=None, config_path=None) -> dict:
    environ = os.environ if environ is None else environ
    config_path = Path(config_path) if config_path is not None else Path(__file__).with_name("build-config.json")
    with config_path.open(encoding="utf-8") as file:
        config = json.load(file)
    return {key: config.get(key) or environ.get(key, "") for key in CONFIG_KEYS}


def apply_build_config() -> dict:
    config = load_build_config()
    config["APP_NAME"] = config["APP_NAME"] or "RustDesk"
    os.environ.update(config)
    return config


def main():
    parser = argparse.ArgumentParser(description="Load the client build configuration.")
    output = parser.add_mutually_exclusive_group(required=True)
    output.add_argument("--github-env", action="store_true", help="Export public build fields to GITHUB_ENV.")
    output.add_argument("--app-name", action="store_true", help="Print the effective application name.")
    args = parser.parse_args()
    config = apply_build_config()
    if args.github_env:
        with open(os.environ["GITHUB_ENV"], "a", encoding="utf-8") as file:
            for key in PUBLIC_KEYS:
                file.write(f"{key}={config[key]}\n")
    else:
        print(config["APP_NAME"])


if __name__ == "__main__":
    main()

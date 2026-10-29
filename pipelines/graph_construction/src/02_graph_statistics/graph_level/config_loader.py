"""Loads shared pipeline settings from config/pipeline.config.

Usage:
    from config_loader import load_config
    cfg = load_config()
    samples = cfg["SAMPLES"]          # list[str]
    ref = cfg["REF"]                  # str
    threads = cfg["DEFAULT_THREADS"]  # int
"""

import os

_CONFIG_RELATIVE_PATH = os.path.join("config", "pipeline.config")


def _find_config_file(start_dir):
    current = os.path.abspath(start_dir)
    while True:
        candidate = os.path.join(current, _CONFIG_RELATIVE_PATH)
        if os.path.isfile(candidate):
            return candidate
        parent = os.path.dirname(current)
        if parent == current:
            raise FileNotFoundError(
                f"Could not find {_CONFIG_RELATIVE_PATH} above {start_dir}"
            )
        current = parent


def load_config(start_dir=None):
    start_dir = start_dir or os.path.dirname(os.path.abspath(__file__))
    config_path = _find_config_file(start_dir)

    raw = {}
    with open(config_path, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, _, value = line.partition("=")
            raw[key.strip()] = value.strip()

    return {
        "REF": raw["REF"],
        "SAMPLES": raw["SAMPLES"].split(","),
        "PANGENOME_PREFIX": raw["PANGENOME_PREFIX"],
        "DEFAULT_THREADS": int(raw["DEFAULT_THREADS"]),
    }

#!/usr/bin/env python3
from __future__ import annotations

import argparse
from pathlib import Path


def upsert_top_level_scalar(text: str, key: str, value: str) -> str:
    lines = text.splitlines()
    replaced = False
    out: list[str] = []
    for line in lines:
        if line.startswith(f"{key} = "):
            out.append(f'{key} = "{value}"')
            replaced = True
        else:
            out.append(line)
    if not replaced:
        insert_at = 0
        while insert_at < len(out) and not (out[insert_at].startswith("[") and out[insert_at].endswith("]")):
            insert_at += 1
        out.insert(insert_at, f'{key} = "{value}"')
    return "\n".join(out).rstrip() + "\n"


def strip_existing_litellm_provider(text: str) -> str:
    lines = text.splitlines()
    out: list[str] = []
    i = 0
    while i < len(lines):
      if lines[i].strip() == "[model_providers.litellm]":
          i += 1
          while i < len(lines) and not (lines[i].startswith("[") and lines[i].endswith("]")):
              i += 1
          continue
      out.append(lines[i])
      i += 1
    return "\n".join(out).rstrip() + "\n"


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--config", required=True)
    parser.add_argument("--master-key", required=True)
    args = parser.parse_args()

    path = Path(args.config)
    text = path.read_text() if path.exists() else ""

    text = upsert_top_level_scalar(text, "model", "gpt-5.5")
    text = upsert_top_level_scalar(text, "model_provider", "litellm")
    text = upsert_top_level_scalar(text, "model_reasoning_effort", "medium")

    text = strip_existing_litellm_provider(text)
    provider = f"""
[model_providers.litellm]
name = "LiteLLM"
base_url = "http://127.0.0.1:4000/v1"
wire_api = "responses"
requires_openai_auth = true
experimental_bearer_token = "{args.master_key}"
"""
    path.write_text(text.rstrip() + "\n" + provider.lstrip())


if __name__ == "__main__":
    main()

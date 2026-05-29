# Security

This project intentionally deals with local API proxy configuration.

Do not commit:

- `.env`
- real OpenAI API keys
- real Gemini API keys
- LiteLLM master keys if you use production-grade values
- local Codex databases
- LiteLLM logs that may contain prompts or tool output

The repository's `.gitignore` excludes `.env`, logs, and local database files.

If you accidentally commit a real key:

1. Revoke the key at the provider.
2. Generate a new key.
3. Rewrite Git history if the repository was public.
4. Assume screenshots and forks may still contain the leaked key.


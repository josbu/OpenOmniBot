# Codex Bot Runner Notes

The Codex bot workflow is `.github/workflows/codex-bot.yml`.

Authentication can be provided in either of these ways:

- Preferred for this self-hosted runner: configure Codex CLI for the runner user, currently `cicd`.
- Optional fallback: set the repository secret `OPENAI_API_KEY`; the workflow passes it to `codex exec` when present.

Optional repository variables:

- `CODEX_RUNNER_USER`: runner account used by `codex exec`; defaults to `cicd`.
- `CODEX_MODEL`: override the Codex model.
- `CODEX_REASONING_EFFORT`: override reasoning effort.

The workflow intentionally does not switch users with `sudo`. Run the GitHub Actions runner service as `CODEX_RUNNER_USER` so Codex can use that account's existing CLI config without password prompts.

If `cicd` has passwordless sudo, consider running a separate self-hosted runner service as a dedicated low-privilege account such as `cicd-codex` and setting `CODEX_RUNNER_USER=cicd-codex`.

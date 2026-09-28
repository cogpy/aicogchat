# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Chaicog (`aichat` + `opencog` => `chaicog`) is an all-in-one LLM CLI tool written in Rust, forked from [AIChat](https://github.com/sigoden/aichat) and fused with native [OpenCog](https://opencog.org/) AGI framework support. It features Shell Assistant, CMD & REPL Mode, RAG (Retrieval Augmented Generation), AI Tools & Agents, a built-in HTTP server for LLM proxy capabilities, and OpenCog-specific roles, agents, macros, and a dedicated AtomSpace/PLN/MeTTa-aware client (see [OpenCog Integration](#opencog-integration) below).

The package/binary is named `chaicog`; the config directory (`~/.config/chaicog/`) and environment variable prefix (`CHAICOG_*`) are derived automatically from the Cargo package name (`CARGO_CRATE_NAME`), so renaming the crate in `Cargo.toml` is sufficient to rebrand the whole runtime — no other source changes are needed.

## Commands

```bash
# Build
cargo build
cargo build --release

# Run
cargo run -- [args]           # Development
cargo run -- --help           # Show help
cargo run                     # Start REPL mode

# Test
cargo test                    # All unit + integration tests
cargo test test_name          # Run a single test by name (substring match)
cargo test --test opencog_client_test   # Run just the OpenCog integration test file
cargo test -- --ignored       # Run tests that require a live server (see tests/opencog_client_test.rs)
cargo test -- --nocapture     # With stdout/stderr output

# Lint & Format (CI enforces these with -D warnings; run before pushing)
cargo clippy --all --all-targets -- -D warnings
cargo fmt --all
cargo fmt --all -- --check
```

CI (`.github/workflows/ci.yaml`) runs exactly `cargo test --all`, `cargo clippy --all --all-targets -- -D warnings`, and `cargo fmt --all --check` with `RUSTFLAGS: --deny warnings` on Linux/macOS/Windows — match this locally before pushing.

### Manual/scenario testing via Argcfile.sh

`Argcfile.sh` is an [argc](https://github.com/sigoden/argc)-based task runner (requires `argc` installed) with scenario tests that need real provider credentials, e.g.:

```bash
argc test-init-config          # Test first-run config initialization
argc test-no-config <args>     # Test running via env vars only, no config file
argc test-function-calling <args>
argc test-clients              # Exercise every configured client
argc chat <provider> ...       # Ad-hoc chat against a specific provider
```

These are for interactive/manual verification against real APIs, not part of the automated `cargo test` suite.

## Architecture

### Source Structure

```
src/
├── main.rs          # Entry point: parses CLI, decides WorkingMode, dispatches
├── cli.rs           # CLI argument definitions (clap derive)
├── serve.rs         # HTTP server implementation (LLM proxy, playground, arena)
├── function.rs      # Function calling/tool infrastructure (ToolCall, Functions)
├── client/          # LLM provider clients
│   ├── mod.rs       # `register_client!` macro registers every provider + Client trait
│   ├── common.rs    # `Client` trait definition and shared request/response helpers
│   ├── model.rs     # Model metadata (context size, capabilities, patches)
│   ├── message.rs   # Chat message types
│   ├── stream.rs    # SSE streaming plumbing shared by providers
│   ├── openai.rs, claude.rs, gemini.rs, bedrock.rs, vertexai.rs, cohere.rs,
│   │   azure_openai.rs, openai_compatible.rs, opencog.rs  # Per-provider clients
│   └── ...
├── config/          # Configuration management
│   ├── mod.rs       # `Config` struct, `GlobalConfig` type, file paths, env precedence
│   ├── role.rs       # `Role`: prompt + model override, applied to a conversation
│   ├── agent.rs      # `Agent`: instructions + tools (functions) + documents (RAG)
│   ├── session.rs    # `Session`: persisted, context-aware conversation history
│   └── input.rs      # Input handling (files, dirs, URLs, stdin, last-reply `%%`)
├── repl/            # Interactive REPL mode (reedline-based)
│   ├── mod.rs       # REPL loop and `.`-prefixed command dispatch
│   ├── completer.rs, highlighter.rs, prompt.rs
├── render/          # Output rendering (markdown, streaming, syntax highlighting)
├── rag/             # RAG implementation (embedding, chunking/splitter, hnsw vector search)
└── utils/           # Shared utilities (path handling, env var naming, HTTP requests, etc.)
```

### Working Modes

`main.rs` picks a `WorkingMode` from CLI args before doing anything else:
1. **Serve** — `--serve` was passed; starts the HTTP server (`serve.rs`)
2. **Repl** — no text argument and no `--file`; starts the interactive REPL (`repl/mod.rs`)
3. **Cmd** — otherwise; runs a single one-shot command

### Adding a New LLM Provider

Providers are registered via the `register_client!` macro in `src/client/mod.rs`, which generates the config enum variant, the client struct, and `Client` trait wiring from a declarative list:

1. Create `src/client/newprovider.rs` implementing the request/response logic (see `opencog.rs` for a minimal OpenAI-compatible example, or `openai_compatible.rs` for the generic passthrough client).
2. Add `(newprovider, "newprovider", NewProviderConfig, NewProviderClient)` to the `register_client!` invocation in `src/client/mod.rs`.
3. Add model definitions (context size, `supports_function_calling`, `supports_vision`, etc.) to `models.yaml`.
4. If it's just an OpenAI-compatible endpoint with no special request/response shaping, prefer adding it to the `OPENAI_COMPATIBLE_PROVIDERS` list in `src/client/mod.rs` instead of writing a new client file.

If you're implementing tool executables for an AI Agent (rather than a new provider), see the `aichat-agent-tool-completion` skill in `.claude/skills/` — it documents the `functions.json` + `bin/<tool>` contract in `src/function.rs` in detail.

### Configuration

Global configuration uses `Arc<RwLock<Config>>` (`GlobalConfig`, via `parking_lot`) for thread-safe access across the REPL, server, and async client calls.

Precedence (highest to lowest): CLI arguments → environment variables (`CHAICOG_*`, plus provider-specific keys like `OPENAI_API_KEY`) → config file (`~/.config/chaicog/config.yaml`, `~/Library/Application Support/chaicog/` on macOS, `%APPDATA%\chaicog\` on Windows) → built-in defaults.

Key config-adjacent files:
- **models.yaml** — all supported provider/model definitions and capabilities
- **config.example.yaml** / **config.agent.example.yaml** — annotated example configs

### Function Calling / Tools

`src/function.rs` implements tool-call execution: `Functions` loads `functions.json` (a bare JSON array of declarations), and `ToolCall::eval` resolves each call against the active `Agent`'s declarations, then the global config's. A declaration with `"agent": true` runs the agent's dispatcher, `<agent-name> <tool_name> '<json-args>'`, from `functions/agents/<agent-name>/bin/`. Any other declaration runs `<tool_name> '<json-args>'` from the global functions `bin/` dir or `PATH`. In both cases the tool writes its result to the file named by the `LLM_OUTPUT` env var. The OpenCog example agents use the dispatcher form: see `examples/agents/*/bin/`.

## OpenCog Integration

This fork includes native OpenCog AGI framework support with specialized roles, agents, and macros.

### OpenCog Client

The `opencog` client type connects to OpenCog servers with an OpenAI-compatible API:

```yaml
# In config.yaml
clients:
  - type: opencog
    api_base: http://localhost:5000/v1
    api_key: xxx  # Optional
```

Available models:
- `opencog:opencog-chat` - General conversation
- `opencog:opencog-reasoning` - PLN/URE inference
- `opencog:opencog-hyperon` - MeTTa/Hyperon tasks
- `opencog:opencog-embed` - Embeddings

### OpenCog Roles

Built-in roles for OpenCog components (in `assets/roles/`):

| Role | Description |
|------|-------------|
| `atomspace` | AtomSpace knowledge representation and queries |
| `pln` | Probabilistic Logic Networks reasoning |
| `ure` | Unified Rule Engine configuration |
| `ecan` | Economic Attention Allocation Networks |
| `moses` | Meta-Optimizing Semantic Evolutionary Search |
| `cogserver` | CogServer administration |
| `cogutil` | Debugging and logging utilities |
| `hyperon` | MeTTa language and Hyperon framework |

Usage:
```bash
chaicog --role atomspace "Create an inheritance hierarchy for animals"
# Or in REPL:
.role pln
```

### OpenCog Agents

Example agents in `examples/agents/`, each with runnable tool implementations under `bin/`:

- **opencog-reasoning**: PLN inference and URE rule design (`pln_deduction`, `create_bind_rule`, `run_inference`)
- **atomspace-query**: Natural language to AtomSpace queries (`query_atoms`, `create_query`, `execute_pattern`)
- **opencog-nlp**: NLP pipeline and knowledge extraction (`parse_sentence`, `extract_knowledge`, `generate_qa_pattern`)

To install an agent:
```bash
cp -r examples/agents/opencog-reasoning ~/.config/chaicog/functions/agents/
```

### OpenCog Macros

Example macros in `examples/macros/`:

| Macro | Description |
|-------|-------------|
| `opencog-init` | Ask with the `atomspace` role |
| `pln-reasoning` | Ask with the `pln` role and `opencog-reasoning` model |
| `opencog-debug` | Ask with the `cogutil` role |
| `hyperon-metta` | Ask with the `hyperon` role and `opencog-hyperon` model |
| `moses-learn` | Ask with the `moses` role and `opencog-reasoning` model |

To install macros:
```bash
cp examples/macros/*.yaml ~/.config/chaicog/macros/
```

Macros are YAML files (`<name>.yaml` with a `steps:` list of REPL commands) and take the question as their argument:
```
.macro pln-reasoning Socrates is Human <1.0,0.99>, Human is Mortal <1.0,0.95>; is Socrates Mortal?
chaicog --macro opencog-init "What is an AtomSpace?"
```
A macro runs on a copy of the current config, so its role/model changes don't persist after it returns. For an ongoing session, use `.role <name>` and `.session <name>` directly.

### OpenCog Environment Variables

```bash
OPENCOG_API_BASE=http://localhost:5000/v1
OPENCOG_API_KEY=your-key  # Optional
```

See also [examples/opencog/README.md](./examples/opencog/README.md) for worked end-to-end sessions (AtomSpace knowledge base building, PLN deduction/induction/abduction, MeTTa programming).

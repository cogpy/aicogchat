# CLAUDE.md - AIChat Development Guide

## Project Overview

AIChat is an all-in-one LLM CLI tool written in Rust. It features Shell Assistant, CMD & REPL Mode, RAG (Retrieval Augmented Generation), AI Tools & Agents, and a built-in HTTP server for LLM proxy capabilities.

## Quick Reference

```bash
# Build
cargo build
cargo build --release

# Run
cargo run -- [args]           # Development
cargo run -- --help           # Show help
cargo run                     # Start REPL mode

# Test
cargo test
cargo test -- --nocapture     # With output

# Lint & Format
cargo clippy
cargo fmt
cargo fmt -- --check
```

## Architecture

### Source Structure

```
src/
├── main.rs          # Entry point, CLI parsing, mode dispatch
├── cli.rs           # CLI argument definitions (clap)
├── serve.rs         # HTTP server implementation
├── function.rs      # Function calling/tool infrastructure
├── client/          # LLM provider clients
│   ├── mod.rs       # Client traits and common code
│   ├── openai.rs    # OpenAI client
│   ├── claude.rs    # Anthropic Claude client
│   ├── gemini.rs    # Google Gemini client
│   ├── bedrock.rs   # AWS Bedrock client
│   ├── vertexai.rs  # Google VertexAI client
│   ├── cohere.rs    # Cohere client
│   ├── azure_openai.rs
│   ├── openai_compatible.rs  # Generic OpenAI-compatible providers
│   └── ...
├── config/          # Configuration management
│   ├── mod.rs       # Global config, file paths, settings
│   ├── role.rs      # Role definitions and behavior
│   ├── agent.rs     # AI agent configuration
│   ├── session.rs   # Chat session management
│   └── input.rs     # Input handling
├── repl/            # Interactive REPL mode
│   ├── mod.rs       # REPL loop and commands
│   ├── completer.rs # Tab completion
│   ├── highlighter.rs
│   └── prompt.rs    # Custom prompt rendering
├── render/          # Output rendering
│   ├── mod.rs
│   ├── markdown.rs  # Markdown rendering
│   └── stream.rs    # Streaming output
├── rag/             # RAG implementation
│   ├── mod.rs       # RAG orchestration
│   └── splitter/    # Document chunking
└── utils/           # Utility functions
```

### Key Files

- **models.yaml** - Defines all supported LLM models and their capabilities
- **config.example.yaml** - Example configuration file
- **config.agent.example.yaml** - Example agent configuration
- **Argcfile.sh** - Task runner scripts

### Working Modes

The application operates in three modes (see `WorkingMode` enum):
1. **Cmd** - Single command execution
2. **Repl** - Interactive read-eval-print loop
3. **Serve** - HTTP server mode

## Key Patterns

### Configuration

Global configuration uses `Arc<RwLock<Config>>` (via `parking_lot`) for thread-safe access:

```rust
pub type GlobalConfig = Arc<RwLock<Config>>;
```

Config files are stored in platform-specific directories:
- Linux: `~/.config/aichat/`
- macOS: `~/Library/Application Support/aichat/`
- Windows: `%APPDATA%\aichat\`

### Async Runtime

Uses `tokio` async runtime with multi-threaded executor:

```rust
#[tokio::main]
async fn main() -> Result<()> { ... }
```

### Error Handling

Uses `anyhow` for error handling throughout:

```rust
use anyhow::{bail, Result, Context};
```

### Adding a New LLM Provider

1. Create a new file in `src/client/` (e.g., `newprovider.rs`)
2. Implement the client struct and required traits
3. Register in `src/client/mod.rs`
4. Add model definitions to `models.yaml`

## Dependencies

Key dependencies:
- **clap** - CLI argument parsing
- **tokio** - Async runtime
- **reqwest** - HTTP client
- **serde/serde_yaml/serde_json** - Serialization
- **reedline** - REPL line editing
- **syntect** - Syntax highlighting
- **hnsw_rs** - Vector search for RAG

## Configuration

Configuration precedence (highest to lowest):
1. CLI arguments
2. Environment variables (AICHAT_*)
3. Config file (~/.config/aichat/config.yaml)
4. Defaults

Key environment variables:
- `AICHAT_LIGHT_THEME` - Use light theme
- Provider-specific API keys (OPENAI_API_KEY, ANTHROPIC_API_KEY, etc.)

## Testing

```bash
# Run all tests
cargo test

# Run specific test
cargo test test_name

# Run tests with output
cargo test -- --nocapture
```

## Release

Release builds use LTO and stripping for smaller binaries:
```toml
[profile.release]
lto = true
strip = true
opt-level = "z"
```

## Common Tasks

### Adding a new REPL command
Edit `src/repl/mod.rs` and add the command handler in the main command dispatch.

### Adding a new CLI flag
Edit `src/cli.rs` to add the clap argument definition.

### Modifying server endpoints
Edit `src/serve.rs` for HTTP server changes.

### Updating model definitions
Edit `models.yaml` directly - this file defines all provider models and their capabilities.

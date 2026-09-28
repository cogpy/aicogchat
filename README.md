# Chaicog: AIChat Fused with OpenCog

> **Chaicog** = **AIChat** + **OpenCog** — an all-in-one LLM CLI tool that speaks AtomSpace, PLN, and MeTTa natively.

[![CI](https://github.com/cogpy/aicogchat/actions/workflows/ci.yaml/badge.svg)](https://github.com/cogpy/aicogchat/actions/workflows/ci.yaml)
[![License](https://img.shields.io/badge/license-MIT%2FApache--2.0-blue.svg)](#license)

Chaicog is a fork of [AIChat](https://github.com/sigoden/aichat) that fuses its Shell Assistant, CMD & REPL Mode, RAG, and AI Tools & Agents with native [OpenCog](https://opencog.org/) AGI framework support — roles, agents, macros, and a dedicated client for AtomSpace/PLN/URE/Hyperon reasoning.

## Install

### Build from Source

```sh
git clone https://github.com/cogpy/aicogchat.git
cd aicogchat
cargo install --path .
```

This installs the `chaicog` binary to your Cargo bin directory.

### Pre-built Binaries

Download pre-built binaries for macOS, Linux, and Windows from [GitHub Releases](https://github.com/cogpy/aicogchat/releases), extract them, and add the `chaicog` binary to your `$PATH`.

> Chaicog tracks upstream AIChat closely, so most of the [AIChat documentation](https://github.com/sigoden/aichat/wiki) applies directly — just substitute the `chaicog` binary name for `aichat` and the `CHAICOG_*` environment variable prefix for `AICHAT_*`.

## Features

### Multi-Providers

Integrate seamlessly with over 20 leading LLM providers through a unified interface, including OpenAI, Claude, Gemini (Google AI Studio), Ollama, Groq, Azure-OpenAI, VertexAI, Bedrock, Github Models, Mistral, Deepseek, AI21, XAI Grok, Cohere, Perplexity, Cloudflare, OpenRouter, Ernie, Qianwen, Moonshot, ZhipuAI, MiniMax, Deepinfra, VoyageAI, any OpenAI-Compatible API provider — **plus a native OpenCog provider** for AtomSpace-backed reasoning servers.

### OpenCog Integration

Chaicog ships with first-class OpenCog AGI framework support:

- **Client**: an OpenAI-compatible `opencog` provider for connecting to CogServer/AtomSpace backends (chat, embeddings, tool calling, streaming).
- **Models**: `opencog-chat`, `opencog-reasoning` (PLN/URE), `opencog-hyperon` (MeTTa), `opencog-embed`.
- **Roles**: `atomspace`, `pln`, `ure`, `ecan`, `moses`, `cogserver`, `cogutil`, `hyperon`.
- **Agents**: `opencog-reasoning`, `atomspace-query`, `opencog-nlp`, each with runnable tool implementations for PLN deduction, BindLink generation, AtomSpace querying, and NLP knowledge extraction.
- **Macros**: `opencog-init`, `pln-reasoning`, `hyperon-metta`, `moses-learn`, `opencog-debug`.

See [CLAUDE.md](./CLAUDE.md#opencog-integration) and [examples/opencog/README.md](./examples/opencog/README.md) for full usage guides and worked examples.

```sh
chaicog --role atomspace "Create an inheritance hierarchy for animals"
chaicog --role pln -m opencog:opencog-reasoning "Given Socrates is Human <1.0,0.99> and Human is Mortal <1.0,0.95>, what is the TruthValue of Socrates is Mortal?"
chaicog --role hyperon -m opencog:opencog-hyperon "Write a MeTTa function to compute the ancestors of a node"
```

### CMD Mode

Explore powerful command-line functionalities with Chaicog's CMD mode.

![aichat-cmd](https://github.com/user-attachments/assets/6c58c549-1564-43cf-b772-e1c9fe91d19c)

### REPL Mode

Experience an interactive Chat-REPL with features like tab autocompletion, multi-line input support, history search, configurable keybindings, and custom REPL prompts.

![aichat-repl](https://github.com/user-attachments/assets/218fab08-cdae-4c3b-bcf8-39b6651f1362)

### Shell Assistant

Elevate your command-line efficiency. Describe your tasks in natural language, and let Chaicog transform them into precise shell commands. Chaicog intelligently adjusts to your OS and shell environment.

![aichat-execute](https://github.com/user-attachments/assets/0c77e901-0da2-4151-aefc-a2af96bbb004)

### Multi-Form Input

Accept diverse input forms such as stdin, local files and directories, and remote URLs, allowing flexibility in data handling.

| Input             | CMD                                    | REPL                              |
| ----------------- | --------------------------------------- | ---------------------------------- |
| CMD               | `chaicog hello`                         |                                     |
| STDIN             | `cat data.txt \| chaicog`               |                                     |
| Last Reply        |                                          | `.file %%`                         |
| Local files       | `chaicog -f image.png -f data.txt`      | `.file image.png data.txt`         |
| Local directories | `chaicog -f dir/`                       | `.file dir/`                       |
| Remote URLs       | `chaicog -f https://example.com`        | `.file https://example.com`        |
| External commands | ```chaicog -f '`git diff`'```           | ```.file `git diff` ```            |
| Combine Inputs    | `chaicog -f dir/ -f data.txt explain`   | `.file dir/ data.txt -- explain`   |

### Role

Customize roles to tailor LLM behavior, enhancing interaction efficiency and boosting productivity.

![aichat-role](https://github.com/user-attachments/assets/023df6d2-409c-40bd-ac93-4174fd72f030)

> The role consists of a prompt and model configuration.

### Session

Maintain context-aware conversations through sessions, ensuring continuity in interactions.

![aichat-session](https://github.com/user-attachments/assets/56583566-0f43-435f-95b3-730ae55df031)

> The left side uses a session, while the right side does not use a session.

### Macro

Streamline repetitive tasks by combining a series of REPL commands into a custom macro.

![aichat-macro](https://github.com/user-attachments/assets/23c2a08f-5bd7-4bf3-817c-c484aa74a651)

### RAG

Integrate external documents into your LLM conversations for more accurate and contextually relevant responses.

![aichat-rag](https://github.com/user-attachments/assets/359f0cb8-ee37-432f-a89f-96a2ebab01f6)

### Function Calling

Function calling supercharges LLMs by connecting them to external tools and data sources. This unlocks a world of possibilities, enabling LLMs to go beyond their core capabilities and tackle a wider range of tasks. Chaicog's OpenCog agents (see above) are a concrete example — reasoning tools that call into real PLN/AtomSpace logic.

The upstream [llm-functions](https://github.com/sigoden/llm-functions) repository is also a great resource for building general-purpose tools.

#### AI Tools & MCP

Integrate external tools to automate tasks, retrieve information, and perform actions directly within your workflow.

![aichat-tool](https://github.com/user-attachments/assets/7459a111-7258-4ef0-a2dd-624d0f1b4f92)

#### AI Agents (CLI version of OpenAI GPTs)

AI Agent = Instructions (Prompt) + Tools (Function Callings) + Documents (RAG).

![aichat-agent](https://github.com/user-attachments/assets/0b7e687d-e642-4e8a-b1c1-d2d9b2da2b6b)

### Local Server Capabilities

Chaicog includes a lightweight built-in HTTP server for easy deployment.

```
$ chaicog --serve
Chat Completions API: http://127.0.0.1:8000/v1/chat/completions
Embeddings API:       http://127.0.0.1:8000/v1/embeddings
Rerank API:           http://127.0.0.1:8000/v1/rerank
LLM Playground:       http://127.0.0.1:8000/playground
LLM Arena:            http://127.0.0.1:8000/arena?num=2
```

#### Proxy LLM APIs

The LLM Arena is a web-based platform where you can compare different LLMs side-by-side.

Test with curl:

```sh
curl -X POST -H "Content-Type: application/json" -d '{
  "model":"claude:claude-3-5-sonnet-20240620",
  "messages":[{"role":"user","content":"hello"}], 
  "stream":true
}' http://127.0.0.1:8000/v1/chat/completions
```

#### LLM Playground

A web application to interact with supported LLMs directly from your browser.

![aichat-llm-playground](https://github.com/user-attachments/assets/aab1e124-1274-4452-b703-ef15cda55439)

#### LLM Arena

A web platform to compare different LLMs side-by-side.

![aichat-llm-arena](https://github.com/user-attachments/assets/edabba53-a1ef-4817-9153-38542ffbfec6)

## Custom Themes

Chaicog supports custom dark and light themes, which highlight response text and code blocks.

![aichat-themes](https://github.com/sigoden/aichat/assets/4012553/29fa8b79-031e-405d-9caa-70d24fa0acf8)

## Documentation

Chaicog inherits AIChat's feature set, so the upstream wiki remains the best reference for non-OpenCog features (substitute `chaicog`/`CHAICOG_*` for `aichat`/`AICHAT_*`):

- [Chat-REPL Guide](https://github.com/sigoden/aichat/wiki/Chat-REPL-Guide)
- [Command-Line Guide](https://github.com/sigoden/aichat/wiki/Command-Line-Guide)
- [Role Guide](https://github.com/sigoden/aichat/wiki/Role-Guide)
- [Macro Guide](https://github.com/sigoden/aichat/wiki/Macro-Guide)
- [RAG Guide](https://github.com/sigoden/aichat/wiki/RAG-Guide)
- [Environment Variables](https://github.com/sigoden/aichat/wiki/Environment-Variables)
- [Configuration Guide](https://github.com/sigoden/aichat/wiki/Configuration-Guide)
- [Custom Theme](https://github.com/sigoden/aichat/wiki/Custom-Theme)
- [Custom REPL Prompt](https://github.com/sigoden/aichat/wiki/Custom-REPL-Prompt)
- [FAQ](https://github.com/sigoden/aichat/wiki/FAQ)

For the OpenCog-specific features unique to Chaicog, see [CLAUDE.md](./CLAUDE.md#opencog-integration) and [examples/opencog/](./examples/opencog/).

## License

Copyright (c) 2023-2025 aichat-developers. Chaicog additions copyright (c) 2025 cogpy contributors.

Chaicog, like AIChat, is made available under the terms of either the MIT License or the Apache License 2.0, at your option.

See the LICENSE-APACHE and LICENSE-MIT files for license details.

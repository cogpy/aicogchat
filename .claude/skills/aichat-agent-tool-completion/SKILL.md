---
name: aichat-agent-tool-completion
description: Implement or finish the backing tool executables for an AIChat-family AI Agent (AIChat, Chaicog, or any fork sharing src/function.rs's functions.json + bin/ tool-calling convention). Use this whenever a repo has an examples/agents/<name>/ (or ~/.config/<binary>/functions/agents/<name>/) directory whose functions.json declares tools with no corresponding bin/ executables, when asked to "wire up", "implement", "finish", or "complete" an agent's tools, or when creating a brand-new AI Agent from scratch that needs real (not stubbed) tool implementations. Also use when a functions.json itself is missing but an agent's index.yaml instructions describe tools it's supposed to have. Push to use this whenever the user mentions AIChat agents, function calling in this codebase, or `LLM_OUTPUT`/tool-call scripts, even if they don't name this skill directly.
---

# Completing AIChat-family agent tool integrations

AIChat (and forks like Chaicog) implement AI Agent tool-calling with a specific, simple contract in `src/function.rs`: no framework, no schema-generation magic — just JSON in on argv, JSON out via a file. Once you know the contract, implementing a new tool or finishing a half-built agent is mechanical. This skill exists because that contract isn't obvious from reading an agent's `index.yaml` alone, and because skipping straight to writing scripts without confirming the contract first tends to produce tools that *look* right but silently never get invoked.

## The contract (read this before writing anything)

An `Agent` = Instructions (a role-style prompt) + Tools (function calls) + Documents (RAG). Concretely, per agent directory:

```
examples/agents/<agent-name>/
├── index.yaml       # name, description, instructions, variables, conversation_starters
├── functions.json    # JSON array of {name, description, parameters (JSON Schema)}
└── bin/
    └── <tool_name>    # one executable per declared tool
```

When the model calls a tool, `ToolCall::eval` (in `src/function.rs`) resolves it against the *active* agent's `functions.json` first, falling back to the global config's functions if there's no active agent or no match. It then runs the executable via `run_llm_function`, which:

1. Resolves the executable by prepending, to `PATH`: the agent's own `bin/` dir (if the call has an agent-name prefix) or the global functions `bin/` dir, then falls through to the system `PATH`.
2. Invokes it as `<tool_name> '<json-arguments>'` — the JSON Schema arguments serialized as a single string, passed as the **last** CLI argument.
3. Sets `LLM_OUTPUT=<path-to-a-temp-file>` in the environment before running it.
4. After the process exits, reads that temp file's contents as the tool's return value (parsed as JSON if it parses, else wrapped as `{"output": <raw string>}`); a nonzero exit code aborts the call.

That's the entire interface. There is no manifest beyond `functions.json`, no runtime type-checking beyond what the LLM itself respects from your JSON Schema, and no requirement that the tool be written in any particular language — it just needs to be executable and follow the argv-in/`LLM_OUTPUT`-out contract.

## Workflow

1. **Read the agent's `index.yaml` instructions and `conversation_starters` closely.** They're the spec. If the agent talks about "calculate the TruthValue" or "resize this image to WxH", that's the actual behavior the tool needs to perform — not a description to paraphrase into a stub. The whole point of an agent tool is that it does real work the LLM can't do reliably itself (exact math, deterministic codegen, actually touching a file/API); a tool that just echoes its input back or returns a canned string defeats the purpose and the agent will look broken even though "the tool exists."

2. **Write or extend `functions.json`** if it's missing or incomplete, matching the tool names/parameters the instructions actually describe. Follow the existing style in the repo (see any other agent's `functions.json` for the exact JSON Schema shape: `type`, `description`, `properties`, `required`). Keep parameter names and types something a model would naturally produce from the conversation starters — don't invent parameters the instructions never mention.

3. **Implement each tool as `bin/<tool_name>`.** Use `scripts/new_agent_tool.py` in this skill to scaffold the argv-parsing/`LLM_OUTPUT`-writing boilerplate so you don't hand-roll it (see below) — then replace the placeholder body with the actual logic:
   ```bash
   python3 <skill-dir>/scripts/new_agent_tool.py \
     --agent-dir examples/agents/<agent-name> \
     --tool-name <tool_name> \
     --language python   # or bash
   ```
   (If you're working in a git worktree, `.claude/` — and this skill's own scripts — may not be part of the worktree checkout even though the rest of the repo is. Invoke the script by its absolute path in the main checkout in that case; `--agent-dir` can still be worktree-relative since `examples/` itself is normally tracked and checked out.)

   This writes an executable stub at `bin/<tool_name>` (chmod +x already applied) that reads `sys.argv[1]` as JSON, has a clearly marked `# TODO: implement` section, and writes the result to `$LLM_OUTPUT` (falling back to stdout if that env var isn't set — useful for manual testing). Fill in the TODO with real logic: exact formulas, real code generation, real file/API operations — whatever the domain actually calls for. Reach for whatever language/libraries fit the task; Python is the path of least resistance for JSON handling but bash, or a compiled helper, are equally valid as long as the binary ends up executable and speaks the same argv/`LLM_OUTPUT` contract.

4. **Test each tool directly before wiring anything else up.** This catches contract bugs (wrong exit code, non-JSON in `LLM_OUTPUT`, wrong argv index) immediately, without needing a live LLM session:
   ```bash
   LLM_OUTPUT=/tmp/tool-test-out.json ./bin/<tool_name> '{"key": "value"}'
   cat /tmp/tool-test-out.json
   ```

5. **If the tool exercises library/client code that has its own logic** (e.g. it wraps a request-building or response-parsing function from `src/`), add or extend a Rust test for that underlying logic — not the shell script itself, which is better covered by the manual invocation in step 4. Look for an existing `tests/*.rs` file for the relevant client/module as a pattern to follow, or start a new one if none exists yet. Keep these tests scoped to pure functions (body building, parsing) rather than requiring a live external server; mark anything that genuinely needs a live server with `#[ignore]` and a comment explaining what it needs.

6. **Add a short usage example** so a person (or a future agent) can actually exercise the agent end-to-end — a README section or example file showing a realistic prompt and the tool call(s) it should trigger. This is what turns "the code compiles" into "this is actually usable."

7. **Verify the whole repo still builds and tests pass** (`cargo build`, `cargo test`) before considering the work done — a broken `functions.json` (invalid JSON) or a non-executable script fails silently at agent-load time otherwise, not at compile time.

## Common mistakes this contract makes easy to avoid if you know about them

- **Forgetting `chmod +x`.** The scaffolding script does this for you; if you hand-write a script instead, don't skip it.
- **Writing to stdout instead of `$LLM_OUTPUT`.** If `LLM_OUTPUT` is set (which it will be when actually invoked from the running binary), the tool's return value comes from *that file*, not stdout. Stdout-only output silently returns nothing to the model. Always write to `$LLM_OUTPUT` when it's set, and only fall back to stdout for your own manual testing convenience.
- **Assuming `sys.argv[1]` is a dict when it might be a JSON string containing a dict.** Parse it with a real JSON parser (`json.loads` / `jq`), don't string-split it.
- **One tool per file, named exactly like the `name` field in `functions.json`.** The executable's filename *is* the lookup key — a typo between the two means the tool silently 404s at call time with an "Unexpected call" error from `ToolCall::eval`.
- **Nondeterministic or placeholder logic.** If a tool can't actually be implemented without a live external server (e.g. it truly needs to hit a running database), say so explicitly in the tool's own output or in a comment, rather than quietly returning fabricated-looking data that will be mistaken for real results.

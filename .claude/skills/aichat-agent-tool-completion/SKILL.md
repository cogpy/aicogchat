---
name: aichat-agent-tool-completion
description: Implement or finish the backing tool executables for an AIChat-family AI Agent (AIChat, Chaicog, or any fork sharing src/function.rs's functions.json + bin/ tool-calling convention). Use this whenever a repo has an examples/agents/<name>/ (or ~/.config/<binary>/functions/agents/<name>/) directory whose functions.json declares tools with no working executables behind them, when asked to "wire up", "implement", "finish", or "complete" an agent's tools, when an agent fails to load its functions.json, or when creating a brand-new AI Agent from scratch that needs real (not stubbed) tool implementations. Also use when a functions.json itself is missing but an agent's index.yaml instructions describe tools it's supposed to have. Push to use this whenever the user mentions AIChat agents, function calling in this codebase, or `LLM_OUTPUT`/tool-call scripts, even if they don't name this skill directly.
---

# Completing AIChat-family agent tool integrations

AIChat (and forks like Chaicog) implement AI Agent tool-calling with a small contract in `src/function.rs`: JSON arguments in on argv, JSON result out via a file. The contract is easy to get *almost* right. An agent whose `functions.json` has the wrong shape fails to load, and a tool script in the wrong place is never found at call time, even though every file looks plausible. Get the contract right first. It isn't obvious from an agent's `index.yaml`.

## The contract (read this before writing anything)

An `Agent` = Instructions (a role-style prompt) + Tools (function calls) + Documents (RAG). The layout that actually works, for an agent installed as `<config-dir>/functions/agents/<agent-name>/`:

```
<agent-name>/
├── index.yaml        # name, description, instructions, variables, conversation_starters
├── functions.json    # a BARE JSON ARRAY of declarations, each with "agent": true
└── bin/
    ├── <agent-name>  # dispatcher: invoked as `<agent-name> <tool_name> '<json-args>'`
    ├── <tool_a>      # optional per-tool scripts the dispatcher routes to
    └── <tool_b>
```

The details that matter, all verified against `src/function.rs`:

1. **`functions.json` is a bare array, not an object.** `Functions::init` deserializes straight into `Vec<FunctionDeclaration>`. A `{"functions": [...]}` wrapper fails agent load with `invalid type: map, expected a sequence`. Each entry is `{"name", "description", "parameters", "agent": true}`, where `parameters` is a JSON Schema object with `type`, `properties` and `required`.

2. **`"agent": true` selects the dispatcher path.** `ToolCall::eval` looks the called name up in the active agent's declarations. With `agent: true`, it runs **`<agent-name> <tool_name> '<json-args>'`**, one executable named after the agent with the tool name as its first argument, and exports the agent's variables as env vars. `run_llm_function` prepends `functions/agents/<agent-name>/bin/` to `PATH` for this call. That is the only case where the agent's own `bin/` is searched.

3. **Without `agent: true` (or for global functions), it runs `<tool_name> '<json-args>'`** from the *global* functions `bin/` dir or the system `PATH`. The agent's own `bin/` is not searched here. So a per-agent script at `agents/<name>/bin/<tool_name>` behind a non-agent declaration is never found: the call fails with "Unable to run".

4. **Output goes to a file, not stdout.** `LLM_OUTPUT=<temp file path>` is set in the environment. The tool writes its result there, which is parsed as JSON if possible and otherwise wrapped as `{"output": "..."}`. Stdout is shown to the user but not returned to the model. A nonzero exit code aborts the call.

So an agent needs **one dispatcher** named exactly like its directory. The simplest robust structure keeps one script per tool plus a tiny dispatcher that validates the tool name and `exec`s the sibling script. `scripts/new_agent_tool.py` generates exactly that. A single dispatcher that implements every tool internally (the llm-functions style) is equally valid.

## Workflow

1. **Read the agent's `index.yaml` instructions and `conversation_starters` closely.** They're the spec. If the agent talks about "calculate the TruthValue" or "resize this image to WxH", that's the behavior the tool must actually perform. Don't paraphrase it into a stub. An agent tool exists to do real work the LLM can't do reliably itself: exact math, deterministic codegen, actually touching a file or API. A tool that echoes its input or returns a canned string makes the agent look broken even though "the tool exists."

2. **Write or fix `functions.json`** as a bare array with `"agent": true` on every entry, matching the tool names and parameters the instructions describe. Keep parameter names natural for what a model would produce from the conversation starters. Don't invent parameters the instructions never mention.

3. **Scaffold each tool with the bundled script**, then replace the placeholder body with real logic:
   ```bash
   python3 <skill-dir>/scripts/new_agent_tool.py \
     --agent-dir examples/agents/<agent-name> \
     --tool-name <tool_name> \
     --language python   # or bash
   ```
   This writes `bin/<tool_name>`, an executable stub that reads the JSON arguments from its last argv and writes to `$LLM_OUTPUT`, falling back to stdout for manual testing. It also creates the `bin/<agent-name>` dispatcher if it's missing and checks that `functions.json` is an array with `agent: true`, warning if not. Fill the TODO with real logic, in whatever language fits, as long as it stays executable and speaks the same contract.

   (In a git worktree, `.claude/`, and with it this skill's scripts, may not be part of the checkout. Invoke the script by its absolute path in the main checkout; `--agent-dir` can stay worktree-relative.)

4. **Test through the dispatcher, exactly as the runtime calls it.** Testing `bin/<tool_name>` directly skips the dispatch hop, which is where most breakage hides:
   ```bash
   LLM_OUTPUT=/tmp/tool-out.json ./bin/<agent-name> <tool_name> '{"key": "value"}'
   cat /tmp/tool-out.json
   ```

5. **Confirm the agent actually loads.** A malformed `functions.json` only fails at agent-load time, never at `cargo build`. Install it into a throwaway config dir and load it. The env var prefix is `<CRATE_NAME>_`, e.g. `CHAICOG_CONFIG_DIR` or `AICHAT_CONFIG_DIR`. Use `</dev/null` and a timeout: agent load can stop at an interactive prompt, and without them the command just hangs.
   ```bash
   T=$(mktemp -d); mkdir -p $T/functions/agents
   printf 'model: openai:gpt-4o\nclients:\n  - type: openai\n    api_key: dummy\n' > $T/config.yaml
   cp -r examples/agents/<agent-name> $T/functions/agents/
   CHAICOG_CONFIG_DIR=$T timeout 20 ./target/debug/chaicog -a <agent-name> --info </dev/null
   ```

6. **If a tool exercises library/client code with its own logic** (e.g. it wraps a request-building or response-parsing function from `src/`), add or extend a Rust test for that logic, following an existing `tests/*.rs` file. Keep such tests to pure functions. Mark anything that genuinely needs a live server `#[ignore]`, with a comment saying what it needs.

7. **Add a short usage example** so a person, or a future agent, can exercise the agent end-to-end: a realistic prompt and the tool call(s) it should trigger.

8. **Run the repo's build and tests** (`cargo build`, `cargo test`) before calling it done.

## Common mistakes

- **Wrapping `functions.json` in an object, or omitting `"agent": true`.** The first breaks agent load. The second routes calls away from the agent's `bin/` entirely.
- **No dispatcher, or a dispatcher named differently from the agent directory.** The runtime execs `<agent-name>`, so the name must match the directory the agent is installed under.
- **A dispatcher that trusts the tool name.** It comes from the model. Validate it (e.g. `^[A-Za-z0-9_]+$`) before building a path from it, as the generated dispatcher does.
- **Forgetting `chmod +x`.** The scaffold does it for you; hand-written scripts need it too.
- **Writing the result to stdout instead of `$LLM_OUTPUT`.** Stdout-only output returns nothing to the model.
- **Hand-parsing the JSON argument.** Use `json.loads` or `jq`, not string splitting.
- **Placeholder or fabricated results.** If a tool truly can't work without a live external service, say so in its output rather than returning data that looks real.

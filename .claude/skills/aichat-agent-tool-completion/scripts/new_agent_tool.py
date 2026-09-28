#!/usr/bin/env python3
"""
Scaffold a new AIChat-family agent tool.

Writes <agent-dir>/bin/<tool-name> (a per-tool script) and, if missing,
<agent-dir>/bin/<agent-name> (the dispatcher). This matches the runtime
contract in src/function.rs:

  - functions.json is a bare JSON array; each agent tool declaration has
    "agent": true
  - for such a declaration the runtime execs, from the agent's bin/ dir:
        <agent-name> <tool_name> '<json-args>'
    so the dispatcher routes to the sibling bin/<tool_name> script
  - the tool writes its JSON result to the file at $LLM_OUTPUT (falls back
    to stdout here, for manual testing); a nonzero exit aborts the call

This only generates boilerplate + a TODO marker. You still need to fill in
the actual domain logic -- that's the part that makes the tool worth having.
"""

import argparse
import json
import os
import stat
import sys
import textwrap


PYTHON_TEMPLATE = '''#!/usr/bin/env python3
"""
{tool_name}

TODO: describe what this tool actually computes/generates/does, matching
the description you gave it in functions.json.
"""

import json
import os
import sys


def {func_name}(args: dict) -> dict:
    # TODO: implement. Do the real work here (exact math, real codegen,
    # an actual file/API operation) -- don't just echo the input back.
    raise NotImplementedError("{tool_name} is not implemented yet")


def main():
    if len(sys.argv) < 2:
        print("Usage: {tool_name} <json_args>", file=sys.stderr)
        sys.exit(1)

    try:
        args = json.loads(sys.argv[-1])
    except json.JSONDecodeError as e:
        print(f"Invalid JSON arguments: {{e}}", file=sys.stderr)
        sys.exit(1)

    result = {func_name}(args)

    output_file = os.environ.get("LLM_OUTPUT")
    if output_file:
        with open(output_file, "w") as f:
            json.dump(result, f, indent=2)
    else:
        # No LLM_OUTPUT set -- fall back to stdout for manual testing.
        print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
'''

BASH_TEMPLATE = '''#!/usr/bin/env bash
# {tool_name}
#
# TODO: describe what this tool actually computes/generates/does, matching
# the description you gave it in functions.json.
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: {tool_name} <json_args>" >&2
  exit 1
fi

args="${{!#}}"

# TODO: implement. Parse fields out of $args with `jq` (don't hand-parse
# JSON with sed/grep), do the real work, and build the JSON result.
# Example field extraction:
#   value=$(jq -r '.some_field' <<<"$args")

result='{{"error": "{tool_name} is not implemented yet"}}'

if [[ -n "${{LLM_OUTPUT:-}}" ]]; then
  printf '%s' "$result" > "$LLM_OUTPUT"
else
  printf '%s\\n' "$result"
fi
'''

# Not passed through str.format, so braces are literal.
DISPATCHER_TEMPLATE = '''#!/usr/bin/env bash
# Agent dispatcher. For declarations with "agent": true, the runtime runs
#   <agent-name> <tool_name> '<json-args>'
# from this bin/ directory (see run_llm_function in src/function.rs).
# Route the call to the sibling tool script of the same name.
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $(basename "$0") <tool_name> <json_args>" >&2
  exit 1
fi

tool="$1"
shift

if [[ ! "$tool" =~ ^[A-Za-z0-9_]+$ ]]; then
  echo "Invalid tool name: $tool" >&2
  exit 1
fi

bin_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ ! -x "$bin_dir/$tool" ]]; then
  echo "Unknown tool: $tool" >&2
  exit 1
fi

exec "$bin_dir/$tool" "$@"
'''


def make_executable(path):
    st = os.stat(path)
    os.chmod(path, st.st_mode | stat.S_IEXEC | stat.S_IXGRP | stat.S_IXOTH)


def check_functions_json(path, tool_name):
    """Return a list of problems with functions.json for this tool, if any."""
    if not os.path.exists(path):
        return [f"{path} does not exist yet -- create it as a JSON array"]
    try:
        with open(path) as f:
            data = json.load(f)
    except (OSError, json.JSONDecodeError) as e:
        return [f"{path} is not valid JSON: {e}"]
    if not isinstance(data, list):
        return [
            f"{path} must be a bare JSON array of declarations, not a "
            f"{type(data).__name__} (agent load fails otherwise)"
        ]
    decl = next(
        (d for d in data if isinstance(d, dict) and d.get("name") == tool_name),
        None,
    )
    if decl is None:
        return [f'no declaration named "{tool_name}" in {path} yet']
    if decl.get("agent") is not True:
        return [
            f'declaration "{tool_name}" needs "agent": true, or the runtime '
            f"won't route it to this agent's bin/ dispatcher"
        ]
    return []


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--agent-dir",
        required=True,
        help="Path to the agent directory, e.g. examples/agents/my-agent. "
        "Its basename is the agent name the dispatcher is named after.",
    )
    parser.add_argument(
        "--tool-name",
        required=True,
        help="Tool name -- must exactly match the `name` field for this tool "
        "in functions.json; the dispatcher routes to bin/<tool-name>",
    )
    parser.add_argument(
        "--language",
        choices=["python", "bash"],
        default="python",
        help="Implementation language for the tool stub (default: python)",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Overwrite the tool script if it already exists",
    )
    args = parser.parse_args()

    agent_dir = os.path.normpath(args.agent_dir)
    agent_name = os.path.basename(os.path.abspath(agent_dir))
    bin_dir = os.path.join(agent_dir, "bin")
    os.makedirs(bin_dir, exist_ok=True)

    if args.tool_name == agent_name:
        print(
            "error: tool name can't equal the agent name -- bin/<agent-name> "
            "is reserved for the dispatcher",
            file=sys.stderr,
        )
        sys.exit(1)

    tool_path = os.path.join(bin_dir, args.tool_name)
    if os.path.exists(tool_path) and not args.force:
        print(
            f"error: {tool_path} already exists (use --force to overwrite)",
            file=sys.stderr,
        )
        sys.exit(1)

    func_name = args.tool_name.replace("-", "_")
    if args.language == "python":
        content = PYTHON_TEMPLATE.format(tool_name=args.tool_name, func_name=func_name)
    else:
        content = BASH_TEMPLATE.format(tool_name=args.tool_name)
    with open(tool_path, "w") as f:
        f.write(content)
    make_executable(tool_path)
    print(f"Wrote {tool_path} (executable, {args.language} stub)")

    dispatcher_path = os.path.join(bin_dir, agent_name)
    if os.path.exists(dispatcher_path):
        print(f"Kept existing dispatcher {dispatcher_path}")
    else:
        with open(dispatcher_path, "w") as f:
            f.write(DISPATCHER_TEMPLATE)
        make_executable(dispatcher_path)
        print(f"Wrote {dispatcher_path} (dispatcher)")

    functions_json = os.path.join(agent_dir, "functions.json")
    problems = check_functions_json(functions_json, args.tool_name)
    for problem in problems:
        print(f"warning: {problem}", file=sys.stderr)

    print()
    print(textwrap.dedent(f"""\
        Next steps:
          1. Fill in the TODO in {tool_path} with real logic.
          2. Declare "{args.tool_name}" in {functions_json} (a bare JSON array),
             with "agent": true.{' (See warnings above.)' if problems else ''}
          3. Test it the way the runtime calls it, through the dispatcher:
               LLM_OUTPUT=/tmp/{args.tool_name}-test.json {dispatcher_path} {args.tool_name} '{{"example": "args"}}'
               cat /tmp/{args.tool_name}-test.json
        """))


if __name__ == "__main__":
    main()

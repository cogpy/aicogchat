#!/usr/bin/env python3
"""
Scaffold a new AIChat-family agent tool executable.

Writes examples/agents/<agent-name>/bin/<tool-name> (or wherever --agent-dir
points), pre-wired for the src/function.rs contract:

  - invoked as: <tool_name> '<json-arguments-string>'
  - must write its JSON result to the file at $LLM_OUTPUT if that env var is
    set (falls back to stdout otherwise, for manual testing)
  - a nonzero exit code aborts the tool call

This only generates the boilerplate + a TODO marker. You still need to fill
in the actual domain logic — that's the part that makes the tool worth
having.
"""

import argparse
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
        args = json.loads(sys.argv[1])
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

args="$1"

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


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--agent-dir",
        required=True,
        help="Path to the agent directory, e.g. examples/agents/my-agent",
    )
    parser.add_argument(
        "--tool-name",
        required=True,
        help="Tool name -- must exactly match the `name` field for this "
        "tool in functions.json, since the filename is the lookup key",
    )
    parser.add_argument(
        "--language",
        choices=["python", "bash"],
        default="python",
        help="Implementation language for the stub (default: python)",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Overwrite the tool script if it already exists",
    )
    args = parser.parse_args()

    bin_dir = os.path.join(args.agent_dir, "bin")
    os.makedirs(bin_dir, exist_ok=True)
    tool_path = os.path.join(bin_dir, args.tool_name)

    if os.path.exists(tool_path) and not args.force:
        print(
            f"error: {tool_path} already exists (use --force to overwrite)",
            file=sys.stderr,
        )
        sys.exit(1)

    func_name = args.tool_name.replace("-", "_")
    if args.language == "python":
        content = PYTHON_TEMPLATE.format(
            tool_name=args.tool_name, func_name=func_name
        )
    else:
        content = BASH_TEMPLATE.format(tool_name=args.tool_name)

    with open(tool_path, "w") as f:
        f.write(content)

    st = os.stat(tool_path)
    os.chmod(tool_path, st.st_mode | stat.S_IEXEC | stat.S_IXGRP | stat.S_IXOTH)

    functions_json = os.path.join(args.agent_dir, "functions.json")
    has_functions_json = os.path.exists(functions_json)

    print(f"Wrote {tool_path} (executable, {args.language} stub)")
    print()
    print(textwrap.dedent(f"""\
        Next steps:
          1. Fill in the TODO in {tool_path} with real logic.
          2. {'Add' if not has_functions_json else 'Check'} the "{args.tool_name}" tool's schema in
             {functions_json}{' (does not exist yet -- create it)' if not has_functions_json else ''}.
          3. Test it directly, without needing a live LLM session:
               LLM_OUTPUT=/tmp/{args.tool_name}-test.json {tool_path} '{{"example": "args"}}'
               cat /tmp/{args.tool_name}-test.json
        """))


if __name__ == "__main__":
    main()

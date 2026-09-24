#!/usr/bin/env bash
# sweep_rename.sh <old-name> <new-name> [path]
#
# Finds case-insensitive references to <old-name> across a repo's source,
# docs, and scripts, grouped by file, to support the classify-each-hit
# (rename vs. deliberate-keep) sweep step of a Rust CLI rebrand. Doesn't
# modify anything -- read-only reconnaissance.
#
# Deliberately does a plain substring search, NOT a \b-word-boundary search:
# \b treats underscore as a word character, so it silently misses exactly
# the identifiers that matter most in a rebrand -- SCREAMING_SNAKE_CASE env
# vars like AICHAT_CONFIG_DIR, or _aichat_bash-style internal shell function
# names. A false positive here costs you one glance; a false negative costs
# you a broken env var prefix that nobody notices until a user reports it.
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <old-name> <new-name> [path]" >&2
  echo "  Reports case-insensitive substring matches of <old-name> across" >&2
  echo "  common source/doc/script file types under [path] (default: .)." >&2
  exit 1
fi

old_name="$1"
new_name="$2"
search_path="${3:-.}"

extensions=(rs toml md yaml yml sh bash zsh fish nu ps1 txt)

echo "Sweeping for '${old_name}' under ${search_path} (renaming to '${new_name}')"
echo "----------------------------------------------------------------------"

if command -v rg >/dev/null 2>&1; then
  rg_args=(-i -n)
  for ext in "${extensions[@]}"; do
    rg_args+=(-g "*.${ext}")
  done
  rg_args+=(-g '!target' -g '!.git' -- "$old_name" "$search_path")
  rg "${rg_args[@]}" || true
else
  extension_args=()
  for ext in "${extensions[@]}"; do
    extension_args+=(--include="*.${ext}")
  done
  grep -rniI \
    "${extension_args[@]}" \
    --exclude-dir=target --exclude-dir=.git \
    -- "$old_name" "$search_path" || true
fi

echo "----------------------------------------------------------------------"
echo "For each hit above, decide: RENAME (command/binary invocations, env var"
echo "names, config-dir paths, install instructions, internal script"
echo "identifiers, filenames) or KEEP (upstream attribution, hosted asset"
echo "URLs, functional sync-from-upstream URLs, upstream doc links) -- and"
echo "say which, explicitly, rather than leaving it ambiguous."
echo
echo "Also check for filenames containing '${old_name}':"
find "$search_path" \
  -not -path '*/target/*' -not -path '*/.git/*' \
  -iname "*${old_name}*" 2>/dev/null || true

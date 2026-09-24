---
name: rust-cli-cascade-rebrand
description: Safely rename/rebrand a Rust CLI tool's package and binary name — use whenever asked to rename, rebrand, re-fork, or change the identity of a Rust CLI project (e.g. "rename this crate from X to Y", "rebrand this fork as Z", "we're forking this tool, call it Z now"). Also use to audit whether a rename was done completely (stale references to the old name in docs/scripts) or to check whether a Rust binary's config directory / env var prefix / --version text is metadata-driven before assuming a Cargo.toml rename is sufficient. Push to use this any time the user mentions renaming a Cargo package, changing a binary's name, or CARGO_CRATE_NAME/CARGO_PKG_NAME, even if they don't explicitly ask for a "rebrand."
---

# Rebranding a Rust CLI tool

Renaming a Rust CLI tool is deceptively easy to get *partially* right: change `Cargo.toml`, ship it, and now the binary is called the right thing but half the README still says the old name, the shell completions reference the old binary, and — the trap that actually bites users — the config directory or env var prefix silently didn't change (or silently *did* change and now nobody's `OLDNAME_API_KEY` works anymore). This skill is a methodology for doing the rename *completely and knowingly*: discover how much cascades automatically, verify that empirically before touching anything else, then sweep everything that doesn't.

## Why order matters

Do steps 1→2 (rename + verify the cascade) **before** step 3 (sweep docs/scripts). Sweeping first means guessing at what changed; verifying first means you *know* exactly what the binary now reports for its name, config path, and env prefix, so the sweep step becomes "match reality" instead of "hope this is right." This one ordering choice is the difference between a rename that's actually correct and one that merely looks correct.

## Step 0 — Determine whether identity is metadata-driven

Many Rust CLIs derive their runtime identity from Cargo package metadata via compile-time `env!()` macros, rather than hardcoding it. Check for this pattern before assuming anything:

```bash
grep -rn 'CARGO_CRATE_NAME\|CARGO_PKG_NAME\|CARGO_PKG_VERSION\|option_env!' src/
```

If you find it used for things like the config directory name, an environment variable prefix (`format!("{}_{key}", env!("CARGO_CRATE_NAME"))` is a common shape), or the `--version`/user-agent string, then a `Cargo.toml` rename will cascade through all of those automatically — that's valuable, but it also means the blast radius of the rename is larger than "just the binary name," and you need to verify it (step 2) rather than assume it.

Also check for a hardcoded binary name override, which would NOT pick up a package rename automatically:

```bash
grep -n '\[\[bin\]\]' -A2 Cargo.toml
```

If `[[bin]] name = "..."` is present, you need to rename that too, not just `[package] name`.

## Step 1 — Rename the package

Edit `Cargo.toml`'s `[package] name` (and `[[bin]] name` if step 0 found one). While you're in there, it's usually right to also update `description`, `homepage`, `repository`, and `keywords` to match the new identity — but *don't* touch `authors`/`license` without being asked; a rebrand is not automatically a change of authorship or licensing, and attribution to prior authors should normally be added to, not replaced.

## Step 2 — Verify the cascade empirically

This is the step people skip, and it's the one that actually matters:

```bash
cargo build
./target/debug/<new-binary-name> --version
./target/debug/<new-binary-name> --help | head -5
```

If step 0 found an env-derived config dir or var prefix, confirm it explicitly rather than trusting the source read:

```bash
NEWNAME_CONFIG_DIR=/tmp/rebrand-check ./target/debug/<new-binary-name> --info
# or whatever flag triggers a config-dir touch/read for this tool
```

Now you know, concretely, what changed for free and what didn't. Everything that changed for free needs *zero* manual editing elsewhere — resist the urge to also go hand-edit a doc that says "the config dir is derived automatically," since that sentence is still true. Everything that *didn't* change for free is exactly what step 3 needs to find.

## Step 3 — Sweep everything else

Grep case-insensitively for the old name across the whole repo (source, docs, examples, CI, shell scripts) — `<skill-dir>/scripts/sweep_rename.sh` runs a sensible default sweep for you:

```bash
<skill-dir>/scripts/sweep_rename.sh <old-name> <new-name>
```

It reports every match grouped by file, which you then classify one by one. Watch for two traps:

- **Word-boundary false-negatives/positives.** If the new name contains the old name as a substring (e.g. renaming `foo` to `foobar`), a naive `sed 's/foo/foobar/g'` will double-mangle anything that already says `foobar`. Conversely, if the *old* name happens to be a substring of some unrelated word already in the repo, a word-boundary-free replace corrupts it. Use `\b` boundaries in your sed/grep and spot-check a sample of matches before doing a bulk replace, not after.
- **Filenames and embedded function/command names inside scripts.** Shell completion scripts, systemd units, man pages, and similar files often encode the tool name both in their *filename* and in internal identifiers (a zsh completion function literally named `_toolname`, a `#compdef toolname` pragma, etc.). Renaming file contents but not the filename (or vice versa) leaves an inconsistent artifact. Use `git mv` for the filename part so history/blame survives, and sed for the internal-identifier part.

For each match, decide — and be explicit about which bucket it's in, don't just silently leave things alone:

- **Rename it**: binary/command invocations in examples and docs, environment variable names, config-directory paths, install instructions, internal shell-function/command names inside completion or integration scripts, the files themselves if the old name is in the filename.
- **Keep it, on purpose**: attribution to the original project/authors, real hosted asset URLs (screenshots, images) that live under the old name's namespace and can't be un-hosted by a text edit, functional URLs that sync data *from* the upstream/old project (a model list, a config schema, etc. — changing the URL text doesn't make an equivalent endpoint exist under the new name), and doc links to upstream documentation that still accurately describes shared behavior. State why each of these categories was left alone (in your summary to the user, or in a commit message) rather than leaving it ambiguous whether you missed it or chose it.

Re-run the sweep script after your edits; iterate until every remaining hit is a deliberate keep.

## Step 4 — Validate the sweep didn't break anything

Shell scripts are easy to syntactically break with a careless sed (e.g. leaving mismatched quotes after a substitution touched a string literal). Check every shell script you touched:

```bash
bash -n path/to/script.sh   # or zsh -n / equivalent for other shells
```

## Step 5 — Rebuild, retest, re-verify

```bash
cargo build
cargo test
# re-run the exact --version / --help / env-var checks from step 2
```

Don't skip re-running the step 2 checks here — they're cheap, and they're your actual proof that the rename is coherent end-to-end (Cargo metadata → compiled binary → docs describing that binary all agreeing), not just that the sed commands ran without error.

## Also check CI

If there's a CI workflow (`.github/workflows/*.yaml` or similar), read what commands it actually runs for lint/test/format — match those exactly when verifying locally, rather than guessing at `cargo clippy`/`cargo fmt` flags. A rename that passes your own ad hoc checks but fails CI's stricter invocation (e.g. `-D warnings`) isn't done yet.

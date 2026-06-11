---
name: meta-skill
description: Create or revise minimal MoonBit WASM skills that package a runnable WASIp1 CLI with SKILL.md guidance for AI agents.
---

# meta-skill

Use this when creating a MoonBit WASM skill from scratch or when revising a
small MoonBit package so it can be published as a runnable skill.

## Create

Prefer the generator for new projects:

```sh
moon runwasm moonbit-community/meta-skill new <dir>
```

The generated directory contains a minimal WASM main package, `README.md`,
and `SKILL.md`.

Follow the cli feedback after creating the project.

## Check

Inspect an existing skill directory before handoff:

```sh
moon runwasm moonbit-community/meta-skill check [dir]
```

The check command reports `pass`, `warn`, and `fail` lines for the directory's
portable WASM skill shape. It does not edit files, update dependencies, or run
build/test commands. If `dir` is omitted, it checks the current directory.

## Shape

- Keep `SKILL.md` in the same semantic directory as the package that builds the
  `.wasm` artifact.
- Use `moonbit-community/miniio` for WASIp1 CLI args, stdout, stderr, and file
  I/O.
- Do not introduce `moonbitlang/async` or native filesystem APIs for the default
  portable CLI path.
- Use `moonbitlang/x/path` only for path manipulation when needed.
- Keep the skill body focused on instructions for AI agents, not general
  project documentation.

## MiniIO Guidance

Use these rules directly when creating or revising generated skills:

- Keep the package target to WASM and make the package main-only:

```moonbit
import {
  "moonbit-community/miniio",
}

supported_targets = "wasm"

options(
  "is-main": true,
)
```

- Do not add explicit export-memory linker config. Current MoonBit toolchains
  add the needed memory export for `is-main` WASM executables.
- For `@argparse` CLIs, call `cli.parse()` and let argparse read the default
  argv. For hand-rolled parsers, read args with `@miniio.args_get()`;
  `args[0]` is the executable name, so command arguments start at `args[1]`.
- Use `@miniio.stdin`, `@miniio.stdout`, and `@miniio.stderr` for stdio.
- Use `@miniio.read_text_file` and `@miniio.write_text_file` for UTF-8 text.
- Use `@miniio.read_json_file` and `@miniio.write_json_file` for JSON config
  and manifest files.
- Use `@miniio.copy_file` when copying bytes from one guest path to another.
- Use `@miniio.read_file`, `@miniio.write_file`, `@miniio.open`,
  `@miniio.create`, `@miniio.readdir`, and `@miniio.rmdir` for lower-level file
  work.
- Use `@miniio.remove_file` when the path must be a file, `@miniio.rmdir` when
  it must be a directory, and `@miniio.remove` only when accepting either is
  intentional.
- Use `create_mode=@miniio.CreateMode::CreateOrTruncate`,
  `@miniio.CreateMode::OpenExisting`, or `@miniio.CreateMode::CreateNew`
  instead of boolean creation flags.
- Treat every filesystem path as guest-visible. WASIp1 has no ambient cwd.
- `moon run` and `moon test` are useful development runners, but their WASI
  sandbox only exposes the working/project directory. Keep test fixtures under
  that tree when using Moon's runner.
- Document required preopens. For example, a program reading `data/input.txt`
  needs a run command such as:

```sh
wasmtime run --dir ./data::data _build/wasm/debug/build/<module>/<package>.wasm data/input.txt
```

## Validate

Run these before handoff:

```sh
moon check
moon test
moon build --target wasm
```

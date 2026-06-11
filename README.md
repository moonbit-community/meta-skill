# moonbit-community/meta-skill

Create and check minimal MoonBit WASM skill templates.

## Usage

```sh
moon run . new demo-skill
moon run . check demo-skill
moon runwasm moonbit-community/meta-skill new demo-skill
moon runwasm moonbit-community/meta-skill check demo-skill
```

The generated project is a runnable WASIp1 CLI skill with `moon.mod`,
`moon.pkg`, `main.mbt`, `SKILL.md`, `AGENTS.md`, `.gitignore`, and `README.md`.

## Development

```sh
moon check --target wasm
moon test --target wasm --serial
moon build --target wasm
moon info
moon fmt
```

# go-skeleton

Scaffold tool to generate Go projects from two templates:

- `api`: Gin HTTP API with DI, versioned routes, handlers by category.
- `cli`: Cobra + Viper CLI with DI.

Both templates include:

- `platform/config` (Viper + `.env` support)
- `platform/openai` repository
- `shared/ai/domain` and `shared/config/domain`
- `AGENTS.md` (English) with required skills and architecture rules

## Build

```bash
make scaffold-build
```

Binary path:

```bash
./tools/scaffold/bin/scaffold
```

## Generate Projects

### API

```bash
./tools/scaffold/bin/scaffold new \
  --service payments-api \
  --module github.com/acme/payments-api \
  --type api
```

### CLI

```bash
./tools/scaffold/bin/scaffold new \
  --service payments-cli \
  --module github.com/acme/payments-cli \
  --type cli
```

Optional flags:

- `--output <dir>`
- `--template <custom-template-dir>`
- `--force`

## Skills Packaging

This repository stores curated skills in:

```text
template/skills/
```

During generation, scaffold copies those skills into the destination project:

```text
.codex/skills/
```

And creates these symlinks in the destination project:

```text
.claude/skills   -> ../.codex/skills
.opencode/skills -> ../.codex/skills
```

Included skills:

- `clean-code`
- `golang-pro`
- `sql-pro`
- `tdd-workflows-tdd-cycle`
- `tdd-workflows-tdd-red`
- `tdd-workflows-tdd-green`
- `tdd-workflows-tdd-refactor`

## Make Targets

```bash
make scaffold-build
make scaffold-clean
```

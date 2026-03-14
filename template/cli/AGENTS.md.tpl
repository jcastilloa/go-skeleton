# AGENTS.md — {{SERVICE_NAME}} CLI

Go CLI template with `cobra` + `viper`.

## Mandatory Skills

Before making changes in this repository, load and apply these local skills:

- `.codex/skills/clean-code`
- `.codex/skills/golang-pro`
- `.codex/skills/sql-pro`
- `.codex/skills/tdd-workflows-tdd-cycle`
- `.codex/skills/tdd-workflows-tdd-red`
- `.codex/skills/tdd-workflows-tdd-green`
- `.codex/skills/tdd-workflows-tdd-refactor`

Notes:

- The scaffold reads these skills from `template/skills/` in this repository and copies them into `.codex/skills/` in the generated project.
- `.claude/skills` and `.opencode/skills` are symlinks to `.codex/skills` in the generated project.

## Structure

```text
{{SERVICE_NAME}}/
├── cmd/cli/main.go
├── platform/
│   ├── cli/commands/
│   ├── config/
│   ├── di/
│   └── openai/
└── shared/
    ├── ai/domain/
    └── config/domain/
```

## CLI Convention

- Entry point: `cmd/cli/main.go`.
- Commands live in `platform/cli/commands/` and are resolved via DI.
- Flags are defined with `cobra` and bound with `viper`.

Included sample flags:

- `--prompt` (required)
- `--system`
- `--model`
- `--json`

## Adding New Commands

1. Create a file in `platform/cli/commands/<command>.go`.
2. Define a `*cobra.Command` with `RunE`.
3. Bind command flags using `viper.BindPFlag`.
4. Register the command under the root command.

## Layer Dependencies

```text
platform -> shared
cmd -> platform + shared
```

Do not allow `shared -> platform` imports.

## Service and Repository Size Rule

- Do not create giant monolithic services or repositories.
- Split responsibilities into multiple focused `.go` files, following `clean-code` (SRP, small units, clear naming).
- Prefer composition of small components over one large file/class handling everything.

## First-Level Business Entities

If a specific domain appears (example: `post`), place it at project root:

```text
post/
├── application/
└── domain/
```

## Checklist

- [ ] Required flags use `MarkFlagRequired` when applicable.
- [ ] Environment variables are supported via `viper.AutomaticEnv()`.
- [ ] Configuration comes from `config.yaml`/env (no hardcoded values).
- [ ] No `platform` imports inside `shared` or `domain`.
- [ ] `go test ./...` and `go vet ./...` pass.

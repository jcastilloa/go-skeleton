# go-skeleton

A scaffolding tool for generating production-ready Go boilerplate projects with **hexagonal architecture**, built-in **AI coding agent support** (AGENTS.md + skills), and an opinionated project structure powered by battle-tested libraries.

## Features

- **Three project types**: HTTP API (Gin), CLI (Cobra + Viper), and MCP server (mcp-go + Cobra + Viper)
- **Hexagonal architecture** out of the box — clean separation between `platform`, `shared`, and domain layers
- **AI agent coverage**: every generated project ships with an `AGENTS.md` and a curated set of coding skills compatible with Codex, Claude, and OpenCode
- **OpenAI-compatible AI repository** included with retry logic, exponential backoff, JSON mode, and provider abstraction
- **Configuration via Viper** — YAML files, environment variables, and `.env` support
- **Dependency injection** in all templates via [sarulabs/di](https://github.com/sarulabs/di)
- **Single binary, zero runtime dependencies** — the scaffold tool compiles to a standalone Go binary

## Prerequisites

- **Go 1.26+** (the scaffold tool itself requires Go; generated projects target Go 1.26)
- **Make** (optional, for convenience targets)

## Quick Start

```bash
# Clone the repository
git clone https://github.com/<your-org>/go-skeleton.git
cd go-skeleton

# Build the scaffold binary
make scaffold-build

# Generate an API project
./tools/scaffold/bin/scaffold new \
  --service my-api \
  --module github.com/acme/my-api \
  --type api

# Generate a CLI project
./tools/scaffold/bin/scaffold new \
  --service my-cli \
  --module github.com/acme/my-cli \
  --type cli

# Generate an MCP project
./tools/scaffold/bin/scaffold new \
  --service my-mcp \
  --module github.com/acme/my-mcp \
  --type mcp
```

The generated project is created under `./<service-name>/` by default.

## Building the Scaffold Tool

```bash
make scaffold-build    # Compiles to ./tools/scaffold/bin/scaffold
make scaffold-clean    # Removes the compiled binary
```

Or build manually:

```bash
cd tools/scaffold && go build -o ./bin/scaffold .
```

## CLI Reference

```
scaffold new [flags]
```

### Required Flags

| Flag        | Description                                        | Example                          |
|-------------|----------------------------------------------------|----------------------------------|
| `--service` | Service name — used as the output folder name      | `--service payments-api`         |
| `--module`  | Go module path for `go.mod`                        | `--module github.com/acme/pay`   |

### Optional Flags

| Flag         | Default | Description                                                                 |
|--------------|---------|-----------------------------------------------------------------------------|
| `--type`     | `api`   | Template type: `api`, `cli`, or `mcp`                                       |
| `--output`   | `.`     | Base output directory (project is created at `<output>/<service>`)           |
| `--template` | —       | Custom template directory; overrides `--type` resolution                    |
| `--force`    | `false` | Overwrite the target directory if it already exists                         |

### Examples

```bash
# API project in the current directory
scaffold new --service billing-api --module github.com/acme/billing-api --type api

# CLI project in a custom output folder
scaffold new --service reports-cli --module github.com/acme/reports-cli --type cli --output ./projects

# MCP project in the current directory
scaffold new --service assistant-mcp --module github.com/acme/assistant-mcp --type mcp

# Overwrite an existing project
scaffold new --service billing-api --module github.com/acme/billing-api --force

# Use a fully custom template directory
scaffold new --service custom-svc --module github.com/acme/custom-svc --template /path/to/my/template
```

## Generated Project Structure

### API Template (`--type api`)

Generates a Gin HTTP API with versioned routes, handler-based architecture, and dependency injection.

```
<service>/
├── AGENTS.md                          # AI agent instructions
├── config.sample.yaml                 # Sample configuration
├── go.mod / go.sum
├── cmd/
│   └── api/
│       └── main.go                    # Application entry point
├── platform/                          # Infrastructure & adapters
│   ├── config/
│   │   └── viper_repository.go        # Viper-based config reader
│   ├── di/
│   │   └── container.go               # Dependency injection container
│   ├── server/
│   │   └── server.go                  # Gin engine setup & route registration
│   ├── routes/
│   │   ├── build_endpoint.go          # Handler ↔ route wiring helper
│   │   ├── hello.go                   # GET /v1/hello
│   │   └── system.go                  # GET /v1/version
│   ├── handlers/
│   │   ├── handler.go                 # Handler interface
│   │   ├── hello/
│   │   │   └── get.go                 # Hello world handler
│   │   └── system/
│   │       └── version.go             # Version handler
│   └── openai/
│       └── openai_repository.go       # OpenAI-compatible AI provider
├── shared/                            # Cross-cutting domain contracts
│   ├── ai/domain/
│   │   ├── entity.go                  # Request / Response / Usage
│   │   ├── provider_config.go         # Provider configuration VO
│   │   └── repository.go              # AIRepository port interface
│   └── config/domain/
│       ├── repository.go              # Config repository port
│       └── service_config.go          # ServiceConfig value object
└── .codex/skills/                     # AI coding skills (+ symlinks)
```

**Included sample endpoints:**

| Method | Path          | Description         |
|--------|---------------|---------------------|
| GET    | `/v1/hello`   | Hello world         |
| GET    | `/v1/version` | Service version     |

### CLI Template (`--type cli`)

Generates a Cobra + Viper command-line application with OpenAI integration and dependency injection.

```
<service>/
├── AGENTS.md
├── config.sample.yaml
├── go.mod / go.sum
├── cmd/
│   └── cli/
│       └── main.go                    # Entry point
├── platform/
│   ├── cli/commands/
│   │   └── root.go                    # Root command + version subcommand
│   ├── config/
│   │   └── viper_repository.go        # Viper-based config reader
│   ├── di/
│   │   └── container.go               # Dependency injection container
│   └── openai/
│       └── openai_repository.go       # OpenAI-compatible AI provider
├── shared/
│   ├── ai/domain/                     # Same AI domain contracts
│   └── config/domain/                 # Same config contracts
└── .codex/skills/
```

**Included CLI flags:**

| Flag       | Required | Description                  |
|------------|----------|------------------------------|
| `--prompt` | Yes      | User prompt                  |
| `--system` | No       | System prompt                |
| `--model`  | No       | Model override               |
| `--json`   | No       | Request JSON response mode   |

Also includes:

- `version` subcommand to print the service version.

### MCP Template (`--type mcp`)

Generates an MCP server skeleton using [`mark3labs/mcp-go`](https://github.com/mark3labs/mcp-go), with Cobra + Viper, dependency injection, and tool wiring ready to extend.

```
<service>/
├── AGENTS.md
├── config.sample.yaml
├── go.mod / go.sum
├── cmd/
│   └── server/
│       └── main.go                    # Entry point
├── mcp/
│   ├── application/
│   │   └── hello/service.go           # Hello use case
│   └── domain/
│       └── hello/repository.go        # Hello domain port
├── platform/
│   ├── config/
│   │   └── viper_repository.go        # Viper-based config reader
│   ├── di/
│   │   └── container.go               # Dependency injection container
│   ├── mcp/
│   │   ├── commands/root.go           # Cobra runner + version command
│   │   ├── server/server.go           # MCP server wrapper
│   │   ├── tools/hello_world.go       # Tool definition + handler
│   │   └── hello/repository.go        # Infra adapter for hello port
│   └── openai/
│       └── openai_repository.go       # OpenAI-compatible AI provider
├── shared/
│   ├── ai/domain/                     # Same AI domain contracts
│   └── config/domain/                 # Service and provider config contracts
└── .codex/skills/
```

**Included sample command and tool:**

| Item       | Description                                      |
|------------|--------------------------------------------------|
| CLI flag   | `--transport` (default `stdio`)                 |
| Subcommand | `version`                                       |
| MCP tool   | `hello_world(name)`                             |

## Running a Generated Project

### API

```bash
cd my-api
cp config.sample.yaml config.yaml   # Edit with your values
go run ./cmd/api/...
```

The server starts at `http://0.0.0.0:8080/v1` by default.

### CLI

```bash
cd my-cli
cp config.sample.yaml config.yaml   # Edit with your values
go run ./cmd/cli/... --prompt "Hello, world!"
```

### MCP

```bash
cd my-mcp
cp config.sample.yaml config.yaml   # Edit with your values
go run ./cmd/server/... --transport stdio
```

## Configuration

Generated projects use [Viper](https://github.com/spf13/viper) and look for configuration in this order:

1. `$HOME/.config/<service-name>/config.yaml`
2. `./config.yaml` (working directory)
3. Environment variables (with `_` replacing `.`, e.g. `SERVICE_PORT=9090`)
4. `.env` file (via [godotenv](https://github.com/joho/godotenv))

### Sample `config.yaml`

```yaml
service:
  host: 0.0.0.0
  port: 8080
  api_prefix: /v1
  version: 0.1.0

openai:
  provider_name: openai
  api_key: sk-xxxx
  base_url: https://api.openai.com/v1
  model: gpt-4o-mini
  timeout: 30s
  max_retries: 3
  supports_system_role: true
  supports_json_mode: true
```

## Architecture

All templates follow a **hexagonal (ports & adapters)** layout:

```
cmd/           → Application bootstrap (main.go)
platform/      → Infrastructure adapters (HTTP server, config, DI, external APIs)
shared/        → Cross-cutting domain contracts (ports, value objects, entities)
<entity>/      → First-level business entities (added by the developer)
  ├── domain/        → Pure business rules (no infrastructure imports)
  └── application/   → Use cases
```

### Layer Dependency Rule

```
platform → shared     ✅
cmd      → platform   ✅
cmd      → shared     ✅
shared   → platform   ❌  (never)
```

## AI Agent Support

Every generated project includes:

### AGENTS.md

A project-specific instruction file that tells AI coding agents (Codex, Claude, OpenCode, Gemini) how the project is structured, what conventions to follow, and how to add new features.

### Bundled Skills

Skills are sourced from `template/skills/` in this repository, then installed into `.codex/skills/` in generated projects, with symlinks at `.claude/skills/` and `.opencode/skills/`:

| Skill                         | Purpose                                      |
|-------------------------------|----------------------------------------------|
| `clean-code`                  | SRP, small units, clear naming               |
| `golang-pro`                  | Modern Go patterns and best practices        |
| `sql-pro`                     | SQL optimization and database patterns       |
| `tdd-workflows-tdd-cycle`     | Full TDD cycle overview                      |
| `tdd-workflows-tdd-red`       | Red phase — write failing tests first        |
| `tdd-workflows-tdd-green`     | Green phase — minimal implementation         |
| `tdd-workflows-tdd-refactor`  | Refactor phase — improve without breaking    |

## Template Tokens

Templates use simple text replacement (no Go `text/template` engine). The following tokens are replaced during generation:

| Token              | Replaced With        |
|--------------------|----------------------|
| `{{SERVICE_NAME}}` | Value of `--service` |
| `{{MODULE_NAME}}`  | Value of `--module`  |

Files with the `.tpl` extension have the suffix stripped and their content processed for token replacement. Files without `.tpl` are copied as-is.

## Project Layout

```
go-skeleton/
├── Makefile                  # Build / clean targets
├── tools/
│   └── scaffold/
│       ├── main.go           # Scaffold CLI source
│       ├── go.mod
│       └── go.sum
└── template/
    ├── api/                  # API project template
    ├── cli/                  # CLI project template
    ├── mcp/                  # MCP project template
    └── skills/               # Shared AI coding skills
```

## License

This project is provided as-is for scaffolding purposes. See individual dependency licenses for their terms.

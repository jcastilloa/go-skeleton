package main

import (
	"errors"
	"fmt"
	"io"
	"io/fs"
	"os"
	"path/filepath"
	"strings"

	"github.com/spf13/cobra"
)

const (
	serviceToken = "{{SERVICE_NAME}}"
	moduleToken  = "{{MODULE_NAME}}"
)

var requiredSkills = []string{
	"clean-code",
	"golang-pro",
	"sql-pro",
	"tdd-workflows-tdd-cycle",
	"tdd-workflows-tdd-red",
	"tdd-workflows-tdd-green",
	"tdd-workflows-tdd-refactor",
}

type options struct {
	service     string
	module      string
	projectType string
	templateDir string
	outputDir   string
	force       bool
}

func main() {
	if err := newRootCommand().Execute(); err != nil {
		fmt.Fprintf(os.Stderr, "scaffold error: %v\n", err)
		os.Exit(1)
	}
}

func newRootCommand() *cobra.Command {
	root := &cobra.Command{
		Use:   "scaffold",
		Short: "Generate Go projects from local templates",
		Long: `scaffold creates new Go projects from local templates in this repository.

Quick start:
  1) Build: make scaffold-build
  2) Generate: ./tools/scaffold/bin/scaffold new --service <name> --module <module> --type <api|cli|mcp>

Template types:
  api  Gin HTTP API with versioned routes (/v1), handlers and server wiring
  cli  Cobra + Viper command-line app scaffold
  mcp  MCP server scaffold (mcp-go) with Cobra + Viper + DI and sample tools

The generated project folder is: <output>/<service>.`,
		Example: `  scaffold new --service payments-api --module github.com/acme/payments-api --type api
  scaffold new --service payments-cli --module github.com/acme/payments-cli --type cli
  scaffold new --service payments-mcp --module github.com/acme/payments-mcp --type mcp
  scaffold new --service billing-api --module github.com/acme/billing-api --output ./projects --force`,
		Args: cobra.NoArgs,
		RunE: func(cmd *cobra.Command, args []string) error {
			return cmd.Help()
		},
	}
	root.CompletionOptions.DisableDefaultCmd = true

	root.AddCommand(newCreateCommand())
	return root
}

func newCreateCommand() *cobra.Command {
	opts := options{}

	cmd := &cobra.Command{
		Use:   "new",
		Short: "Create a project from template/api, template/cli or template/mcp",
		Long: `Create renders one template into a new project directory.

By default scaffold resolves templates in this order:
1) ./template/<type> from current working directory
2) ../../template/<type> relative to the scaffold binary

Required flags:
  --service <name>   output project directory name
  --module  <path>   module path used in go.mod and imports

Supported types:
  api | cli | mcp`,
		Example: `  scaffold new --service users-api --module github.com/acme/users-api --type api
  scaffold new --service users-cli --module github.com/acme/users-cli --type cli
  scaffold new --service users-mcp --module github.com/acme/users-mcp --type mcp
  scaffold new --service users-api --module github.com/acme/users-api --template /custom/template/api`,
		RunE: func(cmd *cobra.Command, args []string) error {
			opts = normalizeOptions(opts)
			return run(opts)
		},
	}

	cmd.Flags().StringVar(&opts.service, "service", "", "service name, used as output folder name")
	cmd.Flags().StringVar(&opts.module, "module", "", "Go module path (example: github.com/acme/service)")
	cmd.Flags().StringVar(&opts.projectType, "type", "api", "template type: api, cli or mcp")
	cmd.Flags().StringVar(&opts.templateDir, "template", "", "custom template directory; overrides --type")
	cmd.Flags().StringVar(&opts.outputDir, "output", ".", "base output directory")
	cmd.Flags().BoolVar(&opts.force, "force", false, "overwrite existing target directory if it already exists")
	cmd.Flags().SortFlags = false

	_ = cmd.MarkFlagRequired("service")
	_ = cmd.MarkFlagRequired("module")

	return cmd
}

func run(opts options) error {
	if err := validateOptions(opts); err != nil {
		return err
	}

	targetRoot := filepath.Join(opts.outputDir, opts.service)
	if err := prepareTargetRoot(targetRoot, opts.force); err != nil {
		return err
	}

	replacements := map[string]string{
		serviceToken: opts.service,
		moduleToken:  opts.module,
	}

	filesWritten, err := renderTemplate(opts.templateDir, targetRoot, replacements, opts.force)
	if err != nil {
		return err
	}

	skillsCopied, err := installSkills(targetRoot)
	if err != nil {
		return err
	}

	fmt.Printf("project created: %s\n", targetRoot)
	fmt.Printf("files written: %d\n", filesWritten)
	fmt.Printf("skills copied: %d\n", skillsCopied)
	return nil
}

func normalizeOptions(opts options) options {
	if strings.TrimSpace(opts.templateDir) != "" {
		return opts
	}

	cwdCandidate := filepath.Join("template", opts.projectType)
	if dirExists(cwdCandidate) {
		opts.templateDir = cwdCandidate
		return opts
	}

	exePath, err := os.Executable()
	if err != nil {
		opts.templateDir = cwdCandidate
		return opts
	}

	binaryCandidate := filepath.Join(filepath.Dir(exePath), "..", "..", "template", opts.projectType)
	binaryCandidate = filepath.Clean(binaryCandidate)
	if dirExists(binaryCandidate) {
		opts.templateDir = binaryCandidate
		return opts
	}

	opts.templateDir = cwdCandidate
	return opts
}

func validateOptions(opts options) error {
	if strings.TrimSpace(opts.service) == "" {
		return errors.New("--service is required")
	}
	if strings.TrimSpace(opts.module) == "" {
		return errors.New("--module is required")
	}
	if strings.Contains(opts.service, string(filepath.Separator)) {
		return fmt.Errorf("invalid --service value %q: cannot contain path separators", opts.service)
	}
	if opts.service == "." || opts.service == ".." {
		return fmt.Errorf("invalid --service value %q", opts.service)
	}
	if opts.projectType != "api" && opts.projectType != "cli" && opts.projectType != "mcp" {
		return fmt.Errorf("invalid --type value %q: expected api, cli or mcp", opts.projectType)
	}

	info, err := os.Stat(opts.templateDir)
	if err != nil {
		return fmt.Errorf("template directory not accessible: %w", err)
	}
	if !info.IsDir() {
		return fmt.Errorf("template path is not a directory: %s", opts.templateDir)
	}

	return nil
}

func prepareTargetRoot(targetRoot string, force bool) error {
	info, err := os.Stat(targetRoot)
	if err == nil {
		if !info.IsDir() {
			return fmt.Errorf("target path exists and is not a directory: %s", targetRoot)
		}
		if !force {
			return fmt.Errorf("target directory already exists: %s (use --force to overwrite)", targetRoot)
		}
		return nil
	}

	if !errors.Is(err, os.ErrNotExist) {
		return fmt.Errorf("cannot inspect target path: %w", err)
	}

	if mkErr := os.MkdirAll(targetRoot, 0o755); mkErr != nil {
		return fmt.Errorf("cannot create target directory: %w", mkErr)
	}

	return nil
}

func renderTemplate(templateDir, targetRoot string, replacements map[string]string, force bool) (int, error) {
	filesWritten := 0

	err := filepath.WalkDir(templateDir, func(path string, d fs.DirEntry, walkErr error) error {
		if walkErr != nil {
			return walkErr
		}
		if path == templateDir {
			return nil
		}

		relPath, err := filepath.Rel(templateDir, path)
		if err != nil {
			return fmt.Errorf("resolve relative path for %s: %w", path, err)
		}

		renderedRel := renderString(relPath, replacements)
		targetPath := filepath.Join(targetRoot, renderedRel)
		if err := ensureSubPath(targetRoot, targetPath); err != nil {
			return err
		}

		if d.IsDir() {
			return os.MkdirAll(targetPath, 0o755)
		}

		content, err := os.ReadFile(path)
		if err != nil {
			return fmt.Errorf("read template file %s: %w", path, err)
		}

		if strings.HasSuffix(renderedRel, ".tpl") {
			renderedRel = strings.TrimSuffix(renderedRel, ".tpl")
			targetPath = filepath.Join(targetRoot, renderedRel)
			if err := ensureSubPath(targetRoot, targetPath); err != nil {
				return err
			}
			content = []byte(renderString(string(content), replacements))
		}

		if err := os.MkdirAll(filepath.Dir(targetPath), 0o755); err != nil {
			return fmt.Errorf("create target parent dir for %s: %w", targetPath, err)
		}

		if !force {
			if _, err := os.Stat(targetPath); err == nil {
				return fmt.Errorf("target file already exists: %s", targetPath)
			} else if !errors.Is(err, os.ErrNotExist) {
				return fmt.Errorf("cannot inspect target file %s: %w", targetPath, err)
			}
		}

		mode := fs.FileMode(0o644)
		if info, err := d.Info(); err == nil {
			mode = info.Mode().Perm()
		}

		if err := os.WriteFile(targetPath, content, mode); err != nil {
			return fmt.Errorf("write file %s: %w", targetPath, err)
		}

		filesWritten++
		return nil
	})

	if err != nil {
		return 0, err
	}

	return filesWritten, nil
}

func renderString(input string, replacements map[string]string) string {
	output := input
	for key, value := range replacements {
		output = strings.ReplaceAll(output, key, value)
	}
	return output
}

func ensureSubPath(root, candidate string) error {
	cleanRoot := filepath.Clean(root)
	cleanCandidate := filepath.Clean(candidate)

	rel, err := filepath.Rel(cleanRoot, cleanCandidate)
	if err != nil {
		return fmt.Errorf("resolve relative path from %s to %s: %w", cleanRoot, cleanCandidate, err)
	}
	if rel == ".." || strings.HasPrefix(rel, ".."+string(filepath.Separator)) {
		return fmt.Errorf("target path escapes output directory: %s", candidate)
	}
	return nil
}

func dirExists(path string) bool {
	info, err := os.Stat(path)
	return err == nil && info.IsDir()
}

func installSkills(targetRoot string) (int, error) {
	sourceSkillsRoot, err := resolveSourceSkillsRoot()
	if err != nil {
		return 0, err
	}

	targetSkillsRoot := filepath.Join(targetRoot, ".codex", "skills")
	if err := os.MkdirAll(targetSkillsRoot, 0o755); err != nil {
		return 0, fmt.Errorf("create target skills root: %w", err)
	}

	copied := 0
	for _, skill := range requiredSkills {
		src := filepath.Join(sourceSkillsRoot, skill)
		dst := filepath.Join(targetSkillsRoot, skill)

		if err := os.RemoveAll(dst); err != nil {
			return copied, fmt.Errorf("clear destination skill %s: %w", skill, err)
		}
		if err := copyDir(src, dst); err != nil {
			return copied, fmt.Errorf("copy skill %s: %w", skill, err)
		}
		copied++
	}

	if err := ensureSkillsSymlink(targetRoot, ".claude", ".codex"); err != nil {
		return copied, err
	}
	if err := ensureSkillsSymlink(targetRoot, ".opencode", ".codex"); err != nil {
		return copied, err
	}

	return copied, nil
}

func resolveSourceSkillsRoot() (string, error) {
	// Packaged skills are stored under template/skills in this repository.
	localCandidates := []string{
		filepath.Join("template", "skills"),
		filepath.Join("..", "template", "skills"),
		filepath.Join("..", "..", "template", "skills"),
	}
	for _, candidate := range localCandidates {
		if dirExists(candidate) {
			return candidate, nil
		}
	}

	// If executed from a built binary, resolve relative to the binary path.
	exePath, err := os.Executable()
	if err == nil {
		exeCandidates := []string{
			filepath.Join(filepath.Dir(exePath), "..", "..", "..", "template", "skills"),
			filepath.Join(filepath.Dir(exePath), "..", "..", "template", "skills"),
		}
		for _, candidate := range exeCandidates {
			candidate = filepath.Clean(candidate)
			if dirExists(candidate) {
				return candidate, nil
			}
		}
	}

	return "", fmt.Errorf("skills source not found: expected template/skills in this repository")
}

func ensureSkillsSymlink(projectRoot, aliasDirName, canonicalDirName string) error {
	aliasRoot := filepath.Join(projectRoot, aliasDirName)
	if err := os.MkdirAll(aliasRoot, 0o755); err != nil {
		return fmt.Errorf("create %s dir: %w", aliasDirName, err)
	}

	linkPath := filepath.Join(aliasRoot, "skills")
	if err := os.RemoveAll(linkPath); err != nil {
		return fmt.Errorf("clear %s link: %w", linkPath, err)
	}

	target := filepath.Join("..", canonicalDirName, "skills")
	if err := os.Symlink(target, linkPath); err != nil {
		return fmt.Errorf("create symlink %s -> %s: %w", linkPath, target, err)
	}

	return nil
}

func copyDir(srcRoot, dstRoot string) error {
	if !dirExists(srcRoot) {
		return fmt.Errorf("source directory does not exist: %s", srcRoot)
	}

	return filepath.WalkDir(srcRoot, func(path string, d fs.DirEntry, walkErr error) error {
		if walkErr != nil {
			return walkErr
		}

		rel, err := filepath.Rel(srcRoot, path)
		if err != nil {
			return err
		}
		dst := filepath.Join(dstRoot, rel)

		if d.IsDir() {
			return os.MkdirAll(dst, 0o755)
		}

		info, err := d.Info()
		if err != nil {
			return err
		}

		return copyFile(path, dst, info.Mode().Perm())
	})
}

func copyFile(src, dst string, mode fs.FileMode) error {
	in, err := os.Open(src)
	if err != nil {
		return err
	}
	defer in.Close()

	if err := os.MkdirAll(filepath.Dir(dst), 0o755); err != nil {
		return err
	}

	out, err := os.OpenFile(dst, os.O_CREATE|os.O_TRUNC|os.O_WRONLY, mode)
	if err != nil {
		return err
	}

	if _, err := io.Copy(out, in); err != nil {
		_ = out.Close()
		return err
	}

	return out.Close()
}

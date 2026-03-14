.PHONY: help scaffold-build scaffold-clean

SCAFFOLD_DIR := ./tools/scaffold
SCAFFOLD_BIN := $(SCAFFOLD_DIR)/bin/scaffold

help:
	@echo "Targets:"
	@echo "  make scaffold-build"
	@echo "  make scaffold-clean"
	@echo ""
	@echo "Usage after build:"
	@echo "  $(SCAFFOLD_BIN) new --service <name> --module <module> --type <api|cli|mcp> [--output .] [--force]"

scaffold-build:
	@mkdir -p $(dir $(SCAFFOLD_BIN))
	@cd $(SCAFFOLD_DIR) && go build -o ./bin/scaffold .
	@echo "built: $(SCAFFOLD_BIN)"

scaffold-clean:
	@rm -f $(SCAFFOLD_BIN)
	@echo "cleaned: $(SCAFFOLD_BIN)"

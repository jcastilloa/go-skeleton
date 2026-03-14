package hello

import (
	"fmt"
	"strings"

	domain "{{MODULE_NAME}}/mcp/domain/hello"
)

type Repository struct{}

func NewRepository() domain.Repository {
	return Repository{}
}

func (r Repository) Greet(name string) string {
	cleanName := strings.TrimSpace(name)
	if cleanName == "" {
		cleanName = "world"
	}
	return fmt.Sprintf("Hello, %s!", cleanName)
}

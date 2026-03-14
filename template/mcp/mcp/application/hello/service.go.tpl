package hello

import (
	"strings"

	domain "{{MODULE_NAME}}/mcp/domain/hello"
)

type Service struct {
	repository domain.Repository
}

func NewService(repository domain.Repository) Service {
	return Service{repository: repository}
}

func (s Service) Execute(name string) string {
	cleanName := strings.TrimSpace(name)
	if cleanName == "" {
		cleanName = "world"
	}
	return s.repository.Greet(cleanName)
}
